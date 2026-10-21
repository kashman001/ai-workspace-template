<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 11 (2026-10-21): L103 fixed — guide generator on the kit; item closed

**Summary.** Finished L103 (reopened in s10b, whose test + builder were committed in
`d8734b7`). This session: the real page left five non-kit classes (pandoc section
`level*`, code-block language) → added test case G3 "only kit classes" (seen red
11/1), builder strips them (12/0). `docs/workspace-structure.html` regenerated:
AUTHORING.md greps 0/0, one script, `check-links.sh` OK, hash check and
`run-checks.sh` 46/0. Card moved to the archive (scorecard 1/157/5/0/6). Commit `9c63810`.

**Decisions.** Strip pandoc's non-kit classes in the builder rather than list them in
the kit (commit trailer; too small for `decisions.md`).

**Open.** None for this item. L97 is the only open template card (not html-kit).

Learnings:
- `render-check.sh` shoots figures only; a page with none prints "No figures found". For a
  layout look, take full-page headless Chrome shots (`--screenshot`, `--blink-settings=preferredColorScheme=1|0`).
- Pandoc's plain `ul`/`table`/`pre`/`hr`/`blockquote` render well under `body.doc`; the
  Markdown's Contents list stays a plain list, not `nav.toc`.

# Session Handoff — 10 (2026-10-18): plan 04-adopt closed — kit in docs/kit/, TADR-0015

**Summary.** Nodes 04–07 done; plan `04-adopt` closed 7/7. Kit, rules and both
scripts `git mv`'d to `docs/kit/` (flat); `docs/setup-guide.html` converted
(content word-identical to the old page); 48 render-check shots viewed via
contact sheets, all pass; 8 prototype pages re-pointed at `docs/kit/` (`aa356a0`).
TADR-0015 written, docs index + structure map updated (`1fe41bc`). Backlog: L102
resolved, L103 filed (`build-guide-html.sh` onto the kit). The html-kit work item
has no open plan.

**Decisions.** `decisions.md` → "Kit files flat in docs/kit/; shots go to the temp dir".

**Open.** L103 only (backlog card, not this item's plan).

Learnings:
- Another session had uncommitted edits in the backlog HTML files. Stage only your own hunks: apply your edit to `git show HEAD:<f>`, `git hash-object -w`, `git update-index --cacheinfo`, and apply the same edit to the working file.
- BSD `sed` basic regex has no `\|`; use `sed -E` with `(a|b)`.

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
- A child `copilot -p` run from this repo registers via its hooks and takes ownership of the bound item (`owner_live` at rollover); `register --takeover` after it exits. Launch children with the TF_SESSION_* vars unset.
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

