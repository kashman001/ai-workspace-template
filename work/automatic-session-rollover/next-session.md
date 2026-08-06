# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The subagent-rollover design is under **active user review** of
`subagent-rollover-research.html` — no new work unprompted. Session 15
shipped issues 02 (approval ladder: `default<edits<auto<full`, `auto` =
classifier tier) and 03-core (session roles primary/auxiliary/superseded,
SessionEnd lock release, role statusline). Next: respond to review findings
as the user raises them; when review settles, start implementation slice 1
(registry/lock schema extension in `context-budget.sh` — agent records with
`parent_session_id`/`depth`, per-child locks, release-order guard; R4/R5),
M-class scenarios first, folding in issues/03's deferred items
(superseded_by back-link, --takeover) where they touch the same schema.

## Read these, in order

1. `handoff.md` top block — session-15 record.
2. On demand only: `issues/03-session-roles.md` (roles model + deferred);
   `rollover-scenarios.md`; research md by §-pointer; HTML only for the
   section being edited.

## First actions

1. **Sync check:** confirm the local main checkout is at/past `e7d9f10`
   (`git log --oneline -1`). If behind, `git pull --ff-only` first — session
   15 worked in a worktree; live `.claude/settings.json` references
   `scripts/statusline-context-budget.sh`, which only exists after the pull.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary` in the output (first live exercise of the role
   field; the predecessor's lock should be gone via SessionEnd hook or manual
   release — if `register` reports auxiliary against a dead holder, that's a
   finding for issues/03's `--takeover` case).
3. Report readiness and wait for the user (mid-review; no new work
   unprompted). If they green-light slice 1: TDD per `scripts/tests/` harness
   style (mktemp fixtures, `touch -t` mtimes).

## Do NOT reload

- `handoff-archive.md` and blocks before session 15 — superseded.
- The full HTML file — mirror of md content; open only the section under edit.
- Backlog cards **L17**/**L18** — separate follow-up threads.
- Issues 02 (approval ladder) and 03-core (roles) — shipped, tested,
  documented; re-derive nothing. Deferred 03 items live in the issue file.
- The M14 fix — shipped and now verified live (session-15 bootstrap).
- The gitignore/tracked-vs-untracked discussion — codified in
  `docs/work-directory-conventions.md`.

## Constraints already decided (do not re-litigate)

- Vendor-agnostic layering; child rollover verb = successor dispatch, never
  resume; parent never rolls with live children (drain; I4).
- Parent kinds = node *position* — `depth`/`parent_session_id` suffice
  (decisions.md 2026-08-06).
- Approval ladder `default<edits<auto<full`; `auto` = classifier where the
  runtime has one, nearest-level fallback + note elsewhere (decisions.md
  2026-08-06, backlog L19).
- Session roles: one primary per work item, lock authoritative; auxiliary
  never writes launcher/ledger; superseded is terminal (decisions.md
  2026-08-06, backlog L20, issues/03).
- Runtime state stays gitignored; commit only what a future session reads.
- Implementation may begin when the user says so. Standing push-to-main
  approval applies.

## State snapshot (at session-15 rollover, 2026-08-06)

- origin/main at `e7d9f10`; worktree `issue-02-permission-mode-auto` fully
  pushed; **local main checkout behind until pulled** (was `bc3fab3`).
- Machine-local: live `.claude/settings.json` has SessionEnd + statusLine;
  `work/automatic-session-rollover/.rollover-options` =
  `ROLLOVER_OPT_APPROVAL=auto`; `context-budget.env` per-item sets
  `ROLLOVER_RELAUNCH=auto` (not exercised this rollover — worktree
  divergence; see handoff).
- No background agents or servers.

## At session end

The lock now releases mechanically: `launch-next-session.sh` at rollover, or
the SessionEnd hook on plain exit. Manual fallback:
`scripts/context-budget.sh release --project automatic-session-rollover`.
