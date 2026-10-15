<!--
Effort-level spec for work/clear-session-loop/ — distinct from root SPEC.md
(product-level Z0). Convention: docs/agents/issue-tracker.md → "Spec conventions".
-->

# Spec — clear-session-loop: three small fixes to the attended `/clear` path

Status: in-review         <!-- draft | in-review | approved -->
Approved-by: —           <!-- who signed off; set when Status: approved -->
Date: 2026-10-15
Spec-of-record: —

Inputs: `work/clear-session-loop/research.md` (verdict PARTIAL) and
`work/clear-session-loop/decisions.md`. The first draft covered all of research
§7 A plus the Spike B; on review the user cut it to the three items below
(`decisions.md`, second 2026-10-15 note). Every repo claim cites `file:line` as
read on 2026-10-15; anything not read in the repo or in primary vendor docs is
marked **(unverified)**.

## 1. Design overview

A Claude Code session can already roll over in place: `launch-next-session.sh
--clear` writes the bootstrap prompt plus this process's pid into
`launch.pending` (`scripts/launch-next-session.sh:282-285,430-435`), the human
presses `/clear`, and the `SessionStart` hook's `register` matches the pid,
binds the new session id and prints the prompt into the cleared context
(`scripts/context-budget.sh:788-795,847-850,865-877`).

The research found no case for building more on `/clear` (no sanctioned
trigger but a keypress; the gains are startup time only; portability is
weakest there). It did find three cheap fixes that protect the setup we
already have:

1. **Owner check in the turn-end hook** before it kills anything (§2).
2. **Optional `PreCompact` hook** that blocks auto-compaction while a work
   item is bound, off by default (§3).
3. **Test the "types nothing" claim** once and make the docs match (§4).

Nothing changes on any runtime other than Claude Code, and nothing changes in
`session-loop.sh` or the record schema.

## Requirements

<!-- Stable IDs — never renumber; strike through retired items. Tickets
     reference these as `Spec: S3`; verification docs as `Covers: S1, S3`. -->

Retired on review (2026-10-15, see Non-goals): ~~S1 pin the clear binding~~,
~~S2 `sessionTitle`~~, ~~S3 `SessionEnd` timeout~~, ~~S5 `chain.clears`~~,
~~S6 supervised clear mode~~, ~~S7 `dispatch_open` gate~~, ~~S8 `--clear`
under a supervisor~~, ~~S9 background-shell rule~~, ~~S10–S12 supervisor
verdicts~~, ~~S16–S17 Spike B~~.

### 2. Turn-end owner check

- **S4 — the turn-end hook checks the current owner before any SIGTERM.**
  Today `budget_hook_should_exit` fires on `.staged != null and .staged.by == $sid`
  (`scripts/hooks/context-budget-hook-lib.sh:124-134`) and `budget_hook_exit`
  then runs `kill -TERM $PPID` (`:141`). Requirement: the predicate becomes
  `.staged != null and .staged.by == $sid and .session.session_id == $sid`.
  Why: after a `/clear` the live process has a new session id, while a
  surviving background child (changelog 2.1.72, research §2.1) still fires
  hooks with the old one. `scripts/hooks/context-budget-hook.sh:111-113` routes
  those to a `-sidechain` key for measurement, but the `end` branch at `:81-91`
  runs before that routing. The research did not reproduce a kill from this
  path; the check is cheap insurance.
  Test: record with `staged.by == sid` and `session.session_id != sid` → no
  signal; both equal → signal (today's behaviour).

### 3. Optional `PreCompact` auto-block

- **S13 — opt-in auto-compaction block.** A new `PreCompact` hook entry in
  `.claude/settings.json` with matcher `auto` and shim
  `scripts/hooks/context-budget-precompact-hook.sh`. It exits 2 (blocks, per
  the hooks page exit-code table — research Verification) **only** when
  `CONTEXT_BLOCK_AUTOCOMPACT=1` is set in `context-budget.env` (or the work
  item's copy) **and** this session owns a work item (`resolve_own_project`
  succeeds). `manual` is never matched. Off by default: on a session that
  ignored STOP, a blocked compaction is a hard wall at the model's window, not
  a rollover. Fail-open on every error (no jq, no record, no env).
  Test: fixture payloads `trigger: auto|manual` × env on/off × owner/non-owner
  → exit code only.

### 4. The "types nothing" question

Claim under test: after `/clear`, the cleared session acts on the seeded hook
context without a typed message (`skills/session-rollover/SKILL.md:251-252`:
"the human presses `/clear` and types nothing"; TADR-0009
`docs/template-adr/0009-clear-based-rollover-relaunch.md:61`: "the human types
nothing beyond the keystroke"). The docs describe `SessionStart` stdout only
as added context, and `initialUserMessage` is `-p`-only (research
Verification). The stage-2 probe typed a message after `/clear`
(`work/template-improvement-review/evaluation/stage2-probes.md:51`), so it does
not settle it. **Unverified today.**

- **S14 — Probe A1 (attended).** In a real session that owns a work item, at
  a genuine rollover: run `--clear`, press `/clear`, type nothing, wait 60 s.
  Record in `work/clear-session-loop/probes.md`: claude version, date, whether
  an assistant turn started, and whether its first tool call read
  `work/<p>/next-session.md`. Run it in two sessions before declaring. The
  same sessions may note, for free, whether CLAUDE.md is re-read and whether
  "allow for this session" permissions carry over (research §2.1, both
  **(unverified)**).
- **S15 — docs follow the answer.**
  - PASS → add "(verified <date>, claude <version>)" at
    `skills/session-rollover/SKILL.md:251-252`, TADR-0009 `:61`, and
    `docs/context-budget.md:360-363`. No code.
  - FAIL → the launcher's human-facing line (`scripts/launch-next-session.sh:453`,
    today "NOW PRESS /clear and type nothing"; test L1i pins that it mentions
    `/clear`, `scripts/tests/test-launch-next-session.sh:341`) becomes "press
    `/clear`, then type `go`"; the skill at `:251-252` and the docs bullet at
    `:360-363` say the same; TADR-0009 gets an amendment noting the keystroke
    is two, not one. The bootstrap prompt text does not change (TADR-0003
    verbatim rule, `docs/context-budget.md:368-371`).

## 5. Failure modes

| # | Failure | Effect | Handled by |
| --- | --- | --- | --- |
| F1 | Human presses `/clear` but the cleared session sits idle (A1 FAIL) | work stops until a message is typed | S15: the launcher line says to type `go` |
| F5 | Sidechain hook firing after `/clear` with the old sid reaches the turn-end branch | SIGTERM to the live process | S4 owner check |
| F11 | `PreCompact` block on a session that ignored STOP | hard wall at the window | S13 opt-in, default off |

## 6. Test strategy

- S4: a hook-lib unit case in the suite that already sources
  `context-budget-hook-lib.sh` — **(unverified)** which one; the implementer
  greps for it, or adds a case to `scripts/tests/test-launch-next-session.sh`.
  Must be seen to fail against today's predicate before the fix.
- S13: a shim test driving the four fixture combinations above, exit code
  only; plus a jq assertion that `.claude/settings.json` has the `PreCompact`
  entry with matcher `auto` (in whichever existing test already parses
  settings — **(unverified)**).
- S14: live runs recorded in `probes.md`, not tests. If S15 takes the FAIL
  branch, update L1i's expected text.

## 7. Docs touched

- `scripts/hooks/context-budget-hook-lib.sh` (S4), new
  `scripts/hooks/context-budget-precompact-hook.sh` and `.claude/settings.json`
  (S13).
- `context-budget.env`: commented `CONTEXT_BLOCK_AUTOCOMPACT=0` with a one-line
  note (S13).
- `docs/context-budget.md`: the clear bullet `:360-366` (S15); a short
  `PreCompact` paragraph near the hook wiring (S13).
- `skills/session-rollover/SKILL.md:251-252` and TADR-0009 (S15).
- `docs/template-workspace-backlog.html`: resolve/append per CONTEXT.md
  "Template Backlog".

## Non-goals

- pty/tmux/expect keystroke injection in `session-loop.sh`.
- `/clear`-based chains on Codex, Copilot, Gemini or the VS Code agents — they
  keep the fresh-process path.
- An event-driven supervisor rewrite, or letting the supervisor accept
  in-process `/clear` hops (former S5, S6, S8, S10–S12).
- The `dispatch_open` drain gate and the background-shell rule (former S7,
  S9): the existing skill already says to checkpoint children before rolling
  over.
- `sessionTitle` on the clear binding and the `SessionEnd` timeout (former S2,
  S3): cosmetic or already harmless (a stale `release` is a no-op,
  `scripts/context-budget.sh:1052-1058`).
- Spike B / an SDK-hosted headless runner (former S16, S17). Revisit only if
  hands-off chains move to an SDK host.
- **Several sessions per work item** — a separate work item,
  `work/concurrent-sessions/`.

## 8. Open questions

1. **A1 itself** (§4) — decides which S15 branch lands.

## Verification

First draft by a fable subagent (dispatch `spec`, gen 1, closed DONE); repo
claims spot-checked by the orchestrating session on 2026-10-15 at `3e0ac29`.
Claims kept in this version and confirmed then: the hook-lib predicate and
`kill -TERM $PPID` (`context-budget-hook-lib.sh:124-141`); `release`
compare-and-set and non-owner no-op (`context-budget.sh:1052-1058`); skill
`:251-252`; TADR-0009 `:61`; the launcher's "type nothing" line (`:453`); no
`PreCompact` entry in `.claude/settings.json`; the stage-2 probe typed a
message after `/clear` (`stage2-probes.md:51`). Line anchors in
`docs/context-budget.md` were not re-checked; the implementer re-reads them
before editing.
