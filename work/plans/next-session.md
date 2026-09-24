# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Ticket **10** (`issues/10-front-door-and-downloaders.md`): the front door and
reference for plans — a short Plans section in `CONTEXT.md` plus the glossary
terms under Language (worktree as an alias to avoid); `docs/plans.md`
completed (wayfinder mapping paragraph, worked example; format, verbs, tiers,
Replans are already there) and indexed from `docs/README.md`; the optional
`plans/` row in `docs/work-directory-conventions.md`; per-runtime notes;
`docs/for-non-engineers.md` note; backlog card resolved; `TEMPLATE_VERSION`
bump; `test-doc-consistency.sh` covers every new doc and skill path. Then
**11** (dogfood) only if budget allows — `record` before it.

## Read these, in order (keep it lean)

1. `issues/10-*.md` (short) and `spec.md` — S32, S33, S35, S36 only
   (`grep -n 'S3[2356]' spec.md` for the lines); nothing else from the spec.
2. `docs/plans.md` whole — it is the reference ticket 10 completes; note what
   is missing against the ticket's list, not what is there.
3. `CONTEXT.md` → "Language", "Workspace Skills" (the `plans` line landed in
   session 13), and the section order — the Plans section is one short
   paragraph pointing at `docs/plans.md` and `skills/plans/SKILL.md`.
4. `skills/plans/SKILL.md` headings only (`grep -n '^## '`) — what the front
   door points at; do not rework the skill.
5. `docs/README.md` (the index format), `docs/work-directory-conventions.md`
   → the directory table and "Generated blocks", `docs/for-non-engineers.md`
   (one note), `scripts/tests/test-doc-consistency.sh` (how paths are listed).
6. `docs/template-workspace-backlog.html` — grep for `plans` to find the card;
   edit by targeted reads per its "Maintaining this backlog" section.
7. `work/plans/concept.md` → glossary rows only (`grep -n -A2 '^\*\*\|^- \*\*'`
   or the "Language"/glossary heading) — source for the Language terms.

## Do NOT reload

- `decisions.md`, `seams.md`, the grill, the rest of `spec.md`/`concept.md`.
- Tickets 01–09 — done. `plan.sh`, `session-loop.sh`, `plan-tiers.env`, the
  skills — do not touch (ticket 10 adds docs and test paths, no code).
- `handoff.md` — the top block only if something above is unclear.

## Still binding

- No concrete model name anywhere. Nothing pushed to origin.
- `test-plan.sh` (238), `test-session-loop.sh` (140),
  `test-doc-consistency.sh` (7, grows with the new paths) stay green (run with
  `bash …`; the files are not executable here).
- Plan vocabulary says "work item", never "worktree".

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (50+
ahead). Tickets: 01–09 `done`; 10–11 `ready-for-agent`. Chain supervised by
`session-loop.sh` (seq 13 → 14; cap 15). Budget at rollover: ~115K (below
WARN; rolled over because 10 needs a fresh window). Untracked
`work/jev-integration/research/spike.{md,py}` are another item's — leave them.
No plan is open in this item (none of `work/plans/plans/`).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=14`).
2. No question to pose. Proceed hands-off.
3. Ticket 10 in slices, `record --label "ticket 10 <slice>"` after each,
   commit each: (a) `CONTEXT.md` Plans section + Language terms; (b)
   `docs/plans.md` completion + `docs/README.md` index +
   work-directory-conventions row + for-non-engineers note + per-runtime notes;
   (c) doc-consistency paths + `TEMPLATE_VERSION` bump + backlog card.
4. Tick the three boxes in `issues/10-*.md`, status `done`; commit.
5. At the end or at WARN/STOP: ledger block, rewrite this launcher (ticket 11
   next, or the item's close-out), update the `work/README.md` row, commit.
   Do not push main; report how far ahead it is.
