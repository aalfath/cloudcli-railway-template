# Deploy and Host CloudCLI on Railway

CloudCLI (formerly Claude Code UI) is an open-source web and mobile interface for AI coding agents: Claude Code, OpenAI Codex and OpenCode. It gives you chat, a file tree with an editor, a git panel and a terminal in the browser, so you can run and follow agent sessions on a server from any device.

## About Hosting CloudCLI

This unofficial template runs CloudCLI UI 1.37.9 (https://github.com/siteboon/claudecodeui, AGPL-3.0, by Siteboon AI B.V.) as one Railway service, built from a public GitHub repo that pins the official npm release on a pinned Node 22 image. Claude Code, Codex and OpenCode come preinstalled. A volume at `/home/node` keeps your login database, chat history, agent logins and projects. Your login is created from generated variables before the public URL opens, so nobody else can claim the app. After deploying, open the URL, sign in with `CLOUDCLI_USERNAME` and `CLOUDCLI_PASSWORD` from the service's Variables tab, then sign in to an agent (subscription login or API key) in Settings → Agents. Updates arrive as Railway update notices when the repo is bumped.

## Common Use Cases

* Start a Claude Code or Codex task from your phone and check on it later without keeping a laptop open
* Keep long-running agent sessions, chat history and agent logins on a server you control
* Work on your Git repos from any browser with a terminal, file editor and git panel

## Dependencies for CloudCLI Hosting

* A Claude Pro/Max subscription or an Anthropic API key (Claude Code), a ChatGPT plan or OpenAI API key (Codex), or any provider key OpenCode supports
* A Railway volume for `/home/node` (included)

### Deployment Dependencies

* CloudCLI source and releases: https://github.com/siteboon/claudecodeui (v1.37.9)
* CloudCLI documentation: https://cloudcli.ai/docs
* Claude Code: https://docs.anthropic.com/en/docs/claude-code
* OpenAI Codex CLI: https://github.com/openai/codex
* OpenCode: https://github.com/sst/opencode
* Template source: https://github.com/aalfath/cloudcli-railway-template

### Implementation Details

One service, **CloudCLI**, listens on `PORT` 3001 with a health check on `/health`. Its variables:

* `CLOUDCLI_USERNAME` (default `admin`) and `CLOUDCLI_PASSWORD` (generated): your login. CloudCLI has no password-change page, so change the variable and redeploy; that also signs every browser out.
* `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`: optional. Leave empty and sign in from CloudCLI instead.

Everything stateful lives on the volume: `~/.cloudcli/auth.db` (login, sessions, settings), `~/.claude`, `~/.codex`, `~/.local/share/opencode` and `~/projects` for your code. The server runs as the unprivileged `node` user, and a crash exits non-zero so Railway restarts it.

Memory: the web app idles at about 150 MB, and each agent run adds its own process. One Claude Code or Codex session fits the Free plan's 0.5 GB; for several sessions at once or large repositories, give the service 1–2 GB (Hobby plan). Docker-in-Docker sandboxes are not available on Railway. To update, apply Railway's update notice: the repo's `CHANGELOG.md` lists each version and your volume is kept.

## Why Deploy CloudCLI on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying CloudCLI on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
