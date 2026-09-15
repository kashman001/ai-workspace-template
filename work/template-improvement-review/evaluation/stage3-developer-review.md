# Stage 3 — Developer review of Part 2 (2026-09-15)

> Reviewer stance: a fresh senior developer who would implement Part 2 (`evaluation/stage2-design-part2.md`) in bash + jq. Read: Part 2 whole, §1b.5/§1b.7, `stage2-probes.md`, and only the script lines Part 2 cites (main `d5f40ab`; the cited line numbers still match). Nothing was edited or run. "Unverified" means I did not confirm it on disk.

## 1. Buildability per section

| § | Verdict | One line |
|---|---|---|
| (a) Concepts kept | OVER-SPECIFIED | The "Replaces (today)" column and the excluded list are a migration checklist, not design; the seven concepts themselves are clear. |
| (b) Record | AMBIGUOUS | Three questions: (1) how does `record_update` know "the block the filter touched" — is the block an argument or does it diff top-level keys? (2) "one deliberate shared touch" is false: the launcher nulls `session`, `register` nulls `launch.pending`, `register --project` opens `seq` — three cross-block writes; which are sanctioned? (3) what does `release` do when `session == null` or `session.session_id != mine`? |
| (c) Liveness | BUILDABLE | pid + `ps -o lstart` equality is what cb:697-723 already records; the table is complete for the four first-class runtimes. |
| (d) Supervisor | AMBIGUOUS | The **staged** predicate reads `R.session.registered_at > R.launch.launched_at ∧ R.session.seq == seq_before`, but by (b)'s own iteration table the child's `--emit` has already nulled `session` and replaced `launch` with N+2's. Question: is the verdict computed on the alarm-probe snapshot of `session` and the pre-`eval` copy of `launch.launched_at`? (It must be; the text says otherwise.) |
| (e) Identity binding | BUILDABLE (`exec`, `eval`, `--clear`); UNNECESSARY (`--bg`) | Probe B shows `--bg` can never be bound exactly; the design keeps it with a TTL scan plus a new refusal. See §7 Q2. |
| (f) Adapter table | BUILDABLE | One `case` per field; the support matrix is honest. The `logout=unknowable` suffix is extra code for a gap the matrix already states. |
| (g) Fleet | BUILDABLE | A pure move; no design content beyond "no runtime interface", which is the right call. |
| (h) Gates | AMBIGUOUS | `not_owner` needs "mine"; for copilot-cli and gemini the session id is a newest-artifact heuristic (cb:352-357), so the gate is not a disk fact there. Question: accept the heuristic or require `--session-id` on those runtimes? Also: what does `verify --door stop` check (ledger only, presumably)? |
| (i) Doc set | OVER-SPECIFIED | Fates of 12 documents and a doc-consistency test are a Stage 4 checklist. The WARN-rule resolution paragraph is the one design decision here and is clear. |
| (j) Tests | BUILDABLE | Reason-code list and exit-code table are the contract I would implement against; the probe catalogue is a plan artefact. |
| (k) ADRs | OVER-SPECIFIED | Full ADR text inside the design; the "Rejected" lists are valuable, the tables of amendments are not. |
| (l) Non-goals | BUILDABLE | Short and useful. |
| (m) Open questions | BUILDABLE | Answered in §7. |

## 2. The record (b)

**Atomic single write: yes.** read → `jq` → `mktemp` in `work/<p>/` → `mv` is portable (macOS/GNU) and same-filesystem (the worktree link is a directory symlink, so the temp lands in the real dir). Two conditions the text omits and the helper must enforce: refuse when jq exits non-zero *or* prints empty/non-object output (a filter typo would otherwise `mv` an empty file over the record), and run with `umask` unchanged so the record stays user-private like today's lock.

**Concurrent writers: not safe as specified.** "The lifecycle orders the writers" holds on the happy path only. Three real overlaps, each a read-modify-write of the whole file where the last `mv` silently drops the other writer's block:

1. **Supervisor EXIT trap vs a live child.** `kill <supervisor>` (the documented operator move, loop:441-445) clears `chain.supervisor` while the child may be mid-`--emit` (writing `seq`/`launch`/`staged`). One of the two writes is lost.
2. **`release` vs `register` on `/clear`.** Probe A logs `SessionEnd(reason=clear)` and `SessionStart(source=clear)` in the same second. Whether claude serialises the two hooks is unverified. If `release` lands after `register`, it stamps `ended` onto the *new* session's block.
3. **`release` vs `close`, and `release` on a nulled `session`.** Both write `session.ended`; a `set` in `release` overwrites `close`'s `door:"stop"` and the next launch classifies `abandoned` instead of `stopped`. After a bump `session` is `null`; `.session.ended = …` on null creates `{"ended":…}` with no `session_id`, which breaks the `staged_spent` and adoption predicates.

**How I would close them (about 15 lines total):** (a) a `mkdir "$rec.lock"` spin with a 5 s timeout inside `record_update` — `flock(1)` is absent on macOS, `mkdir` is atomic on both; (b) every writer's jq filter carries its own precondition, so the write is compare-and-set: `release` is `if .session.session_id == $mine then .session.ended = … else . end`, `close` likewise, `register` checks `.session == null or owner-dead`; (c) `release` merges (`+=`) rather than sets `ended`. With (b), a lost race becomes a no-op rather than a corruption, and the design's "no locking" sentence can stay true in spirit.

**Fields nothing reads** (per the design's own gates and verdicts): `launch.reason`, `launch.path`, `launch.predecessor.runtime`, `launch.predecessor.session_id`, `session.source`, `session.user` (kept on purpose, decision 16), `session.supervisor_pid` (duplicates `chain.supervisor.pid`, which is what the launcher actually tests), `chain.last_seq`, `chain.reopened_at`, `chain.opened_at` (message text only), and every `written_by`/`written_at` — no gate reads them; today's `written_by` checks (loop:912-914) are replaced by `staged.by.session_id`. Keep `session.user`; drop or demote the rest to "diagnostic, unstamped".

**Nit:** `.gitignore:34-63` has 18 `work/*/` lines, of which 14 (not twelve) are retired by (a)#2; `.session-loop.log` and `.session-loop.alarm-stop` survive and are not mentioned.

## 3. The gates (h)

| Gate (verb) | Inputs read from disk | Exit / `reason=` |
|---|---|---|
| `register` | registry record, `session` block, pid liveness, env `TF_SESSION_*`, `launch.pending` | 0 always; codes `owner_live`, `adopted_*`, `takeover`, `pending_mismatch`, `pending_expired` |
| `check` | transcript, thresholds | 0/1/2, 3 usage |
| `rollover-start` | `session.session_id` vs mine; hashes of `handoff.md`/`next-session.md` | 4 `not_owner` |
| `verify --door continue\|stop` | `session.rollover` present; top `# Session Handoff — N` vs `session.seq`; `check-ledger.py` rc; ledger/launcher hashes vs `session.rollover.*_hash` | 4 `prep_missing`, `ledger_seq_mismatch`, `ledger_shape`, `ledger_unchanged`, `launcher_unchanged`, `not_owner` |
| launcher | `session.verified_at > session.rollover.started_at`; owner liveness; `chain.closed`; `chain.supervisor` liveness; `staged`/`pending` with `session == null`; runtime; other records' `pending`; git worktree state; `options` shape; `schema` | 4 `unverified`, `not_owner`, `owner_live`, `chain_closed`, `supervised_stage_only`, `staged_unconsumed`, `runtime_path_unsupported`, `pending_elsewhere`, `worktree_unsynced`, `options_invalid`, `schema_mismatch` |
| `close` | `session.verified_at` | 4 `unverified` (inferred; the row says "0; 4" without naming the code) |
| supervisor bootstrap | record, `chain.*`, env `ROLLOVER_RELAUNCH` | 1 `record_unreadable`, `schema_mismatch`, `chain_closed`, `supervisor_live`, `relaunch_off` |
| supervisor verdict | record snapshot, child rc, file hashes, `logout_for` | 0 `quit_*`/`cap`; 1 broken codes |
| turn-end hook | `staged.by.session_id == mine` | SIGTERM `$PPID`, exit 0 |

**Not checkable from disk:** every `not_owner`/owner test depends on *mine*. For claude (`CLAUDE_CODE_SESSION_ID`) and codex (`CODEX_THREAD_ID`) it is env; for copilot-cli and gemini it is "the newest artifact" (cb:352-357) — a guess, and gemini's id is the constant `workspace`. Second: `logout_for` on codex/copilot-cli is *unknowable* by the design's own admission. Third: `jq_missing` — the hook cannot parse its payload or key the stamp without jq, so "prints once per session via the stamp" needs a jq-free fallback path the text does not describe.

## 4. Migration

**Must be true of the live system at the first commit:** no supervisor is running any `session-loop.sh` (bash reads the script incrementally; pid 72900 is on the old file and this work item's own rollovers run through it — decision 12). So: end 72900 at its next pause, and do the implementation on a branch or worktree against a *throwaway* work item, not against `template-improvement-review`, until the last step. The one-time `seq` import reads `work/<p>/.session-seq`; the root `context-budget.env` currently has `ROLLOVER_RELAUNCH=auto` (env:31) and this item has **no** per-item env, so flipping the root default to `manual` needs a new committed `work/template-improvement-review/context-budget.env` in the same change or this chain stops relaunching.

**Order I would implement:**
1. `scripts/lib/session-lib.sh` + `test-session-record.sh` (no callers yet; lock, compare-and-set, schema refusal, atomicity).
2. `scripts/fleet.sh` extraction + `test-fleet-*.sh` (pure move; independent; shrinks cb by ~400 lines before touching it).
3. cb: `register`/`release` on the record; `rollover-start`/`verify`/`close`; `test-verify.sh`, `test-liveness.sh`.
4. launcher: bump/`launch`/`staged`/`pending`; refusals; `test-launch-next-session.sh` rewritten to `assert_reason`/`assert_field`.
5. `session-loop.sh`: `main "$@"` wrapper commit, then the three-verdict body; stub-child suite.
6. dispatcher + adapter table (`test-hook-dispatcher.sh` byte-for-byte).
7. skill, docs, `.gitignore`, env defaults, doc-consistency test.

**Smallest first vertical slice testable end to end:** step 1 alone is unit-testable; the first *end-to-end* slice is steps 1+3+4 on a stub runtime: `register --project t` → `rollover-start` → agent writes two files → `verify` → `launch-next-session.sh t --emit` → assert `seq` +1, `launch.predecessor.disposition=rolled_over`, `staged.by.session_id`, `session == null`; then a stub successor `register` with `TF_SESSION_PROJECT/SEQ` fills `session`. That is S1 with no supervisor and no vendor, and it exercises every gate in (h) but `supervised_stage_only`.

## 5. Test posture (j)

Writable as self-checking scripts: `test-session-record` (yes, including a two-writer race with `&`), `test-liveness` (yes — recycled pid is simulated by a live pid with a mismatched `pid_start`, since real recycling is not controllable), `test-verify` (yes), `test-hook-dispatcher` (yes; existing suite is the net), `test-doc-consistency` (yes, grep), supervisor suite (yes, stub children as today's `test-session-loop.sh:46`).

Fixtures nobody has: codex logout transcript, copilot-cli logout transcript, copilot-cli `agentStop` payload (never fired), gemini `AfterAgent` payload (unprobed), codex `Stop` payload (fired once, log never committed — `.codex/config.toml:9-11`). V9a-d are vendor-gated and cannot be CI. V1, V3–V7, V13 are listed "live" but each has a stub-runtime twin; the design should say the twin is the CI contract and the live run is the acceptance run.

## 6. Cut list

**Implementation detail to drop from the design text (move to a Stage 4 appendix):** every `file:line` citation; (a)'s "Replaces" column and excluded list; (i) whole table; (j) suite rename/merge list, fixture helper, probe catalogue; (k) amendment table; the `logout=unknowable` suffix; the bootstrap five-step list in (d) (the verdict table plus the iteration table in (b) already say it); the `reason` codes for `alarm` and `hooks`; the migration paragraph. Estimated: Part 2 drops from 309 to ~150 lines and reads as one schema, one liveness rule, one verdict table, one gate table, one adapter table, five questions.

**To drop from the design itself:** `--bg` (Q2); `written_by`/`written_at` per block and the unread fields in §2; `session.supervisor_pid`; the `logout=unknowable` verdict suffix; `pending_elsewhere`/`pending_expired` (fall with `--bg`); `verdict=cap` as a separate exit path at start (it is a bootstrap refusal like the others); `test-doc-consistency`'s `ROLLOVER_RELAUNCH` literal assertion (a grep any reviewer can run).

### Readability

Terms I had to decode (E = essential, keep and define once; R = rename; D = drop):

- `rc` R → "the child's exit status". `seq` E → define once as "session number". `R` D → "the record". `CMD` R → "the staged command". `sid`/`mine` R → "session id" / "the calling session's id". `door` R → "continue or stop" (define "two doors" in one sentence or drop the metaphor). `bump` E → define: "advance the session number". `stage`/`consume`/`spent` E → define in one line each; they are the supervisor's vocabulary. `slot` R → "the owner field". `emit`/`--emit` E → "stage mode: write the successor's command instead of running it". `handsoff`/`interactive` E → define once. `flush hashes` R → "the launcher/ledger file hashes". `alarm probe` R → "the supervisor's watchdog". `fleet`/`dispatcher` E → define. `pid_start`/`lstart`/`mtime` E (standard). `quit_plain`/`quit_stop` E but rename `quit_plain` → `quit`. `hook-lib`, `cb`, `launch`, `loop` R → "the hook library / the measurer / the launcher / the supervisor". "ledger" is overloaded: `handoff.md` and `.context-budget/context-ledger.jsonl` are both "the ledger" R → "the handoff ledger" / "the measurement log". `∧ ∈ ⇒` R → "and", "is one of", "then". `D4/D9/D11/D14/D18`, `M12/M16/M31`, `L33/L45`, `F1–F10`, `I4`, `P4a/P4b`, `TE6`, `D-B/D-E/D-G`, `coupling 1/2/4`, `cm_bugs 2026-09-03`, `architect §2d`, `scenario §C.4` D — replace each with its sentence or delete. `S1–S10/E/I` D from the design (keep in the evaluation). `V1–V13` E as probe names but give each a word (`V2 clear-rotation`). `ADR-000n` R → name the ruling in words, id in parentheses. `§1b.7` R → "the mechanical-gate rule" stated once at the top.

**Workspace dependence.** Pointer classes that only resolve inside this repo: (1) `file:line` citations — ~120 occurrences; almost all replaceable by "today the supervisor checks X in four places" style sentences; (2) ADR/decision/backlog ids — ~60; replaceable by the ruling in words; (3) scenario/probe ids (S/E/I/V/P) — ~50; replaceable in (d)/(h) by the situation ("a session that was killed mid-chain"), not replaceable in (j) which is the catalogue itself; (4) file names used as nouns (`.session-seq`, `.next-command`, `hook-lib`) — replaceable by role words. By sentence count, roughly two of every three sentences carry at least one such pointer; by character count about 35–40 % of the text is citation. Sections (b) schema + writers table + iteration table, (c), (d) verdict table, (e) path table, (f) adapter table, (h) gate table and (l) are readable stand-alone once the ids go; (a), (i), (j) probes, (k) are unreadable without the repo and are also the sections I would cut.

## 7. Recommended answers to §(m)

1. **WARN rule:** yes, one rule — ask iff `ROLLOVER_RELAUNCH` resolves to `manual`/`off`. Implement as one branch in the hook-lib message; no knob.
2. **`--bg`:** drop it from this design (follow-up). Probe B proves env cannot bind it; the prompt cannot carry a token without the agent echoing it (violates §1b.7); the `--name` payload is inferred, not verified. `--clear` and attached exec/print cover the unsupervised paths; removing `--bg` deletes `pending.expires_at`, the freshest-unexpired scan, resolution rule (4), `pending_elsewhere` and `pending_expired`.
3. **Logout shapes:** the operator captures them on the first V9d run; until then codex/copilot-cli quits are `quit_plain`, and the support matrix row says "logout not classified". No `unknowable` code path. Closing a chain on a logout is acceptable — `--reopen` is one command.
4. **`--unstage` spends a number:** accept the gap. The carve-out reinstates the "was it consumed" judgement the design exists to remove.
5. **Vendor exit facts:** advisory only; pid liveness stays the sole oracle. Probe A shows `SessionEnd` and the next `SessionStart` can land in the same second, so `ended` is not a trustworthy liveness fact even on claude.

## 8. Overall

**YES-AFTER-CLARIFICATIONS.** Minimum set before Stage 4:

1. (d) The **staged** verdict must be stated on the pre-`eval` `launch.launched_at` and the watchdog's snapshot of `session`, not on `R` after the child's bump.
2. (b) `record_update` takes the block name as an argument; list the sanctioned cross-block writes (launcher nulls `session`; `register` nulls `pending` and opens `seq`); add the `mkdir` lock and compare-and-set preconditions, or state why not.
3. (b/h) `release` semantics: no-op unless `session.session_id == mine`; merge, never replace, `ended`.
4. (h) Decide how *mine* is known on copilot-cli/gemini for `not_owner` (heuristic accepted, or `--session-id` required).
5. (m.2) Decide `--bg`.
6. (i) State the jq-free fallback for `jq_missing`, or drop the claim that the hook reports it.
