# Report 2 — independent architecture review of the suggested changes (D-A..D-G, as scoped by §5)

Reviewer: architect agent, read-only, 2026-09-14/15. Repo `ai-workspace-template` @ main `a213b3d` (clean).
Evidence tags: **VERIFIED** = I read the cited lines / ran the command; **INFERRED** = reasoning from verified facts.
Line numbers are for the files as they stand on `a213b3d`. cb = scripts/context-budget.sh, launch = scripts/launch-next-session.sh, loop = scripts/session-loop.sh, hook-lib = scripts/hooks/context-budget-hook-lib.sh.

---

## 0. Ground that moved after the findings (PRs #54–#60) and what it does to the findings

The delta `22ed187..main -- scripts/ docs/` is 2,061 insertions / 53 deletions across 15 files (VERIFIED via `git diff --stat`). Relevant to the directions:

| PR | What landed | Effect on the findings |
|---|---|---|
| #60 (`4d2b8c4`) | `.next-command.json` identity sidecar written by `--emit` (launch:1220-1256), `staged_stale_reason()` + `consumer_since()` in the supervisor bootstrap (loop:537-643), `.next-command.stale` parking | Fixes the "already-run command re-run → two session #18s" defect, **but** adds an 8th/9th state file and ~110 lines of exactly the inference class F2 describes (timestamp compare against registry `registered_at`, cksum pair-check). Strengthens D-B's case; under a record this is one field. |
| #54/#55 | `invoked_by_supervisor()` strict-`$PPID` exemption (launch:702-721); six-runtime `env_session_record()` table (launch:611-630) | Closes the "bootstrap `--emit` has no session record" refusal bug. Adds pid-ancestry inference and a "must stay a DIRECT call" fragility contract (launch:697-701; tests F1/E10). Record-compatible: the bootstrap launch can simply be tagged `launch.by="supervisor"`. |
| #56/#57 | `check --session-id` read-only pin (cb:72-74, 111-121, 419-443); `successor_advisory()` on `register`/`record` (cb:539-560); stall-alarm P4a/P4b two-tick logic (loop:723-798); `.chain-closed` + `--reopen` + `ROLLOVER_RELAUNCH=off` startup gate + `--relaunch-override` (loop:348-412, 869-890; launch:332-343); STOP/WARN hook text now carries step-6 inline (hook-lib:90-97) | The pin is sound and survives D-B unchanged (it reads the registry, not item state). `.chain-closed` is a 10th state file with its own override flag. P4b counts ticks — more inference. Net: F2's "same fact encoded N times" got worse, not better, since the review. |
| #58 | handoff-anchor gotcha restored in the skill | Docs only. |
| #59 | repo-scoped GitHub access | Unrelated to this subsystem. |

**F10 re-checked on main:** `.pending-clear-seed` is still not ignored (VERIFIED: `git check-ignore -q work/x/.pending-clear-seed` → NOT-ignored; `.gitignore:34-63` lists every other dotfile including the new `.next-command.json/.stale` and `.chain-closed`). `SESSION_LOOP_NOTIFY="${ROOT:-.}/…"` (env:94): **latent, not live** — the only reader is `session-loop.sh`, which defines `ROOT` at :32 before sourcing at :37; `cb:57` and `launch:406` source the env with `ROOT` unset but never use the variable (VERIFIED by grep). Still worth the one-line fix (an absolute in-script default) because any future reader trips it. ADR-0009's `/clear` transcript question is still unverified — the live chain's #5→#6 was a supervised `--emit` spawn (loop log 02:44Z), not a `/clear`. INFERRED strongly from cb:134 (`glob_artifact_for`: transcript basename = session id) and ADR-0009:73-75 (`/clear` assigns a new session id): a new id implies a new JSONL. A 30-second manual check closes it.

---

## 1. D-A — delete retired / speculative surface

### 1a. Is anything on the delete list still load-bearing? (dispatch/children/watch are OFF the list per decision 3)

| Item | Where | Load-bearing? | Verdict |
|---|---|---|---|
| `rollover-complete` subcommand | cb:1344-1437 (94 lines), usage :9, dispatch :1453 | **No.** The only reader is the transitional fallback in `budget_hook_should_exit` (hook-lib:142-148), explicitly "one release". Both in-flight chains have rolled past R2.17: the live chain's bump record at `work/template-improvement-review/.session-seq.bump.json` carries identity (`session_id b8ab07fd…`, `written_by launch-next-session.sh`) — VERIFIED. | DELETE, including hook-lib:142-148, `SENTF` in loop:87,100,676, the `--unstage` entry launch:299, `.gitignore:41`, and `scripts/tests/test-rollover-sentinel.sh` (122 lines; it copies `context-budget.sh` alone into a temp tree, :12). |
| One-time ledger migration | cb:43-50 | No (M19, 2026-08-11; `work/context-decay/` is a research dir). Runs a `[ -f ]` on every hook firing. | DELETE. |
| Legacy scalar registry `rm` | cb:801 | No. | DELETE. |
| `session_handoff.md` alternate ledger name | launch:263-264, loop:482 | No item uses it (VERIFIED: no `work/*/session_handoff.md` exists; only `handoff.md`). | DELETE. |
| Cross-checkout max-wins display | rollover-prep:164-181 | Display-only ("effective: N (max across checkouts)"). Retired per ADR-0008 once `seq-sync` became the only writer (cb:1245-1315). | DELETE. |
| Stray `.session-seq` copy reporting | launch:466-474 | Warning-only. Same retirement rationale. | DELETE (with D-B it is moot anyway). |
| `.rollover-options` cross-checkout adoption | launch:933-949 | Same heuristic class ("newest copy across checkouts wins"), even though `opts-sync` (cb:1317-1340) resolves the common dir and is the documented single writer. | DELETE — not on the findings' list but belongs on it. |
| Hook throttle stamps never GC'd | hook-lib:44-52 | 112 stamp/status files for 12 registry records (VERIFIED `ls .context-budget`). | **Do not write a GC.** Extend the existing purge at cb:802 (`find "$STATE_DIR/sessions" -name '*.json' -mtime +7 -delete`) to `hook-*` in `$STATE_DIR` — one `find`. Adding a GC subcommand is the speculative-code smell the user's principle forbids. |

Nothing on the list is load-bearing. **AMEND:** "stamp GC" → "widen the existing 7-day purge".

### 1b. Not on the list but should be (or should be decided with D-B)

- **`watch`** (cb:1112-1127). It is not fleet machinery; it is the "layer 3 polling watcher for hook-less runtimes" (docs/context-budget.md:930), and every one of the six runtimes has a committed hook (docs:937-968). Its `osascript` call is macOS-only. Zero callers outside docs. Decision 3 lumped it with dispatch/children by name, not by function. **Recommend deleting it regardless of decision 3** — 16 lines, and its doc claim is false.
- **`--takeover`** (cb:87, 734-751, 1009-1035) and the **`superseded`/`superseded_by` stamping** (cb:634-679, 1025-1028; launch:1133-1138). Under D-B roles go away (§2), so the stamping goes with them. Keep `--takeover` only as the bare "steal the owner slot, log it" override — no record stamping.
- **`successor-pending-<project>.json` handshake** (launch:1191-1197, 1204, 1268, 1312; cb:803-855). A fifth identity file with a 600s TTL and a freshest-wins heuristic that D14 already had to special-case (cb:815-827). It is not "retired", but D-B must decide its fate (§2, coupling 1).
- **`test-rollover-sentinel.sh`** and the sentinel rows in `docs/context-budget.md:414, 442, 951` (the vendor-hook table still says the Stop hook keys on `.rollover-complete` — VERIFIED :951; the code keys on the bump record, hook-lib:137-140).

### 1c. Verdict on D-A

**AGREE**, with the two amendments above (no GC code; add `watch`, the `.rollover-options` adoption, and the stray-seq reporting to the list). Risk: low. The only ordering constraint: the sentinel fallback in hook-lib must not be removed while a session that predates R2.17 is still in flight — none is (VERIFIED above), so this can go first.

---

## 2. D-B — one launcher-owned lifecycle record per session

### 2a. What the seven-plus files actually encode today (VERIFIED, per-item under `work/<p>/`)

| File | Writer | Fact |
|---|---|---|
| `.session-seq` | launcher (:874), `seq-sync` (cb:1282) | last-launched number, bare int |
| `.session-seq.provenance.json` | `seq-sync` (cb:1301-1310) | who ran the assertion, action |
| `.session-seq.bump.json` | launcher at the bump (:889-924) | seq, successor, identity, mode, reason — **the verdict** |
| `.next-command` + `.json` + `.stale` | launcher `--emit` (:1203-1264); supervisor consumes (loop:676) / parks (:637) | staged command, its identity, its freshness |
| `.active-session` | `register` (cb:762-770); launcher removes (:1117); `release` removes | owner: runtime, sid, pid, pid_start, supervisor_pid |
| `.rollover-options` | `opts-sync` / capture | successor flags |
| `.session-loop` | supervisor (loop:437-438) | supervisor pid, started_at |
| `.session-loop.budget` | supervisor (loop:278-286) | chain used/cap/opened_at |
| `.chain-closed` | supervisor (loop:885-889) | deliberate end |
| `.hands-off` / `.interactive` | human | mode override |
| `.pending-clear-seed` | launcher `--clear` (:1025) | prompt text, drained by the SessionStart hook |
| `.context-budget/successor-pending-<p>.json` | launcher (:1192-1197) | "a successor was just started for project p" |
| `.context-budget/sessions/<rt>-<sid>.json` | `register` (cb:869-881) | measurement identity + role + parent/depth |

Consumers that infer from them: `own_record()` fallback (launch:631-641), lineage gate + evidence legs + fingerprint (launch:485-584, ~100 lines), `--unstage` rewind (launch:287-327), lock staleness `lock_holder_age` (cb:562-577, duplicated launch:777-783 "keep in sync"), `sweep_stale_primaries`/`backstamp_superseded` (cb:634-679), `staged_stale_reason` (loop:581-623), the four-check bump match (loop:908-921), `child_probe`/`dead_child_artifact`/`child_logged_out` (loop:150-240), `invoked_by_supervisor` (launch:702-711), `holder_process_note` (launch:812-835), `attach-session.sh fork_of()` (header :7).

### 2b. Is one record the right shape? — judged against (i)–(v)

**(i) Gitignored, machine-local.** Yes. Every file above is already machine-local (ADR-0007 rejected committing the counter). A per-item record inherits that; nothing changes for clones (ADR-0006:71-73: clones are distinct coordination domains). The record documents *the current launch* only; history stays in `handoff.md`. Fine.

**(ii) EnterWorktree + common-dir root (ADR-0006).** Unaffected: the record lives in `work/<p>/` under the common-dir-resolved root, exactly where `.session-seq` lives; `link-local-work.sh` symlinks gitignored item dirs into worktrees (hook-lib:41-42). What the record does **not** fix is M16: the *artifact path inside the record* still stales when a claude transcript relocates, so the id-keyed re-resolution (`glob_artifact_for`, cb:125-138, used at cb:437, 470, 570) must survive. The record is not a liveness oracle; it holds a pointer to one.

**(iii) Two concurrent sessions on one repo (ADR-0004, S4).** Two cases, and they differ:
- *Two work items* → two records, no shared state. This is the S4 core case and a per-item record handles it trivially — better than today, where the registry's `sweep_stale_primaries` scans every record for `project == $PROJECT` (cb:663-678).
- *Two sessions on the same item* (helper terminal, D4 fork, IDE resume, human opening a second window). The record has exactly one `session` slot. A second `register --project X` from a different sid must not overwrite a live owner. So "attach" is expressible **without roles**: owner = `record.session.session_id == mine`; everything else is a non-owner that is measured (registry) but writes nothing. The four roles collapse to a derived boolean; `superseded` becomes "the slot was overwritten by the next launch" (which is the "closed at next launch" semantic); `auxiliary` becomes "not the owner"; `child` is fleet (§5). `statusline-context-budget.sh:40-41` and `attach-session.sh:156-164` currently read `role` — both become "am I the record's session".
  The part that does **not** disappear is the liveness question when a second session wants the slot ("is the recorded owner dead?"). See coupling 2.

**(iv) A session dies unobserved.** The record says `session:{id, pid, pid_start, registered_at}` and no `ended_at`. The successor (or a human's next launch) infers death from `kill -0 pid` + `lstart == pid_start` (already captured since R2.10 — cb:697-723, launch:812-825) — a *positive* test — falling back to artifact mtime only where no pid exists. What the record adds over today: `seq`, `launched_at` and the owner identity in one place, so "the launched session never came back" is `record.launch.seq == N && record.session absent-or-dead && ledger top block == N-1` — one predicate instead of the lineage gate's three evidence legs (launch:507-516) plus fingerprint (launch:531-566). **The bigger simplification is to stop reclaiming numbers**: ADR-0008:120-121 already set the precedent ("the over-count is not repaired… lineage stays as launched"). If a dead session keeps its number and the successor annotates the gap in its ledger block, the reclaim branch (launch:517-520), the fingerprint, the neutral/reconstruct messages, and `--unstage`'s rewind (launch:309-323) all delete. The remaining lineage-gate leg (counter ≠ ledger and not one-ahead → refuse, launch:578-582) guards the s102/#104 class *where an agent hand-wrote the counter* — a writer ADR-0008 removed. It can become a warning.

**(v) Supervisor: "child ended, rollover staged" vs "child died".** Today: `.next-command` presence-after-run (consumed before eval, loop:676, checked :819) + `delta == 1` (:902) + bump-record four-check (:908-921) + flush hash (:930-933) + rc/logout classification (:822-857). Under a record: `staged` object present with `staged.by == launched sid` and `seq == launched_seq + 1` → staged; `staged` absent, rc 0, seq unchanged, transcript not a terminal auth error → quit; anything else → broken. The record can express the first two facts; it **cannot** express the logout (coupling 4) or the flush (agent-written files, keep the 6-line hash). The D18 consumption leg (loop:554-567, timestamp compare) becomes structural: the successor's `register` writes `session.seq`; a leftover `staged` whose `successor` already appears as a registered `session.seq` is spent. No timestamps, no cksum (same file, atomic `mv`).

### 2c. Where I disagree with D-B as written

1. **"Launcher becomes the sole author" is impossible, and the findings' own F1 says why.** The successor's identity (sid, pid, artifact) exists only at the successor's `register` — ADR-0005:67-68 rejected launcher-side `superseded_by` stamping for exactly this reason. The supervisor owns the chain budget and the close. So the honest shape is **one schema, three writers, disjoint fields at disjoint moments**: launcher writes `launch`/`staged` (at bump/emit), `register`/`release`/`seq-sync`/`opts-sync` write `session`/`seq`/`options`, `session-loop.sh` writes `chain`. That still honours F2's principle — every field is script-written at the moment its writer knows both halves — and it is what makes the record a real replacement rather than a rename of the bump record.
2. **Concurrency is fine only if all writers go through one helper.** Read-modify-write on one JSON file from three scripts is safe here because the lifecycle orders them (supervisor writes before eval; launcher writes while the supervisor waits; register/release at session edges), and hooks stay out of the record (stamps/status remain per-session files). But the only acceptable implementation is a single `record_update <proj> '<jq filter>'` (tmp + `mv`) in the shared lib — which makes **D-C a precondition of D-B**, not a parallel track.
3. **Retiring `.hands-off`/`.interactive`** is right, but not by moving them into the record: a human touching a file mid-chain is the only *human* input channel into an unattended chain. Either keep exactly one marker (`.interactive` — the "a human is here now" signal; `handsoff` is already the default, launch:158) or delete both and rely on `--loop-mode` + Ctrl-C at the pause (loop:982-996). Open question 2.
4. **The successor-pending handshake does not go away by itself.** A project-less `register` (claude SessionStart, `.claude/settings.json`) must find "my launch". Under the record that is a scan of `work/*/session-state.json` for `launch` without `session` within a TTL — the same freshest-wins heuristic with the same D14 two-chains-in-one-TTL hazard (cb:815-827). The clean fix is to pass the project through the process environment on the two exec paths (`launch:1313 exec`, `:1269 --bg`) the way the supervisor already does (`TF_SESSION_LOOP_PROJECT`, loop:436; adopted at cb:822-827). The code comment at launch:1184-1185 claims an env var "must survive `claude --bg` daemonization" — that claim is **unverified in the repo** (no test, no probe log); it needs a 1-minute check before the handshake file can be retired.

### 2d. Hidden coupling — inference mechanisms slated for deletion that cover a case the record cannot

| Mechanism (to delete) | Case it covers | Evidence | Record covers it? |
|---|---|---|---|
| Lock staleness (`lock_holder_age`, LOCK_STALE=3h; cb:562-577, 725-760) | owner died with no exit event; a new session needs the slot | ADR-0004:45-49, L20 (3h squat), ADR-0005 | **Partly.** Positive pid liveness (pid+pid_start, R2.10) replaces it for claude/codex/gemini/copilot-cli. Not for copilot-vscode (no process, cb:700-702) — artifact mtime must remain as the fallback there. |
| Resumed-predecessor fingerprint (launch:522-566) | IDE restart resumes the predecessor under a NEW transcript id, which then finishes its rollover after staging | cm_bugs 2026-09-03 incident | **Yes, better:** owner re-keying is "record.session dead-or-same-pid, seq unchanged, no newer launch" → adopt. Same rule handles `/clear` (new sid, same pid — ADR-0009:73-75) and the D4 fork (launch:1106-1109). |
| Four-check bump match + top-of-loop backstop (loop:668-670, 908-921) | a hand-written or retired verdict record | D11 (hand-written sentinel), D10 (frozen provenance sidecar) | **Yes:** one file, one writer per field, `staged.by` compared to the launched sid. `written_by` sanity check can stay (1 line). |
| Logout transcript sniff (loop:233-240, 854-857) | vendor logout exits rc 0 looking exactly like `/exit`; 7 sessions across 2 chains | R2.21 / D12 | **No.** The runtime never records "I logged out" anywhere but the transcript, and the JSON shape is claude-specific. Keep as a small runtime-adapter function; note it silently never matches on codex/gemini/copilot, so a codex logout writes `.chain-closed` today. |
| MIN_LIFETIME + "own measurement" leg (loop:945-961) | gemini shared telemetry serves the predecessor's count on the successor's first turn → spurious STOP → instant rollover | M12 | **Partly.** `record.session.registered_at > launch.launched_at` replaces the registry-mtime inference; the lifetime floor itself is a gemini-specific guard that decision 2's live gemini exercise should confirm or delete. |
| `staged_stale_reason` + `consumer_since` (loop:554-623) | supervisor restart inherits an already-run staged command | D18 (two session #18s) | **Yes:** `staged.successor` already present as a registered `session.seq` ⇒ spent. |
| `invoked_by_supervisor` PPID test (launch:702-711) | bootstrap `--emit` has no session record | #54/#55 | **Yes:** the supervisor's bootstrap launch is tagged `launch.by=supervisor`; no ancestry walk. |
| `child_probe` transcript-silence (loop:150-162) + KILL_AFTER | a hung child that writes nothing for hours (3d20h) | D6/D7 | **No, and it is wrong for two runtimes:** gemini's artifact is the shared `.gemini/telemetry.log` and opencode's is the shared sqlite db, so "transcript mtime" is *any* session's — silence can never be detected and KILL_AFTER must not fire there. Keep; scope it. |
| `successor_advisory` (cb:539-560) | a supervised session past STOP with nothing staged | B1 (three incidents of "I think I rolled over") | **Yes** (reads `staged`), and it is the right place — it is delivered by a command the agent already runs. |

### 2e. Migration risk and the live supervisor

- **Risk: medium**, not medium-high. The verdict logic is ~60 real lines; the volume is guard comments and the suites. The suites are the real cost: `test-session-loop.sh` (1,792 lines, 90 `assert_contains` on log-message fragments vs 77 `assert_eq`), `test-launch-next-session.sh` (1,352 lines, 142 vs 118), `test-context-budget-registry.sh` (852 lines, 39 vs 81) — VERIFIED counts. Roughly half the assertions pin message text; every suite builds fixtures by copying single scripts into a temp tree (e.g. `test-rollover-sentinel.sh:12 cp scripts/context-budget.sh`), so both D-B and D-C invalidate the fixtures wholesale. Decision 4 (behaviour-first tests: exit codes + record fields, not log strings) is the right call and must be done *with* the cut, not after.
- **Flag-day, not dual-write.** The record replaces a protocol between three scripts within one iteration (launcher writes at the bump → supervisor reads after `eval`). Dual-writing would double the writers to be reasoned about and keep every inference path alive. The only "dual" needed is a one-time import: on the first launch after the cut, if the record is absent and `.session-seq` exists, seed `seq` from it (≈5 lines; delete after one release, like the sentinel shim).
- **The live chain constrains the cut, and exposes a hazard the findings missed.** pid 72900 (`bash ./scripts/session-loop.sh template-improvement-review`, started 2026-09-14T22:55:58Z, running session #6 = the session this review is inside; VERIFIED via `ps`, `.session-loop`, `.session-loop.budget`; claude pid 35849 is a direct child of 72900, so `child_probe`'s strict-parent test holds). `a213b3d` (21:44 local, +292 lines to `session-loop.sh`) landed **while that process was running** — and the running supervisor still executes pre-#60 code: it consumed `.next-command` at 02:44:28Z but left `.next-command.json` behind (VERIFIED: file exists; current code removes both at loop:676). Bash reads a script lazily by byte offset; the `while` body was parsed whole on entry, so the current iteration is safe, but the post-loop region (`cap_stop`, loop:999-1002) is now at a stale offset. Consequences: (1) never edit `session-loop.sh` while a supervisor is live — end the chain at a deliberate boundary first; (2) the **first** change to `session-loop.sh` should be a `main() { … }; main "$@"` wrapper (3 lines) so the file is parsed before it executes — a well-known bash idiom, not on any list; (3) the same applies to `launch-next-session.sh` only transiently (it runs to completion in seconds).

**Verdict on D-B: AGREE with amendments** — single record yes; single writer no; roles/staleness/lineage/fingerprint/unstage-rewind/sentinel/bump/provenance/sidecar/budget/chain-closed/mode-markers retire; pid-liveness first with artifact-mtime fallback; numbers never reclaimed; D-C first; flag-day between chains; `main()` wrapper first.

---

## 3. D-C — shared lib + one hook dispatcher

- **Is `scripts/lib/repo-paths.sh` the seed?** Only structurally (a `scripts/lib/` dir that two scripts source, VERIFIED: it resolves onboarded-repo paths for `onboard-repo.sh`/`check-repo-context.sh`, :4-8). Content-wise unrelated. The seed the subsystem needs is `resolve_workspace_root` (12 copies: cb:28-40, launch:59-71, loop:20-32, hook-lib:17-28, clear-seed:41-47, rollover-prep:36-48, attach:34-, capture:26-, statusline, link-local-work …), the lock/liveness helper (cb:562-577 ≡ launch:777-783, "keep in sync"), the ledger-heading grammar (launch:269-274 ≡ loop:480-492 ≡ check-ledger.py), and — under D-B — the single `record_update` helper.
- **ADR-0006:59-62 explicitly rejected a shared lib** because "test suites and vendor-hook deployment copy scripts around as self-contained units". That objection is real and VERIFIED (fixtures `cp` single scripts). It is not a reason to reject D-C; it is the ordering constraint: the lib lands together with a one-line fixture helper (`copy_scripts` that copies `scripts/lib/` too) applied to every suite. ADR-0006 should be amended, not silently contradicted.
- **M31 property** ("each runtime's hook wiring is a committed file the runtime reads"). A single `context-budget-hook.sh <runtime> <event>` does not touch it: the wiring files stay (`.claude/settings.json` hooks block, `.codex/config.toml`, `.gemini/settings.json`, `.github/hooks/*.json`, `.opencode/plugins/context-budget.js` — all VERIFIED committed); only the command they point at changes. Two real constraints: (a) codex's hash-based trust re-prompts on any edit to the command file (`.codex/config.toml:2`), so a shared dispatcher means every runtime's change re-prompts codex users — today the same is nearly true via the sourced lib, so no regression in practice; (b) the opencode plugin is JS and calls the bash hook with its own argument shape (`<sid>` / `--exit-check <sid>`, plugin :11, :46) — the dispatcher must accept that shape or the plugin changes; leave the JS alone. The four bash wrappers differ genuinely only in envelope (stderr+exit 2 / `hookSpecificOutput` JSON / `{additionalContext}` / `{decision:block}` / gemini's mandatory `{}`), each vendor-verified by live probes (hook file headers). A `case "$runtime:$event"` dispatcher must reproduce them byte-for-byte; `test-vendor-budget-hooks.sh` (401 lines) is the net.
- **Value: modest (−150 LOC, one place to add a runtime); risk: low.** The contract pinned only by tests — hook-lib re-parsing `cb`'s `key=value` line with grep (hook-lib:64-66) — is stable and cheap; do not add `--json` output (speculative).

**Verdict: AGREE.** Order: lib + fixture helper → record helper → D-B. The hook dispatcher is independent and can go any time.

---

## 4. D-D — claude-first, adapters marked "unverified"

- **A "verified flag" gating non-claude paths is speculative configurability — REJECT that form.** The facts already live in one table (docs/context-budget.md:884-912: gemini "**unverified** against a live session", copilot-cli "no live CLI session has run in this workspace yet"); the harness already exists in embryo (`test-turn-end-exit.sh --live <runtime>`, :5-7, :21). Decision 2 moots the gate for the four first-class runtimes anyway. What is needed is a *per-runtime verification row* (date, commit, which of the five touchpoints were exercised) and the `--live` harness — not a runtime switch.
- **Simpler alternative for the non-first-class runtime (opencode):** deleting it costs the same work as leaving it, and leaving it costs nothing at runtime; the only cost is the doc claim. Downgrade the claim, keep the code, do not gate.
- **Is the seam there for codex/copilot/gemini rollovers?** Five touchpoints per runtime, VERIFIED: discover/measure/session-id (cb:154-341, 376-409), runtime detection (cb:343-358), the env identity table (launch:611-630), the CMD case (launch:1155-1171), the hook wrapper + exit hook. They are enumerated in **seven** places with "keep in sync" comments (cb:352, 360-374, 381-391, 402-407; launch:613, 755-761, 1155). That is the architectural precondition for decision 2: collapse them into one per-runtime adapter table (a function or associative block per runtime returning all five facts), so "verify runtime X" is one file and one `--live` run. Without that, each live exercise touches seven sites.
- **Where the launcher genuinely assumes claude (VERIFIED):** `--clear` (launch:744-746, by design), `--bg` (:752-753, by design), `claude --name` (:1156), `capture-rollover-options.sh` (header: claude-only, fail-open), `attach-session.sh` (claude-only, by design), `glob_artifact_for` relocation (cb:133-135; M16 is an EnterWorktree phenomenon — fine). **Where the supervisor assumes claude and it matters:** the logout classifier (loop:233-240 keys on `isApiErrorMessage`/`authentication_failed`/"Not logged in") — on codex/copilot/gemini a logout is recorded as a deliberate quit and writes `.chain-closed`; `child_probe` transcript silence is meaningless for gemini/opencode (shared artifacts); gemini has **no exit hook** (gemini hook header :9-18: `AfterAgent` never fired because auth was never configured) so a supervised gemini chain cannot self-terminate; copilot-vscode has no process and `--emit` is refused for it (launch:732-734) — it can never be supervised. Auto-registration is hook-driven only for claude and copilot-vscode; codex/gemini/copilot-cli depend on the agent running `register --project` from `next-session.md` First actions (skill:171-176).
- So: the *unsupervised* rollover (S1/S2, spawn path) seam exists for all four; the *supervised* chain (S3) is claude + codex (+ copilot-cli, unproven) only. Decision 2's "exercise a real rollover on each" should be scoped as: unsupervised rollover on all four; supervised chain on claude+codex; gemini supervision stays "not supported" unless the `AfterAgent` probe is funded (needs auth). "Copilot" must mean the CLI (a process with `agentStop`), not VS Code.

**Verdict: AMEND** — no flag; adapter table + `--live` harness + explicit supervisability matrix.

---

## 5. Decision 3 — keep the fleet machinery: compatible with D-B? Maintenance shape?

What "fleet" is, VERIFIED: child registration (`register --parent-session`, cb:449-457, 856-862), per-child locks `.agent-locks/` + transitive parent-chain walk (cb:590-632), I4 release-order guard (cb:916-948, 986-998, 1010-1014; **duplicated into the launcher's daily rollover path**, launch:784-799, 854-867), `children` sweep (cb:1050-1110, claude-only, reads the undocumented `<transcript>/subagents/agent-*.jsonl`), `dispatch-contract/open/close/list` (cb:1129-1243, `.agent-dispatch/<task>.json`, generation fencing), plus three suites (`test-children-sweep.sh` 115, `test-dispatch-contract.sh` 77, `test-dispatch-records.sh` 143 lines). Non-test callers: none for `dispatch-close/list`; `dispatch-open` is mandated by CONTEXT.md:278-280 (VERIFIED grep).

- **Compatible with D-B?** Yes, provided fleet state stays *out* of the item record. Children are per-parent-session and per-task with their own lifetimes (generations); the record is per-item, per-launch. Folding per-child measurement into it would make the record multi-lifetime and give it a fourth writer. **Do not fold.**
- **What entangles today is not dispatch — it is the lock hierarchy.** The child-lock sweep + I4 refusal runs inside every daily rollover (launch:854-867) and inside every `release` (cb:986-1014), and `register`'s role assignment consults it (cb:864-868). Under D-B there are no roles for `child` to hang on. I4 guards "a parent released under live children" — under a supervised chain the turn-end SIGTERM kills the parent regardless (hook-lib:155-161), so the guard only ever refuses an attended human; no incident is recorded for it (ADR-0005 cites research §5/§6 and invariant I4, no field failure).
- **Recommended shape:** one `scripts/fleet.sh` (or `context-budget-fleet.sh`) holding `children` + `dispatch-*` + child registration, its own three suites (already separate), its own doc section (already `docs/context-budget.md:802-883`), invoked by the parent per the skill — and **zero references from the daily loop**: the launcher and `release` stop sweeping `.agent-locks`; the drain check before a parent rolls over is `fleet.sh dispatch-list` (exit 1 iff open), which the skill already describes as the parent's pre-rollover step (docs:875). "Gated fleet-only" then means "not called unless the parent chose to dispatch", with no gate code. This is simpler than folding because it removes code from the hot path instead of adding a field.
- **Honest view on "keep".** Keep is defensible for `dispatch-contract`/records: they are a *protocol* (report file + yield statuses) the user's CONTEXT.md mandates for long-running subagents, cheap, runtime-agnostic, and out of the daily path. Keep is **wrong** for the transitive child-lock hierarchy (ADR-0005 slice 1) and for `watch`: the hierarchy is the only fleet piece that entangles the daily loop, it exists to enforce an invariant no incident has needed, and it depends on the roles D-B retires. `children` is borderline — claude-only, reads a vendor-internal path — keep but freeze. If the user keeps the hierarchy anyway, it must move wholesale into `fleet.sh` with its own lock semantics, and the launcher must not call it.

**Verdict: AGREE with decision 3 for dispatch/children; AMEND to drop the lock hierarchy from the daily loop (relocate or delete) and delete `watch`.**

---

## 6. D-E, D-F, D-G

**D-E docs.** No architectural objection. Ordering: the *contradiction fixes* are independent and can land now (VERIFIED: CONTEXT.md:286 says `--mode interactive`, the flag is `--loop-mode` (launch:91); CONTEXT.md:264-265 "ask the user whether to roll over" vs skill:29-31 "do not ask"; docs/context-budget.md:951 still says the Stop hook keys on `.rollover-complete`). The *consolidation* (split daily/supervisor, one boundary skill) must land **after** the D-B cut or it documents a state that does not exist. `skills/handoff` is vendored (Matt Pocock set) — do not edit it; stop pointing at it. Removing incident narrative from `context-budget.env` (:50-93) is pure win; the env file is sourced by four scripts and every comment line is parsed.

**D-F recording as a side effect.** The per-tool hook already measures every 60s and writes `.status` (hook-lib:44-71); it just does not append to the ledger. Appending a ledger line **on escalation** (the WARN/STOP transition, hook-lib:70-71) is ~3 lines and gives the "63% of STOP sessions never saw a WARN checkpoint" problem a mechanical fix. **Object to the commit-hook variant**: git hooks are not committed, need `setup.sh` wiring, and are a downloader burden (D-G) for a fact the tool hook already has. Keep `record --label` as an optional *labelled* checkpoint. Ordering: independent, but under D-B the "session produced its own measurement" leg (loop:949-961) must read `record.session.registered_at`, not ledger/registry mtime.

**D-G downloader hygiene.** Dangling paths VERIFIED: `docs/context-budget.md:172, 897, 1011, 1019` and `skills/session-rollover/SKILL.md:51` (five). No ordering constraint. One conflict to surface: `ROLLOVER_RELAUNCH=auto` is the committed default (env:31) **and** the user's standing rule ("auto is standing authorization", CONTEXT.md bold paragraph; skill:245-258), while ADR-0004:56-57 says the default is `manual` and a fresh clone under `auto` background-launches token-spending successors on first STOP (F9). This repo is simultaneously the template and the operator's instance (memory note "template additions are first-class"), so "neutral default" is a user decision, not a hygiene edit (open question 4). `KILL_AFTER=14400` and `ALARM=900` are reasonable defaults; the neutral value is not "off" for guards that only ever notify.

---

## 7. (a) Ranking by value / risk

| Rank | Direction | Value | Risk | Note |
|---|---|---|---|---|
| 1 | D-A (+`watch`, `.rollover-options` adoption, stray-seq reporting; purge instead of GC) | high | low | Independent; do first. |
| 2 | D-C lib + fixture helper (root resolver, liveness helper, ledger grammar, `record_update`) | medium | low | Precondition of D-B; amend ADR-0006. |
| 3 | D-B as amended (one schema / three writers / no roles / no number reclaim / pid-liveness first / flag-day between chains / `main()` wrapper first) | highest | medium | Suites rewritten with it (decision 4). |
| 4 | Runtime adapter table + `--live` harness (the real content of D-D under decision 2) | high for decision 2 | low-medium | Vendor CLIs drift; every live run re-verifies flags. |
| 5 | D-E contradictions now; consolidation after the cut | medium | low | Ordering only. |
| 6 | D-F as hook-lib escalation append | medium | low | 3 lines. |
| 7 | Decision 3 shape: `fleet.sh` isolated, hierarchy out of the daily path | medium | low | Removes code from the hot path. |
| 8 | D-G | low | low | One user decision inside it. |

## 7. (b) What I REJECT or AMEND

- **REJECT** D-B "launcher is the sole author" → one schema, field ownership per writer (launcher / context-budget.sh / session-loop.sh), one helper.
- **REJECT** D-D's verified-flag gate → verification rows + `--live` harness; no runtime switch.
- **REJECT** D-A's "stamp GC" as new code → widen the existing 7-day `find`.
- **REJECT** D-F's commit-hook variant → escalation-time ledger append in hook-lib.
- **REJECT** keeping `watch` under the fleet umbrella → delete (not fleet; layer 3 is dead).
- **AMEND** decision 3 → keep `dispatch-*` + `children` in an isolated `fleet.sh`; remove the transitive child-lock hierarchy / I4 from the launcher and `release` (relocate or delete); never fold per-child measurement into the item record.
- **AMEND** D-B → also retire number reclaim, the resumed-predecessor fingerprint, `--unstage`'s rewind, the successor-pending handshake (after the `--bg` env check), and the mode markers (or keep exactly one); keep the logout classifier, the flush hash, and id-keyed artifact re-resolution as small adapter functions the record cannot replace.
- **AMEND** D-C → the opencode JS plugin stays; dispatcher covers the four bash wrappers; ADR-0006's "no shared lib" consequence is amended explicitly.
- **ADD** (on no list): `main "$@"` wrapper in `session-loop.sh` before any other edit to it; scope `child_probe`/KILL_AFTER to runtimes with per-session artifacts; declare the supervisability matrix (claude+codex+copilot-cli supervisable; gemini and copilot-vscode not).

## 7. (c) Top 5 hidden couplings a redesign must handle

1. **Successor identity binding across the launch → register gap.** The sid does not exist at launch; a project-less hook `register` must find its launch. Today: `successor-pending-<p>.json` (600s TTL, freshest-wins, D14 swap hazard) or `TF_SESSION_LOOP_PROJECT`. Under the record either the same scan heuristic survives or the project travels in the process environment on the exec/`--bg` paths — pending a check that `claude --bg` daemonization preserves env (launch:1184 claims it does not; unverified).
2. **Identity re-keying while the launch stays the same.** `/clear` (new sid, same pid — ADR-0009), IDE resume (new sid, new pid — cm_bugs 2026-09-03), the D4 fork. `seq` must bind to the launch, not the sid; `register` needs one adoption rule ("owner slot dead-or-same-pid, no newer launch" → adopt) that replaces `own_record()` fallback, `attach-session.sh fork_of()`, and the fingerprint.
3. **No positive liveness for two runtimes.** copilot-vscode has no process (cb:700-702); gemini has one identity per workspace (cb:389) and a shared telemetry artifact; opencode's artifact is a shared db. pid liveness cannot be the only oracle; artifact-mtime fallback stays for them, and transcript-silence kill must be scoped away from shared-artifact runtimes.
4. **Runtime-specific end-of-session facts the record cannot hold.** Vendor logout is knowable only from the transcript and the classifier is claude-JSON-shaped (loop:233-240): on the other three first-class runtimes a logout reads as a deliberate quit and closes the chain. Gemini's shared-telemetry first-turn STOP (M12) is what MIN_LIFETIME guards. Both are adapter concerns, not record concerns.
5. **Test and process coupling.** Suites copy single scripts into fixtures (breaks on a shared lib); ~half the assertions pin log-message text; the stall guard's bookkeeping set mirrors `.gitignore` (L46); and a running supervisor is a bash process reading its script by offset — `session-loop.sh` was already modified under pid 72900 at `a213b3d`.

## 7. (d) The simplest design that satisfies §5 (≤1 page)

**Concepts kept (7):**
1. **Measure from disk, per session** — `.context-budget/sessions/<rt>-<sid>.json` `{runtime, session_id, artifact, project, pid, pid_start, supervisor_pid, registered_at}`; drop `role`, `superseded_*`; keep `parent_session_id/depth` for fleet. Id-keyed artifact re-resolution stays.
2. **One per-item lifecycle record** `work/<p>/session-state.json`, gitignored, common-dir-rooted, written only through `lib/record_update`:
   - `seq` (int) — the last-launched number; `seq-sync` remains the assertion verb (ADR-0008).
   - `launch` `{seq, launched_at, mode, reason, by: session|supervisor, predecessor:{runtime,sid}}` — written by the launcher at the bump.
   - `session` `{runtime, sid, pid, pid_start, artifact, registered_at, seq}` — written by `register` (owner slot; adopt rule for re-keying; refuse silently if a live different owner holds it); cleared by `release`.
   - `staged` `{command, successor, by, written_at}` — written by `--emit`; deleted by the supervisor before `eval`; a leftover whose `successor` equals a registered `session.seq` is spent.
   - `chain` `{supervisor:{pid,started_at}, used, cap, opened_at, closed_at, closed_by_seq}` — written by `session-loop.sh`.
   - `options` `{approval, model, extra}` — written by `opts-sync`.
   Retired: `.session-seq`, `.provenance`, `.bump.json`, `.next-command(.json/.stale)`, `.active-session`, `.rollover-options`, `.session-loop`, `.session-loop.budget`, `.chain-closed`, `.hands-off`/`.interactive`, `.rollover-complete`, `successor-pending-*.json`. Kept as files: `.pending-clear-seed` (atomic drain by deletion), `.session-loop.log`, `.alarm-stop` (ephemeral), `.agent-locks/`+`.agent-dispatch/` (fleet, if kept).
3. **Liveness = pid+pid_start first, artifact mtime fallback** (copilot-vscode, gemini). `--takeover` = overwrite the owner slot, logged. Numbers are never reclaimed; a gap is annotated in the ledger.
4. **Supervisor with three verdicts**: *staged* (`staged.by == launched sid` and `seq == launch.seq+1`, flush hash changed) → next; *quit* (no `staged`, rc 0, `seq` unchanged, transcript not a terminal logout) → `chain.closed_*`; *broken* (anything else) → halt. Budget from `chain`. `main "$@"` wrapped. Silence-kill only for per-session-artifact runtimes.
5. **One per-runtime adapter table** (discover, measure, session-id, env identity, launch command, exit-hook kind) in one file; one bash hook dispatcher `<runtime> <event>` + the existing stop-hook and clear-seed hook; opencode JS untouched. A `--live <runtime>` harness is the verification instrument; a verification-row table is the record.
6. **Fleet isolated** in `scripts/fleet.sh` (`dispatch-*`, `children`, child registration) with its own suites/doc; the daily loop does not reference it.
7. **Launcher/ledger files + one boundary skill** (`session-rollover` absorbs `checkpoint`'s tie-break; step 6 = `seq-sync` assert → `launch-next-session.sh` with `--emit` under a supervisor, `--clear`/spawn otherwise); hooks append the ledger on escalation; `record --label` is optional.

Writers: `launch-next-session.sh` (launch, staged, seed), `context-budget.sh` (session, seq, options; check/record/register/release/seq-sync/opts-sync/supervised), `session-loop.sh` (chain). Nothing else writes item state. Everything an agent is told to *remember* today collapses to: run `register --project` at start (or let the hook do it), run the skill at STOP, end with the launcher.

## 7. (e) Open questions only the user can answer

1. **Session numbers:** accept "never reclaim a number; gaps are logged in the ledger" (deletes the lineage-gate evidence legs, the fingerprint and `--unstage`'s rewind; ADR-0008:120-121 is the precedent)?
2. **Human mode override:** have `.hands-off`/`.interactive` ever been touched on this machine? If not, delete both and rely on `--loop-mode` + the interactive pause; if yes, keep exactly `.interactive`.
3. **`--takeover`:** keep as the single human override (overwrite the owner slot, logged, no stamping)?
4. **Template default for `ROLLOVER_RELAUNCH`:** this repo is both template and your instance. Ship `manual` (ADR-0004) in the root env and carry your `auto` in a per-item/committed override, or keep `auto` and accept the F9 downloader exposure?
5. **"Copilot" scope:** CLI (process, `agentStop`, supervisable) or VS Code (no process, `--emit` refused). I recommend CLI as the first-class one.
6. **Gemini supervisability:** accept "gemini = unsupervised rollover only" as its first-class contract, or fund the `AfterAgent` probe (needs a gemini login)?
7. **Fleet:** accept dropping the transitive child-lock hierarchy/I4 from the launcher and `release` (keeping `dispatch-*` + `children` in `fleet.sh`)?
8. **Live chain:** may the pid-72900 chain be ended deliberately (Ctrl-C at the next interactive pause) before `session-loop.sh` is touched again, with the `main()` wrapper as the first commit to that file?
9. **Log text as contract:** are `.session-loop.log` messages a stable interface (tests keep pinning them) or free-form (tests move to exit codes + record fields)? Decision 4 implies the latter; confirm.
10. **Successor-pending handshake:** authorise the 1-minute check of whether `claude --bg` preserves the launcher's environment (launch:1184 claim), which decides whether the handshake file can be retired.
