<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #10)

## Mission

Finish the session-8 user directive (cards are DONE, delivered at `dcebc95`):

1. **Apply the setup-docs audit fixes** — all 18 findings are enumerated with
   exact locations and fixes in
   `work/template-maintenance/setup-docs-audit-2026-08-29.md` (F1–F18 + fixer
   notes: fix the .md sources first, then regenerate guide HTML via
   `scripts/build-guide-html.sh`, then hand-fix setup-guide.html if it isn't
   generated). No behavior changes; F8 (graphify→graphifyy package name) is the
   one user-facing install bug. Commit, ff-push to main (authorized pattern,
   PR #40 precedent). No backlog cards exist for these; either fold into the
   commit message or file/resolve one card for the audit as a whole.
2. **Workspace currency (user's own checkout):** it sits on
   `vendor-mattpocock-skills` (now FULLY merged into main by dcebc95 —
   verified ancestor). Switch it to `main` + pull; delete the vendor branch
   (local + origin) — no user ask needed, it is merged; remove the merged
   `m31-close` worktree (`git worktree remove`, it's locked — unlock first);
   verify M31 migration live: `.claude/settings.json` is the tracked copy,
   personal bits in `settings.local.json`, hooks fire once.
3. If headroom remains: L43 (two out-of-order historical archives — see the
   backlog card; ledger-content pass, deliberate re-file + posture decision).

**No-human-in-the-loop:** all of 1–2 is buildable unattended. Touching the
user's main checkout (switch to main + pull + branch/worktree cleanup) is
explicitly directed by the session-8 user directive — do it, don't ask; only
stop if the checkout is dirty with non-trivial uncommitted changes (then leave
it, note it, continue with the rest).

## Read these, in order

1. `work/template-maintenance/setup-docs-audit-2026-08-29.md` — the work list.
2. Only when reaching item 2: `git -C <main-checkout> status` first.

## Do NOT reload

- M32/M33/L41/L42 details — delivered (dcebc95), cards in the backlog archive.
- The peer message / downstream commits — fully consumed at sessions #8–9.
- docs/context-budget.md, the M31 history — settled; audit verified the
  migration note CLEAN.
- The audit's methodology — trust the findings file; re-verify only the line
  numbers you edit (they were taken at dcebc95).

## State snapshot

- main = `dcebc95` (cards + backlog + L43). Backlog: 7 open / 73 resolved.
- Session-9 worktree `tm-s9` (branch `worktree-tm-s9`) carried the rollover
  commit; launcher self-heals by ff-pushing it to main at launch.
- `m31-close` worktree: merged, locked, disposable. `doc-review-skill` and
  `learn-agentic-workflows-s2` worktrees belong to OTHER work — leave them.
- Repo-wide `scripts/check-ledger.py` exits 1 (L43's two archives, known);
  per-project `work/template-maintenance` is green.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Work the audit findings file top-down (F1–F18), verify, commit, push.
3. `scripts/context-budget.sh record --label "audit fixes done"`, then item 2.
