# CloudCLI on Railway

One-click [Railway](https://railway.com) template for **CloudCLI UI** (formerly Claude Code UI): a web and mobile interface for Claude Code, OpenAI Codex and OpenCode, with chat, a file tree and editor, a git panel and a terminal.

> Based on **CloudCLI UI (https://github.com/siteboon/claudecodeui)** by Siteboon AI B.V., licensed AGPL-3.0-or-later. This repository is an unofficial Railway packaging, not the original CloudCLI UI software; it changes no CloudCLI code.

## What it deploys

| Service | What it does |
|---|---|
| **CloudCLI** | CloudCLI UI **1.37.9** (npm `@cloudcli-ai/cloudcli@1.37.9`, tarball and the tag's `package-lock.json` checked by sha256) on `node:22.23.5-bookworm-slim@sha256:e9f565d3…`. Claude Code (the native binary bundled with the Claude Agent SDK 0.3.311), Codex 0.166.0 and OpenCode 1.19.5 are preinstalled. Port `3001`, health check `/health`, volume at `/home/node`. |

Upstream publishes no server image, so the `Dockerfile` here builds the official npm release on a pinned Node image.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `CLOUDCLI_USERNAME` | `admin` | Your login name (3+ characters). |
| `CLOUDCLI_PASSWORD` | generated (`${{secret(24)}}`) | Your password (8+ characters). |
| `ANTHROPIC_API_KEY` | empty, optional | For Claude Code. Or sign in with a Claude subscription from CloudCLI. |
| `OPENAI_API_KEY` | empty, optional | For Codex. Or sign in with ChatGPT from CloudCLI. |
| `PORT` | `3001` | Leave as is. |

CloudCLI normally lets the first visitor create the only account. Here the start script creates the login from `CLOUDCLI_USERNAME`/`CLOUDCLI_PASSWORD` **before** the public port opens, and refuses to start without them. CloudCLI has no password-change page: change the variables and redeploy (every browser is signed out). The login variables are removed from the environment that terminals and agents see.

## After deploying

1. Open the service URL and sign in with `CLOUDCLI_USERNAME` and `CLOUDCLI_PASSWORD` (service → Variables).
2. In Settings → Agents, sign in to Claude Code, Codex or OpenCode (subscription login or API key).
3. Clone a repo into `~/projects` from the terminal and open it as a project.

## Data

Everything lives on the volume mounted at `/home/node` (the app user's home): `~/.cloudcli/auth.db` (login, sessions, settings), `~/.claude`, `~/.codex`, `~/.local/share/opencode`, and your code in `~/projects`.

## Memory

The web app idles around 150 MB. Each agent run starts its own process (Claude Code, Codex or OpenCode). One session at a time fits Railway's Free plan (0.5 GB); for parallel sessions or large repos give the service 1–2 GB. The server's JavaScript heap is sized from the service's memory limit, git is capped for small memory (`/etc/gitconfig`), and an unexpected stop exits non-zero so Railway's `ON_FAILURE` policy restarts it. Docker-in-Docker sandboxes are not available on Railway.

## Updates

Railway shows an update notice when this repo's `main` changes. Read `CHANGELOG.md` before applying; your volume is kept. The agents' self-updaters are switched off (the image is read-only for them); new versions come through this repo.

## License

The packaging files here are AGPL-3.0-or-later, like CloudCLI UI. CloudCLI UI's [additional terms](https://github.com/siteboon/claudecodeui/blob/main/LICENSE) apply: keep the attribution above, and "CloudCLI" and "Siteboon" are trademarks of Siteboon AI B.V.
