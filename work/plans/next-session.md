# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Ticket **09** (`issues/09-plans-skill.md` — check the exact filename with
`ls issues/09-*`): `skills/plans/SKILL.md`, vendor-neutral, with three
procedures — **create** a plan from a spec or from tickets (a ticket becomes
a node by gaining frontmatter), **reconcile** (run a reconcile node: join,
verify on disk, record decisions, replan within the authority tiers), and
**replan** — plus the subagent prompt template that lets a subagent write
only its node's Log and Acceptance ticks. `.claude/commands/plan.md` wraps
it; one line in `CONTEXT.md` → "Workspace Skills". Then **10** only if
budget allows — `record` before it.

## Read these, in order (keep it lean)

1. `issues/09-*.md` (short) and `spec.md` lines 171–174 (S30) and
   177–180 (S31) — the two stories; nothing else from the spec.
2. `docs/plans.md` — the format (node frontmatter, plan.md, markers), the
   verb table, "Check rules", "Tiers"; it is the skill's reference — the skill
   points at it, never restates it.
3. `scripts/plan.sh` header (`sed -n 1,45p`) — the verbs the procedures use.
4. `scripts/tests/fixtures/plan-01-concept/` — a whole plan (nodes + board);
   `nodes/07-spec.md` is the node shape; the Log line format is
   `- s<n> · <text>` (what `plan.sh` writes: `s<seq>` or `--by <actor>`).
5. `skills/session-rollover/SKILL.md` step 3 (the split, lines ~87–124) — the
   style for a `plan.sh` procedure inside a skill; `skills/decision-log/SKILL.md`
   + `.claude/commands/decision.md` — a skill + wrapper pair of the right size.
6. `CONTEXT.md` → "Workspace Skills" — the one-line list format.
7. `issues/` — the tickets this item runs on; ticket box 1 converts them into a
   plan **on a copy of the fixture item under the scratchpad**, never in
   `work/plans/` itself (no plan opens here).

## Design (settled where the ticket says so; the rest is a proposal — confirm
## it against `grep -n '^## ' decisions.md` headings before building, without
## reloading the file)

- The skill owns three procedures; `plan.sh` owns every write. Nothing in the
  skill edits node `status` by hand; only the split (rollover) edits files.
- Ticket → node: frontmatter `id/title/status/kind/wave/blocked_by/tier/sessions`
  from the ticket's title, `Blocked by`, and status (`done` → `done`,
  `ready-for-agent` → `todo`); the ticket body becomes Goal + Acceptance
  (boxes). *Proposed:* waves from the blocking edges (longest path); one
  reconcile node closes each wave (`check` rules `reconcile-count`/`reconcile-last`).
- *Proposed:* reconcile procedure = the reconcile node's Goal: verify the wave's outputs
  on disk (subagent claims are hints), record decisions (`decision-log`),
  replan — `add`/`drop`/`block` within the authority tiers in `docs/plans.md`
  (a tier the node lacks → a hitl node, not a silent change), `check`, `sync`.
- Subagent prompt template: the child gets its node file path, may append
  Log lines (`- s<n> · …`) and tick Acceptance boxes, never writes `status`
  or other nodes; the orchestrator runs `start`/`done`.
- `/plan` wrapper: `argument-hint: "<create|reconcile|replan> [args]"`, a thin
  pointer at the skill like `.claude/commands/create-work-item.md`.
- `skills/vendored-skills.md` untouched (ticket box 3). Any runtime: no
  Claude-only instruction in the skill. `writing-for-agents` applies (load it).

## Do NOT reload

- `decisions.md`, `concept.md`, `seams.md`, the rest of `spec.md`, the grill.
- Tickets 01–08 — done. `plan.sh`, `session-loop.sh`, `plan-tiers.env`, the
  test suites — do not touch (the skill adds no code).
- `handoff.md` — the top block only if something above is unclear.

## Still binding

- No concrete model name anywhere. Nothing pushed to origin.
- `test-plan.sh` (238), `test-session-loop.sh` (140),
  `test-doc-consistency.sh` (7) stay green (run with `bash …`; the files
  are not executable here).

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (46+
ahead). Tickets: 01–08 `done`; 09–11 `ready-for-agent`. Chain supervised by
`session-loop.sh` (seq 1 → … → 12 → 13). Budget at rollover: ~105K (OK, below
WARN; rolled over because 09 needs a fresh window). Untracked
`work/jev-integration/research/spike.{md,py}` are another item's — leave them.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=13`).
2. No question to pose. Proceed hands-off.
3. Ticket 09 per "Design": skill file first (create procedure, exercised by
   converting a copy of `issues/` on a fixture-item copy under the
   scratchpad until `plan.sh check` is silent), then reconcile + replan
   procedures, then the prompt template, then the wrapper + `CONTEXT.md`
   line; `record --label "ticket 09 <slice>"` after each; commit each slice.
4. Tick the three boxes in `issues/09-*.md`, status `done`; commit.
5. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (ticket 10 next), update the `work/README.md` row, commit.
   Do not push main; report how far ahead it is.
