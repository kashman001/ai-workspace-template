<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 7 (2026-09-14): Stage 2 design drafted (Part 2); awaiting user review

**Summary.** Ran the two authorised probes (one agent, isolated temp dir with its
own hook config; report `evaluation/stage2-probes.md`): **V2 = ROTATES** —
`/clear` fires SessionEnd(reason=clear) then SessionStart(source=clear) with a
new session id and a new transcript JSONL, the old file frozen; **`claude --bg`
env = SURVIVES-ONLY-IF-THE-LAUNCH-SPAWNS-THE-DAEMON** — the var reaches the hook
on a cold start, but a second `--bg` 40 s later replayed the first launch's
stale value (daemon pre-forks spares from the spawning caller's env). So
`--clear` stays (ADR-0009 amended, open item closed) and the handshake file is
NOT retired (launcher line ~1184's rationale is mis-stated, the mechanism is
right). Then one general-purpose agent drafted **Part 2** (sections a–m per
the launcher) from the architect's §7(d) seed + the 17 accepted decisions +
§1b.7; appended to `session-management-review-findings.md` (lines 371–679;
source copy `evaluation/stage2-design-part2.md`). Status header updated. No
scripts, skills, docs or ADRs touched; nothing pushed.

**Decisions.** None new by the user this session. The design proposes (for
review, not decided): 7 kept concepts; record field owners launcher→`seq`/
`launch`/`staged`, context-budget.sh→`session`/`options`, session-loop.sh→
`chain`; `--clear` kept; handshake relocated into `launch.pending` + a
`pending_elsewhere` refusal; support matrix claude supported (attended +
supervised), codex/copilot-CLI unverified, gemini attended-unverified /
supervised-unsupported; ADR-0010/0011/0012 proposals.

**Learnings:**
- Probe cost 91K agent tokens / 8 min; design agent 232K / 11.5 min. Parent
  stayed under WARN by reading only headers + agent summaries.
- `/clear` transcript caveats for measurement: filter records by camelCase
  `sessionId` (snake_case `session_id` on some new-file records is stale);
  the `/clear` command record lands in the NEW file; no transcript is written
  when `CLAUDE_CODE_CHILD_SESSION` is inherited (probe needed `env -u`).
- `tmux` is not installed on this machine; `expect` drove the TUI fine.

**Review artifact (session 7, after commit eab995a).** Part 2 + the probe
appendix published as a private claude.ai page for the user's review:
https://claude.ai/artifact/4KeTb5seRPdSS8AtEKQmmV (title "Session Redesign
Part 2"; 13 sections a–m + appendix; source HTML in the session scratchpad,
not in the repo). Rolled over at WARN (137K) on the user's instruction; the
successor opens by presenting the URLs and answers review questions
(`--loop-mode interactive`).

**Open / next.** User reviews Part 2. On go: Stage 3 (fresh architect +
scenario/flow agents over the design, verdicts → Part 3). Part 2 §(m) lists 5
open questions for Stage 3. Supervisor pid 72900 hazard unchanged (decision 12).

