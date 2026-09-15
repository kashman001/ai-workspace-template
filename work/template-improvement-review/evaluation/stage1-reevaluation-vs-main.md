# Report 1 — Re-evaluation of findings F1–F10 / S1–S10 against local main (a213b3d)

Scope: finding-by-finding re-verification with the delta `22ed187..main` applied (origin PRs #54–#60, 7 PRs, 15 commits). Read-only. Every number below was re-measured on disk unless marked INFERRED or NOT RE-VERIFIED. Line numbers are current main.

Delta actually touching the subsystem: #54 (session-chain observability: P1', P2, P4a/P4b, P6 `.chain-closed`, G1-a off-gate, `check --session-id`, D16 bootstrap exemption), #55 (supervised identity keyed on positive identity; env table widened 4→6), #57 (docs: stall-alarm table + "What the chain tells you"), #58 (SKILL.md anchor gotcha, +4 lines), #60 (bootstrap freshness: `.next-command.json` sidecar, `.next-command.stale`, `consumer_since`). #59 (repo-scoped GitHub access) is outside the subsystem. `docs/workspace-structure.md`, `docs/work-directory-conventions.md`, `skills/checkpoint`, `skills/handoff`, `README.md`, `docs/setup-guide.html`, `scripts/hooks/context-budget-stop-hook.sh` are byte-identical to what the review agents read (`git diff --stat 22ed187..main` on those paths is empty).

## 0. §1 "Big picture" numbers — CHANGED

| Item | Findings (@8d2d542) | Now (@a213b3d) | Δ |
|---|---|---|---|
| `scripts/context-budget.sh` | 1356 | 1454 | +98 (`--session-id` pin :70-72, :85, :111-118, :411-444; `successor_advisory` :539-561) |
| `scripts/launch-next-session.sh` | 1201 | 1318 | +117 (`.chain-closed` gate :336-345; `invoked_by_supervisor` :702-711 + 30-line comment; sidecar write :1212-1256) |
| `scripts/session-loop.sh` | 722 | 1002 | +280 (`child_past_stop` :172-180; `consumer_since` :554-567; `staged_stale_reason` :581-628; off-gate :373-380; `.chain-closed` gate :392-410; P4a/P4b :726-791; close writer :875-889) |
| 10 scripts total | ≈3.9K | 4414 | +≈500 |
| 9 hooks | 467 | 482 | +15 (hook-lib messages :90-96) |
| six hook wrappers | 221 | 221 | 0 |
| test suites | "22" | 23 files (22 `.sh` + `test-check-ledger.py`), same count pre-delta | 0 |
| test LOC | ≈5.5K (5839) | 6456 | +617 |
| `docs/context-budget.md` | 925 | 1037 | +112 |
| `skills/session-rollover/SKILL.md` | 466 | 495 | +29 |
| `context-budget.env` | 89 | 94 | +5 |
| repo commits | 433 | 448 | +15 (6 subsystem commits + merges) |
| `.gitignore` `work/*/` rules | — | +3 (`.next-command.json`, `.next-command.stale`, `.chain-closed`) | |

Growth continued at the same slope in the two days since the review: the three big scripts grew +495 LOC for four fixes. All of it is in the shape F4 describes (top-level straight-line code in the launcher; more branches in the one while-body in the supervisor).

## 1. Findings F1–F10 — verdicts with evidence

### F1 (core is sound) — STILL HOLDS
Nothing in the delta touches measure-from-disk, the id-keyed registry, ADR-0006/0008 or the `--clear` path. #55 *strengthens* the id-keyed principle (the refusal now keys on `$OWN_ENV_REC`, launch:714). #60 reuses the bump-record shape for the sidecar ("Same shape as the bump record on purpose", launch:1218-1220). Verdict unchanged.

### F2 (no durable identity / no exit event; facts should be script-written) — STILL HOLDS, and the delta is new evidence *for* it
Re-counts of "same fact encoded N times":

- **Session number**: script-written state files carrying a seq. Before: 7. Now **9**: `.session-seq`; `.session-seq.provenance.json` (cb:1301-1310); `.session-seq.bump.json` (launch:911-914); `successor-pending-<p>.json` (launch:1194-1195); `.session-loop.budget` `last_seq` (session-loop:281-283); `.rollover-complete` `seq` (cb:1419); **NEW** `.next-command.json` `seq`+`successor` (launch:1243-1244); **NEW** `.chain-closed` `seq`+`top_ledger_seq` (session-loop:885-886). Plus the ledger heading and `next-session.md` (agent-written). ×7 → ×9.
- **Mode** ×4: unchanged (bump record, sentinel, `.hands-off`, `.interactive`; the sidecar carries no mode field — launch:1249-1251).
- **"A rollover happened"** ×3 → **×5** handshake-state artifacts: sentinel, bump record, `.next-command` non-empty, **NEW** `.next-command.json` (staged, by whom, when), **NEW** `.chain-closed` (deliberately did not).
- **Liveness oracles** ×3 → **×4**: pid `kill -0` (launch:708; cb `.session-loop` pid), artifact mtime age (`child_probe`, `lock_holder_age`), lock-stale seconds; **NEW** time-ordering oracle: `consumer_since` compares registry `registered_at` against sidecar `written_at` by ISO string, strictly greater, second-granular (session-loop:554-567, comment :137-142). `child_past_stop` additionally uses the *budget* as a chain-progress signal (session-loop:172-180).
- **Role** ×2: unchanged (registry record `role` key — verified in a live record; `.active-session`).
- Roles still 4 values in cb (`primary`, `auxiliary`, `child`, `superseded`); lineage gate launch:485-584 (≈100 lines, was "109"); `--takeover`, `--unstage` (now also removes the sidecar, launch:298), resumed-predecessor fingerprint, logout sniff (session-loop:233, :854) — all still present.

**Task 3 — effect of #54/#55/#60 on the thesis.**
- #55 does not add a mechanism; it tightens an existing one (refusal keyed on positive identity, launch:714) and widens the env table to six runtimes (launch:613). Cost: the launcher's table and `session_id_for()` (cb:381-393) are now an explicit "must stay in step" pair (launch:597-600) — a new cross-file invariant pinned only by D17f/D17g. And it makes F2's premise literal for gemini: `session_id_for` returns the constant `"workspace"` (cb:389); launch:602-608 accepts that "two concurrent gemini sessions on one checkout are indistinguishable".
- #60 **adds another inference mechanism beside the bump record, it does not replace one.** The consumption event actually happens at session-loop:676 (`rm -f "$NEXTF" "$NEXTIDF" "$SENTF"` before each run) and is discarded; the bootstrap then *reconstructs* whether consumption happened from timestamps vs registry records (`staged_stale_reason`, 7 legs, :581-628). This is exactly the pattern F2 describes — a fact the script knew at one moment (iteration N consumed the command staged by session N-1) being re-inferred later from side evidence. A lifecycle record with a `consumed_at` field written at :676 would make `consumer_since` unnecessary. The sidecar itself *is* the right shape (written at the moment the launcher knows project/seq/successor/identity); what is inferred is its consumption.
- #54's `.chain-closed` is script-written at the right moment (the supervisor's quit classifier, :875-889, one writer) — good shape, but it is the 9th lifecycle file rather than a field, and it now has two readers with two copies of the gate (session-loop:392-410, launch:336-345).

**F6's "4 answers + backstop" count → grows.** End-of-iteration verdict: rc gate (:832), counter delta (:903-904), bump-record 4-field match (:908-921), ledger top block (:862-868) + top-of-loop backstop (:669) = 4+1 as before; **plus** `.chain-closed` write in the quit branch (:875-889), the vendor-logout discriminator (:854, existed), the 7-leg bootstrap freshness verdict at chain start (:581-640), and two mid-flight alarm predicates P4a/P4b (:730, :737-745). Overlapping "is the handshake sound?" answers: roughly 5 → 8.

### F3 (retired and dead surface) — STILL HOLDS; one item got a new dependent
- `rollover-complete`: still shipped. `cmd_rollover_complete` cb:1353-1440, dispatch cb:1453; 25 mention lines across cb/hook-lib/session-loop/launcher; hook-lib comments still describe "the sentinel exists" (:108-118); session-loop still `rm -f $SENTF` (:676); `test-rollover-sentinel.sh` 122 lines and still in the suite lists #54/#55 ran (19 passes). V4/V5 fixtures in `test-session-loop.sh` still call it (:1083, :1132).
- Dispatch/children/watch: cb:1050-1248 ≈199 LOC (matches "~180"). **CHANGED context**: user decision §5.3 = KEEP, so this bullet moves out of D-A. And #54 adds a *third* "ask about another session's budget" surface — `check --session-id` (cb:411-444) + `child_past_stop` (session-loop:172-180) — beside `watch` (cb:1112) and `children` (cb:1064). `successor_advisory` is explicitly placed outside `emit_check()` *because* `cmd_children`/`cmd_watch` call it (cb:538-539) — the new code takes their existence as a design constraint.
- Migration shim cb:42-49 still re-stat'd per invocation; legacy scalar rm cb:801; `session_handoff.md` still gated at launch:264 and session-loop:482; rollover-prep max-wins still computed :164-181 (SKILL.md:193 says it was retired).
- Hook throttle stamps: **224 files / 12 session records** (was 222/11); hook-lib:44-52 only touches, never GCs.

### F4 (duplication / shape) — STILL HOLDS; numbers moved up
- `resolve_workspace_root()` defined in **8** scripts (attach, capture, cb, context-experiment, context-inspect, launch, rollover-prep, session-loop) + `budget_hook_resolve_root` in hook-lib + link-local-work's own = 10 verified; the finding's "12" not reproduced (method-dependent; may have counted tests).
- Lock helpers "keep them in sync" launch:776 — still. Seq parsing `tr -cd '0-9'` at **7** script sites (cb 3, launch 2, prep 1, loop 1 via `read_seq`) — finding said 9; close.
- Marker-override block still byte-duplicated: launch:151-154 ≡ cb:1363-1370.
- Runtime enumeration ×2 — **now with an explicit load-bearing "must stay in step"** (launch:597-600 ↔ cb:381-393): a missing row silently ends that runtime's supervised chain. Worse than before (it was a comment; now it is a refusal).
- Launcher: **13** functions (was 11; +`invoked_by_supervisor`, whose 30-line comment :676-700 documents a *new* fragile contract: session-loop's bootstrap must be a direct `$PPID` call — "never `$(...)`, never a pipeline" — pinned only by tests F1/E10). Top-level straight-line ≈1160 of 1318 (INFERRED from function spans).
- Supervisor: one while-body now **:653-997 = 345 lines** (was 272) with **23** halt/exit sites (was 16); +3 top-level functions.
- hook-lib still greps `cb`'s text line (:64-66) — unchanged.
- New test-only contract: `stage_next()` in `test-session-loop.sh` replaces 26 hand stagings — a good move for that one pair, but it confirms the pair (command + sidecar) is a contract nothing but tests pin.

### F5 (six wired, one exercised) — STILL HOLDS
- Ledger `.context-budget/context-ledger.jsonl`: **275 lines, 275 `claude`, 0 other** (was 273). Registry: 12 records, all `claude`.
- Nuance the findings missed: three `hook-opencode-ses_*.stamp/.status` files dated 2026-08-05/06 exist, so opencode's per-tool hook *has* fired once, in early August, without producing a ledger line or a registration. "No non-claude session has ever registered, measured, or rolled over here" is the precise statement.
- Runtime `case` sites in cb: 3 `case "$rt"` statements (:133, :381, :402) plus 15 runtime-branch lines; the "11 sites" figure is method-dependent and not reproduced — the adapter surface is unchanged by the delta.
- #55 widened the launcher's table to include gemini/opencode and added fixtures D17f/D17g — still fixture-only. **New fact**: gemini has no per-session identity by design (cb:389; launch:602-608), which answers "gemini supervisor undetermined" at the design level: it works, but only one gemini session per checkout can be told apart.
- MIN_LIFETIME / M12: untouched by the delta; NOT RE-VERIFIED.

### F6 (supervisor real but thin in evidence) — STILL HOLDS; PARTLY ADDRESSED for false pages by #54; new incident added by #60
- Evidence here: no new chain ran in this repo (ledger +2 claude lines, this session). The new incidents cited by the code (#60's "two sessions numbered 18", "work/*/handoff-archive.md, the s18 addendum") are not in this repo — no `work/*/handoff-archive.md` mentions `s18`. `work/session-loop-hardening/defects.md` (5 refs in scripts/tests) and `docs/session-chain-scenarios.md` (3 refs in code+docs) **do not exist in this repo**. The evidence base is still downstream.
- False pages: #54 changes the *wording* (blocked / staged-and-still-running) and adds a page in the "still writing" branch when stranded (session-loop:757-766); the silence/backoff timing is untouched, so the two 2055s/2847s pages would still fire, now possibly with a sharper message. PARTLY ADDRESSED.
- STALL_LIMIT still not exercised outside tests. Overlap count: up (see F2).

### F7 (≈50 concepts vs 3-concept core) — STILL HOLDS, worse
- +6 user/agent-facing concepts: `.chain-closed`, `--reopen`, `--relaunch-override`, `check --session-id`, "successor: NOT STAGED" advisory, identity sidecar + `.stale`. Of these, the sidecar and `.stale` have **0** mentions in docs/skills/CONTEXT.
- Precedence table still duplicated: `skills/checkpoint/SKILL.md:22-27` ≡ `skills/session-rollover/SKILL.md:60-65`. `handoff` still writes to the OS temp dir (`skills/handoff/SKILL.md:15`).
- Pre-first-rollover reading grew: SKILL.md 466→495, context-budget.md 925→1037.
- "record --label at every boundary" now has a mechanical partial backstop: `successor_advisory` fires on `record`/`register` (cb:892-894, :908) — but only under a live supervisor and only if the agent runs `record`. The 63% figure: NOT RE-VERIFIED.
- #58 is direct evidence for this finding's thesis: it restores a *third* prose countermeasure for ledger-anchor failures (SKILL.md:115-118) after two rounds had already been added.

### F8 (docs contradict on load-bearing rules) — STILL HOLDS; one sub-item PARTLY ADDRESSED; one WAS WRONG
- WARN policy: `CONTEXT.md:269` "then ask the user" vs `docs/context-budget.md:119` and heading `:174` "WARN asks" vs `skills/session-rollover/SKILL.md:24,29` "without asking / do not ask". STILL HOLDS (line numbers moved).
- `CONTEXT.md:293` still ships `--mode interactive`; the flag is `--loop-mode` (launch:91) with the "Deliberately NOT --mode" comment at launch:88-90. STILL HOLDS.
- `ROLLOVER_RELAUNCH` default: doc sample `manual` (context-budget.md:213), shipped env `auto` (context-budget.env:31), launcher built-in `off` (launch:434), `CONTEXT.md:289` assumes `auto`. **Four statements, three values — STILL HOLDS.** #54 edited both the env comment block (env:21-26) and the doc sample (cb.md:207-209) to widen `off` and left the value contradiction in place.
- Sentinel still documented as the stop-hook trigger: context-budget.md:442, :951; workspace-structure.md:574 (was 413/839/572-576). hook-lib comments :108-118 too. STILL HOLDS.
- Undocumented knobs: `--reset-cap` now appears in the usage line (cb.md:388) and the refusals table — **PARTLY ADDRESSED by #54**. `TF_SESSION_LOOP_PROJECT`: 0 docs — STILL. `CHECK_EVERY`: documented at context-budget.md:940 (vendor-hook table, untouched by delta) — **WAS WRONG**. **NEW undocumented**: `.next-command.json` / `.next-command.stale` (0 docs, 0 skills); `--relaunch-override` and `--session-id` appear only in context-budget.md.
- Index still omits "The supervisor" (`## The supervisor` at :383; index :28-48 lists the new "What the chain tells you" (#57) but not it). STILL HOLDS.
- Change-log narrative: STILL; #54/#57 added ≈120 lines keyed to scenario ids (B1–B3, P1', P4a/b, H1–H9, D16–D18) that point at `docs/session-chain-scenarios.md`, **which is not in this repo**.
- `context-budget.env` narrates other workspaces' incidents (:55-56 policy-dev-onboarding/token-factory/cm_bugs, :78 s29) — STILL; #54 added a "scenario B3" narrative (:22-26).
- "Three change-log findings still say Status: Open": could not locate any `Status: Open` prose in any `.md` pre- or post-delta (0 matches); only the backlog HTML has two `Open` status cards. **WAS WRONG / mis-sourced** (not load-bearing).

### F9 (downloader leakage) — STILL HOLDS
- Dangling `repos/ai-workspace-template/...` paths: exactly **5** — context-budget.md:172, :897, :1011, :1019; SKILL.md:51.
- `SESSION_LOOP_KILL_AFTER=14400` (env:87), `ROLLOVER_RELAUNCH=auto` (env:31) — unchanged.
- `docs/setup-guide.html`: 0 mentions of rollover/session-loop/jq; 2 of ccstatusline — unchanged. `README.md`/`CONTEXT.md`: 0 mentions of session-loop/supervisor — unchanged.
- #59 adds a macOS-only optional script + docs; documented as optional/off-by-default and outside the subsystem — not a leak.

### F10 (incidental defects) — STILL HOLDS (3 of 4), 1 WAS WRONG
- `.pending-clear-seed` **still not in `.gitignore`** — #54/#60 added three `work/*/` rules on the adjacent lines (:46-47, :61) and missed it.
- `SESSION_LOOP_NOTIFY="${ROOT:-.}/…"` (env:94): sourcing sites are now **4** — session-loop:37 (`ROOT` set at :32 → correct), cb:58, launch:407, attach:49 (all three use `WORKSPACE_ROOT`; `ROOT` unset → resolves to `.`). STILL HOLDS, count 3→4 (+session-loop's per-item re-source at :58).
- ADR-0009 open item (`/clear` transcript rotation) still marked "unverified here" at ADR-0009:141-143.
- "Status: Open" — WAS WRONG (see F8).

## 2. Scenarios S1–S10 — updated status

| # | Updated status | What the delta changed |
|---|---|---|
| S1 solo, attended | works; concept load +6 | none functionally; more docs to read |
| S2 hands-off single | works on claude only | none (P1' advisory fires only under a supervisor, cb:550-553) |
| S3 unattended chain | targeted by #54/#60 (stranded-chain paging, `.chain-closed`, off-gate, bootstrap freshness); evidence here still 4 sessions | +1 downstream incident (s18 duplicate session); +2 state files; +3 flags |
| S4 two items concurrently | works; #55 makes concurrent **gemini** sessions on one checkout indistinguishable by design (launch:602-608) | scope note for §5.2 |
| S5 worktrees | unchanged | `consumer_since` reads `$ROOT/.context-budget/sessions` (session-loop:557) — repository-keyed, consistent with ADR-0006 |
| S6 exit/crash/logout/resume | densest cluster **grew**: sidecar consumption leg at bootstrap (:635-640), `.chain-closed`/`--reopen`, K4 pins logout-before-close ordering | this is the scenario D-B must design against first |
| S7 non-claude runtimes | still fixture-only; env table widened (launch:613), D17f/g fixtures; gemini identity limitation now explicit | §5.2's "actually exercise" requirement unchanged |
| S8 fleet dispatch | KEEP (§5.3); **new input**: three overlapping "measure another session" surfaces (`watch`, `children`, `check --session-id`+`child_past_stop`) — the maintenance answer must cover all three | |
| S9 downloader | worse by 2 undocumented state files; `.pending-clear-seed` still untracked-visible | |
| S10 non-engineer | unchanged | |

## 3. What the delta added that the findings do not cover

1. `work/<p>/.next-command.json` identity sidecar — launch:1212-1256 writer, session-loop:581-628 reader, `--unstage` removes it (launch:298). 0 docs. Right shape, wrong home (a 9th file; belongs in the lifecycle record as `staged_at/staged_by/command_cksum`).
2. `work/<p>/.next-command.stale` — session-loop:635-640 parks a rejected command. 0 docs, no reader, no GC.
3. `work/<p>/.chain-closed` — writer session-loop:875-889; gates at session-loop:392-410 and launch:336-345; `--reopen` deletes it. Documented (cb.md:397-404, SKILL.md:415-420). Good "one writer" discipline; duplicated gate.
4. `session-loop.sh --reopen`, `--relaunch-override` (session-loop:47-48). Documented in context-budget.md only.
5. `context-budget.sh check --session-id <sid>` read-only pin (cb:70-72, :85, :111-118, :411-444). Overlaps `watch`/`children` functionally; documented at cb.md:685-708.
6. `successor_advisory` "successor: NOT STAGED" on `record`/`register` (cb:539-561). Two-sided by design; stderr only; a small step toward D-F.
7. Longer in-band WARN/STOP prose (hook-lib:90-96): more instruction text delivered per hook fire.
8. `invoked_by_supervisor` `$PPID` exemption (launch:702-711) — a new pid-topology contract ("direct call only") pinned by tests F1/E10.
9. G1-a: `ROLLOVER_RELAUNCH=off` now also refuses a supervisor start (session-loop:373-380). Consistent edits to env/doc/ADR-0009; semantic widening of a knob a downloader ships with `auto`.
10. P4a/P4b alarm predicates (session-loop:726-791): sharper pages; same cadence.
11. Docs: "What the chain tells you" (cb.md:610-640), SKILL "Signals" (:400-425), anchor gotcha (:115-118). Refs to `docs/session-chain-scenarios.md` — file absent in this repo.
12. Tests: N1–N4, D17a–h, S1a–m, registry N1 pin, K1–K6, GA1–4, P4a-a..d, P4b-a..d, E10, CL1, T13, U4e (+617 LOC). Mostly golden-string assertions on log wording (e.g. `assert_contains … "discarding the staged command"`), which §5.4 already flags. `test-attach-session.sh` reported 20/2 red pre-existing in the #54 commit message — NOT RE-VERIFIED here.
13. #59 — outside the subsystem; five new surfaces incl. `scripts/setup-github-repo-access.sh` (287 lines, macOS-only).

## 4. Effect on directions D-A..D-G

- **D-A (delete retired/speculative)**: premise intact for sentinel, migration shim, legacy scalar rm, `session_handoff.md`, rollover-prep max-wins, stamp GC — none used by the new code (new code touches `$SENTF` only in `rm -f`). Per §5.3 the dispatch/children/watch bullet leaves D-A. Nothing "retired" is now live.
- **D-B (one lifecycle record)**: premise **strengthened**. The list "7 state files" must become: `.session-seq`, `.session-seq.provenance.json`, `.session-seq.bump.json`, `.rollover-complete`, `.session-loop.budget`, `.hands-off`/`.interactive`, **`.next-command.json`, `.next-command.stale`, `.chain-closed`** (plus the non-lifecycle coordination files `.session-loop`, `.active-session`, `.rollover-options`, `.pending-clear-seed`, `.session-loop.log`, `.session-loop.alarm-stop`, `.next-command`). The record's schema must absorb three facts the delta introduced: staged (`staged_at`, `staged_by`, `command_cksum`), **consumed** (write it at session-loop:676 instead of inferring it at :554-628), closed (`closed_at`, `closed_by`, `top_ledger_seq`). #60 is the clearest single example in the history of the pattern D-B fixes.
- **D-C (shared lib + collapse hooks)**: unchanged; two new concrete targets — the runtime table pair (launch:613 ↔ cb:381-393) and the `$PPID` direct-call contract.
- **D-D (claude-first adapters)**: superseded by §5.2 (four first-class). New input: gemini's identity is a constant (cb:389) — the plan must decide whether that is acceptable for a first-class runtime or gemini needs a per-session id source before "actually exercising" it.
- **D-E (one doc/one skill/one rule)**: premise strengthened — three contradictions untouched, one doc section added without fixing the index, one prose gotcha re-added, two new docs sections referencing a non-existent scenarios file.
- **D-F (record as side effect)**: `successor_advisory` is a partial move in this direction but still depends on the agent invoking `record`.
- **D-G (downloader hygiene)**: unchanged; +2 undocumented files, `.pending-clear-seed` still missed.

## 5. Corrected findings summary

| Finding | Verdict |
|---|---|
| F1 | STILL HOLDS |
| F2 | STILL HOLDS — counts up: seq ×7→×9, rollover-happened ×3→×5, liveness ×3→×4; #60 adds an inference mechanism (sidecar consumption) beside the bump record, #55 tightens one, #54's `.chain-closed` is script-written but a 9th file |
| F3 | STILL HOLDS — sentinel/shim/legacy unchanged; dispatch bullet moves out per §5.3; `--session-id` is a third per-child measurement surface |
| F4 | STILL HOLDS — launcher 13 fns/≈1160 top-level; loop body 345 lines/23 halts; runtime tables now a load-bearing "keep in step" pair |
| F5 | STILL HOLDS — 275 claude / 0 other; nuance: opencode hook stamps from Aug exist; gemini identity is a constant by design |
| F6 | STILL HOLDS; PARTLY ADDRESSED (page wording) by #54; evidence still downstream (`session-chain-scenarios.md`, `session-loop-hardening/`, s18 archive all absent here); overlap 5→≈8 |
| F7 | STILL HOLDS, +6 concepts (2 undocumented) |
| F8 | STILL HOLDS; `--reset-cap` PARTLY ADDRESSED; `CHECK_EVERY` WAS WRONG (documented at :940); "Status: Open" WAS WRONG; new: docs cite a non-existent scenarios file |
| F9 | STILL HOLDS — 5 dangling paths, same env defaults, guide/README/CONTEXT unchanged |
| F10 | STILL HOLDS (3 of 4): `.pending-clear-seed` still not ignored; NOTIFY/ROOT now 4 sites; ADR-0009 still open; "Status: Open" WAS WRONG |

Scenarios: S1, S2, S5, S10 unchanged; S3 and S6 materially changed (more mechanism, one new downstream incident); S4 and S7 gain the gemini-identity caveat; S8 gains a third overlapping surface; S9 slightly worse.

**What the re-evaluation changes.** Nothing in #54–#60 invalidates a finding; three sub-claims were wrong or unsourced (`CHECK_EVERY` is documented; the "Status: Open" prose does not exist; the "12 copies"/"11 case sites"/"9 seq sites" figures are method-dependent — 10/3+15/7 on my count). Every structural finding got *more* true: +495 script LOC, +2 lifecycle files (one of them a discarded-evidence parking file), +3 flags, +1 explicit cross-file table invariant, +1 pid-topology contract, +6 concepts, and a doc layer that now cites a scenarios file this repo does not have. The one direction whose premise the delta genuinely sharpens is D-B: #60 infers at chain start (`consumer_since`) a fact the supervisor knew and threw away at session-loop:676, which is the F2 thesis in one commit. For the plan, three concrete inputs: (1) the lifecycle record must carry staged/consumed/closed, not just seq/identity/mode/disposition/budget; (2) the fleet-maintenance answer (§5.3) must cover `check --session-id` + `child_past_stop` alongside `watch`/`children`; (3) gemini's constant identity is a first-class-runtime decision to make before exercising it.
