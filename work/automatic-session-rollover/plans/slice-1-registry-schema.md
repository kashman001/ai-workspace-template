# Slice 1 — registry/lock schema extension (R4/R5)

Status: COMPLETE (sessions 16–17; T7–T14 green, follow-through done,
promoted to ADR-0005).
Scope: `scripts/context-budget.sh` + registry tests. Research §5/§6 + §14.1;
issues/03 deferred items folded in where they touch the schema.

## Design (decided this session)

- **Child registration is parent-side, artifact-keyed:** `register
  --parent-session <sid> [--agent-id <id>] --transcript <child-artifact>
  --project <p>`. With `--parent-session`, the session id comes from the
  artifact, never the env (the registering process is the parent).
- **Record schema** gains `parent_session_id`, `depth` (parent's `.depth //
  0` + 1; parent must be registered or die), `agent_id` (optional).
- **Role extends to `child`** (rejected: overloading `auxiliary` — a child
  holds a lock and writes its task report; an auxiliary must not write).
- **Per-child locks:** `work/<p>/.agent-locks/<runtime>-<sid>.json`
  `{runtime, session_id, agent_id, parent_session_id, depth, project,
  acquired_at}`. Project lock untouched by children. Granted only when the
  parent chain terminates at the current project-lock holder (transitive
  validity, ≤10 hops); otherwise loud refusal, role=auxiliary.
- **Release-order guard (I4):** `release` sweeps stale child locks (holder
  artifact older than LOCK_STALE via registry record), then refuses (die,
  exit 3) if live child locks block the releaser — project holder blocked by
  ANY live child lock; a child blocked by live locks naming it as parent.
  A child's own release removes its `.agent-locks/` file only.
- **superseded_by back-stamp:** on primary acquisition, newest record for
  the same project with `role=superseded` and no `superseded_by` gets
  `superseded_by: <runtime>-<sid>`.
- **--takeover:** explicit recorded steal at register; wins even against a
  live holder (S33 human authority); old holder's record stamped
  superseded + superseded_at + superseded_by.

## Test plan (registry suite T7+)

- T7 child record fields (parent_session_id/depth/agent_id; artifact-keyed id)
- T8 child lock granted under lock-holding parent; role=child; project lock untouched
- T9 refusal when parent doesn't hold the lock (no lock file, role=auxiliary, loud)
- T10 release-order guard: parent refused while child live; child releases own; parent then ok
- T11 stale child lock swept at release
- T12 depth-2: grandchild depth=2 via chain walk; child refused release while grandchild live
- T13 superseded_by back-stamp at successor register
- T14 --takeover: lock moves, old holder stamped superseded_by, loud note

## Follow-through (after green)

- `.gitignore`: `work/*/.agent-locks/`
- Docs: `docs/context-budget.md` (Session roles / multi-session model)
- `issues/03-session-roles.md`: mark folded items; `decisions.md` note (role=child)
- Backlog card + changelog row; scenario-catalog notes (I2/I4 groundwork)
- Commit + push to origin/main (standing approval); user pulls main checkout
