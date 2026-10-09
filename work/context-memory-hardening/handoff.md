<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-10-08)

1. Documentation gap review done: `doc-gap-review.md` (commit `fdfbbd1`),
   nine gaps ranked. Filed as cards L53–L59 (+ harness ideas below).
2. User asked what the template could learn from Böckeler's harness
   engineering article (martinfowler.com). Five ideas accepted, filed as
   M44, M45, L60–L62; new work item `work/harness-engineering/` scaffolded
   (`0316f26`). Both it and `template-maintenance` (L53–L59, then L63–L65,
   then the L54 `TEMPLATE_VERSION` bump) were run by the user's
   session-loop chains and finished — HEAD `40f4389`, all cards resolved.
3. User decision: bump `TEMPLATE_VERSION` on each push of template-facing
   changes, no changelog file (`bc14373`).
4. User asked for a new work item `deep-seek-harness-eval` (evaluate
   github.com/deepseek-ai/deepseek-harness). Not started: hit STOP (150K).
   Repo checked: exists, MIT, ~270 MB, branch `master`, has `AGENTS.md`,
   `CLAUDE.md`, `.agents/`, `.claude/`, `apps/`; tagline "Everything is a
   Plugin". Rolled over (user-requested) to hand the scaffold to a fresh
   session — see launcher.

Learnings:
- Two session-loop chains on one checkout (harness-engineering,
  template-maintenance) both editing the backlog HTML worked when run
  back-to-back; launchers told each to re-read before editing.

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
