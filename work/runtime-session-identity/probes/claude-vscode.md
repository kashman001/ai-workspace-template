# Probe — Claude Code VS Code extension (Anthropic, 2.1.296)

## Post-fix (s9)

User row 3: two separate Claude Code conversations in the probe clone `ws-identity-probe-s9`
(sessions `12ec3517`, `78a676a3`).

- **Agent shell:** `CLAUDE_CODE_ENTRYPOINT=claude-vscode` and `CLAUDE_CODE_SESSION_ID` set to
  each conversation's own id; `CLAUDE_PID` points at that conversation's own `claude` process.
  `register` and `check` bound its own transcript (`method=exact`).
- **Hooks:** PostToolUse and Stop payloads each carried their own `session_id`.
- **Registry:** one `claude-<sid>.json` per conversation, each artifact present. **No phantom
  records.** The pre-fix probe saw the extension pre-spawn idle processes that registered
  never-written transcripts; none appeared this time.

**Result: PASS.**
