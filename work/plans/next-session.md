# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Tickets 01 and 02 are
done; the frontier is 03, 05, 06 (all blocked only by done tickets). Take
**03** (`plan.sh check`, the lint) — 04 needs it, and it is the deepest.

## Read these, in order

1. `work/plans/issues/03-check-lint.md` — the ticket (rules listed there).
2. `handoff.md` top block → "For ticket 03" — the loader already refuses a
   dangling `blocked_by`; decide how `check` reports that rule first.
3. `docs/plans.md` — the format, every verb, exit codes; extend, don't
   restate. Note the wave-size limit: "limit in plan frontmatter, workspace
   default" — no such field or default exists yet; you name both (plan
   frontmatter key + a value in `context-budget.env` or a new env file —
   check `work/plans/spec.md` S15 and "Implementation Decisions" first).
4. `scripts/plan.sh` — read it whole (~260 lines): `load_nodes` gives every
   verb a JSON array of nodes; `DERIVE_JQ` is the shared jq prelude; add
   verbs as `cmd_<verb>` + a `case` arm.
5. `scripts/tests/test-plan.sh` — T8 shows the pattern for fixture variants
   (`reset`, `setf <id> <key> <value>`, `squeeze`); append `T11…`.
6. `work/plans/spec.md` — only S15 plus "Implementation Decisions" → check
   rules / wave size.

## Do NOT reload

- `decisions.md` in full — every note is settled; open it only to append a
  new note or check one rejected alternative.
- `concept.md`, `seams.md` — the format is now in `docs/plans.md`.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, or the integration list.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match `scripts/plan.sh`'s style. Exit codes 0/1/2 as
  documented. Text by default, `--json` on every read verb.
- `check`: one line per violation on stdout, exit non-zero when any; exit 0
  and silence on a clean plan; `--json` lists violations as objects. The
  fixture plan must pass clean (every wave there ends in one reconcile node).
- Wave names ("1 ground") live in no frontmatter — derive or omit; note the
  choice in the ledger for ticket 05 (board renderer).

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. Tickets:
01, 02 `done`; 03–11 `ready-for-agent`; frontier = 03, 05, 06. Chain
supervised by `session-loop.sh` (seq 1 → 2 → 3 → 4 → 5). Budget at
rollover: OK (~95K; ticket 02 finished under WARN).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=5`).
2. No question to pose. Proceed hands-off.
3. `implement` ticket 03 with `tdd`: one red case per rule in
   `test-plan.sh` first (each a fixture variant tripping exactly that rule,
   plus the clean fixture and `--json`), then `plan.sh check` green one rule
   at a time.
4. Extend `docs/plans.md` → "`plan.sh`" table with `check` and a "Check
   rules" list; document the wave-size field and default.
5. Tick the ticket's boxes as each lands; `Decision:` trailer on the commit.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher (next
   ticket on the frontier), update the `work/README.md` row, commit. Do not
   push main; report how far ahead it is.
