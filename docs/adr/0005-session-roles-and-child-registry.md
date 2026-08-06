# ADR-0005: Session roles with the lock as primary marker, and a parent/child session registry

- Status: accepted
- Date: 2026-08-06
- Deciders: Kashif + Claude Code sessions 15–17 (automatic-session-rollover project)

Extends ADR-0004's multi-session model. That ADR made measurement and
work-item ownership hold under N concurrent sessions; this one records what a
session *is* relative to a work item — its role, its lineage across
rollovers, and how subagent (child) sessions attach to the tree.

## Context

Three pressures made roles a real decision:

1. A plainly-exited session squatted its work-item lock for the whole 3h
   stale window (backlog L20), and nothing distinguished a live helper
   session from a dead predecessor — both were just "not the holder".
2. The subagent-rollover design (research §5/§6, R4/R5) needs child sessions
   that are *measured and lock-holding* but must never contend with their
   ancestors for the work item itself, and whose teardown must be ordered
   (a parent releasing under live children orphans them — invariant I4).
3. Rollover lineage was only forward-walkable by timestamp: the launcher
   stamps the dying record `superseded` but cannot know the successor's id
   (the runtime generates it later), so the chain had no back-links, and a
   human reclaiming a wedged item had no non-silent way to take the lock.

## Decision

- **Four roles, recorded per session record: `primary`, `auxiliary`,
  `child`, `superseded`.** The project lock *is* the primary marker: a
  session is primary iff `work/<proj>/.active-session` carries its
  identity; on conflict the lock beats any cached `role` claim. Exactly one
  primary per work item; it is the sole writer of the launcher/ledger and
  sole rollover authority. An auxiliary is associated and measured but
  holds nothing and writes nothing; a superseded record is terminal.
- **Children are registered by their parent, keyed by artifact identity.**
  `register --parent-session <sid> [--agent-id <id>] --transcript <path>`
  derives the child's session id from the artifact, never the env (the
  registering process is the parent). Records gain `parent_session_id` and
  `depth`; children take per-child locks in `work/<proj>/.agent-locks/`,
  granted only when the parent chain terminates at the current project-lock
  holder. Release is bottom-up: a stale sweep first (one liveness rule,
  shared with the project lock), then refusal while live descendants block.
- **Lineage closes successor-side; steals are explicit and recorded.** On
  primary acquisition the successor back-stamps `superseded_by` onto the
  newest unclaimed superseded record for the project. `register --takeover`
  wins even against a live holder — human authority beats liveness
  heuristics — but always stamps the loser's record, never silently.

## Alternatives considered

- **primary/secondary/retired or main/helper/handed-off vocabularies** —
  rejected: "secondary" reads as backup-primary; "retired" hides that the
  state is terminal-by-rollover.
- **Overloading `auxiliary` for subagent children** — rejected: a child
  holds a lock and writes its task report; an auxiliary must not — the
  write-authority distinction is the point of the role field.
- **Env-derived child identity** — rejected: the registering process is the
  parent, so env identity would claim the child's record for the parent
  (caught designing test T7).
- **Keying child locks by `agent_id`** — rejected: non-claude children may
  have none; `<runtime>-<session-id>` matches every other identity in the
  system.
- **Liveness checks inside the parent-chain walk** — rejected: the
  release-time stale sweep keeps a single liveness rule (I7).
- **Launcher-side `superseded_by` stamping** — rejected: the successor's id
  does not exist yet when the launcher stamps.
- **Takeover refused against a live holder** — rejected: defeats its
  purpose (the non-takeover path already refuses); the safeguard is the
  audit trail, not another liveness veto.

## Consequences

- A dead predecessor can never be mistaken for a usable session, and the
  rollover lineage is walkable in both directions
  (`superseded_at`/`superseded_by`).
- Subagent fleets get ordered teardown by construction: the project holder
  cannot release under live children (I4), so orphaned child locks surface
  loudly instead of silently outliving their tree.
- Wedged items have a sanctioned, auditable human override (`--takeover`)
  instead of ad-hoc lock-file deletion.
- More gitignored runtime state per work directory (`.agent-locks/`); the
  stale sweep inherits ADR-0004's caveat that artifact-mtime liveness is a
  heuristic, not a guarantee.
- The role field is now schema: future session kinds must extend this set
  deliberately rather than overloading an existing role.

## Provenance

- Promoted from:
  `work/automatic-session-rollover/decisions.md#2026-08-06--session-roles-primary--auxiliary--superseded-lock-as-the-primary-marker-session-15`,
  `…#2026-08-06--slice-1-child-registry-artifact-keyed-identity-role-child-blocked-release-i4-guard-session-16`,
  `…#2026-08-06--rollover-lineage-completed-successor-side-takeover-is-a-recorded-steal-session-17`
- Commits: 0339ad7, 4c6569e (+ the slice-1 T13/T14 commit)
- Refs: ADR-0004 (the model this extends);
  `work/automatic-session-rollover/plans/slice-1-registry-schema.md`;
  `work/automatic-session-rollover/issues/03-session-roles.md`;
  tests `scripts/tests/test-context-budget-registry.sh` T6–T14
