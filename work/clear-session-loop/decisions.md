## 2026-10-15 — A PARTIAL research verdict gets a spec for the go half only
**Chose:** Treat `research.md`'s PARTIAL verdict as go for its §7 A (harden the attended Claude `--clear` path) and B (one time-boxed headless spike), and write `spec.md` covering only those two. Section C (pty/tmux/expect injection, `/clear` chains on other runtimes, an event-driven supervisor rewrite) is a non-goal. Section D (several sessions per work item) is out of scope here.
**Because:** The launcher said "go → spec, no-go → stop". PARTIAL has a defined, cheap go half (about one session plus a spike), and the no-go half has concrete reasons (no sanctioned TUI trigger; programmatic resets mean hosting the session in an SDK; portability is weakest exactly there).
**Rejected:** Treat PARTIAL as no-go and stop — it would drop low-risk fixes the research found (turn-end owner check, drain-before-clear, SessionEnd budget, the "types nothing" doc question); Spec the full unattended clear chain — rests on unsupported keystroke injection.
**Blast radius:** `work/clear-session-loop/spec.md` scope; later plan for this item.
**Promote?:** no

## 2026-10-15 — Spec cut to three small fixes on review
**Chose:** Keep only S4 (turn-end owner check), S13 (opt-in `PreCompact` auto-block, default off) and S14/S15 (probe the "types nothing" claim and fix the docs to match). Retire S1–S3, S5–S12, S16–S17.
**Because:** The user reviewed the research and saw little benefit beyond the existing loop. The retired items only make the attended Claude-only `/clear` path a little smoother (supervisor hop counting, drain gate, session title) or explore an SDK host nobody plans to build (Spike B). The three kept items protect the loop we already run, whether or not anyone uses `/clear`.
**Rejected:** Keep the full A+B spec and review its six design calls (more parts to maintain for a path that only works attended on one runtime); Close the item as no-go with the fixes parked as backlog cards (the fixes are about one session, so doing them now is cheaper than carrying them).
**Blast radius:** `work/clear-session-loop/spec.md`; later plan for this item.
**Promote?:** no

## 2026-10-15 — S4 (turn-end owner check) retired during implementation
**Chose:** Do not add `.session.session_id == $sid` to `budget_hook_should_exit`; leave the turn-end predicate as it is.
**Because:** `launch-next-session.sh --emit` empties `session` in the same write that creates `staged`, so the added clause is false at every supervised exit. Applying it failed six existing assertions in `test-vendor-budget-hooks.sh` (X4a–c, X5a, K1f, opencode fixture). The hazard it guarded is not real: the hook signals `$PPID`, which after `/clear` is the same process that staged the successor.
**Rejected:** Check `.launch.predecessor.session_id == $sid` instead (guards nothing real; another clause to keep in sync with the launcher).
**Blast radius:** `scripts/hooks/context-budget-hook-lib.sh` unchanged; spec S4 struck.
**Promote?:** no
