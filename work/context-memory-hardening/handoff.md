<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-10-07 (session 3: tickets 03–05 done, item finished)

1. Ticket 03 (M43) done, commit `f9b7067`: git-derived `Last confirmed`
   dates on all 22 `operational-knowledge.md` entries, 6-month review age;
   `checkpoint` → "Classify before you write" plus a stale-list step;
   `decision-log` classifies before a note. Doc-only, no script.
2. Ticket 04 (L51) done, commit `9d79e6d`: `CONTEXT.md` 20,656 → 15,206
   bytes; five sections cut behind pointers, must-keep rules inline.
3. Ticket 05 (D5) done, commit `080cd1a`: ADR-0013 (no vector store, MMR,
   or decay scoring), promoted from the Tier-2 note.
4. New finding L52 filed: `skills/session-rollover/SKILL.md:78` cites a
   `CONTEXT.md` section that doesn't exist. Scorecard 1/98/5/0/6.
5. Item finished. After checkpoint, at the user's request: L52 fixed
   (`42edb9a`); a sub-agent checked ADR-0013's premise with a stdlib BM25 +
   MMR prototype — vector search does break the design, MMR/date-decay don't
   but add nothing; ADR reason corrected and a "scan the `## ` headings,
   judge by meaning" rule added to CONTEXT.md, checkpoint, ADR-0013
   (`64f8908`). User asked to push: `main` pushed to origin (0 ahead).
6. Rolled over (user-requested, landed at STOP 154K) to hand a workspace
   documentation gap review to a fresh session — see launcher.

Learnings:
- `git log -1 -L <start>,<end>:<file>` per `## ` range gives a defensible
  per-entry "last touched" date without inventing one.
- Ledger insert must anchor after the purpose comment's `-->`, not on the
  first `# Session Handoff` text (the comment quotes it). Caught by
  `check-ledger.py` and redone.

# Session Handoff — 2026-10-07 (session 2: tickets 01–02 done, WARN rollover)

1. Ticket 01 (L49) done, commit `9996954`: "Cache the prefix, vary the
   tail" in `docs/context-budget.md`, pointer in `CONTEXT.md`, date-line
   warning in `check-workspace-structure.sh` + `test-context-prefix-stability.sh`.
   Hook audit in the ticket's `## Answer`: no hook change needed.
2. Ticket 02 (L50) done, commit `0e489b5`: ledger rows carry
   `cache_read_share` (Claude, Codex, OpenCode; `null` elsewhere); the
   check/record line shows `cache=NN%`. This session read `cache=99%`.
3. Three Tier-2 notes written to `decisions.md`. Scorecard now 3/96/4/0/6.
4. Rolled over at WARN (131K). Next: ticket 03 (M43).

Learnings:
- `scripts/tests/test-jev.sh` failed once (stub endpoint unused, request hit
  the live URL → 401), then passed on rerun with no change. Flaky; not filed.
- `test-launch-next-session.sh`, `test-plan.sh`, `test-session-loop.sh` lack
  the exec bit and `test-check-ledger.py` is Python: run suites as
  `bash`/`python3`, not `./`.
