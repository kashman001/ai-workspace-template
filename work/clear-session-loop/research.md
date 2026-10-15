# Research — can a `/clear`-style reset drive the session loop?

Work item `clear-session-loop`, 2026-10-15. Drafted by a research subagent (fable), then verified and corrected by the orchestrating session — see **Verification** at the end; corrections are marked *[verified: …]* inline. Repo claims cite `path:line` at commit `5183247`; external claims cite URLs. Anything not confirmed from a primary source is marked **unverified**. Runtime behaviour was researched from docs and from probes already on disk, not by live-running other CLIs.

**Verdict in one line: PARTIAL.** Harden the attended Claude `--clear` path and run one headless spike; do not build an unattended `/clear` chain on the interactive CLIs; running several sessions in one work item at once is a separate change that `/clear` neither helps nor blocks (§6, §7).

## Glossary (loop terms used below)

- **Session** — one agent conversation with one context window. In Claude Code it has a session id and a transcript file (`~/.claude/projects/<cwd-slug>/<id>.jsonl`, `docs/context-budget.md:701`).
- **Work item** — a `work/<item>/` directory with a launcher, a ledger and a record.
- **Record** — `work/<item>/session-state.json`: `seq` (session number), `launch`, `session` (the owner), `staged`, `chain` (`docs/context-budget.md:274-294`).
- **Owner** — the one session the record's `session` block names; alive while its pid runs with the recorded start time (`docs/context-budget.md:373-379`).
- **Launcher** — `next-session.md`, forward-only, REPLACED at each rollover (`docs/work-directory-conventions.md:12-27`).
- **Ledger** — `handoff.md`, append-only, newest block on top; the block heading carries the session number (`docs/work-directory-conventions.md:70-73`).
- **Rollover** — the dying session writes ledger + launcher, then runs the launcher script, which advances `seq` and either launches, stages (`--emit`) or seeds a `/clear` (`--clear`) (`docs/context-budget.md:317-366`).
- **Supervisor / chain** — `scripts/session-loop.sh`: runs one session after another in the foreground, reads a verdict from the record after each child exits (`docs/context-budget.md:410-480`).
- **WARN / STOP** — 120K / 150K tokens (`context-budget.env`, `docs/context-budget.md:192-200`). WARN asks (under `manual`), STOP goes.
- **Hands-off / interactive** — `--loop-mode`: hands-off chains run without a person; interactive waits for Enter between sessions (`docs/context-budget.md:512-516`).
- **Dispatch record** — `work/<item>/.agent-dispatch/<task>.json` + report file: how a parent tracks a long-running child across its own rollover (`docs/context-budget.md:630-684`).
- **Clear path (today)** — `launch-next-session.sh --clear`: claude-only, attended; writes the prompt + this pid into `launch.pending`; the human presses `/clear`; the `SessionStart` hook's `register` matches the pid and prints the prompt into the cleared context (`skills/session-rollover/SKILL.md:245-254`, `scripts/launch-next-session.sh:279-285,422-423,452-455`).

---

## 1. The video

**Source.** "Don't Use /compact Until You See This $1.22 Test", DIY Smart Code, uploaded 2026-10-12, 11:47, https://www.youtube.com/watch?v=3AOhAS7vGqU (auto-captions `en-orig`; the channel's description lists its own sources: `code.claude.com/docs/en/costs`, `.../context-window`, `.../prompt-caching`, `.../checkpointing`). It is a practitioner's measurement video, not a primary source; every number below is the presenter's single run on a Max plan and is **unverified** beyond that.

**What it shows.**

1. Claude Code resends the whole conversation with every request: an "ok" 15 minutes into a session sent 306K tokens versus 27K in a fresh session; the cost did not scale the same way because ~95% of the tokens were prompt-cache reads.
2. A fresh session already carries ~27K tokens before the first prompt (tool definitions ~16K, system prompt, skills list, CLAUDE.md, auto-memory). MCP tools cost nothing until used.
3. `/compact` on the 306K session took 32 s and left ~5K. What comes back from disk: system prompt, root CLAUDE.md, auto-memory, up to five recent files (large ones as a path only). What is lost: rules given only in chat, path-scoped rules, subfolder CLAUDE.md files — they live in the conversation and get summarised. A planted rule survived in the presenter's run.
4. `/clear` costs nothing at the moment of clearing; the next message pays the same ~27K startup load as a brand-new session. `/clear <name>` names the old session on the way out; `/resume` still finds it; and — against the help-center claim that `/clear` cannot be undone — the rewind menu (Esc Esc) showed a "previous session" entry that brought 284K tokens of messages back, until the process quits.
5. **Compact vs handoff file, same trap:** from one point in a session carrying a planted rule and a dead end, three branches (plain `/compact`; write a handoff file → `/clear` → fresh session reads it; `/compact` with a focus line) all finished the task, kept the rule and avoided the dead end. The handoff route cost about a quarter less ($0.37 vs $0.49), mostly because writing the file ($0.22) was cheaper than compacting ($0.33) — but writing the file was itself two requests that each resent the whole 300K session.
6. A cold-cache compact (session idle 66 min) cost 3.7× the warm one ($1.22 vs $0.33). The verdict: when you reset matters more than which reset; do it before stepping away.
7. Smaller levers: "summarize from here" in the rewind menu (partial compaction); subagents keep noisy work out of the main window; `/btw` side questions stay out of history; hooks that filter tool output; a status line with the context percentage; `/context` itself costs ~1.2K per run.
8. A CLAUDE.md edit applied mid-session on 2.1.296 (the docs say it waits for clear/compact/restart).

**What applies here.** The video's recommended technique — *write a handoff file, `/clear`, continue from the file* — is exactly this workspace's rollover (ledger + launcher on disk, then a fresh context that reads them; TADR-0003 rejected conversation-as-carrier handoffs, `docs/template-adr/0009-clear-based-rollover-relaunch.md:48-52`). Three points sharpen our design:

- **`/clear` and a fresh process cost the same at the next prompt** (both pay the startup load), so the case for `/clear` is not tokens; it is process continuity (login, MCP connections, speed), which is also what TADR-0009 argued (`docs/template-adr/0009-...md:30-40`).
- **The rollover itself is the expensive step** and it is cheaper warm than cold. Our rule "wrap up at WARN, not STOP" (`skills/session-rollover/SKILL.md:316`) and "write ahead at every pause" (`:43-46`) are the same lesson; a chain should never let a session go idle past the cache TTL before rolling.
- **"Previous session" in the rewind menu is a trap for an unattended loop**: a human could pull 284K tokens back into a cleared process. Not a concern hands-off (nobody presses Esc Esc), but a note for the attended clear path.

---

## 2. `/clear` in Claude Code

*(Filled from the Claude Code docs helper — see the section's own citations. Everything not cited to code.claude.com, platform.claude.com or the CHANGELOG is **unverified**.)*

**What this repo already knows, from its own probe** (`work/template-improvement-review/evaluation/stage2-probes.md:47-85`, `claude` 2.1.272, 2026-09-15): `/clear` **rotates** the session — a new session id and a new transcript file; the hooks fire `SessionEnd` with `reason: "clear"` on the old id and then `SessionStart` with `source: "clear"` on the new id (`:59-62`); the old JSONL is frozen at the clear instant (`:67`); the post-clear turn was billed as a fresh context of the same size (`:75-76`); the TUI's own help line reads "Start a new session with empty context; previous session stays on disk (resumable with /resume)" (`:55`). The probe also notes that transcripts are not written at all when `CLAUDE_CODE_CHILD_SESSION` is inherited (nested launches) unless `CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1` is set (`:83-85`). Our own `register` already consumes that rotation: the same pid with a new session id binds as `adopted` (`scripts/context-budget.sh:847-850`, `docs/context-budget.md:385`).

**And a fact the probe itself proves about triggering:** that probe drove `/clear` with an `expect` script (`spawn claude`, send `/clear⏎`, `stage2-probes.md:49-51`). So "an agent cannot press `/clear`" (`skills/session-rollover/SKILL.md:248`, TADR-0009 `:96-97`) is precisely true of the agent's *own* tool shell (no handle on its TTY) and precisely false of a process that owns the pty — which `session-loop.sh` is ("owns the terminal", `docs/context-budget.md:412-413`).

### 2.1 What survives and what resets

Sources: the commands page (https://code.claude.com/docs/en/commands), sessions page (https://code.claude.com/docs/en/sessions), hooks page (https://code.claude.com/docs/en/hooks), checkpointing (https://code.claude.com/docs/en/checkpointing), CLI reference (https://code.claude.com/docs/en/cli-reference), Agent SDK TypeScript reference (https://code.claude.com/docs/en/agent-sdk/typescript), and the raw changelog (https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md, cited by version — it carries no dates).

| Thing | On `/clear` | Source |
|---|---|---|
| Conversation / context | Reset: "Start a new conversation with empty context." Aliases `/reset`, `/new`; `/clear <name>` names the old session. | commands page, `/clear [name]` row |
| Previous conversation | Saved; `/resume` finds it; in the *same process* the rewind menu has a "previous session" entry (what the video showed). | sessions page → "Manage context within a session"; checkpointing → "Rewind past a cleared conversation"; changelog 2.1.191 |
| OS process, pid | Survive — implied by "in the same Claude Code process" (rewind entry); not stated as "pid". Confirmed empirically by our probe (same `expect`-spawned process, `stage2-probes.md:49-62`). | sessions page |
| MCP servers, plugins, connectors | Retained. Changelog 2.1.136 fixed them "silently disappearing after `/clear`" (VS Code, JetBrains, SDK). Caches are cleared (2.1.63 skills cache, 2.1.69 session caches). | changelog |
| Background bash tasks and background agents | **Survive.** Changelog 2.1.72: "Fixed `/clear` killing background agent/bash tasks — only foreground tasks are now cleared." | changelog |
| Hooks, settings | Loaded hooks keep running (SessionEnd/SessionStart fire); `CLAUDE_ENV_FILE` variables are re-applied after `/clear` (2.1.136). Whether CLAUDE.md is re-read: **unverified** (the commands page only says `/clear` keeps "project memory"). The video observed a CLAUDE.md edit applied mid-session without any reset on 2.1.296 (§1, unverified). | changelog; commands page |
| Session id, transcript file | **New id, new JSONL** — our probe (`stage2-probes.md:59-69`). The docs do not state it; the SDK's `conversation_reset` message says an empty transcript is mounted under `new_conversation_id` while `session_id` is still carried — see the discrepancy note below. | probe; SDK TS reference → `SDKConversationResetMessage` |
| `--name` / `/rename` title | Kept across `/clear` (2.1.111, 2.1.243 fixes). | changelog; sessions page |
| Permissions ("allow for this session"), cwd, auto-memory | **Unverified** for `/clear`; the sessions page documents carry-over only for `/branch`. | sessions page |
| Cost counter, subagent spawn budget | Reset (2.1.211, 2.1.212). | changelog |
| `--continue` / `--resume` afterwards | 2.1.277 mentions "sessions continued after `/clear` (restart, `--continue`, `--resume`)" — `--continue` lands on the post-clear conversation; `--resume <old id>` reaches the pre-clear one. Inferred from changelog wording; **unverified** routing. | changelog |

**Discrepancy to settle on first live use:** the TUI probe shows a *new `session_id`* in the hook payloads after `/clear` (`stage2-probes.md:59-62`), while the SDK doc describes `conversation_reset` as "replaced without ending the session" with a `new_conversation_id` and the same `session_id` (SDK TS reference — *[verified: the `SDKConversationResetMessage` type carries both `session_id` and `new_conversation_id`; `trigger` may be `clear | plan_mode_exit | fresh_session | onboarding`]*). Either the SDK's `session_id` is the SDK's own handle and hooks still see a rotation, or SDK and TUI differ. Our binding logic tolerates both (pid match → `adopted`, `scripts/context-budget.sh:847-850`), but the registry and escalation state are keyed by session id, so a *non-rotating* id would keep the old WARN/STOP escalation slot (`hook-<rt>-<sid>.status`) and the old transcript path — a false STOP on the first post-clear check. Spec item: verify on the surface actually used.

### 2.2 Hooks that fire

- **`SessionStart`** with `source` ∈ `startup | resume | clear | compact | fork` (hooks page → "Matcher patterns", "SessionStart input"; `fork` since 2.1.214). Common input fields: `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `permission_mode`, plus `source`, optional `model`, `session_title`; resume/fork add `context_tokens`, `prompt_cache_likely_expired` and friends. Output can add context: `hookSpecificOutput.additionalContext`, plain stdout on exit 0, and also **`initialUserMessage`**, `sessionTitle`, `watchPaths`, `reloadSkills` (hooks page → "Add context for Claude"; `reloadSkills`/`sessionTitle` since 2.1.152). No blocking or decision control.
  - **`initialUserMessage` does not help the interactive path.** *[verified: hooks page, SessionStart decision-control table — "String used as the first user message of the session, in non-interactive mode with the `-p` flag. It becomes the first turn even if you pass no prompt."]* It is documented for `-p` only, so it cannot make the TUI start working after `/clear`. Today the clear path prints the bootstrap prompt as hook stdout (`scripts/context-budget.sh:877`), which lands as *context*, not as a user turn. **Open question:** does the cleared TUI session act on that context with no typed message? `skills/session-rollover/SKILL.md:251-252` and TADR-0009 (`docs/template-adr/0009-clear-based-rollover-relaunch.md:61`) both say "the human types nothing beyond the keystroke", but the docs describe hook stdout only as added context, and the stage-2 probe typed a message after `/clear` (`stage2-probes.md:51`), so it does not settle it. **Unverified — check on the first real `--clear` use.** If a turn is needed, the attended path is "`/clear`, then type `go`", and the docs should say so. `initialUserMessage` *does* matter for the headless spike (§7 B): in `-p` mode a SessionStart hook can supply the first turn.
- **`SessionEnd`** fires on `/clear` with `reason: "clear"`; reasons: `clear | resume | logout | prompt_input_exit | other` (hooks page → "SessionEnd"; matches our probe `:60`). **SessionEnd hooks share a 1.5 s budget**; a longer per-hook `timeout` raises it (up to 60 s), and `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` overrides it explicitly *[verified: hooks page; changelog 2.1.74, 2.1.268]*. Our `release` runs there (`.claude/settings.json` SessionEnd) — it must stay well under 1.5 s or be made idempotent with `register`'s rebind, which it is (`release` is a no-op for a non-owner, `scripts/context-budget.sh:1058`).
- **`PreCompact`** (2.1.105): matchers `manual | auto` (auto includes idle compaction); input `trigger`, `custom_instructions`; **exit 2 or `{"decision":"block"}` blocks compaction.** **`PostCompact`** (2.1.76): `trigger`, `compact_summary`; no control. These are the only hooks with any say over a context reset, and only in the blocking direction. For the loop this is directly useful: a `PreCompact` hook that blocks `auto` while a work item is bound would guarantee "deliberate rollover beats auto-compaction" (`docs/context-budget.md:201-204` only relies on 150K < ~200K today).
- **Nothing in any hook's output can trigger a `/clear` or a compaction** (hooks page, full text grep by the helper; changelog likewise).

### 2.3 Can anything but a human keypress trigger it?

| Route | Status | Source |
|---|---|---|
| Typed `/clear` in the TUI | The documented way. "A command is only recognized at the start of your message." Model-emitted text is not a user message — an agent cannot clear itself by emitting `/clear` (**unverified**, but no mechanism exists for it). | commands page |
| Keybinding | None. `chat:clearInput` (Ctrl+L) and `chat:clearScreen` (Cmd+K) preserve the conversation; the double-press `/clear` shortcut was removed in 2.1.238; no `clear conversation` action in the keybindings list. | https://code.claude.com/docs/en/keybindings; changelog |
| Hook output / exit code | None (2.2). | hooks page |
| Plugin / mod | **Unverified**: the mods surface (`prompt.change` hook, 2.1.296 area) concerns prompt-box text only; nothing documented clears the conversation. | changelog |
| **Agent SDK `query()` with `/clear` as the prompt** | **Documented.** "In a `query()` call, only `/clear` and its aliases produce this message" — `SDKConversationResetMessage` with `new_conversation_id`; the conversation is "replaced without ending the session" (CLI ≥ 2.1.203; new fields ≥ 2.1.281). `Query` methods (`interrupt`, `setModel`, `reinitialize`, `close`, …) include no clear; `close()` ends the process. The sessions page's "start empty" advice is "a new `query()` call without `resume`" — whether that reuses the subprocess is **unverified**. | SDK TS reference; sessions page |
| `claude -p --input-format stream-json` with a `/clear` user message | **Unverified** (no control message documented on the streaming page; the SDK route above runs the same CLI underneath, so it may work). The one cheap experiment worth running. | https://code.claude.com/docs/en/agent-sdk/streaming-vs-single-mode |
| `claude -p --continue` / `--resume` / `--fork-session` / `--session-id` | All start a **new process**; `--fork-session` mints a new id on resume; `-p`/SDK sessions are excluded from `--continue` unless `-p --continue`. That is today's fresh-process path, not a same-process reset. | https://code.claude.com/docs/en/headless; CLI reference |
| `/compact [instructions]`, `--autocompact <auto|tokens>` | A compaction, not a clear; TADR-0003/the skill reject compaction as the rollover mechanism (`skills/session-rollover/SKILL.md:340-341`). | commands page; CLI reference |
| Keystroke injection (tmux `send-keys`, `expect`, `osascript`) | **Works empirically** (our own probe drove it with `expect`, `stage2-probes.md:49-51`) and is **unsupported by every vendor** (helper's search of all command/hook/headless pages for the five runtimes). | probe |
| Remote Control clients | `/clear` resets propagate to Remote Control clients (2.1.224) — a reset is *observable* remotely; whether it can be *issued* from a remote client is **unverified**. | changelog |

**Also relevant for a loop:** 2.1.286 fixed `/clear` typed inside a background agent's transcript acting on the main conversation (a dialog now guards it); 2.1.84 added an idle-return nudge suggesting `/clear` after 75+ minutes — an attended session left idle will be *invited* to clear, which an unattended chain never sees.

**Bottom line for §7:** inside the interactive CLI, the only triggers are a human or a pty-owning driver. The only *documented* programmatic same-process reset is the Agent SDK's `/clear`-prompt → `conversation_reset`, which means the session is hosted by an SDK program (headless), not by the TUI the supervisor runs today.

---

## 3. Our loop, part by part — what a `/clear`-based rollover changes

The loop today, in one line: the owner session works → WARN/STOP arrives in-band (`PostToolUse` hook, `scripts/hooks/context-budget-adapters.conf` claude row) → the session writes ledger + launcher → runs the launcher script → **supervised:** `--emit` stages the successor command, the `Stop` hook SIGTERMs the session at the turn boundary, the supervisor reads the verdict and `eval`s the staged command in the foreground (`docs/context-budget.md:449-487`); **attended:** `--clear` (claude, human keypress) or a plain launch (fresh process, any runtime) (`skills/session-rollover/SKILL.md:212-216`).

A `/clear`-based loop would keep every artefact and gate and replace one thing: *the process boundary between sessions*. The next session is the same OS process with a new session id. Component by component:

### 3.1 `scripts/context-budget.sh` — register / record / bind

- **Already works across `/clear`.** `register` runs from the `SessionStart` hook on every start, resume and clear (`.claude/settings.json` SessionStart; `docs/context-budget.md:869-872`). `bind_work_item` matches `launch.pending.pid` + `pid_start` against this process (`scripts/context-budget.sh:788-795`), binds the new session id to the open launch, nulls `launch.pending` and prints the pending prompt on stdout — which Claude Code adds to the cleared context (`:812-817,865-868,877`). No change needed for the binding itself.
- **Measurement is correct after the rotation** because the new transcript is the new artifact (`register` writes the registry record from the payload's `transcript_path`, `docs/context-budget.md:834-846`). Caveat already on record: a `record` right after `/clear` reads near zero until the first response lands (`docs/template-adr/0009-...md:17-19`).
- **One change:** today a `/clear` binding is an *attended* outcome. Under a chain, `register` would need to tell the supervisor "the successor is live" — it already does, implicitly: the record's `session` block is refilled with the new session id and `seq` unchanged from the bump. The supervisor just has to read it (3.3).
- **`release` on `SessionEnd(reason=clear)`** ends the old owner's block before the new `register` fills it (`.claude/settings.json` SessionEnd; `scripts/context-budget.sh:1046-1058`). Ordering is what the stage-2 probe observed (end, then start, same timestamp, `stage2-probes.md:60-61`). A race here is a theoretical risk: `release` is a no-op for a non-owner (`:1058`), so if `register` ran first, the late `release` would not clobber it — safe either way.

### 3.2 `scripts/launch-next-session.sh` — `--clear`, `--emit`, the launch record, the pending prompt

- `--clear` exists and is tested (`scripts/tests/test-launch-next-session.sh:330-343`). It refuses off claude (`runtime_path_unsupported`, `scripts/launch-next-session.sh:184-186`), refuses when the owner has no pid (`:282-285`), **refuses while a supervisor is live** (`supervised_stage_only`, `:195-197`; test V2 `:192-193`), and cannot be combined with `--emit` (`:89`).
- **What changes:** a supervised clear-based rollover needs a third shape — *stage a clear*: write `launch.pending` (pid, start, prompt) **and** mark `staged` so the supervisor and the `Stop` hook know a rollover was performed. Today `staged` carries `successor`, `command`, `by` (`docs/context-budget.md:287`); a clear-stage would carry `command: null` or `kind: clear`. The gate table (`docs/context-budget.md:331-344`) and the reason-code list pinned by `test-doc-consistency.sh` (`:548-557`) both change.
- **The bootstrap prompt stays verbatim** (TADR-0003; `docs/context-budget.md:368-371`); it already travels in `launch.pending.prompt`.
- **Loss accepted by TADR-0009 stays:** a `/clear` inherits the dying session's launch flags — model, permission mode, MCP fragment, `--name` — so any rollover that must change them still spawns (`docs/template-adr/0009-...md:66-71`). The session title also keeps the pre-rollover number (`:130-132`); cosmetic.

### 3.3 `scripts/session-loop.sh` — supervisor, verdicts, chain

This is where the real change is. The supervisor's whole model is *process = session*: it `eval`s the staged command in the foreground, waits for it to exit, then reads the verdict from the record (`docs/context-budget.md:449-466`; `scripts/session-loop.sh:338-392`). The verdict `staged` requires: `seq` moved by exactly one, `launch.predecessor` names the child as `rolled_over`, `staged.by` is the child's session id, lifetime ≥ `--min-lifetime` (`:377-392`). `quit_*` is "child exited with nothing staged" (`:355-372`). The watchdog identifies the child by `session.pid` and ages `session.artifact` (`docs/context-budget.md:502-510`).

Under `/clear` the child never exits between sessions, so:

- **The loop body becomes event-driven on the record, not on `wait`.** The supervisor must poll (or `fswatch`) the record for the transition "`seq` advanced + `launch.pending` set" (rollover requested) and "`launch.pending` null + `session.session_id` ≠ predecessor" (successor bound). Every verdict (`staged`, `quit_*`, `cap`, `plan_closed`, `stall`, `staged_invalid` legs) has to be re-expressed on those transitions. `cap`/`chain.used` is charged on consume today (`scripts/session-loop.sh:338`); it would be charged on each rebind.
- **The trigger belongs to the supervisor.** The dying session cannot press `/clear` from a tool shell. The supervisor can, *if* it runs the child under a pty it controls (`expect`, `script`, or a `tmux` pane) and sends `/clear⏎` when it sees `launch.pending` — the same mechanism the stage-2 probe used. That is a new dependency (`expect` ships on macOS; `tmux` does not) and a new failure class: typing into a TUI that may be mid-render, mid-permission-prompt or mid-tool-call. Mitigation: only send after the `Stop` hook has fired for the staging turn (today that hook SIGTERMs; it would instead write a "turn ended" mark, 3.5).
- **Does the cleared session start working without a human turn?** The seeded prompt arrives as `SessionStart` hook output in the context (`docs/context-budget.md:362-363`). Whether Claude Code then *runs a turn* on hook context alone, or waits for a user message, is load-bearing and is answered in §2. If it waits, the supervisor must also send the one-line bootstrap prompt + Enter after `/clear` — trivial with a pty, impossible without one. Either way this is the question that decides whether an unattended clear-chain exists at all.
- **Liveness and `quit`:** a process that exits still ends the chain (`quit_plain`); the record's `session.ended.door` still distinguishes `quit_stop`. Unchanged.
- **`plan.sh sync`/`check` between children** (`docs/context-budget.md:438-441`) would run on the rollover-requested transition instead of after exit.
- **Logout classification** (`child_logged_out`, `docs/context-budget.md:469-470`) becomes rarer — the whole motivation (TADR-0009 `:32-36`) — but the transcript-tail check still works on the new file.

Net: a rewrite of the supervisor's iteration loop and verdict reader (about `scripts/session-loop.sh:300-430`), plus a pty-driver layer, with the record schema gaining a staged-clear shape. The gates and the handoff artefacts do not move.

### 3.4 `scripts/session-loop-notify.sh`

Unchanged: it is a message sink (`scripts/session-loop-notify.sh:1-17`). New page tokens (e.g. `clear_sent`, `clear_unbound` — `/clear` sent but no rebind within N seconds) would be new strings, nothing more.

### 3.5 `scripts/hooks/` — dispatcher, adapters, Claude wiring

- The claude row: check on `PostToolUse` (stderr + exit 2), turn-end `Stop:sigterm`, register by config (`scripts/hooks/context-budget-adapters.conf` claude row). `budget_hook_exit` SIGTERMs `$PPID` when `staged.by` is this session under `TF_SESSION_LOOP=1` (`scripts/hooks/context-budget-hook-lib.sh` → `budget_hook_exit`, the `kill -TERM "$PPID"` line).
- **What changes:** for a staged *clear*, the `Stop` hook must **not** kill the process (the process is the successor). It would instead record "staging turn ended" in the record (a timestamp on `staged`) so the supervisor knows the TUI is idle and may send `/clear`. The adapter table gains an action (`sigterm|mark`), the lib a second predicate. Escalation state is keyed per session id (`hook-<runtime>-<sid>.status`, `docs/context-budget.md:767-770`), so the new session id gets a fresh WARN/STOP budget automatically — correct.
- `SessionStart`/`SessionEnd` wiring needs no change (3.1). `stop_hook_active` re-entrancy guard (`docs/context-budget.md:795-796`) applies as today.
- **Known open hazard that a clear-chain inherits unchanged:** the WARN push can be swallowed when a busy child wins the throttle race (backlog L32, resolved in the archive per `docs/template-workspace-backlog-archive.html:1689`; the finding is in `docs/template-workspace-backlog.html:240`). Neutral.

### 3.6 `scripts/fleet.sh` and dispatch records

See §4. The records are keyed to the parent's session id (`fleet.sh dispatch-open … --agent-id`, `docs/context-budget.md:659-684`); a `/clear` changes the parent's session id exactly as a fresh process does, so the "successor parent cannot resume the predecessor's children" rule (`:679-684`) holds unchanged.

### 3.7 Launcher / ledger write rules

Unchanged. The launcher is still REPLACED and the ledger still gets one block per session number (`docs/work-directory-conventions.md:12-27,70-73`); `launcher_unchanged`, `ledger_shape` and `ledger_seq_mismatch` gates run the same (`docs/context-budget.md:342-344`). The `/clear` path's one discipline difference: the dying session must write both files *before* `--clear`, exactly as before `--emit` — already the skill's step order (`skills/session-rollover/SKILL.md:132-182`). The rewind-menu hazard (§1) is the only new way a cleared *attended* session could re-import history; a hands-off chain has no keyboard.

### 3.8 Plan frontier (`scripts/plan.sh`)

Unchanged. `start` stamps the session number on the node (`scripts/plan.sh:520-522`), `done` needs `doing`, `frontier` derives from node files (`:420`); the number comes from the record's `seq` (`:313-320`), which the launcher advances identically for a clear. The supervisor's between-children `sync`/`check`/`plan_closed`/hitl-interactive logic (`docs/context-budget.md:431-447`) moves to the rebind transition (3.3). The split-at-rollover procedure (`skills/session-rollover/SKILL.md:99-130`) is identical.

### 3.9 Hands-off vs interactive

- **Interactive** (a person at the keyboard) is where `--clear` already lives and works (`skills/session-rollover/SKILL.md:245-254`). Under a supervisor in interactive mode, the supervisor waits for Enter between sessions (`docs/context-budget.md:512-516`); with a clear-chain, "press Enter" could become "press `/clear`" — but then the human is the trigger and the supervisor only watches, which is today's attended path with a watchdog. Cheap and safe.
- **Hands-off** is the hard case: no keyboard, so the supervisor needs the pty driver (3.3) or a programmatic reset (§2). This is the whole question of the work item.

### 3.10 Runtime-session-identity findings — reused, not redone

`work/runtime-session-identity/findings.md` settles the per-runtime identity facts a clear-chain depends on: Codex and Copilot CLI export a session id to the agent shell and fire a session-start hook with `session_id`/`sessionId` + transcript (`:11-12`); Gemini CLI exports no id var — only hooks get `GEMINI_SESSION_ID` (`:11`); Antigravity has no SessionStart at all, only `PreInvocation` (`:12`); newest-file discovery is wrong whenever two sessions are live (`:16-18`); Copilot in VS Code now runs on the CLI runtime (`:27-31`); the Claude VS Code extension pre-spawns phantom sessions (`:33-34`, handled by `prune_phantoms`, `docs/context-budget.md:856-863`). The consequence for §5: a clear-equivalent on another runtime is only usable by the loop if, after the reset, the new session id reaches a hook or the agent shell — Codex and Copilot CLI yes (if their reset fires their session-start hook, §5), Gemini hook-only, Antigravity by its first `PreInvocation`.

---

## 4. Subagents

**Effect of `/clear` on running background agents, workflows and shells.** The Claude Code facts are in §2. From this repo's side:

- A subagent's transcript lives under the *parent's* session directory (`<parent-artifact-dir>/<parent-uuid>/subagents/agent-*.jsonl`, `docs/context-budget.md:613-617`), and `children` sweeps by parent session id (`scripts/fleet.sh` `cmd_children`, `:136-155`). After `/clear` the parent has a new session id and a new directory, so a sweep from the cleared session finds **none** of the predecessor's children; they are the dead parent's, exactly as after a fresh process. The `.agent-dispatch` records are the recovery path (`docs/context-budget.md:679-684`).
- `PostToolUse` fires for a child's tool calls keyed to the parent id (backlog finding, `docs/template-workspace-backlog.html:240`), and the dispatcher routes sidechain firings to a `<sid>-sidechain` key so they do not consume the parent's escalation slot (`scripts/hooks/context-budget-hook.sh`, the `+chain` branch; `adapters.conf` claude row `payload:.transcript_path+chain`). If a background child survives the parent's `/clear` (§2 says whether it does), its firings would carry the *old* parent id with a transcript under the old directory — the hook would keep measuring a dead session's slot and could still SIGTERM `$PPID`, which is the live process. **The `Stop`/turn-end hook must check the record's current owner id, not just `staged.by`**, before any kill — a concrete spec item.
- The research's R-rules already forbid resume-across-rollover and demand records (`docs/context-budget.md:651-684`); the skill's step 3 "verify sub-agent-claimed outputs exist on disk" (`skills/session-rollover/SKILL.md:93-97`) and the `dispatch-list` drain check (`:673-676`) apply unchanged. **Rule for a clear-chain:** drain or checkpoint every open dispatch generation *before* `--clear`, because a child that is still running when the parent clears is orphaned the moment the parent id changes — neither worse nor better than a process exit, but faster, so easier to forget.

**Can children use a clear-style reset themselves?** No, and they do not need to. A child is a sidechain inside the parent's process; it has no TTY, no `/clear`, no hooks of its own (D1 applies twice over, `docs/context-budget.md:632-633`). Child rollover is by design "successor dispatch" — the parent checkpoints the child via the report file and dispatches `--gen N+1` fresh (R3, `:651-658`), and `ROLLOVER_NEEDED` is only ever a response (`:646-648`). A `/clear` in the parent is orthogonal to that: it is the *parent's* rollover. Neutral.

**Background shells.** `Bash run_in_background` tasks belong to the process; whether they survive `/clear` is a §2 fact. From the loop's side they are invisible (nothing in the record tracks them), so the skill's step 5 "State snapshot — running processes" (`skills/session-rollover/SKILL.md:157`) is the only carrier. A spec should say: list them in the launcher, or kill them before `--clear`.

---

## 5. Portability matrix

Per runtime, from primary docs (helper survey, 2026-10-15; `developers.openai.com/codex/*` now redirects to `learn.chatgpt.com/docs/*`). "Loop-usable" means: after the reset, the new session id reaches a hook or the agent shell *and* a turn-end hook exists, so the chain can rebind and end a turn (`scripts/hooks/context-budget-adapters.conf`; `work/runtime-session-identity/findings.md:9-15`).

| Runtime | Same-process clear | Session-start hook (event, id field) | Clear/new event exposed | Programmatic trigger | Headless + resume | Same-process handoff for the loop |
|---|---|---|---|---|---|---|
| **Claude Code CLI** | `/clear` (= `/reset`, `/new`) | `SessionStart`, `session_id` + `transcript_path` | Yes: `source: "clear"`, `SessionEnd reason: "clear"` | Only via Agent SDK `query()` `/clear` prompt (headless); none in the TUI | `claude -p --continue \| --resume <id> [--fork-session]` | **Attended: yes (today's `--clear`).** Unattended: only as an SDK-hosted runner, or pty injection (unsupported). |
| **Codex CLI** | `/new` ("fresh chat in the same CLI session"), `/clear`, `/fork` (new id) | `SessionStart`, `session_id` + `transcript_path` (https://learn.chatgpt.com/docs/hooks) | Yes: `SessionStart.source` ∈ `startup\|resume\|clear\|compact\|fork`; `SessionEnd.reason` is "always `other`" and fires only on archive/close/30-min idle | **Yes, headless:** app-server JSON-RPC `thread/start`, `thread/fork` (https://learn.chatgpt.com/docs/app-server); SDK `startThread()` (https://learn.chatgpt.com/docs/codex-sdk). Hook output cannot start a thread. | `codex exec … \| codex exec resume --last\|<id> \| codex exec fork <id>` (https://learn.chatgpt.com/docs/non-interactive-mode) | Attended: plausible (hooks fire `clear`; our codex row registers on `SessionStart`, `adapters.conf`) — **unverified live**; hook trust must be granted first (`docs/context-budget.md:813-817`). Unattended: app-server host, same shape as the Claude SDK route. Whether `/new` keeps MCP/approvals: not stated. |
| **Copilot CLI** | `/clear` = `/new` = `/reset` (`[PROMPT]`); `/restart` restores live sessions | `sessionStart`, `sessionId` (https://docs.github.com/en/copilot/reference/hooks-reference) | Partial: `sessionStart.source` ∈ `startup\|resume\|new`; `sessionEnd.reason` ∈ `complete\|error\|abort\|timeout\|user_exit` (no `clear`) | **Yes, headless:** SDK `createSession({sessionId})`, one client holding several sessions (https://docs.github.com/en/copilot/how-tos/copilot-sdk/features/session-persistence). No hook/config trigger. | `copilot -p … --resume[=id] \| --continue \| --session-id <uuid>` (https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) | Attended: plausible (our copilot row registers on `sessionStart` and SIGTERMs on `agentStop`) — **unverified live**; folder trust required (`docs/context-budget.md:821-823`). Whether `/new` writes a new `session-state/<id>/` dir: implied, **unverified**. |
| **Gemini CLI** | `/clear` ("start a new session"); `/compress`; `/chat save\|resume` (https://geminicli.com/docs/reference/commands/) | `SessionStart`, `session_id` + `transcript_path`; env `GEMINI_SESSION_ID` in hooks only (https://geminicli.com/docs/hooks/) | Yes: `SessionStart.source` ∈ `startup\|resume\|clear`; `SessionEnd.reason` ∈ `exit\|clear\|logout\|prompt_input_exit\|other` | **None documented**; no in-process SDK | `gemini -p … -r latest\|<n>\|<uuid>` (`-p` + `-r` together **unverified**) | **No for the loop today:** our gemini row has `register=agent`, no turn-end hook, chains unsupported (`docs/context-budget.md:780,798-800`); the shared telemetry log is not rotated by a reset (§6 item 10). Also superseded by Antigravity for this workspace (`findings.md:66`); the docs banner says the free tier moved to Antigravity CLI on 2026-06-18. |
| **Antigravity CLI** (`agy`) | not surveyed by the helper — **unverified** | `PreInvocation` only (no SessionStart), `conversationId` + `transcriptPath` (`findings.md:12`) | n/a | n/a | n/a | Attended only (no turn-end hook, `docs/context-budget.md:784`). |
| **OpenCode** | `/new` (= `/clear`), `ctrl+x n` (https://opencode.ai/docs/tui/) | **unverified** (not researched) | **unverified** | `opencode serve` + `--attach` (https://opencode.ai/docs/cli/) | `opencode run -c \| -s <id> [--fork]` | Our row: `session.idle:decide` turn-end via plugin, `register=agent`; a reset would need the plugin to re-register. **Unverified.** |
| **VS Code — Copilot Chat** | `/clear` ("start a new chat and archive the current one"), `/fork`; **New Chat** ⌘N = `workbench.action.chat.newChat` (https://code.visualstudio.com/docs/agents/reference/ai-features-cheat-sheet) | Copilot harness: same SDK hooks as Copilot CLI (B); Local harness: `SessionStart` with `source` "currently always `new`", `session_id`, `transcript_path` ("not stable") (https://code.visualstudio.com/docs/agents/reference/hooks-reference) | No distinct clear event; **no `SessionEnd`** in the Local harness | Command id only; `code` CLI has no `--command`; `vscode://agents/new` opens but does not submit (https://code.visualstudio.com/docs/configure/command-line). `workbench.action.chat.clearHistory` **unverified**. | `code chat "<prompt>"` only | **No.** No process to own, no turn-end, no external trigger. Today already `--emit` is refused on copilot-vscode ("detached by nature", `docs/context-budget.md:335`). |
| **VS Code — Claude Code extension** | `/clear` (subset of slash commands); **New Conversation** ⌘N (opt-in `enableNewConversationShortcut`) (https://code.claude.com/docs/en/vs-code) | Shares `~/.claude/settings.json` hooks with the CLI: `SessionStart source: clear`, `SessionEnd reason: clear` | Yes (same as CLI) | Deep link `vscode://anthropic.claude-code/open?prompt=…&session=<id>` (no session → fresh conversation); no hook-driven reset | `claude -p --resume <id>` (shared transcripts) | Attended: the CLI's `--clear` path should work in the panel (**unverified live**; note the phantom pre-spawned sessions, `findings.md:33-34`). Unattended: no. |
| **VS Code — Codex extension** | `chatgpt.newChat` ⌘N (**partially unverified**: the IDE commands page redirected) | Same trust store as the CLI; hooks apply after the first turn (`docs/context-budget.md:818-820`) | as Codex CLI | none external | n/a | Attended at best; **unverified**. |

**Reading the table.**

1. **Every CLI runtime has a same-process reset and a session-start hook that sees it** (Claude, Codex, Gemini: `source: clear`; Copilot: `source: new`). So an *attended* clear path is portable in principle to Codex and Copilot CLI with the hook-side registration this repo already ships (`adapters.conf` codex/copilot rows) — the pending-pid match in `bind_work_item` is runtime-agnostic (`scripts/context-budget.sh:788-795`), but `register` must know the pid (sandboxed Codex records `pid: null`, `findings.md:23`, `docs/context-budget.md:715-717`) — Codex would need another same-process key (e.g. the predecessor's thread id in the launch block, matched against `SessionStart`'s `source: clear` firing in the same process).
2. **No CLI runtime lets anything but a human or a pty driver issue the reset in the interactive TUI.** The programmatic routes (Claude Agent SDK, Codex app-server/SDK, Copilot SDK) all mean *hosting the session in a program*, i.e. an SDK-based runner replacing `claude`/`codex`/`copilot` as the supervisor's child. Gemini has none; VS Code agents have none reachable from outside.
3. **A fresh process is the only mechanism all runtimes share**, and the one the loop already supports for five of them (`scripts/launch-next-session.sh:396-403`).
4. **tmux/expect injection is supported nowhere** (helper search across all five runtimes' docs).

---

## 6. Current limitations — and what a `/clear` approach does to each

**Sources inventoried.** Open backlog cards: only two remain open — L85 (template-only suites fail in every instance, `docs/template-workspace-backlog.html:152`) and L86 (Antigravity IDE/app and Codex desktop app identity not yet probed, `:160`); the formerly open M16, L32, L33, M39 are in the archive (`docs/template-workspace-backlog-archive.html:780,1689,1705,925`). `docs/context-budget.md` → "Known limitations" (`:911-935`) and the refusal/"not supported" paths (`:331-344,566-580,724-731,797-804`). `work/runtime-session-identity/findings.md`.

| # | Limitation today | Where | `/clear` approach: removes / eases / worsens / neutral |
|---|---|---|---|
| 1 | **One owner per work item**: `owner_live` refusal; launcher/ledger assume a single writer; `--takeover` is the only override | `docs/context-budget.md:373-390`, `docs/work-directory-conventions.md:33-43`, `scripts/launch-next-session.sh:262-266` | **Neutral.** A `/clear` binding is `adopted` by the same pid (`scripts/context-budget.sh:847-850`) — one owner, new id. Concurrency is an independent change (below). |
| 2 | **One supervisor per item** (`supervisor_live`), one child at a time, chain cap 10 | `docs/context-budget.md:421-427,492-494` | Neutral; a clear-chain is still one process per item. |
| 3 | **Chains are Claude Code only (verified)**; codex/copilot-cli unverified; gemini, copilot-vscode, antigravity attended-only (no turn-end hook) | `docs/context-budget.md:796-804` | **Worsens portability** unless each runtime has a programmatic reset *and* a session-start hook (§5). A fresh process is the only mechanism every CLI runtime shares. |
| 4 | **`--clear` is attended-only** ("an agent cannot press `/clear`") | `skills/session-rollover/SKILL.md:248`, `docs/template-adr/0009-...md:96-97` | **This is the limitation under study.** Removed only if §2 finds a sanctioned trigger or §3.3's pty driver is accepted. |
| 5 | **A fresh process re-authenticates and re-connects MCP** — the two observed spawn-path failures (`Not logged in` parked on OAuth; MCP startup race mis-diagnosed three sessions running) | `docs/template-adr/0009-...md:30-40`; `logout` verdict `docs/context-budget.md:469-470` | **Removes** for the ordinary rollover (same person, runtime, cwd). This is the strongest argument for the work. |
| 6 | **A rollover cannot change model / MCP fragment / permission mode** on the clear path | `docs/template-adr/0009-...md:66-71` | Inherent to `/clear`; the spawn path stays for those cases (TADR-0009's selection rule). Neutral if both paths coexist. |
| 7 | **A wedged CLI or MCP state is not fixed by `/clear`** | `docs/template-adr/0009-...md:91-93` | Worsens slightly for a hands-off chain: today every session is a fresh process, so a wedge heals at the next rollover; a clear-chain needs a "spawn instead" escape (e.g. after N failed rebinds). |
| 8 | **Hook check at most once per minute**; a huge tool result can overshoot STOP between checks | `docs/context-budget.md:933-934` | Neutral. |
| 9 | **WARN push swallowed by a busy child** winning the throttle race | `docs/template-workspace-backlog.html:240` (L32 archived) | Neutral (same hook path). |
| 10 | **Gemini: shared workspace telemetry log is single-session**; a successor's first check may read the predecessor's last entry | `docs/context-budget.md:724-731,780` | Neutral for Claude; for a Gemini clear-equivalent the log is *not* rotated by a reset, so it would worsen (the counts carry over). |
| 11 | **Auto-detect prefers env evidence then newest artifact**; with several runtimes active, pass `--runtime` | `docs/context-budget.md:930-932` | Neutral. |
| 12 | **Newest-file discovery is wrong with two live sessions**; `ambiguous_artifact` refuses instead | `findings.md:16-18`, `docs/context-budget.md:848-852` | Neutral for Claude (`CLAUDE_CODE_SESSION_ID` is exported, `probes/claude-cli.md:8-12`). Important for item 1 below. |
| 13 | **Phantom records** from the Claude VS Code extension | `findings.md:33-34`, `docs/context-budget.md:856-863` | Neutral. |
| 14 | **`register` after a stop-door `close` re-binds the closed number (M39)** | archive `:925` | Neutral. |
| 15 | **Measurement right after `/clear` reads near zero** until the first response | `docs/template-adr/0009-...md:17-19` | Specific to `/clear`; the watchdog's `blocked` page (past STOP, nothing staged) would never misfire from it, but `min-lifetime`-style guards must not read a zero as "no own measurement". Mild. |
| 16 | **Transcripts are not written under an inherited `CLAUDE_CODE_CHILD_SESSION`** (nested launches) | `stage2-probes.md:83-85` | Neutral; same for both paths. |
| 17 | **Supervisor edits take effect one invocation late** | `docs/context-budget.md:518-522` | Worsens: a clear-chain supervisor lives for the whole chain *and* the process lives for the whole chain, so a fix to either lands only after a full restart. |
| 18 | Antigravity IDE/app, Codex desktop app identity unprobed (L86) | `docs/template-workspace-backlog.html:160` | Neutral. |

### The headline question: can several sessions be active in one work item at once?

**Today: no, by design.** One owner per item (`docs/context-budget.md:373-390`); the launcher/ledger REPLACE/APPEND semantics "assume a single writer" (`docs/work-directory-conventions.md:33-43`); the record has one `session` block and one `seq` (`docs/context-budget.md:282-289`); the supervisor runs one child (`:449-455`). A second session that registers against a live owner is *measured but not owning* (`register: reason=owner_live`, `scripts/context-budget.sh:851-852`) and the launcher refuses `owner_live`/`not_owner`. The sanctioned shape for parallel work inside one item is **subagents under the one owner** — a plan node's `parallel` field counts subagents in flight inside the node (`docs/plans.md:64`), `isolated: yes` gives a child its own worktree and branch (`:68`), and the dispatch records make the fleet survive the owner's rollover (`docs/context-budget.md:659-684`). Sibling *work items* run concurrently without conflict (TADR-0004's model: session-keyed registry, per-item records, `docs/template-adr/0004-...md:25-32`).

**What true multi-session-per-item would need** (independent of `/clear`):

1. **Record: `session` becomes `sessions[]`** with a lane or role per entry, and `seq` becomes per-lane (or a lane-qualified number like `12.b`) — the ledger heading parser and the `ledger_seq_mismatch` gate (`docs/work-directory-conventions.md:85-110`) both key on one number. Every writer goes through `session_record_update` CAS under a directory lock (`docs/context-budget.md:278-280`), which is already safe for concurrent writers; the schema is not.
2. **Ledger: per-session blocks already exist** (one block per number); concurrent sessions would need a merge-safe append — two sessions prepending at the top at once is a textual race under git, not a lock problem. Per-lane ledgers (`handoff.<lane>.md`) or one block per node are the obvious shapes.
3. **Launcher ownership: the launcher is one front.** Two active sessions have two fronts. Either per-lane launchers, or the plan becomes the launcher (the `<!-- plan:begin position -->` block is already machine-written, `skills/session-rollover/SKILL.md:158-160`) and each session's "front" is its claimed node.
4. **Plan-node claims with locking.** `plan.sh start` writes `status: doing` + the session number into the node file (`scripts/plan.sh:520-522`) with no CAS; two sessions can `start` the same frontier node. A claim needs a compare-and-set on the node's `status`, the same lock the record uses. The frontier verb already lists every ready node (`:420`), so the *scheduling* half exists.
5. **Supervisor: one child per lane**, or one supervisor per lane with `supervisor_live` keyed per lane; verdicts and the stall guard per lane.
6. **Identity under concurrency** is already solved for Claude, Codex and Copilot CLI when their id var is set (`findings.md:16-17`) and refused as ambiguous otherwise — this is the one piece that is done.

**Does `/clear` change any of it?** No. Items 1–5 are about *how many owners a record admits*, not *how a session is reset*. A clear-chain is strictly one-process-one-owner. If anything, concurrency argues *against* same-process resets: with N lanes you want N processes you can kill, spawn and supervise independently. The fair summary for the user: multiple active sessions per work item is a separate, larger change (record schema + ledger/launcher shape + node claims + per-lane supervision), and the existing answer for parallelism — isolated subagents on parallel frontier nodes under one owner — covers most of what people want from it without touching ownership.

---

## 7. Verdict

**Verdict: PARTIAL.** Go for a narrow, attended-first slice; no-go for an unattended `/clear`-driven chain on the interactive CLIs; the concurrency question is an independent work item.

### Why not a full go

1. **There is no sanctioned trigger inside the TUI.** Hooks cannot clear (§2.2), there is no keybinding (§2.3), and the vendors document nothing for driving the TUI from outside (§5). The one thing that works — pty injection — is what our own probe used and what no vendor supports. Building the template's unattended loop on typing into a TUI is a maintenance liability of exactly the kind the adapter table was created to contain (`docs/context-budget.md:692-697`): every TUI redraw, permission dialog, trust prompt or idle nudge (2.1.84) is a new way to type `/clear` into the wrong place.
2. **The documented programmatic resets are all "host the session yourself"** (Claude Agent SDK `/clear` → `conversation_reset`; Codex app-server `thread/start`; Copilot SDK `createSession`). That is a different product from `session-loop.sh` — an SDK runner per runtime, no TUI, a new identity story (the SDK's `session_id` vs the hook's, §2.1 discrepancy), and nothing for Gemini or the VS Code agents. It may be the right long-term shape for hands-off chains (the supervisor already "never talks to a model" and would gain full control of turns), but it is not "make `/clear` drive the loop"; it is "replace the child".
3. **The gains are real but bounded.** Same-process continuity removes the two observed spawn-path failures (re-auth, MCP startup race; §6 item 5) and the startup wall-clock, not tokens (§1: the next prompt pays the same ~27K either way). The spawn path is already verified and portable; the `logout` verdict already catches the auth failure (`docs/context-budget.md:469-470`).
4. **Portability, a hard constraint of this work item, is where `/clear` is weakest** (§5: unattended = none of the five; attended = Claude verified, Codex/Copilot plausible-unverified, Gemini/VS Code no).

### What is worth doing (the "go" half)

**A. Harden the attended clear path (Claude Code; small).** Cost: ~1 session; risk: low.
- Settle whether the cleared TUI session starts a turn on the seeded context alone (§2.2 open question). If not, correct the skill and TADR-0009 ("`/clear`, then type `go`"). `initialUserMessage` cannot do it in the TUI (`-p` only, verified). Set `sessionTitle` = `<item> #<n>` on the clear binding if the field takes effect interactively (the docs say "SessionStart also accepts … `sessionTitle`"; interactive effect **unverified**). That would fix TADR-0009's cosmetic "old title" consequence.
- `SessionEnd` budget: keep `release` under the shared 1.5 s budget, or give the SessionEnd hook its own `timeout` in `.claude/settings.json` (raises the budget, verified). Confirm that `release` then `register` ordering is race-free (§3.1).
- Drain rule: `dispatch-list` must be clean (or every open generation checkpointed) before `--clear`; background shells listed or killed (§4).
- Turn-end hook: check the record's *current* owner id before any SIGTERM, since background agents and their hook firings survive `/clear` (§4).
- Optional: a `PreCompact` hook that blocks `auto` compaction while a work item is bound (§2.2) — independent of `/clear` but the cheapest protection the docs offer for "rollover beats compaction".
- Let the interactive supervisor accept a `/clear` rollover: in `--loop-mode interactive` the "press Enter" pause becomes "press `/clear` (or Enter for a fresh process)", with the supervisor watching the record for the rebind instead of waiting for the exit (§3.3, interactive branch only). This gives the attended chain continuity without any injection.

**B. A time-boxed spike, not a build (Claude only): headless same-process reset.** Cost: ≤ 1 session; risk: none to the loop. Run `claude -p --input-format stream-json --output-format stream-json` with the committed hooks, send a `/clear` user message, and record: does `conversation_reset` arrive, does a SessionStart `initialUserMessage` seed the post-clear first turn (it is documented for `-p`), do `SessionEnd(clear)`/`SessionStart(clear)` fire, does `session_id` rotate (the §2.1 discrepancy), does `register` rebind by pid, is the first post-clear check near zero. The result decides whether an SDK-hosted hands-off runner is a future work item; nothing in the loop changes until then.

**C. Explicitly not doing:** pty/tmux/expect injection in `session-loop.sh`; `/clear`-based chains on Codex/Copilot/Gemini/VS Code; a supervisor rewrite to the event-driven model of §3.3 for hands-off mode.

**D. Concurrency (several active sessions per work item)** is independent of all of the above (§6). If the user wants it, it is its own research+spec: record schema (`sessions[]`, per-lane `seq`), ledger/launcher per lane or per node, node claims with CAS, per-lane supervision. The cheap interim answer is already in the design: parallel frontier nodes as isolated subagents under one owner.

### What a spec for A (+B) should cover

Per `docs/agents/issue-tracker.md` → "Spec conventions" (not read here; the orchestrator should fit the shape): goal and non-goals (C above, verbatim); the `SessionStart` output contract (`initialUserMessage`, `sessionTitle`) and its fallback when the field is absent (older CLI); the `SessionEnd` timing budget; the turn-end owner check; the drain rule and its refusal code (`children_open`?) at `--clear`; the interactive-supervisor watch mode (record transitions, new page tokens `clear_sent`/`clear_unbound`, verdict mapping); test cases (fixtures for `SessionStart source=clear` payloads with and without rotation; `test-launch-next-session.sh` L-series extended; `test-session-loop.sh` interactive-clear case); the spike protocol for B and its pass/fail record; docs touched (`docs/context-budget.md` launcher table and support matrix, `skills/session-rollover/SKILL.md:245-254`, TADR-0009 amendment); open questions (the §2.1 id discrepancy; CLAUDE.md re-read; permissions carry-over).

---

## Key claims (as handed to the orchestrator)

Load-bearing claims the orchestrator should spot-check (repo claims by reading the lines; external ones by opening the URL):

1. `/clear` rotates session id and transcript, with `SessionEnd(reason=clear)` then `SessionStart(source=clear)` — `work/template-improvement-review/evaluation/stage2-probes.md:47-85` (repo probe, `claude` 2.1.272).
2. That probe drove `/clear` with `expect`, i.e. a pty owner can press it — `stage2-probes.md:49-51`.
3. "An agent cannot press `/clear`" is the stated blocker — `skills/session-rollover/SKILL.md:248`; TADR-0009 "no tool or hook can issue `/clear`" — `docs/template-adr/0009-clear-based-rollover-relaunch.md:96-97`.
4. The clear path binds by pid + start time and prints the pending prompt as hook stdout — `scripts/context-budget.sh:788-795,812-817,865-868,877`; the launcher writes `launch.pending` and refuses under a live supervisor — `scripts/launch-next-session.sh:195-197,279-285,422-423`.
5. The supervisor's verdicts require the child to *exit* and the `Stop` hook SIGTERMs the child when `staged.by` is its id — `docs/context-budget.md:457-487`; `scripts/hooks/context-budget-hook-lib.sh:137-142` (`kill -TERM "$PPID"`).
6. `SessionStart` output supports `initialUserMessage` (and `sessionTitle`, `reloadSkills`, `watchPaths`) — hooks page. **Verified: `initialUserMessage` is documented for `-p` mode only.**
7. SessionEnd hooks share a 1.5 s budget; per-hook `timeout` raises it (≤ 60 s); `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` overrides — hooks page; changelog 2.1.74, 2.1.268.
8. Background bash tasks and background agents survive `/clear` — changelog 2.1.72; MCP servers/plugins retained — changelog 2.1.136 (https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md).
9. No hook output or keybinding can trigger `/clear`; `PreCompact` can *block* compaction (exit 2 / `decision: block`) — hooks page "PreCompact"; https://code.claude.com/docs/en/keybindings (no clear-conversation action; double-press shortcut removed 2.1.238).
10. Agent SDK: a `/clear` prompt in `query()` yields `SDKConversationResetMessage` with `new_conversation_id`, "replaced without ending the session" (CLI ≥ 2.1.203) — https://code.claude.com/docs/en/agent-sdk/typescript. The stream-json CLI equivalent is **unverified**.
11. Codex: `/new` is a fresh chat in the same CLI session; hooks fire `SessionStart source: clear`; app-server `thread/start` is a documented in-process new thread — https://learn.chatgpt.com/docs/cli/slash-commands, https://learn.chatgpt.com/docs/hooks, https://learn.chatgpt.com/docs/app-server.
12. Copilot CLI: `/clear`=`/new`=`/reset`; `sessionStart.source ∈ startup|resume|new`; `sessionEnd.reason` has no `clear` — https://docs.github.com/en/copilot/reference/hooks-reference, https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference.
13. Gemini CLI: `/clear` fires `SessionEnd reason: clear` + `SessionStart source: clear`; no programmatic trigger — https://geminicli.com/docs/hooks/, https://github.com/google-gemini/gemini-cli/blob/main/docs/hooks/reference.md.
14. VS Code Copilot Chat Local harness: `SessionStart.source` is always `new`, no `SessionEnd`; `code` CLI has no `--command` — https://code.visualstudio.com/docs/agents/reference/hooks-reference, https://code.visualstudio.com/docs/configure/command-line.
15. Only two backlog cards are open (L85, L86) — `docs/template-workspace-backlog.html:152,160`; one owner per item and single-writer launcher/ledger — `docs/context-budget.md:373-390`, `docs/work-directory-conventions.md:33-43`; `plan.sh start` writes `doing` with no compare-and-set — `scripts/plan.sh:520-522`.

---

## Verification

The orchestrating session checked these claims against the repo and primary sources on 2026-10-15. It did not live-run any runtime.

**Repo claims — read at the cited lines:**

| Claim | Result |
|---|---|
| `/clear` rotates the session id; `SessionEnd(clear)` then `SessionStart(clear)` on the new id; probe driven by `expect` | Confirmed — `work/template-improvement-review/evaluation/stage2-probes.md:47-62` |
| Skill states "An agent cannot press `/clear`" | Confirmed — `skills/session-rollover/SKILL.md:248` |
| TADR-0009 "no tool or hook can issue `/clear`" | Confirmed, **citation corrected** from `:86-88` to `:96-97` |
| Clear path binds a pending launch by pid + start time; same pid + new id → `adopted`; prompt printed on stdout | Confirmed — `scripts/context-budget.sh:790-795`, `:847-850`, `:877` |
| `--clear` refused off claude; launches refused under a live supervisor unless `--emit` | Confirmed — `scripts/launch-next-session.sh:184-186`, `:195-197` |
| Turn-end hook SIGTERMs `$PPID` | Confirmed — `scripts/hooks/context-budget-hook-lib.sh:141` |
| `release` is a no-op for a non-owner | Confirmed — `scripts/context-budget.sh` `release` (`reason=not_owner`, returns 1, writes nothing) |
| `plan.sh start` sets `doing` with no compare-and-set | Confirmed — `fm_set "$NODE_FILE" status doing` with no lock or check (`scripts/plan.sh` ~`:520`) |
| Only two live backlog cards (L85, L86) | Confirmed — the only `<h3><span class="id">` cards in `docs/template-workspace-backlog.html` |

**External claims — fetched and grepped:**

| Claim | Result |
|---|---|
| SessionStart `source` ∈ `startup\|resume\|clear\|compact\|fork`; SessionEnd reasons include `clear` | Confirmed — https://code.claude.com/docs/en/hooks |
| `initialUserMessage` makes the cleared session start working | **Corrected** — documented for `-p` (non-interactive) only; does not apply to the TUI path. §2.2 and §7 A rewritten |
| SessionEnd 1.5 s timeout + env override | Confirmed, sharpened: shared 1.5 s budget; per-hook `timeout` raises it to ≤ 60 s; `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` (changelog 2.1.74, 2.1.268) |
| `PreCompact` can block compaction | Confirmed — exit-code table "Blocks compaction"; `decision: "block"` |
| No hook output triggers `/clear` or compaction | Consistent with the hooks page (no such output field); a negative claim, so "not found" rather than proven |
| Background agent/bash tasks survive `/clear` | Confirmed — changelog 2.1.72 |
| MCP servers/plugins/connectors survive `/clear` (VS Code, JetBrains, SDK fix) | Confirmed — changelog 2.1.136; `CLAUDE_ENV_FILE` re-applied after `/clear` — same release |
| SDK `/clear` prompt → `conversation_reset`, "replaced without ending the session" | Confirmed — https://code.claude.com/docs/en/agent-sdk/typescript; type carries `session_id` **and** `new_conversation_id`, so the §2.1 discrepancy is real in the docs |
| Copilot CLI `sessionStart.source ∈ startup\|resume\|new` | Confirmed — https://docs.github.com/en/copilot/reference/hooks-reference |
| Codex `SessionStart.source` includes `clear`; `SessionEnd.reason` always `other` | Confirmed — https://learn.chatgpt.com/docs/hooks |

**Not checked by the orchestrator** (still on the subagent's word, citations given): the video summary (§1); Gemini CLI, OpenCode, VS Code Copilot Chat and Codex-extension rows of §5; the rest of the changelog items in §2.3. Everything already marked **unverified** in the body stays unverified.

**Effect on the verdict:** none on PARTIAL. The correction removes one item from the "go" half: `initialUserMessage` cannot make the attended TUI path keystroke-only. It adds one open question: does the cleared session act on seeded context without a typed message? It also strengthens the headless spike, where `initialUserMessage` does apply.
