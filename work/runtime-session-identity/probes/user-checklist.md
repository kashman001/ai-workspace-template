# Post-fix probes: steps for the user (s9)

The question: does each surface bind and measure **its own** session, even with two sessions
open at once in one folder? The agent already ran what it could from a terminal (see the
"Post-fix (s9)" sections in `claude-cli.md`, `codex-cli.md`, `copilot-cli.md` and
`antigravity-cli.md`). The rows below need a person, either for a trust prompt or for clicks
in an editor. Each one takes about 5 minutes.

## Setup (already done)

The probe clone is `~/Developer/experiments/ws-identity-probe-s9`. It is a throwaway copy of
the workspace with every hook wrapped so it logs what it receives into `probe-out/`. Run every
step below **in that folder**, never in the real workspace. When anything asks whether to trust
the folder or its hooks, answer **Yes**: hooks don't run in an untrusted folder.

## The same two steps in every row

In **each** of the two sessions, send:

> Run `./probe-env.sh <runtime> <label>` and then `scripts/context-budget.sh check`, and show me
> the output.

Then send one more short message (`ok`) in each session, so the end-of-turn hooks fire.

**Pass:** each session's `artifact=` line names its own transcript (not the other session's),
and `.context-budget/sessions/` gets exactly one record per session.

## Checklist

| # | Surface | How to open two sessions | `<runtime>` | Labels |
|---|---|---|---|---|
| 1 | Copilot CLI: hooks | Two terminals, `cd` into the clone, run `copilot` in each. Accept the folder-trust prompt. | `copilot-cli` | `copilot-A`, `copilot-B` |
| 2 | Antigravity CLI: agent shell | Two terminals in the clone, run `agy` in each. Approve the shell command when asked. | `antigravity` | `agy-A`, `agy-B` |
| 3 | Claude Code: VS Code extension | `code ~/Developer/experiments/ws-identity-probe-s9`, then open **two** Claude chats (new tab/panel each). | `claude` | `cc-vscode-A`, `cc-vscode-B` |
| 4 | Codex: VS Code extension | Same window, open **two** new Codex chats. The hook config changed since the last probe, so Codex should ask to trust the hooks again: accept it, then send `ok` once more in each chat (trust applies after the prompting turn). | `codex` | `codex-vscode-A`, `codex-vscode-B` |
| 5 | Copilot Chat: VS Code agent mode | Same window, open Copilot Chat in **Agent** mode, two chats. | `copilot-vscode` | `copilot-vscode-A`, `copilot-vscode-B` |

Optional, if you use them (backlog L86): the Antigravity IDE/app (`antigravity`, labels
`ag-ide-A/B`) and the Codex desktop app (`codex`, labels `codex-app-A/B`).

For row 3, also note anything odd, for example extra idle Claude processes when the folder opens.
The last probe saw the extension pre-spawn two of them.

## When done

Tell the agent **"probes done"** and which rows you ran. It reads `probe-out/env-<label>.log`,
`probe-out/hook-*.log` and `.context-budget/sessions/` in the clone and writes up the results.
