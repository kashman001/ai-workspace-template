# 07 — Phase 6: one hook dispatcher over an adapter table

**What to build:** one script reads the per-runtime adapter table (transcript location, token method, session-id source, which hook registers, which ends a turn, what logout looks like) and produces each vendor's hook payload. The six per-vendor hook wrappers become one-line shims or are removed. The `jq_missing` check runs before any parsing. Whether `copilot-vscode` and `opencode` keep a shim is decided in this phase's plan file (both are non-goals).

**Blocked by:** 04 (Phase 3).

**Status:** ready-for-agent

- [ ] For every runtime in the adapter table, the dispatcher's payload is byte-identical to today's wrapper output on the same input
- [ ] With `jq` absent, `jq_missing` is printed before any parsing is attempted
- [ ] Per-vendor wrappers are one-line shims or deleted; the vendor hook suite is green against the dispatcher
- [ ] All suites green
