# L96 findings — usage-limit wait vs SESSION_LOOP_KILL_AFTER

**Interactive or not?** Interactive. `scripts/launch-next-session.sh:397` starts the
child as `claude --name "$PROJECT #$SEQ" "$PROMPT"` (no `-p`); codex/gemini/etc. likewise
(`:398-402`). So Claude Code's usage-limit auto-wait (interactive-only) can occur in chain children.

**Can the watchdog kill a waiting session?** Possibly. `scripts/session-loop.sh:374` starts
the watchdog in every mode (`ALARM>0`); `:268-270` kills the child when its transcript
(`session.artifact`) has been silent >= `KILL_AFTER`. Default is 14400s (4h)
(`context-budget.env:101`). A wait spanning that long, with no transcript writes, would be
killed as `page=silent`. Usage-limit resets are up to 24h per R21, so the window is real.

**Uncertain (not verified):** whether Claude Code writes anything to the transcript during
the wait (a status/heartbeat entry would reset the silence clock), and the exact wait
semantics/duration. I could not test this without a real limit-hit session, and did not
launch one. No recognisable signal exists to teach the watchdog, so a test-first
code fix has nothing to assert against.

**Done:** documentation only — a paragraph after the watchdog description in
`docs/context-budget.md` ("A usage-limit wait looks like silence"), with the workaround
(raise or zero `SESSION_LOOP_KILL_AFTER` per work item). No code change; suite
`scripts/tests/test-session-loop.sh` passes (160/0).
