<!--
Effort-level spec for work/clear-session-loop/ — distinct from root SPEC.md
(product-level Z0). Convention: docs/agents/issue-tracker.md → "Spec conventions".
-->

# Spec — clear-session-loop: harden the attended `/clear` rollover (A) + headless spike (B)

Status: draft            <!-- draft | in-review | approved -->
Approved-by: —           <!-- who signed off; set when Status: approved -->
Date: 2026-10-15
Spec-of-record: —

Inputs: `work/clear-session-loop/research.md` (verdict PARTIAL; §7 A and B are
in scope, §7 C is a non-goal, §7 D is out of scope) and
`work/clear-session-loop/decisions.md` (2026-10-15 note). Where the research's
"Verification" section corrects an earlier claim, the correction is what this
spec uses. Every repo claim below cites `file:line` as read on 2026-10-15;
anything not read in the repo or in primary vendor docs is marked
**(unverified)**.

## 1. Design overview

Today a Claude Code session rolls over in one of three shapes
(`docs/context-budget.md:353-366`): a fresh process, a supervised `--emit`
(the `Stop` hook SIGTERMs the session and `session-loop.sh` runs the staged
command), or an attended `--clear` (the launcher writes the bootstrap prompt
plus this process's pid and start time into `launch.pending`,
`scripts/launch-next-session.sh:282-285,430-435`; the human presses `/clear`;
the `SessionStart` hook's `register` matches the pid, binds the new session id
to the open launch and prints the prompt into the cleared context,
`scripts/context-budget.sh:788-795,847-850,865-877`).

The `--clear` path works but is thinly specified: nobody has shown that the
cleared session starts working without a typed message; the `SessionEnd`
`release` hook runs inside a vendor time budget nobody measured; a session can
`--clear` with subagents still running; the turn-end hook kills on
`staged.by` alone; and the supervisor cannot account for a `/clear` that
happened inside a child it is waiting on.

This effort does five small things to the attended Claude path and runs one
spike. It does **not** change how sessions are started on any other runtime and
does **not** build an unattended `/clear` chain.

1. **Settle the "types nothing" question** by probe, then make the skill, the
   launcher's instruction line and TADR-0009 say what is true (§8).
2. **Pin the hook contracts** — `SessionStart source=clear` output,
   `SessionEnd` time budget, turn-end owner check (§3).
3. **Add the drain gate** — `--clear` refuses while a dispatch generation is
   open (§5), and the skill tells the session what to do with background
   shells.
4. **Let the interactive supervisor count in-process `/clear` hops** as valid
   successors by reading one new counter from the record when the child
   finally exits — no polling, no pty, no event-driven rewrite (§6).
5. **Optional `PreCompact` auto-block**, opt-in (§7).
6. **Spike B**: one time-boxed headless run answering six yes/no questions
   about `claude -p` + `/clear`; it changes nothing in the loop (§9).

## 2. Per-runtime behaviour and fallback

| Runtime | Rollover shape after this effort | Source |
| --- | --- | --- |
| Claude Code CLI (attended) | `--clear` (same process) **or** a fresh process; the session chooses by the MCP/runtime rule at `docs/context-budget.md:364-366` | this spec |
| Claude Code CLI (supervised, `launch.mode=interactive`) | `--clear` allowed inside the child (§6) **or** `--emit` | this spec, S8 |
| Claude Code CLI (supervised, `launch.mode=handsoff`) | `--emit` only; `--clear` refused `supervised_stage_only` | `scripts/launch-next-session.sh:195-197` (unchanged) |
| Claude Code VS Code extension | not designed here; the CLI `--clear` path may work in the panel **(unverified)** | research §5 |
| Codex, Copilot CLI, Gemini, Antigravity, OpenCode, Copilot VS Code | **fresh process only.** `--clear` keeps refusing `runtime_path_unsupported` | `scripts/launch-next-session.sh:184-186`; test V2/L-series |

Fallback on Claude when any clear-only gate refuses (no pid recorded, open
dispatch, supervisor in hands-off mode): the session runs the same launcher
without `--clear` (fresh process) or with `--emit` (supervised). No new
fallback path is introduced.

## Requirements

<!-- Stable IDs — never renumber; strike through retired items. Tickets
     reference these as `Spec: S3`; verification docs as `Covers: S1, S3`. -->

### 3. Hook contracts

- **S1 — `SessionStart source=clear` binds the successor (unchanged, now pinned).**
  On a `SessionStart` payload whose pid walk (`scripts/context-budget.sh:683-702`)
  resolves to the pid/`pid_start` held in `launch.pending`
  (`scripts/context-budget.sh:788-795`), `register` binds the new session id
  with action `adopted` (`:847-850`), nulls `launch.pending`, keeps `seq`
  (`:867-871`) and prints the pending prompt once on stdout (`:877`). A
  payload whose `source` is `clear` but whose pid does not match any pending
  launch binds nothing and prints nothing. Test: payload fixture with and
  without a matching pending block; assert record fields and stdout, not
  prose.
- **S2 — `sessionTitle` on the clear binding, behind a probe.** The hooks page
  lists `sessionTitle` among `SessionStart` outputs (research §2.2, verified
  against https://code.claude.com/docs/en/hooks); whether it renames an
  *interactive* session after `/clear` is **(unverified)**. Probe A2 (§8)
  decides. If it applies: for the `pending` binding on runtime `claude` only,
  `register` prints the JSON form
  `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<prompt>","sessionTitle":"<project> #<seq>"}}`
  instead of the bare prompt, so the title matches what the spawn path sets
  with `--name "<p> #<n>"` (`scripts/launch-next-session.sh:397`). Every other
  runtime and every non-pending binding keeps plain stdout. If it does not
  apply: no change; TADR-0009's cosmetic consequence (`:130-132`) stays and the
  probe result is recorded there. Test: stdout shape per runtime and binding
  kind.
- **S3 — `SessionEnd` stays inside the vendor budget.** `SessionEnd` hooks
  share a 1.5 s budget; a per-hook `timeout` raises it (≤ 60 s) and
  `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` overrides it (research §2.2 and
  Verification, hooks page + changelog 2.1.74/2.1.268). Our `release` runs
  there with no `timeout` set (`.claude/settings.json` → `SessionEnd`).
  Requirement: (a) measure `release` wall-clock on this machine ten times
  under `time`; (b) set `"timeout": 5` on the `SessionEnd` hook entry
  regardless, so a slow disk never truncates the owner's `ended` stamp;
  (c) document that a truncated `release` is harmless: `register` on the new
  id adopts a same-pid owner whether or not `ended` was written (`:847-850`),
  and a late `release` from the old id is a no-op for a non-owner
  (`scripts/context-budget.sh:1058`) because the compare-and-set keys on
  `session.session_id` (`:1052-1054`). Test: fixture asserting the settings
  entry carries `timeout`; the ordering claim is covered by the existing
  no-op path (assert `release` with a stale sid returns 1 and writes nothing).
- **S4 — the turn-end hook checks the current owner before any SIGTERM.**
  Today `budget_hook_should_exit` fires on `.staged != null and .staged.by == $sid`
  (`scripts/hooks/context-budget-hook-lib.sh:124-134`) and `budget_hook_exit`
  then `kill -TERM $PPID` (`:141`). Requirement: the predicate becomes
  `.staged != null and .staged.by == $sid and .session.session_id == $sid`.
  Why: after a `/clear` the live process carries a new session id while any
  surviving background child (changelog 2.1.72, research §2.1) still fires
  with the old one (`scripts/hooks/context-budget-hook.sh:111-113` routes those
  to a `-sidechain` key for *measurement* but the `end` branch at `:81-91`
  runs before that routing). The research did not reproduce a kill from this
  path; the check is cheap insurance and also makes the §6 design safe (a
  `--clear` under supervision never writes `staged`, so nothing to kill).
  Test: record with `staged.by == sid` but `session.session_id != sid` → no
  signal; both equal → signal (existing behaviour).

### 4. Launch record / session state

Current shape: `work/clear-session-loop/session-state.json` (schema 1; blocks
`chain`, `seq`, `launch`, `session`, `staged`; field list at
`docs/context-budget.md:283-289`).

- **S5 — one new counter, `chain.clears`.** Integer, default absent (read as
  0). Written only by `register` on a `pending` binding (`via=pending`,
  `scripts/context-budget.sh:788-795`) **while `chain.supervisor` is non-null**:
  in the same compare-and-set write that fills `session` (`:865-871`), add
  `.chain.clears += 1` and `.chain.used += 1`. Rationale: the supervisor
  charges the cap on consume today (`scripts/session-loop.sh:338`) but is not
  awake during an in-process hop, so the measurer charges it. Attended
  (unsupervised) clears touch neither counter — nothing is capping them.
  No other block changes; `launch.pending` keeps `{pid, pid_start, prompt}`
  (`scripts/launch-next-session.sh:430-435`); `staged` is untouched by a
  clear (test L1g, `scripts/tests/test-launch-next-session.sh:339`).
- **S6 — `launch.mode` on a supervised clear is `interactive`.** When `--clear`
  runs under a live supervisor (allowed only in interactive mode, S8), the
  bump writes `launch.mode = "interactive"` and `launch.by = "session"`; the
  successor is in the same process at the same keyboard, so no other mode is
  possible. Schema number stays 1 — additive fields only; `test-doc-consistency.sh`
  pins the record table at `docs/context-budget.md:283-289`, which gains the
  `clears` entry.

### 5. Drain before `--clear`

- **S7 — `--clear` refuses while a dispatch generation is open.** Gate name
  `dispatch_open`; exit **4** via `refuse` (`scripts/launch-next-session.sh:64`),
  message `refused reason=dispatch_open project=<p> open=<task>[,<task>] — checkpoint or close every open generation (scripts/fleet.sh dispatch-list --project <p>), then re-run`.
  Why exit 4 and not 3: the launcher's contract is `0 ok / 3 usage / 4 refused`
  (`:26-27`); a usage error (`die`, `:63`) means the command line is wrong,
  a refusal means a gate found the workspace not ready and names a remedy —
  this is the latter, like `launcher_unchanged`. Detection reuses
  `fleet.sh dispatch-list --project <p>` semantics: exit 1 iff any record's
  last generation has `status: "open"` (`scripts/fleet.sh:288-302`). The gate
  runs for `--clear` only (a fresh process or `--emit` orphans children just
  the same, but that is today's documented behaviour and widening it is out of
  scope), sits in the `--clear` block right after the no-pid check
  (`scripts/launch-next-session.sh:282-285`) and before `worktree_unsynced`,
  and runs under `--check` and `--dry-run` too, writing nothing. It is added
  to the gate table (`docs/context-budget.md:331-344`) and the pinned reason
  list (`:574`).
- **S8 — `--clear` under a live supervisor.** Today refused
  `supervised_stage_only` whenever `supervised` returns live
  (`scripts/launch-next-session.sh:195-197`). Requirement: when a supervisor is
  live **and** the record's `launch.mode` is `interactive`, `--clear` proceeds
  (writes `launch.pending`, S6); in `handsoff` mode it keeps refusing
  `supervised_stage_only` with the remedy text extended: "…or, in an
  interactive chain, `--clear`". A plain launch under a supervisor keeps
  refusing in both modes (test V1).
- **S9 — background shells are the session's job, not a gate's.** Nothing in
  the record tracks `run_in_background` shells, and they survive `/clear`
  (changelog 2.1.72). The skill's step 5 "State snapshot — … running
  processes" (`skills/session-rollover/SKILL.md:157`) gains one sentence: before
  `--clear`, every background shell is either listed in the launcher with its
  purpose or killed. No code.

### 6. Interactive supervisor accepts `/clear` hops

The supervisor runs the child in the foreground and reads the verdict after
it exits (`scripts/session-loop.sh:345-392`). A `/clear` inside the child does
not exit it, so the research's wording "the press-Enter pause becomes press
`/clear`" (§7 A) cannot be literal: at the pause (`:440-445`) the child is
already gone. What the supervisor *can* do is accept that the child advanced
the number more than once while it waited.

- **S10 — verdict arithmetic uses `chain.clears`.** Let `k` = `chain.clears`
  after minus before the child ran (0 today). The verdict legs change as
  follows, nothing else:
  - quit legs (`:355-372`): condition `seq_after == seq + k` and `staged == null`;
    the `no_own_measurement` check compares `session.seq` to `seq + k`.
  - staged leg (`:377-392`): `seq_after == seq + k + 1`; `launch.predecessor.seq == seq_after - 1`
    (the last hop's session) instead of `== seq`; `staged.by` must still equal
    `launch.predecessor.session_id`; lifetime, `registered_at ≥ started_iso`
    and mode checks unchanged.
  - any other delta stays `staged_invalid leg=seq`.
  - the `staged` verdict line gains `clears=<k>` so the chain log shows the
    hop count.
- **S11 — cap and stall.** `chain.used` already includes the hops (S5), so the
  existing `USED -lt MAX_SESSIONS` check at the next consume (`:334`) enforces
  the cap one child late; document that a child may overshoot the cap by its
  own in-process hops. The stall guard is off in interactive mode (`:430-431`),
  so no change. `plan.sh sync`/`check` between children (`:393-428`, sync at `:401`) still run
  at child exit only; the cleared session runs its own plan steps per the
  skill (`docs/context-budget.md:438-441` note).
- **S12 — the pause text.** Unchanged; it is correct (the child has exited).

### 7. Optional `PreCompact` auto-block

- **S13 — opt-in auto-compaction block.** A new `PreCompact` hook entry in
  `.claude/settings.json` with matcher `auto`, shim
  `scripts/hooks/context-budget-precompact-hook.sh`, that exits 2 (blocks,
  per the hooks page exit-code table — research Verification) **only** when
  `CONTEXT_BLOCK_AUTOCOMPACT=1` is set in `context-budget.env` (or the work
  item's copy) **and** this session owns a work item (`resolve_own_project`
  succeeds). `manual` is never matched. Default off, because a blocked
  compaction on a session that ignored STOP is a hard wall at the model's
  window, not a rollover. Fail-open on every error (no jq, no record, no env).
  Test: fixture payloads `trigger: auto|manual` × env on/off × owner/non-owner
  → exit code only.

### 8. The "types nothing" question

Claim under test: after `/clear`, the cleared TUI session acts on the seeded
hook context without a typed message (`skills/session-rollover/SKILL.md:251-252`:
"the human presses `/clear` and types nothing"; TADR-0009
`docs/template-adr/0009-clear-based-rollover-relaunch.md:61`: "the human types
nothing beyond the keystroke"). The docs describe `SessionStart` stdout only as
added context; `initialUserMessage` is `-p`-only (research Verification). The
stage-2 probe typed a message after `/clear`
(`work/template-improvement-review/evaluation/stage2-probes.md:51`), so it
does not settle it. **Unverified today.**

- **S14 — Probe A1 (attended).** In a real session owning a work item, at a
  genuine rollover: run `--clear`, press `/clear`, type nothing, wait 60 s.
  Record in `work/clear-session-loop/probes.md` (format in §9): claude
  version, whether an assistant turn started, and whether its first tool call
  read `work/<p>/next-session.md`. Run twice (two sessions) before declaring.
- **S15 — docs follow the answer.**
  - PASS → add "(verified <date>, claude <version>)" at
    `skills/session-rollover/SKILL.md:251-252`, TADR-0009 `:61`,
    `scripts/launch-next-session.sh:453` (comment only), and
    `docs/context-budget.md:360-363`. No code.
  - FAIL → the launcher's human-facing line (`scripts/launch-next-session.sh:453`,
    which today says "NOW PRESS /clear and type nothing"; test L1i pins that it
    mentions `/clear`, `:341`) says
    "press `/clear`, then type `go`"; the skill at `:251-252` and the docs
    bullet at `:360-363` say the same; TADR-0009 gets a second amendment
    noting the keystroke is two, not one. The bootstrap prompt text is not
    changed (TADR-0003 verbatim rule, `docs/context-budget.md:368-371`).
  - Probe A2 (`sessionTitle`, S2) runs in the same sessions: after the clear
    binding, does `claude agents`/the title bar show `<p> #<n>`?

### 9. Spike B — headless same-process reset

- **S16 — protocol.** Time box: one session **or** two hours wall-clock,
  whichever comes first; the record is the deliverable either way.
  1. Scaffold a throwaway item `work/spike-clear/` (README, launcher, ledger
     block #1) so the launcher's artefact gates pass; do not commit it.
  2. Start `claude -p --input-format stream-json --output-format stream-json --verbose`
     from the workspace root so the committed hooks load. **(unverified)**
     that `SessionStart`/`SessionEnd` hooks run under `-p`; Q3 answers it.
     Add a spike-local hook logger (`SessionStart`, `SessionEnd`, every
     payload appended to `work/spike-clear/hooks.log`) via `--settings <file>`
     **(unverified flag)**; fallback is a local, uncommitted edit of
     `.claude/settings.json`.
  3. Send one user message; read `session_id` from the `system/init` event.
  4. From a second shell, as the owner:
     `CLAUDE_CODE_SESSION_ID=<sid> scripts/launch-next-session.sh spike-clear --clear`
     (the launcher resolves "me" from that variable,
     `scripts/context-budget.sh:444`; the test suite drives it the same way,
     `scripts/tests/test-launch-next-session.sh:57`). Expect exit 0 and
     `launch.pending` set; if it refuses `runtime_path_unsupported` (no pid),
     record that as Q4 FAIL (the pid walk at `:683-702` did not find a
     `claude` ancestor under `-p`) and continue.
  5. Send `{"type":"user","message":{"role":"user","content":"/clear"}}`.
  6. Send nothing for 60 s, then one more user message, then end stdin.
- **S17 — pass/fail record.** `work/clear-session-loop/probes.md`, section
  "Spike B", one table row per question, columns `id | question | result
  (PASS/FAIL/UNOBSERVED) | evidence (stream line or hooks.log line, quoted) |
  claude version | date`:
  - Q1 a `conversation_reset` (or any reset-shaped) event arrives after step 5.
  - Q2 `session_id` in hook payloads rotates between the `SessionEnd` and the
    next `SessionStart` (the §2.1 discrepancy: SDK doc carries `session_id` +
    `new_conversation_id`).
  - Q3 `SessionEnd reason=clear` then `SessionStart source=clear` fire under `-p`.
  - Q4 `register` rebinds by pid (`register: … (adopted)` note in hooks.log).
  - Q5 a `SessionStart` output `initialUserMessage` seeds a first turn with
    no user message (spike-local hook emitting
    `{"hookSpecificOutput":{"hookEventName":"SessionStart","initialUserMessage":"reply SPIKE-OK"}}`
    on `source=clear`): an assistant message `SPIKE-OK` appears before step 6's
    message.
  - Q6 `scripts/context-budget.sh check --session-id <new sid>` reads near
    zero right after the clear and grows after step 6.
  Outcome rule: all of Q1–Q4 PASS → a decision note proposing a separate work
  item "SDK/headless-hosted hands-off runner"; any FAIL → a decision note
  closing the headless route for now. Either way nothing in the loop changes
  from this spike.

### 10. Failure modes

| # | Failure | Effect | Handled by |
| --- | --- | --- | --- |
| F1 | Human presses `/clear` but the cleared session sits idle (A1 FAIL) | work stops until a message is typed | S15 docs; the launcher line says to type `go` |
| F2 | `SessionEnd` `release` truncated by the 1.5 s budget | `session.ended` missing on the old block | S3: `register` adopts by pid anyway; stale `release` is a no-op |
| F3 | `/clear` with a running dispatched child | child orphaned; parent cannot sweep it (`docs/context-budget.md:679-684`) | S7 refuses `dispatch_open` |
| F4 | `/clear` with a background shell | shell keeps running unseen | S9: listed or killed per the skill |
| F5 | Sidechain hook firing after `/clear` with the old sid reaches the turn-end branch | SIGTERM to the live process | S4 owner check |
| F6 | Human presses `/clear` without having run `--clear` | no pending block; `register` adopts same-pid with the same `seq`; no prompt — a plain reset mid-session | existing behaviour (`:847-850`); no change, documented |
| F7 | Human runs `--clear` and never presses `/clear` | open launch; the next `register --project` adopts it, no number spent | TADR-0009 amendment `:7-12`; unchanged |
| F8 | Supervised interactive child clears, then quits | `seq_after == seq + k`, `staged == null` | S10 quit leg |
| F9 | Supervised child clears past the cap | one child overshoots | S11, documented |
| F10 | Record CAS fails during the clear binding (another writer) | not bound; prompt not printed | existing `scripts/context-budget.sh:878`; the human re-runs `register --project` (prints nothing: prompt lost — add to Open questions) |
| F11 | `PreCompact` block on a session that ignored STOP | hard wall at the window | S13 opt-in, default off |
| F12 | Rewind menu re-imports the pre-clear conversation (research §1, §3.7) | context accretion | out of scope; one sentence in the skill's guardrails |

### 11. Test strategy

Both suites exist and are self-contained: a throwaway git workspace, the real
scripts copied in, record/exit-code/reason-code assertions only.

- `scripts/tests/test-launch-next-session.sh` (434 lines; `assert_refused`
  helper `:48-52`; `seed` builds the owner record with optional pid
  `:68-76`; L-series `:329-344` covers `--clear`). Add:
  - L3 `dispatch_open`: `.agent-dispatch/x.json` with last generation `open`
    → exit 4, reason `dispatch_open`, record byte-identical.
  - L4 same with status `closed` → exit 0, `launch.pending` set.
  - L5 `--clear` under a live supervisor (reuse the V-series `mk_sup`
    seeding `:184-190`) with `launch.mode=interactive` → exit 0,
    `launch.mode` stays `interactive`; with `handsoff` → `supervised_stage_only`.
  - L6 `register` pending bind with `chain.supervisor` set → `chain.clears`
    1, `chain.used` +1; without → both untouched. The pid walk needs the
    registering process to present as `claude` (`:694-696`); the suite's
    E-series binds via env, not pid (`:112-116`), so this case needs either a
    stub named `claude` that does not `exec` away or the E-series pattern
    extended — **(unverified)** which is cheaper; implementer's call.
  - S4: a hook-lib unit case — record with `staged.by == sid`,
    `session.session_id != sid` → `budget_hook_should_exit` returns 1.
- `scripts/tests/test-session-loop.sh` (516 lines; stub child at `:61-131`
  selected by `STUB_BEHAVIOUR`; `$TMP/bin/claude` wrapper `:43`; P4 `:432-446`
  shows the interactive pause ends the chain with no tty). Add I-series:
  - I1 stub behaviour `clear-then-stage`: register, run the real launcher
    `--clear`, re-register as a new sid with `chain.clears` bumped (simulated
    binding, since the stub cannot `/clear`), then `--emit` and exit → verdict
    `staged seq=8 successor=10 clears=1`, `chain.used` 2.
  - I2 `clear-then-quit` → `quit_plain`, `chain.closed.by_seq` = 9.
  - I3 seq moved by 2 with `chain.clears` unchanged → `staged_invalid leg=seq`
    (an unaccounted hop is still an error).
- `scripts/tests/test-doc-consistency.sh` pins the reason-code list
  (`docs/context-budget.md:548-580`) — `dispatch_open` must land in both.
- Settings fixture: `.claude/settings.json` `SessionEnd` entry has
  `timeout`; `PreCompact` entry has matcher `auto` (a jq assertion in an
  existing settings test, or `test-agent-entrypoints.sh` if it already reads
  settings — **(unverified)** which test owns settings shape).
- Probes A1/A2 and Spike B are live runs recorded in `probes.md`, not tests.

### 12. Docs touched

- `docs/context-budget.md`: record table `:283-289` (`chain.clears`); gate
  table `:331-344` (`dispatch_open`, `supervised_stage_only` wording); clear
  bullet `:360-366` (A1 outcome); modes paragraph `:512-516` (in-process hops
  in interactive mode); verbs/reason codes `:548-580`; support matrix
  `:796-805` (attended clear: verified with or without a typed turn);
  registration `:864-872` (counter bump on supervised clear binding).
- `skills/session-rollover/SKILL.md`: step 5 `:157` (background shells);
  step 6 code list after `:182` (`dispatch_open`); clear paragraph `:245-254`
  (A1 outcome, drain rule).
- `docs/template-adr/0009-clear-based-rollover-relaunch.md`: second
  amendment block under `:6` recording A1/A2 results, S4, S7, S10.
- `.claude/settings.json`: `SessionEnd` `timeout`; optional `PreCompact` entry.
- `scripts/hooks/context-budget-adapters.conf`: no change (PreCompact is
  claude-only and lives in settings; say so in the file's header comment only
  if a reader would look for it there).
- `docs/template-workspace-backlog.html`: resolve/append per CONTEXT.md
  "Template Backlog".
- `work/clear-session-loop/decisions.md`: the exit-code and counter choices
  (Tier 2), plus the Spike B outcome.

## Non-goals

Verbatim from research §7 C, plus scope decisions:

- pty/tmux/expect keystroke injection in `session-loop.sh` (works empirically,
  unsupported by every vendor).
- `/clear`-based chains on Codex, Copilot, Gemini or the VS Code agents — they
  keep the fresh-process path; no `/clear` design for them, and no live
  verification of their hooks' `clear` sources.
- a supervisor rewrite to the event-driven model of research §3.3 for
  hands-off mode (polling the record, sending `/clear`).
- an SDK-hosted headless runner — Spike B only decides whether to propose one.
- widening the drain gate to `--emit` or plain launches.
- changing the bootstrap prompt text (TADR-0003), the record schema number, or
  the one-owner-per-item rule.
- **D (several sessions per work item)** is out of scope; if wanted it is a
  separate research + spec item (record `sessions[]`, per-lane `seq`, node
  claims with CAS — research §6, §7 D).

## 13. Open questions

1. **A1 itself** (§8) — the whole shape of the attended docs hangs on it.
2. **Session-id rotation under `-p`** (Spike B Q2; research §2.1): if the id
   does not rotate, `hook-<rt>-<sid>.status` keeps the old WARN/STOP slot — a
   false STOP on the first post-clear check. Only matters if the headless
   route is pursued.
3. **F10**: a CAS miss on the clear binding loses the printed prompt; is a
   re-run of `register --project <p>` enough (it adopts but prints nothing,
   `:877` is pending-only)? Cheapest fix: print the prompt on `adopted` too
   when `launch.pending` was non-null at read time.
4. **Is CLAUDE.md re-read on `/clear`, and do "allow for this session"
   permissions carry over?** Both **(unverified)** (research §2.1); A1
   sessions can observe both for free.
5. **`--settings <file>`** as the spike's hook-logger carrier — if the flag
   does not exist, the fallback is a local settings edit (S16 step 2).
6. **Where settings-shape assertions live** (§11) — pick the existing test
   that already parses `.claude/settings.json`, or add one.

## Verification

Drafted by a fable subagent (dispatch `spec`, gen 1, closed DONE); repo claims
spot-checked by the orchestrating session on 2026-10-15 against the files as
committed at `3e0ac29`. Confirmed: launcher exit contract and `die`/`refuse`
(`:26-27`, `:63-64`), `runtime_path_unsupported` and `supervised_stage_only`
gates (`:184-186`, `:195-197`), the no-pid check (`:282-285`), the `--name`
title (`:397`); `register` pending lookup, same-pid adoption and pending-only
prompt print (`scripts/context-budget.sh:788-795`, `:847-850`, `:865-878`);
`release` compare-and-set and non-owner no-op (`:1052-1058`); the hook-lib
predicate and `kill -TERM $PPID` (`context-budget-hook-lib.sh:124-141`);
`fleet.sh dispatch-list` exit-1-iff-open (`:288-302`); supervisor cap charge,
interactive pause and stall-guard note (`session-loop.sh:334`, `:338`,
`:430`, `:440-445`); skill `:157`, `:251-252`; TADR-0009 `:61`; the
`SessionEnd` hook has no `timeout` and there is no `PreCompact` entry in
`.claude/settings.json`; test suite sizes (434 / 516 lines); the stage-2
probe typed a message after `/clear` (`stage2-probes.md:51`).

Corrected: the `launch.pending` write is at `launch-next-session.sh:430-435`
(draft said `:418-419`); the launcher's printed instruction at `:453` already
says "type nothing", so S15 now names that line in both branches.

Not re-checked here: line ranges in `docs/context-budget.md` (§12 list) and
the test-file line anchors in §11 — the implementer re-reads them before
editing. The design calls in S7 (exit 4), S5/S10 (`chain.clears`), S8
(interactive-only `--clear` under a supervisor) and S13 (opt-in, default off)
are the subagent's; they are the review's main questions.

