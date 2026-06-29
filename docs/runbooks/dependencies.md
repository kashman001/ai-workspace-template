<!--
File: docs/runbooks/dependencies.md
Purpose: Agent-followable runbook to install the tools this workspace expects, per OS.
Paired check: scripts/check-dependencies.sh
-->

# Runbook — Install Dependencies

**Goal:** every tool the workspace's workflow uses is on `PATH`. Required tools
block setup; recommended tools are per-feature.

## 0. Assess

```bash
./scripts/check-dependencies.sh
```

Act only on items the check reports as missing. Re-run after each install.

## 1. Tools and what needs them

| Tool | Required? | Needed for |
|---|---|---|
| `git` | **required** | clone, symlinks, registry |
| `gh` | recommended | GitHub auth + MCP token (`gh auth token`) |
| `node` / `npx` | recommended | Claude Code status line (`ccstatusline`) |
| `uv` | recommended | graphify install (`uv tool install graphifyy`) |
| `python3` | recommended | graphify runtime / general tooling |
| `yt-dlp` | recommended | workspace-local YouTube transcript MCP server |
| `docker` | optional | local GitHub MCP server (vs. the hosted one) |
| `graphify` | optional | per-repo knowledge graph |

## 2. Install commands per OS

Detect OS via `uname -s` (`Darwin`=macOS, `Linux`=Linux, `MINGW*/MSYS*`=Windows Git Bash).

### macOS (Homebrew)
```bash
brew install git gh node uv yt-dlp
# docker: brew install --cask docker   (then launch Docker.app once)
# graphify: uv tool install graphifyy
```

### Linux (Debian/Ubuntu — adapt for dnf/pacman)
```bash
sudo apt-get update && sudo apt-get install -y git
# gh:    https://github.com/cli/cli#installation
# node:  https://nodejs.org  (or nvm)
# uv:    curl -LsSf https://astral.sh/uv/install.sh | sh
# yt-dlp: sudo apt-get install -y yt-dlp  (or: python3 -m pip install --user yt-dlp)
# docker: https://docs.docker.com/engine/install/
# graphify: uv tool install graphifyy
```

### Windows (winget; run in PowerShell, then use Git Bash for the scripts)
```powershell
winget install Git.Git GitHub.cli OpenJS.NodeJS astral-sh.uv yt-dlp.yt-dlp
# docker: winget install Docker.DockerDesktop
# graphify: uv tool install graphifyy
```
> The `scripts/*.sh` are bash — run them under **Git Bash** or WSL on Windows.

## 3. Verify

```bash
./scripts/check-dependencies.sh   # expect: "Required dependencies present."
```

Install graphify's agent skill if you use it (see `../recommended-tooling.md`):
```bash
graphify install --platform claude
```
