# Stage 3 — independent architect review of Part 2 (2026-09-15)

> Reviewed: `evaluation/stage2-design-part2.md` (309 lines) against §1b.5 (17 decisions), §1b.7 (binding), the S1–S10 table, the Stage 1 §7(c)/(d) seed and `evaluation/stage2-probes.md`. Every `file:line` citation I relied on was re-read on main `a213b3d`; all matched. Two user findings weighed as design smells: "too long" and "too much internal jargon". Nothing below was tested by running a script.

## 1. Per-section verdicts

| § | Verdict | Reason | Amendment (for AMEND) |
|---|---|---|---|
| (a) concepts kept | AGREE | Seven concepts is the right count; the exclusions are all traceable to a decision. | Move the "Replaces (today)" column and the exclusion paragraph's citations to a migration appendix — they are plan material, not design. |
| (b) record | **AMEND** | Schema is right in shape (one file, three writers, disjoint blocks, atomic rename). But the walk-through table and the supervisor predicate contradict each other, and a third of the fields gate nothing. | (1) The bump nulls `session` (row "session N+1 rolls over → **null**"), yet (d) reads `R.session.registered_at` and `R.session.seq` after the child exits — unsatisfiable. Rule: **the bump copies the owner into `launch.predecessor = {seq, session_id, registered_at, disposition}` and the supervisor reads only `predecessor`**. (2) Delete the `options` block: the launcher captures permission mode from `session.artifact` at the bump (what `capture-rollover-options.sh` already does from the transcript) and replays it; no agent verb, no record field. (3) `register --project p` on a record with `session == null` and an open `staged`/`pending` for `seq` **becomes that session** (fills the slot, nulls `staged`/`pending`). See §5 Q4. (4) Field cuts in §4. |
| (c) liveness | AGREE | pid+pid_start with mtime fallback, `--takeover` sole override, silence-kill scoped by adapter — matches decisions 4/7 and coupling 3. | Drop the copilot-vscode/opencode rows (they are non-goals in (l)); one sentence "follow-up runtimes: mtime fallback" suffices. |
| (d) supervisor | **AMEND** | Three verdicts is right. The `staged` predicate has six legs, two of which are unsatisfiable (see (b)) and one (`child` captured by the alarm subshell) introduces a new timing coupling. | `staged` ⇔ `R.staged != null ∧ R.seq == seq_before+1 ∧ R.launch.predecessor.seq == seq_before ∧ R.launch.predecessor.disposition == rolled_over ∧ flush hashes changed`. `predecessor.disposition == rolled_over` is written by the launcher only when the caller was the registered owner of `seq_before`, so it already proves "the child registered and measured for itself"; delete the `registered_at > launched_at` leg and `no_own_measurement`. `child` (pid/artifact) is then needed only by the alarm probe, not by the verdict. Collapse `seq_moved_unstaged`/`seq_delta`/`staged_by_mismatch` into one `staged_invalid leg=<name>`. |
| (e) identity binding | **AMEND** | exec/eval via env and `/clear` via same-pid are exact and probe-backed. `--bg` is not: rule (4) "freshest unexpired record with `session == null`" is claimed by *any* plain `claude` a human starts in the workspace inside the 600 s window (its register has no project, no env, a non-matching pid — it falls straight through to rule 4). `pending_elsewhere` closes the two-projects swap, not this one. | **Delete `--bg`** from the daily loop (§5 Q2). Rules (1)–(3) remain; rule (4), `expires_at`, `pending_elsewhere`, `pending_expired` go. Merge `adopted_resume`/`adopted_clear` into `adopted` (one predicate: owner dead ∨ owner.pid == mine). |
| (f) adapters | AGREE | One table, one dispatcher, `logout_for` with `unknowable` is honest, hook-less = unsupported is the right call. | Trim the two follow-up columns/rows as in (c). |
| (g) fleet | AGREE | Zero runtime interface to the daily loop; drain is fleet-side by argument, and the argument (report file survives) holds. | — |
| (h) boundary skill | **AMEND** | The gate chain (write → verify → launch/close, refusal codes with the repair command) is exactly §1b.7. But `prep`/`rollover-start` exists only to snapshot hashes for `ledger_unchanged`/`launcher_unchanged`, and the ledger leg is already subsumed by `ledger_seq_mismatch`. | Delete `prep`, `session.rollover`, `prep_missing`, `*_unchanged`. `verify` checks: top ledger block == `session.seq`, `check-ledger.py` == 0, and `mtime(next-session.md) > session.registered_at` (script-measured, no snapshot). Archive rotation moves into the launcher (after verify). Delete `opts-sync`, `--unstage`, `staged_unconsumed` (per (b)(3)). Keep `--loop-mode`/`--loop-reason` as the only agent choices. |
| (i) docs | AGREE | One rule, one place; V12 makes it checkable. | Merge `docs/session-supervisor.md` into `docs/session-management.md` unless the latter exceeds its 250-line cap — two docs for one loop is one more place to drift. |
| (j) tests | **AMEND** | Exit code + record field + reason code is the right contract; the fixture helper fixes coupling 5. | Delete V13 (no `--unstage`); V7 covers "resumed after staging" via (b)(3). Shrink the code list per §4. |
| (k) ADRs | AGREE | Three ADRs with explicit rejected alternatives; amendments to 0004–0009 are precise. | Record the three deletions above (`--bg`, `prep`, `options`) as rejected alternatives in 0010/0011. |
| (l) non-goals | AGREE | — | Add `--bg` (hands-off with a different MCP set from inside a session) and `--unstage`. |
| (m) questions | — | Answered in §5. | — |

## 2. Hidden couplings

| Stage 1 §7(c) | Handled? | Note |
|---|---|---|
| 1 launch → register binding | Partly | exec/eval (env, exact) and `/clear` (same pid, exact) are solid and probe-backed. `--bg` binding is a heuristic with a new hole (any human-started session in the TTL window claims the launch). Fix: delete `--bg`. |
| 2 re-keying under one launch | Yes | One adoption predicate (owner dead ∨ same pid) replaces `own_record()`, `fork_of()`, fingerprint. Gap: a predecessor resumed *after* it staged (V13) is not covered by adoption (the slot is null); Part 2 routes it through `--unstage` and spends a number. (b)(3) covers it with no new verb. |
| 3 no positive liveness on two runtimes | Yes | (c) table + `liveness_oracle` adapter field; silence-kill scoped away from shared artifacts; gemini/copilot-vscode attended-only. |
| 4 runtime-specific end facts | Yes | `logout_for` in the adapter with `unknowable`; MIN_LIFETIME deleted with its gemini rationale (loop:945-947 verified: it guards only the first-turn STOP shape). |
| 5 test/process coupling | Partly | Fixture helper, `assert_reason`, `main "$@"`, gitignore 12→1 all present. **Not named:** the stall guard's bookkeeping set (loop:495-507, `session_made_progress`) must become `{next-session.md, handoff.md, handoff-archive.md}` — the record is gitignored, so it drops out, but the design should say so; otherwise a stale set reintroduces L46. |

**New couplings Part 2 introduces**

- **C6 — verdict depends on an alarm-subshell poll window.** `child = R.session` "as captured by the alarm probe once the successor registered"; the bump then nulls `session`. A child that registers and rolls over between two alarm ticks leaves the supervisor with no `child` and a verdict it cannot compute. Removed by the (d) amendment (verdict reads `launch.predecessor`, written atomically at the bump).
- **C7 — verify is order-coupled to prep.** An agent that writes the ledger *before* running `rollover-prep` gets `ledger_unchanged` for correct work. Removed by deleting prep (mtime/seq predicates need no snapshot).
- **C8 — `release` on a nulled slot.** After a rollover the SessionEnd hook's `release` runs on a record whose `session == null` (or belongs to the successor). Part 2 does not state that `release` is a no-op unless `session.session_id == mine`; it must be, or the successor's slot gets `ended` stamped by its predecessor's exit hook. One sentence fixes it.
- **C9 — `--bg` TTL window vs plain human starts** (above). Removed with `--bg`.
- **C10 — `written_by` stamps duplicate the schema.** Each block already has exactly one writer by rule; stamping it invites tests to pin the stamp instead of the fact. Cut (§4).

## 3. §1b.7 compliance audit

Transitions that still rest on the agent, in decreasing weight:

1. **STOP → rollover begins.** The only push is the in-band hook message (`escalate` row: "prose nudge"). Nothing mechanical makes the agent *start* the skill; the gates only order its steps once started. Supervised mode has `past_stop_unstaged` (alarm page) as a backstop; attended mode has the human. This is the irreducible one — record it as such in ADR-0011 and keep the STOP message repeating every turn (hook-lib already does), rather than pretending a gate exists.
2. **`opts-sync` (agent-run).** Forgotten ⇒ successor launches with default permission mode; no refusal anywhere. Cut: capture at the bump (§1 (b)(2)).
3. **`register --project p` on an ad-hoc start.** Forgotten ⇒ the session is project-less; the rollover verbs refuse `not_owner`. Gated, acceptable, and the refusal names the repair.
4. **`--loop-mode interactive` when the successor must ask a human.** Agent judgement; wrong choice costs a pause or a missed pause, not integrity. Acceptable.
5. **Ledger and launcher *content*.** Shape and freshness are verified; quality cannot be. Acceptable by construction; say so once.
6. **Fleet drain before rollover.** Agent-driven, explicitly non-integrity (report file survives). Acceptable.
7. **Migration step "end the pid-72900 chain at its next pause".** Human, one-time. Fine.
8. **`record --label`.** Optional by decision 14. Fine.

Everything else in (h) is a script with an exit code and a refusal on missing evidence. The design passes §1b.7 once items 1–2 are stated/cut.

## 4. Cut list

| Cut | What breaks if cut |
|---|---|
| `--bg` path: rule (4), `launch.pending.expires_at`, `pending_elsewhere`, `pending_expired`, half of `runtime_path_unsupported`, the D14 discussion, probe B's "bearing" paragraph | Hands-off relaunch with a *different* MCP set from inside an unsupervised session. ADR-0009:16-20 already lists `--bg` re-auth and MCP reconnect failures; under a supervisor `--emit` covers the case; attended, the launcher prints the command. Nothing an existing user of this repo relies on. |
| `prep` / `rollover-start`, `session.rollover`, `prep_missing`, `ledger_unchanged`, `launcher_unchanged` | Nothing — `ledger_seq_mismatch` + `check-ledger.py` + `mtime(next-session.md) > session.registered_at` carry the same guarantee without a snapshot. Rotation moves to the launcher. |
| `--unstage`, `staged_unconsumed`, V13, open question 4 | Nothing — an explicit `register --project p` occupies an open launch (§5 Q4). |
| `options` block, `opts-sync`, `options_invalid`, cross-checkout adoption | Nothing — launcher captures from `session.artifact` at the bump (claude only, as today). |
| Record fields: `written_by`/`written_at` on every block; `session.supervisor_pid` (dup of `chain.supervisor.pid`); `session.source`; `session.ended.reason` (advisory vendor string; keep `ended.door`); `launch.by`; `launch.predecessor.runtime`; `chain.opened_at`, `reopened_at`, `last_seq`; `session.verified_at` stays | Nothing gates on any of them. `written_at` may stay if a test wants ordering evidence; then drop `written_by`. |
| Reason codes: `adopted_resume`+`adopted_clear` → `adopted`; `seq_moved_unstaged`+`seq_delta`+`staged_by_mismatch`+`no_own_measurement` → `staged_invalid leg=…`; `budget_unreadable` → `record_unreadable`; `killed_silent` → `silent killed=1`; drop `ledger_gap (warn)` and `no_record (info)` from the canonical list (log lines, not verdicts) | Nothing — the detail travels as `key=value` after the code, which `assert_field`-style tests can pin. ~45 codes become ~28. |
| Follow-up runtime rows in (c)/(f) (copilot-vscode, opencode) | Nothing — (l) already declares them non-goals. |
| "Replaces"/"Retires" columns in (a)/(b), the deleted/folded row of (i), the migration paragraph of (j), all `loop:NNN` citations in (d) | Nothing in the *design*; they belong to the Stage 4 plan as an appendix. This is roughly 35–40 % of the text (estimate). |
| `docs/session-supervisor.md` as a separate doc | Nothing if `session-management.md` fits 250 lines with a supervisor section. |

### Readability

**Undefined tokens Part 2 uses.** Abbreviations: `rc`, `sid`, `seq`, `R`, `CMD`, `cb`/`launch`/`loop`/`hook-lib`, `TTL`, `ff-push`, `JSONL`, `MCP fragment`. ID codes used as the only explanation: `D4/D11/D14/D18`, `M12/M16/M18/M31`, `F5/F7/F8/F10`, `L33/L46`, `V1–V13`, `S1–S10`, `E1–E17`, `I1–I10`, `P4a/P4b`, `D-B/D-E/D-F/D-G`, `R2.17/R2.19`, `cm_bugs`, `ADR-000x:line`, `§C.4/§2a/§2d/§2e/§4`. Vocabulary never introduced: door, slot, owner, bump, emit, eval, staged, pending, flush hash, alarm probe, page, tick, dumb zone, chain, cap, hands-off/interactive, adapter, dispatcher, envelope, `additionalContext`, `{decision:block}`, fleet, dispatch generation, adhoc, takeover, reopen, common-dir-rooted, link-local-work, registry, stamp/status, worktree, launcher/ledger, "the three loops".

**Essential** (the design cannot be stated without them): session, work item, record, owner (slot), session number, rollover, launcher/ledger, staged command, supervisor/chain, verdict + reason code, liveness, adapter, refusal. **Noise** (delete or footnote): every ID code, every `file:line`, `R`, `CMD`, `rc`, the four script abbreviations, `door`, `page/tick`, `flush hash` (say "the two files changed"), `envelope`.

**Fraction dependent on workspace context** (estimate from a paragraph-by-paragraph pass): about two-thirds of sentences carry at least one token that only this repo can resolve; about 40 % of the text (the Replaces/Retires columns, the doc-set and ADR tables, the migration paragraph, probe scenario columns) has no meaning outside the repo at all. A reader who has never opened the repo can currently follow (c), the verdict table in (d), and the support matrix in (f); little else.

**Recommended one-page shape** (order; ≤4 diagrams; every workspace pointer a footnote):

1. *What this is* — EXPLAIN: "An LLM coding session has a finite context window. This subsystem measures how full it is from the runtime's own transcript on disk, and when it crosses a threshold it hands the work to a fresh session through two files and a small state record. A supervisor can run that hand-off unattended in a chain."
2. *The session lifecycle* — DIAGRAM 1: one row of boxes: start → measure each turn → threshold → write ledger + launcher → verify → launch successor → exit; under each arrow, the script that gates it and the refusal it returns when the previous box's evidence is missing.
3. *The record and its three writers* — DIAGRAM 2: one box (`session-state.json`) split into five blocks; three arrows in, labelled launcher (`seq`, `launch`, `staged`), budget script (`session`), supervisor (`chain`); hooks shown as read-only.
4. *Who is alive* — EXPLAIN: "A session owns a work item while its process id is running and was started at the time the record says. Where a runtime has no process of its own, the transcript's last-modified time is the fallback; a human can always overwrite the owner with `--takeover`."
5. *How the successor finds its number* — EXPLAIN: "The successor's id does not exist until it starts, so the launcher leaves a binding the successor's start hook can match without guessing: an environment variable on attached launches, the process id on `/clear`. Whatever registers against an open launch becomes that session."
6. *The supervisor's decision* — DIAGRAM 3: a three-branch decision after the child exits: did it stage a successor (number advanced by one, files changed)? → next; nothing staged and clean exit → chain closed; anything else → stop and report a code.
7. *The three loops* — DIAGRAM 4 (optional): nested boxes — per turn (measure), per session (rollover), per chain (supervise) — each with its state and its writer.
8. *Runtimes* — EXPLAIN: "Each runtime is one row in a table: where its transcript lives, how to count tokens, which hook fires at start and at turn end. A runtime is supported for a mode only after the corresponding probe script has passed on it."
9. *Glossary* (≤12): session · work item · record · owner · session number · rollover · launcher & ledger · staged command · supervisor / chain · verdict / reason code · liveness · adapter.
10. *Footnotes*: script paths, ADR numbers, decision IDs, probe evidence.

## 5. Answers to the §(m) questions

1. **WARN rule** — Yes: ask iff `ROLLOVER_RELAUNCH` ∈ {manual, off}; under `auto` roll without asking. One existing knob, matches CONTEXT.md:289's definition of `auto`; a consent knob would be a fourth place for the same fact.
2. **`--bg` binding** — Neither option: delete `--bg` from the daily loop. The freshest-unexpired scan is claimable by any plain human start inside the TTL (C9); restricting it to supervised chains makes it dead code (the supervisor `eval`s an attached command). `--clear` is the sole unsupervised hands-off path; a different MCP set needs a supervisor or a human.
3. **Logout shapes** — Keep `unknowable`; a `quit_*` with `logout=unknowable` may close a chain because codex/copilot-cli supervision is *unverified* anyway (matrix (f)) — the fixture is captured by whoever runs V9d, as its first step.
4. **`--unstage` spends a number** — Neither: an open launch (`session == null`, `staged`/`pending` for `seq`) is occupied by the next `register --project p`; the resumed predecessor simply *is* session N+1. No number spent, no exception to never-reclaim, no verb. The lost `staged.command` is regenerated by the next launch.
5. **Vendor exit facts** — Leave pid+pid_start as the only liveness oracle; drop `session.ended.reason` (advisory field nothing reads). Keep `ended.door` for the stop door.

## 6. Overall

**YES-WITH-AMENDMENTS.** The core — one gitignored record with three disjoint writers, pid liveness, a three-verdict supervisor, one adapter table, fleet isolated, gates with reason codes — is sound and satisfies §1b.7 and S1–S9. Minimum amendments before Stage 4:

1. Fix the (b)/(d) contradiction: the bump writes `launch.predecessor` (incl. `session_id`, `registered_at`, `disposition`) and the `staged` verdict reads only `predecessor` + `seq` + file hashes (removes C6).
2. Delete `--bg` from the daily loop (removes rule (4), the TTL, two codes, C9).
3. Delete `prep`/`rollover-start`; `verify` uses seq/shape/mtime predicates (removes C7).
4. "Whoever registers against an open launch becomes that session" (removes `--unstage`, V13, Q4).
5. State that `release` is a no-op for a non-owner (C8) and that the stall guard's bookkeeping set is the three markdown files (coupling 5).
6. Cut the fields and codes in §4 and move migration bookkeeping to an appendix; rewrite in the one-page shape with the 12-term glossary.
