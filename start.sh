#!/bin/sh
# Start CloudCLI on Railway: prepare the volume, sync the login, then run the
# server as the unprivileged "node" user. Any failure exits non-zero, so
# Railway's ON_FAILURE restart policy brings the service back.
set -eu

H=/home/node
log() { echo "[railway] $*"; }

# A fresh Railway volume is owned by root and holds lost+found.
rmdir "$H/lost+found" 2>/dev/null || true
if [ "$(stat -c %u "$H")" != "1000" ]; then
  log "giving the node user ownership of $H"
  chown -R node:node "$H"
fi

as_node() { setpriv --reuid=node --regid=node --init-groups env HOME="$H" USER=node LOGNAME=node SHELL=/bin/bash "$@"; }

as_node mkdir -p "$H/.cloudcli" "$H/projects"
for f in .bashrc .profile; do
  [ -e "$H/$f" ] || as_node cp "/etc/skel/$f" "$H/$f"
done

export DATABASE_PATH="$H/.cloudcli/auth.db"
as_node node /opt/railway/sync-login.mjs

# The web login stays out of the environment that terminals and agents inherit.
unset CLOUDCLI_USERNAME CLOUDCLI_PASSWORD

# Size the server's JavaScript heap from the service's memory limit, leaving
# room for the coding agent it runs (Claude Code, Codex or OpenCode).
LIMIT=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [ "$LIMIT" = "max" ] || [ "$LIMIT" -gt 8589934592 ] 2>/dev/null; then
  HEAP=1024
else
  HEAP=$(( LIMIT / 1048576 * 35 / 100 ))
  [ "$HEAP" -lt 160 ] && HEAP=160
fi
log "memory limit: $LIMIT bytes, server heap: ${HEAP} MB"

export SERVER_PORT="${PORT:-3001}" HOST=0.0.0.0
log "starting CloudCLI $(cloudcli version 2>/dev/null | tail -n1) on port $SERVER_PORT"
cd "$H"
exec setpriv --reuid=node --regid=node --init-groups env HOME="$H" USER=node LOGNAME=node SHELL=/bin/bash \
  node --max-old-space-size="$HEAP" /opt/cloudcli/dist-server/server/modules/cli/cli.js start
