## 2026-10-15 — A PARTIAL research verdict gets a spec for the go half only
**Chose:** Treat `research.md`'s PARTIAL verdict as go for its §7 A (harden the attended Claude `--clear` path) and B (one time-boxed headless spike), and write `spec.md` covering only those two. Section C (pty/tmux/expect injection, `/clear` chains on other runtimes, an event-driven supervisor rewrite) is a non-goal. Section D (several sessions per work item) is out of scope here.
**Because:** The launcher said "go → spec, no-go → stop". PARTIAL has a defined, cheap go half (about one session plus a spike), and the no-go half has concrete reasons (no sanctioned TUI trigger; programmatic resets mean hosting the session in an SDK; portability is weakest exactly there).
**Rejected:** Treat PARTIAL as no-go and stop — it would drop low-risk fixes the research found (turn-end owner check, drain-before-clear, SessionEnd budget, the "types nothing" doc question); Spec the full unattended clear chain — rests on unsupported keystroke injection.
**Blast radius:** `work/clear-session-loop/spec.md` scope; later plan for this item.
**Promote?:** no
