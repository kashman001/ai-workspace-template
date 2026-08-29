# Setup-docs audit — findings (session #9, 2026-08-29)

> **APPLIED** — all 18 findings fixed in session #10 (2026-08-29); backlog card
> M34 (archive). Kept for the audit trail.

Read-only audit of the documented setup paths vs post-M31 reality (tracked
`.claude/settings.json` hook wiring). Verified clean: context-budget.md
migration note + vendor table, check-service-access ↔ authentication runbook,
check-workspace-structure ↔ workspace-structure.md required dirs/symlinks,
CONTEXT.md, README.md prose, .gitignore. No double-wiring instruction exists in
Markdown — only in the stale generated HTML (F1).

Line numbers are as of main @ dcebc95.

## High — stale generated HTML instructs pre-M31 double-wiring

- **F1** `docs/workspace-structure.html:550,554-557` — calls `.claude/settings.json` a
  gitignored permission allowlist and says to copy the example's `hooks` block into it
  (truth: tracked, IS the wiring; example has no hooks; following it = hooks fire twice).
  **Fix: run `scripts/build-guide-html.sh`** (source .md sha1 drifted; check-workspace-structure
  already warns "stale").
- **F2** `docs/workspace-structure.html:1122-1124,1457` — gitignore table + scaffold still list
  `.claude/settings.json` as ignored. Same regeneration fixes it.
- **F3** `docs/setup-guide.html:352` — tracked-vs-gitignored row glob `.claude/settings*.json` → "No"
  wrongly covers the tracked file. Change cell to `.claude/settings.local.json`; add
  `.claude/settings.json` as tracked "Yes".

## Medium — stale Markdown prose

- **F4** `docs/recommended-tooling.md:29` — says `scripts/setup.sh` wires claude hooks; it only
  copies settings.local.json. Say: wiring ships committed in `.claude/settings.json`.
- **F5** `docs/runbooks/README.md:18` — "export the MCP token" (none exists per
  authentication.md:39). Say: authenticate to GitHub via `gh`.
- **F6** `scripts/setup.sh:103` — same stale "export the MCP token" epilogue phrase.
- **F7** `docs/workspace-setup.md:19-20` — delete "the MCP token export and".
- **F8** `scripts/check-dependencies.sh:63` — package name `graphify`; everywhere else says
  `graphifyy` (7 places). Fix: `uv tool install "graphifyy[mcp]"`.
- **F9** `docs/runbooks/README.md:17` — tool list names `docker` (not checked anywhere), omits
  `jq` + hook wiring. Fix list: git, gh, jq, hook wiring, node, uv, python3, yt-dlp, graphify.
- **F10** `docs/runbooks/dependencies.md` — no runbook step for two script checks: Copilot
  `trustedFolders` advisory (check-dependencies.sh:73-80) and "hooks missing → git pull /
  restore `.claude/settings.json`" (:51-53). Add both subsections.

## Low

- **F11** `docs/workspace-setup.md:70` — ordering rationale now only Copilot-trust-seed related.
- **F12** `docs/workspace-structure.md:905` (+html:1417) — bootstrap scaffold says settings.json
  is user-specific/do-not-create; now inverted (settings.local.json is the user-specific one).
- **F13** `docs/workspace-structure.md:533-535` — setup.sh bullet omits GEMINI.md symlink,
  .mcp.json/settings.local.json copies, Copilot trust seed, dependency preflight.
- **F14** `docs/workspace-structure.md:543-546` — check-workspace-structure bullet omits guide-HTML
  sha1 freshness warning + repos/README.md check-ignore assertion.
- **F15** `docs/template-usage.md:128-130` — functional-scripts list omits check-dependencies.sh.
- **F16** `docs/setup-guide.html:402` — still `npx -y ccstatusline@latest`; superseded by
  `npm install -g ccstatusline` (recommended-tooling.md:114-119).
- **F17** `docs/setup-guide.html:248-250` — bare `cp` clobbers on re-run; use `cp -n` or point at
  `./scripts/setup.sh`.
- **F18** `scripts/tests/test-check-dependencies.sh:5,58,66,68` — D2/D3 assert via
  `.claude/settings.local.json` only; point D3's fixture at the tracked `.claude/settings.json`.

## Notes for the fixer

- F1/F2 (and the html side of F12) should fall out of regenerating the guide HTML from the
  updated .md — fix the .md findings FIRST (F12-F14), then run `scripts/build-guide-html.sh`,
  then hand-fix setup-guide.html (F3, F16, F17) if it is not generated (check for a builder).
- setup-guide.html vs build script coverage: verify which HTML files build-guide-html.sh owns
  before hand-editing.
- These are doc/scripts fixes only; no behavior change. F8 is the one user-facing install bug.
