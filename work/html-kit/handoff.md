<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 7 (2026-10-18): plan 03 wave 1 done; cross-runtime test next

**Summary.** Plan `plans/03-adoption-readiness` wave 1 closed (nodes 01–06),
commit `61e8474`. Nodes 03 (check-links) and 04 (portable render-check, Linux
run in a Debian container) ran in parallel subagents; the main session did
01, 02, 05 and viewed every sample shot itself (contact sheets
`prototype/shots/s7/sheet-a.png`, `sheet-b.png`). Rolled over at the wave
boundary near WARN; node 07 needs a fresh budget.

**Shipped** (all under `prototype/`): `DIAGRAMS.md` split out of `AUTHORING.md`
(o200k: 2,812 → 1,999 up front; 3,010 with diagrams); wide-SVG phone scroll
(`kit.js` `data-wide` flag, `kit.css` media rule); `check-links.sh`;
`render-check.sh` Chrome/cropper lookup for macOS + Linux; `kit-sample.html`
regression page; the example's `rework` label moved off its arc (y=93).
Detail and numbers: `prototype/RESULTS.md` → "Session 7".

**Decisions.** In the commit trailer (data-wide flag over a CSS clamp hack;
diagram rules read only when a page has a figure). No new decisions.md entry.

**Open.** Mac-only: setup-guide figs 1, 4 come out 500px wide in 390 shots
(also with the HEAD script; Linux and sample fine) — cause unknown. Mermaid
on Linux not exercised. Sample omits deck-only classes by design.

**Suggested skills.** `plan` (node 08 reconcile), `diagnosing-bugs` only if the
500px crop matters to node 07.

Learnings:
- `git add work/html-kit` fails when cwd is already work/html-kit (Bash cwd
  persists across calls); stage with paths relative to cwd.
