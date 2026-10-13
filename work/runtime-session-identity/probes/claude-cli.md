# Probe — Claude Code CLI

## Post-fix (s9)

Claude Code 2.1.296, probe clone `ws-identity-probe-s9` at 191944f. Two `claude -p` sessions
were launched at once from a clean env (`env -i`), each running `./probe-env.sh claude cli-A|B`
and then `sleep 20`, so both were live together.

- **Agent shell:** `CLAUDE_CODE_SESSION_ID` is set to the session's own id (plus `CLAUDE_PID`,
  `CLAUDECODE=1`). `register` and `check` both bound the session's own transcript
  (`method=exact`).
- **Hooks:** the PostToolUse (claude hook) and Stop payloads each carried their own
  `session_id` + `transcript_path`, with no cross-over.
- **Registry:** exactly one `claude-<sid>.json` per session, each with its own artifact and pid.

**Result: PASS.**
