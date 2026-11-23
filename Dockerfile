# CloudCLI (siteboon/claudecodeui) for Railway.
# Upstream publishes no server image (its docker/ folder holds Docker Sandbox
# templates), so this builds the official npm release on a pinned Node image,
# with the dependency tree locked to the release tag's package-lock.json.

ARG NODE_IMAGE=node:22.23.5-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee

FROM ${NODE_IMAGE} AS build
# CloudCLI release (npm tarball + the lockfile from the same tag, both checked by sha256)
ARG CLOUDCLI_VERSION=1.37.9
ARG CLOUDCLI_COMMIT=f86543fad81d5687bea98644b752fa08fa0da538
ARG CLOUDCLI_TGZ_SHA256=dee7aac06e0535d582c009cfee26d44abd53efa6448c7d16823d9eaa8d735525
ARG CLOUDCLI_LOCK_SHA256=4251b1b658cd435e86bbb7488ad6d0409b28acba354d9dd5c37f5191b9763581
# OpenCode CLI, same version as the @opencode-ai/sdk in CloudCLI's lockfile
ARG OPENCODE_VERSION=1.19.5
ENV CIRCLE_NODE_TOTAL=2 npm_config_jobs=2
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential python3 ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN curl -fsSL --retry 3 -o cloudcli.tgz "https://registry.npmjs.org/@cloudcli-ai/cloudcli/-/cloudcli-${CLOUDCLI_VERSION}.tgz" \
 && echo "${CLOUDCLI_TGZ_SHA256}  cloudcli.tgz" | sha256sum -c - \
 && tar xzf cloudcli.tgz && mv package cloudcli && rm cloudcli.tgz \
 && curl -fsSL --retry 3 -o cloudcli/package-lock.json "https://raw.githubusercontent.com/siteboon/claudecodeui/${CLOUDCLI_COMMIT}/package-lock.json" \
 && echo "${CLOUDCLI_LOCK_SHA256}  cloudcli/package-lock.json" | sha256sum -c -
WORKDIR /opt/cloudcli
# --ignore-scripts skips the repo's dev-only hooks (husky); the native modules are built right after.
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
 && npm rebuild better-sqlite3 bcrypt node-pty @vscode/ripgrep \
 && node scripts/fix-node-pty.js \
 && rm -rf node_modules/@nut-tree-fork node_modules/screenshot-desktop \
 && npm cache clean --force
RUN npm install --prefix /opt/opencode --no-audit --no-fund "opencode-ai@${OPENCODE_VERSION}" \
 && /opt/opencode/node_modules/.bin/opencode --version \
 && npm cache clean --force

FROM ${NODE_IMAGE}
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client procps ripgrep jq less unzip zip python3 tini \
 && rm -rf /var/lib/apt/lists/* \
 && command -v setpriv
COPY --from=build /opt/cloudcli /opt/cloudcli
COPY --from=build /opt/opencode /opt/opencode
RUN chmod 755 /opt/cloudcli/dist-server/server/modules/cli/cli.js \
 && ln -s /opt/cloudcli/dist-server/server/modules/cli/cli.js /usr/local/bin/cloudcli \
 && ln -s /opt/cloudcli/node_modules/@anthropic-ai/claude-agent-sdk-linux-x64/claude /usr/local/bin/claude \
 && ln -s /opt/cloudcli/node_modules/@openai/codex/bin/codex.js /usr/local/bin/codex \
 && ln -s /opt/opencode/node_modules/.bin/opencode /usr/local/bin/opencode \
 && cloudcli version && claude --version && codex --version && opencode --version
COPY gitconfig /etc/gitconfig
COPY start.sh /usr/local/bin/cloudcli-railway-start
COPY sync-login.mjs /opt/railway/sync-login.mjs
RUN chmod 755 /usr/local/bin/cloudcli-railway-start

# The agents' own updaters can't write to /opt or /usr/local; updates come from this repo.
ENV NODE_ENV=production \
    PORT=3001 \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    OPENCODE_DISABLE_AUTOUPDATE=1 \
    OPENCODE_DISABLE_MODELS_FETCH=1 \
    FS_CONCURRENCY=8 \
    UV_THREADPOOL_SIZE=4

EXPOSE 3001
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/cloudcli-railway-start"]
