# ADR-0009: `/clear`-based rollover relaunch

- **Status:** Accepted
- **Date:** 2026-08-28
- **Supersedes:** nothing. **Extends:** ADR-0003 (automate rollover relaunch).
- **Related:** ADR-0004 (multi-session model), ADR-0005 (session roles and
  child registry), ADR-0007 (session-number single source).
- **Closes:** `work/automatic-session-rollover/issues/04-in-place-clear-relaunch.md`

## Context

ADR-0003 automated the relaunch step by spawning a fresh runtime process seeded
with the canonical bootstrap prompt. That works, but a fresh process pays two
costs the rollover does not actually need:

1. **It re-authenticates.** Observed downstream: a `--bg` relaunch started,
   failed with `Not logged in`, and parked on an OAuth screen. The rollover
   artifacts were all correct and on disk; the successor simply could not run.
2. **It re-connects MCP servers.** Three consecutive sessions in one downstream
   work item recorded an MCP server as absent at startup and wrongly diagnosed
   it as a credential problem. It was a per-process startup race.

Neither cost buys anything when the successor is the same person, same runtime,
same working directory, continuing the same work item — which is the ordinary
rollover.

`/clear` resets the conversation inside the existing process. It preserves what
ADR-0003 actually cared about: ADR-0003 rejected conversation-as-carrier
handoffs, and `/clear` keeps disk as the carrier — the cleared context still
bootstraps by reading `next-session.md`.

Issue 04 parked this idea in 2026-08-06 with a five-point "what it loses"
analysis. This ADR adopts the idea and answers those five points; see
"Consequences".

## Decision

Add a second relaunch mechanism rather than replacing the first.

`scripts/launch-next-session.sh <project> --clear` runs the identical freshness
guard, counter bump and prompt construction as the spawn path, then — instead
of spawning — writes the prompt to `work/<project>/.pending-clear-seed` and
instructs the human to press `/clear`. A SessionStart hook,
`scripts/hooks/rollover-clear-seed.sh`, fires on `source == "clear"`, drains the
marker, and returns it as `additionalContext`, so the fresh context arrives
already carrying its mission and the human types nothing beyond the keystroke.

Keeping this as a mode of the existing script is deliberate: ADR-0003 puts the
prompt wording in exactly one place and ADR-0007 puts the counter in exactly
one place. A parallel script would have duplicated both.

**Selection rule — by whether the MCP server set must change:**

- **Same server set → `--clear`.** The common case.
- **Different MCP fragment, different runtime, or `--bg` while this session
  keeps working → spawn a process.** A running session cannot attach a new
  server, so only a relaunch can change the set.

## How the five losses in issue 04 are handled

1. **Launch-config change point.** Not solved — accepted as the boundary of the
   mode. `/clear` inherits the dying session's launch flags, so any rollover
   that wants a different model, approval level or MCP fragment must spawn.
   That is the selection rule above, and it is the reason this is an added mode
   rather than a replacement.
2. **Lineage bookkeeping — the one issue 04 called an "actual bug".** The
   `--clear` path deliberately does **not** release `.active-session` and does
   **not** stamp the dying registry record `superseded`, and it exits before
   the code that would. Issue 04 assumed the spawn path's bookkeeping had to be
   replicated; the opposite is true. The process survives `/clear`, so the
   record is still live and the lock is still correctly held by a session that
   is still running — stamping it `superseded` would mark a live session dead
   and make `attach-session.sh` skip it. The new session id that Claude Code
   assigns on `/clear` is reconciled by the existing SessionStart `register`
   hook, which re-fires on the cleared session; no lock inheritance logic is
   needed. No successor-pending handshake file is written either: no second
   process starts, so there is no second `register` call to consume one.
   Regression-tested (`test-launch-next-session.sh`, C3).
3. **Hands-free auto mode.** Correct as stated, and this is the sketch issue 04
   proposed: the SessionStart(`clear`) hook injects the prompt as
   `additionalContext` off a pending marker. One human keystroke remains
   irreducible — no tool or hook can issue `/clear`, only react to one. The
   workflow is designed around that rather than pretending otherwise.
4. **Runtime-agnosticism.** Accepted and enforced rather than papered over:
   `--clear` refuses any resolved runtime other than `claude` with exit 3, the
   same shape as `--bg`'s existing claude-only refusal. Without that guard the
   flag is a trap — a non-claude runtime has no `/clear` and no drain hook, so
   the counter would advance and the seed would sit unread forever.
5. **Process freshness.** Correct as stated. If rollover was triggered by a
   wedged CLI or wedged MCP state rather than by token count, `/clear` does not
   fix it — spawn instead. Named in the selection rule.

## Consequences

- The ordinary rollover stops depending on re-authentication and on MCP
  connection timing — the two observed failure modes of the spawn path.
- The counter advances at invocation, not at successor start, so an abandoned
  `--clear` leaves it one ahead — the same pre-existing exposure the spawn path
  has when a launch fails, with the same documented fix. `--clear` prints that
  exact rewind command (`context-budget.sh seq-sync --project <p> --session
  <N>`) on every real run, so the operator never has to derive it.
  *(Amended 2026-09-03: the printed remedy is now
  `launch-next-session.sh <p> --unstage`, which removes the abandoned seed AND
  rewinds the counter — still through seq-sync — in one command; the two-step
  manual form above proved missable when a resumed conversation converted the
  seed by hand.)*
- `--clear` is honoured even under `ROLLOVER_RELAUNCH=off`. That knob means "do
  not spawn a successor behind my back"; an explicitly typed `--clear` is not
  that. Regression-tested (C5).
- The session keeps its old display name and registry entry, since the process
  is the same. Cosmetic, but `claude agents` listings show the pre-rollover
  number; ADR-0005's registry keying is unchanged.
- The hook fails open on every error path and emits nothing unless a marker is
  pending, so it cannot block session startup. It resolves the workspace root
  through git's common dir — the same resolution the writer uses — rather than
  `$CLAUDE_PROJECT_DIR`, so a hook firing inside a worktree still finds the seed
  the main checkout holds.
- The marker is **drained** on emit, so an unrelated `/clear` later in the day
  cannot re-seed a stale mission.

## Alternatives considered

- **Replace the spawn path entirely** — rejected: ADR-0004's multi-session
  cases and any MCP-fragment change genuinely need a new process (losses 1 and
  5 above).
- **A standalone `rollover-clear.sh`** — rejected: would duplicate the prompt
  wording (against ADR-0003) and the counter logic (against ADR-0007).
- **Teach `register` that a `clear`-sourced session inherits its predecessor's
  lock** (issue 04's own sketch) — rejected as unnecessary once the path stops
  releasing the lock in the first place. The simpler fix is to not create the
  problem.
- **Seed the whole `next-session.md` as `additionalContext`** — rejected:
  defeats the demand-load discipline. Seed the one-line prompt and let the
  successor read the file, exactly as a spawned session does.

## Open item

Whether `/clear` rotates the transcript to a new JSONL is **unverified here**.
If it does, the existing SessionStart `register` hook re-registers against the
new transcript and the budget resets with no further work. If it appends to the
same file, `record` would keep counting pre-clear tokens and report a false
STOP immediately. Confirm on first real use: after `/clear`, run
`scripts/context-budget.sh record` and check that tokens drop to near zero.
