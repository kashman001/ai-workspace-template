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
| `gh` | **required** | GitHub CLI — the workspace's GitHub path (auth, PRs, API) |
| `jq` | **required** | context-budget accounting (`scripts/context-budget.sh`) |
| context-budget hooks | **required** | wiring, not a binary — `scripts/setup.sh` copies `.claude/settings.json.example` → `.claude/settings.local.json` |
| `node` / `npx` | recommended | Claude Code status line (`ccstatusline`) |
| `uv` | recommended | graphify install (`uv tool install "graphifyy[mcp]"`) |
| `python3` | recommended | graphify runtime / general tooling |
| `yt-dlp` | recommended | workspace-local YouTube transcript MCP server |
| `graphify` | optional | per-repo knowledge graph |

## 2. Install commands per OS

Detect OS via `uname -s` (`Darwin`=macOS, `Linux`=Linux, `MINGW*/MSYS*`=Windows Git Bash).

### macOS (Homebrew)
```bash
brew install git gh jq node uv yt-dlp
# graphify: uv tool install "graphifyy[mcp]"
```

### Linux (Debian/Ubuntu — adapt for dnf/pacman)
```bash
sudo apt-get update && sudo apt-get install -y git jq
# gh:    https://github.com/cli/cli#installation
# node:  https://nodejs.org  (or nvm)
# uv:    curl -LsSf https://astral.sh/uv/install.sh | sh
# yt-dlp: sudo apt-get install -y yt-dlp  (or: python3 -m pip install --user yt-dlp)
# graphify: uv tool install "graphifyy[mcp]"
```

### Windows (winget; run in PowerShell, then use Git Bash for the scripts)
```powershell
winget install Git.Git GitHub.cli jqlang.jq OpenJS.NodeJS astral-sh.uv yt-dlp.yt-dlp
# graphify: uv tool install "graphifyy[mcp]"
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
