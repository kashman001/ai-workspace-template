<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #9)

## Mission

User directive (2026-08-29, session #8): *"integrate all these things …, and
also bring the current workspace up to date. Need to make sure all code and
instructions are updated and there is proper documentation to make sure
existing and new workspaces are set up properly."* Concretely:

1. Work the four peer-flagged backlog cards, in order: **M33** (small: widen
   `launch-next-session.sh:299`'s session-number grep to match `sNNN`
   headings + test), **L41** (one-line doc fix in
   `skills/session-rollover/SKILL.md:145`), **L42** (reword
   `skills/decision-log/SKILL.md:78` bar as trigger), then **M32** (the real
   port: widen `scripts/check-ledger.py` heading grammar to six forms +
   ordering fix + tests — largest, pre-flight headroom first).
2. **Bring THIS workspace current:** after delivery, the user's own checkout
   must be on updated `main` (pull), with the M31 migration applied cleanly —
   verify `.claude/settings.json` is the tracked copy, personal bits live in
   `settings.local.json`, hooks fire once. Retire fully-merged branches
   (`vendor-mattpocock-skills`) with the user's ok; clean the merged
   `m31-close` worktree.
3. **Setup-docs audit (existing + new workspaces):** verify the documented
   setup paths end-to-end — fresh clone (`scripts/setup.sh` +
   `docs/workspace-setup.md`/`template-usage.md`) and existing-workspace
   migration (`docs/context-budget.md` → migration note; runbooks). Every
   instruction must match the post-M31 + post-M32/M33 reality; fix what
   doesn't, and make sure the check scripts (`check-dependencies.sh`,
   `check-workspace-structure.sh`) agree with the docs.

Deliver like M31: commit, ff-push to main (authorized pattern established at
PR #40), resolve cards to the archive with `Fixed:` notes.

## Read these, in order

1. `docs/template-workspace-backlog.html` — grep `M32`, `M33`, `L41`, `L42`
   (each card carries evidence incl. downstream commit refs and exact lines).
2. For M32 only: `scripts/check-ledger.py` + `scripts/tests/test-check-ledger.py`
   (current grammar at lines ~43-55).

## Do NOT reload

- M31 / hook-wiring history — closed, delivered (PR #40, main at a08c58a+).
  See handoff.md top block only if needed.
- The peer message itself — its substance is fully in the four backlog cards.
- Whether the four findings apply here — verified at session #8 (they do).

## State snapshot

- **M32 confirmed locally at rollover:** `check-ledger.py` fails on all 14
  historical headings in `work/template-maintenance/handoff-archive.md`
  (`#N` and date-only-title forms). Fix = widen the grammar (M32), do NOT
  rewrite history; until M32 lands this work item's archive check stays red.

- Everything delivered to `origin/main`; work happens in a fresh worktree off
  main (session #8 used `.claude/worktrees/m31-close`, now merged, disposable).
- Backlog: 10 open / 69 resolved. `vendor-mattpocock-skills` branch fully
  merged — retire it or reuse; ask user only if it blocks something.
- No-human-in-the-loop clause: all four cards are buildable unattended; no
  user decision required. If M32's downstream diff is wanted verbatim, their
  commits (089f526, 87700e7) live in insight-dev-ai-workspace — not fetchable
  from here; reimplement from the card's description instead.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Start with M33 (smallest, sharpest): fix + test + backlog-resolve.
3. `scripts/context-budget.sh record --label "<card> done"` at each card
   boundary; pre-flight headroom before starting M32.
