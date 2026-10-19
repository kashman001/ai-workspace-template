<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 9 (2026-10-18): plan 04-adopt opened, wave 1 done (rule fixes + Copilot test)

**Summary.** Opened plan `plans/04-adopt` (7 nodes, 3 waves). Wave 1 closed:
node 02 made the four rule fixes in `prototype/DIAGRAMS.md` / `AUTHORING.md`
(`31f92e5`); node 01 ran Copilot CLI 1.0.96 on the fixed rules, two rounds,
40 shots viewed: **4/5 unaided, 5/5 after shots** (`1772a6c`; RESULTS
"Session 9"). Reconcile w1 done. Rolled over near WARN (119K) before the
move-and-convert node.

**Decisions.** `decisions.md` → "Rule fixes before the Copilot run".

**Runtime facts found.** Copilot `-p … --sandbox --no-ask-user` with scoped
`--allow-tool` (no `--allow-all`) is allowed by Claude Code auto mode; Chrome
aborts inside its sandbox, so it can't render-check; it handed back honestly.

**Open.** Nodes 04 (move + convert), 05, 06 (docs/backlog/TADR), 07.

**Suggested skills.** `plans` (reconcile nodes), `decision-log` promote.

Learnings:
- macOS has no `timeout`; zsh doesn't word-split `$VAR` flags — pass `--project x` literally.
- Kit decision is template machinery → promote as a TADR in `docs/template-adr/` (next 0015), not `docs/adr/`.

# Session Handoff — 8 (2026-10-18): plan 03 done, cross-runtime proven; user chose ADOPT

**Summary.** Plan `plans/03-adoption-readiness` finished (8/8). Node 07: one
brief (`prototype/xrt/brief.md`), Codex and Gemini each rebuilt the setup guide
from the rules alone, two rounds each; the main session ran the render check for
them and viewed all 80 shots. Codex 0/5 figures unaided → 4/5 after seeing shots;
Gemini 2/5 → 5/5. Greps and link check clean every round; only the render check
caught figure faults. Detail: `prototype/RESULTS.md` → "Session 8". Commits
`2bfb81a`, `d93064a`. The user then chose **adopt** (small first step).

**Decisions.** `decisions.md` → "Adopt the HTML kit, small first step" (scope,
rejected alternatives, user reviews nothing — Claude Code reviews diagram pages).

**Runtime facts found.** Codex `exec -s workspace-write`: Chrome aborts in the
sandbox. Gemini CLI 0.46: free tier refused (`IneligibleTierError`) — use
Antigravity `agy` (Gemini 4 Argon). `agy --mode accept-edits` headless denies
every shell command. Launching `--dangerously-*` / unsandboxed agents is denied
by Claude Code auto mode; sandboxed ones were allowed (agy needed the user's OK).

**Open.** Copilot CLI (1.0.96, installed) untested — user asked whether the kit
works there; VS Code agent mode can only be tested by the user.

**Suggested skills.** `plans` (plan 04 for adoption), `decision-log` promote → ADR.

Learnings:
- Contact sheet for shots: HTML grid of `<img>` + headless Chrome `--screenshot`, one sheet per width; read sheet, then zoom single shots that look off.

