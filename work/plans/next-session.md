# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Ticket **08** (`issues/08-rollover-split-and-skill-hooks.md`):
(a) `session-rollover` gains a node split at WARN — if a plan is open, run
`plan.sh sync` first; if the current node is unfinished, split it into a done
part and a remainder node (same wave, same edges, `sessions` carried) via
`plan.sh add` / `done`; (b) `checkpoint` and the `create-work-item` launcher
template gain the one-line conditional sync step and the launcher markers
(opt-in — plans stay optional). Then **09** only if budget allows — `record`
before it.

## Read these, in order (keep it lean)

1. `issues/08-*.md` (short) and `spec.md` lines 164–167 (S29) and 190–193
   (S34) — the two stories; nothing else from the spec.
2. `scripts/plan.sh` header (`sed -n 1,45p`): `add <slug> --wave <n> [--title]
   [--kind] [--tier] [--blocked-by a,b] …`, `done <id>` (`--force` allows
   todo → done), `show <id> --json` (frontmatter incl. `sessions`,
   `blocked_by`, `wave`), `sync`. Write verbs take `--session <n>` `--by`.
3. `skills/session-rollover/SKILL.md` steps 1–5 only (lines ~62–143): where
   the sync + split step goes (step 3 "Flush" is the natural home).
4. `skills/checkpoint/SKILL.md` (106 lines, whole) — one conditional line.
5. `skills/create-work-item/SKILL.md` around line 84 (the `next-session.md`
   template) — the `<!-- plan:begin position -->` / `<!-- plan:end position -->`
   markers, scaffolded only when asked.
6. `scripts/tests/fixtures/plan-01-concept/` — the fixture to exercise the
   split on once (ticket box 1); `test-plan.sh` shows how the fixture is
   copied to a temp dir.

## Design (settled — do not re-derive)

- The split is a procedure in the skill, made of existing verbs — no new
  `plan.sh` verb. Shape: `show <id> --json` → `add <id>-b --wave <same>
  --kind <same> --tier <same> --blocked-by <same list>` → nodes that were
  blocked by `<id>` also gain `<id>-b` (edit their `blocked_by`) → `done
  <id>` (`--force` when its check cannot pass yet), the Log line naming the
  split → `sync`. Carry `sessions` into the remainder. Write the exact verb
  sequence into the skill, exercised once on a copy of the fixture (ticket
  box 1: "exercised once ... described with its exact verbs").
- Sync step wording, identical in both skills: "If a plan is open
  (`scripts/plan.sh status` exits 0 and says `open`), run `scripts/plan.sh
  sync` first so the launcher's Position block is fresh."
- Launcher markers in `create-work-item`: emitted only on request (a flag or
  an explicit ask); default scaffold unchanged.
- Any runtime: no Claude-only instruction in either skill (ticket box 3).
- `writing-for-agents` applies when editing the skills (load it).

## Do NOT reload

- `decisions.md`, `concept.md`, `seams.md`, the rest of `spec.md`, the grill.
- Tickets 01–07 — done. `session-loop.sh`, `plan-tiers.env` — do not touch.
- `handoff.md` — the top block only if something above is unclear.

## Still binding

- Bash 3.2 + jq only; match the scripts' style. `session-state.json` schema
  stays 1. No concrete model name anywhere. Nothing pushed to origin.
- `test-plan.sh` (238), `test-session-loop.sh` (140),
  `test-doc-consistency.sh` (7) stay green.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (42+
ahead). Tickets: 01–07 `done`; 08–11 `ready-for-agent`. Chain supervised by
`session-loop.sh` (seq 1 → … → 11 → 12). Budget at rollover: ~112K (OK, below
WARN; rolled over because 08 needs a fresh window). Untracked
`work/jev-integration/research/spike.{md,py}` are another item's — leave them.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=12`).
2. No question to pose. Proceed hands-off.
3. Ticket 08 per "Design": split procedure first (exercise on a fixture copy
   under the scratchpad, then write it into `session-rollover`), then the
   sync line in both skills, then the launcher markers; `record --label
   "ticket 08 <slice>"` after each; commit each slice.
4. Tick the three boxes in `issues/08-*.md`, status `done`; commit.
5. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (ticket 09 next), update the `work/README.md` row, commit.
   Do not push main; report how far ahead it is.
