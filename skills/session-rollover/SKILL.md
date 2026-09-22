---
name: session-rollover
description: Use when the context budget hits WARN/STOP (hook message, `context-budget.sh` exit code 1/2, or the user asks) to roll work over to a fresh session via a deliberate, pruned handoff instead of uncontrolled automatic compaction. Rollover = reflect (route conversation-only learnings to disk) + flush (make disk fully current) + handoff (backward-looking handoff.md, forward-looking next-session.md) + the launcher (which checks both files, then launches or stages the successor).
---

# session-rollover

The session is approaching or past the **dumb zone** — the point
(`CONTEXT_DUMB_ZONE_TOKENS` in `context-budget.env`, currently 150K tokens)
where LLM quality degrades regardless of advertised window size. Roll the work
over to a fresh session *deliberately*: decide what the next session loads,
instead of letting automatic compaction decide.

Runtime-neutral: any agent runtime that can run shell commands and edit files
(Claude Code, Codex, Copilot CLI, Copilot in VS Code, Gemini CLI) can follow
these steps. Every load-bearing step is a script with an exit code: `0` pass,
`4` refused with `reason=<code>` and the one command that repairs it. You do
not need to remember the rules — run the script and read the code.
`docs/context-budget.md` is the reference for other occasions.

## When to invoke (trigger policy: WARN asks, STOP goes)

- **STOP** (tokens ≥ `CONTEXT_DUMB_ZONE_TOKENS`, exit code 2, or a hook STOP
  message): finish only the current *atomic step* — nothing new — then run this
  **without asking**. Mid-discussion, the atomic step is the current exchange:
  answer the user's message first, then roll over, carrying the live question
  verbatim into the launcher's START HERE so the successor re-poses it.
- **WARN** (exit code 1, or a hook WARN message): finish the current *work unit*
  **only if it is small** (a doc edit, a review pass, bookkeeping — not an
  implement+test+commit unit). Then: under `ROLLOVER_RELAUNCH=manual` or `off`
  ask the user "roll over now?"; under `auto` roll over without asking. If the
  user says not to, write ahead through the WARN→STOP grace window (the
  standing discipline below, at every natural pause) so the eventual STOP
  rollover is cheap. In this workspace's heavy workflows the procedure costs
  ~20K tokens (median), so WARN leaves room for one small closing unit at most.
- **Pre-flight at work-unit boundaries:** before *starting* a major unit
  (implement+test+commit-scale work — observed cost 50–130K tokens), run
  `record` and check headroom. If current tokens + the unit's likely cost
  exceed the STOP threshold, roll over **first**.
- The user asks to roll over / hand off to a fresh session.

**Write-ahead is the standing discipline, not a WARN-time fallback:** route
learnings and decisions to their disk homes at incident time, and bring the
ledger/launcher current at each work-unit boundary, so steps 2–3 below are a
sweep for what slipped, not the primary capture.

Never roll over mid-atomic-step (half-written file, unresolved merge, mid-migration).

**Hook-less cadence fallback:** in runtimes with no in-band WARN/STOP push, the
signal only arrives when you run `record` — in an extended discussion, run
`scripts/context-budget.sh record` every ~10 exchanges so STOP can't pass unnoticed.

## Which boundary skill? (first yes wins)

1. Context-budget WARN/STOP signal (hook message, or `context-budget.sh` exit code
   1/2)? → `session-rollover` (this skill).
2. Deliberate end of a work chunk, budget OK? → `checkpoint` (it ends the session
   through the stop door, `scripts/context-budget.sh close`).
3. Both true? → `session-rollover` — measurement wins; fold `checkpoint`'s step-1
   reconciliation (backlog, memory, docs, promotions) into steps 2–3 below.

## Steps

1. **Record the start, look at the state.**
   `scripts/context-budget.sh record --label "rollover start: <trigger>"`, then
   `git status --short` (untracked/uncommitted `work/` state that never gets
   committed silently strands the next session) and
   `grep -n '^# Session Handoff' work/<project>/handoff.md`. If the ledger holds
   more than two blocks, move the older ones to the top of
   `work/<project>/handoff-archive.md` (newest-on-top there too) — you own the
   archive step. Your own session number is the one in your bootstrap prompt;
   the record (`work/<project>/session-state.json`, field `seq`) holds the same
   number, and `scripts/launch-next-session.sh <project> --check` will tell you
   if the two files you are about to write disagree with it.

2. **Reflect — route conversation-only learnings to disk.** Anything learned this
   session that lives only in conversation is unrecoverable after rollover. Route
   each item using the three-tier rule in `CONTEXT.md` → "Recording new learnings":
   setup-time/environment → `scripts/setup.sh` / `scripts/check-tooling.sh` /
   `.env.example` / `docs/workspace-setup.md`; operational knowledge →
   `docs/operational-knowledge.md` (distilled anchor in `CONTEXT.md` only if
   broadly load-bearing); code-pointer learnings → the relevant doc/skill WITH a
   `repo/path:line` (or symbol) pointer. Decisions with a rejected alternative →
   `work/<project>/decisions.md` (the `decision-log` skill). Also update, where
   the session produced them: glossary rows, skill corrections, repo-context
   docs. For observations not obviously durable, park each as a one-line entry
   under `Learnings:` in the handoff block. A parked learning is promoted to a
   durable home the *second* time it bites (grep `handoff*.md` for a prior
   strike); single events die in the archive — the right fate for them.

3. **Flush — make disk fully current.** Update state/tracker files the session was
   maintaining; commit per convention or explicitly note uncommitted work in the
   handoff; verify any sub-agent-claimed outputs actually exist on disk
   (summaries are hints, not facts). (No-git workspace: saving the files IS the
   flush.)

4. **Write the new handoff block** — insert it in `work/<project>/handoff.md`
   directly below the PURPOSE comment, above the block(s) already there. Its
   heading carries **your own** session number (`# Session Handoff — <N> (<date>)`);
   the launcher refuses `ledger_seq_mismatch` if it does not. If your edit
   anchors on the previous block's `# Session Handoff` header line, your
   replacement text must END with that same header line — dropping it silently
   merges the old block into yours. **Verify the comment actually closes where
   you think it does** — a prior rollover can leave a block jammed *inside* the
   PURPOSE comment; grep `^# Session Handoff —` and `^-->` and check their line
   order before inserting. `scripts/check-ledger.py work/<project>` catches the
   symptom.
   *Backward-looking*: what happened, what shipped, where things stand. Use the
   document structure from `skills/handoff/SKILL.md` (summary, repos worked on,
   decisions, current state, open questions, next steps, key files). Contract:
   reference artifacts by path/URL (never duplicate their content); a
   **suggested skills** section for the next session; optional `Learnings:`
   line-list (step 2); redact secrets/PII.

5. **Write `work/<project>/next-session.md`** — *forward-looking and deliberately
   pruned*, REPLACING the old content (the launcher refuses `launcher_unchanged`
   if the file's hash is what it was when you registered):
   - **Mission** — the goal, one paragraph.
   - **Read these, in order** — the *smallest sufficient* set of file pointers.
   - **Do NOT reload** — settled side quests and dead ends, each with a one-line
     why, so the next session doesn't re-litigate them.
   - **State snapshot** — branch, uncommitted work, running processes, open items.
   - **First actions** — step 1 is always
     `scripts/context-budget.sh register --project <project>` (the successor
     started by the launcher is already bound by the env pair; an explicit
     register is harmless and is the only way an ad-hoc start binds); then the
     concrete next steps. **Anything mandatory goes here, not only in Mission** —
     the bootstrap prompt sends the successor to this block.

   Under `handsoff` mode the launcher must carry only **position** — "ticket 4 of
   9, 3 done" against a named spec, plan, or ticket path. Over a 10-session
   unattended chain a re-narrated mission is a telephone game; disk anchors facts
   but not intent.

   **If the mission needs the user, say what the successor does with nobody
   there.** Write both halves: a **no-human-in-the-loop** clause — what to do
   unattended (prepare the material, commit it, stop with the question still
   open) versus what must wait for a person — and, when the mission *is* the
   conversation, `ROLLOVER_RELAUNCH=off` in `work/<project>/context-budget.env`
   (or `manual` if a human is watching), so the rollover hands back a
   paste-ready prompt instead of launching a successor into a question only a
   person can answer.

6. **Run the launcher.** It checks both files, advances the number, and launches
   or stages the successor in one atomic write to the record. First:

   ```sh
   scripts/launch-next-session.sh <project> --check
   ```

   Exit 0 means every gate passes. Exit 4 prints `refused reason=<code>` and the
   fix; the codes you can meet here, in the order they are checked:

   | Code | Meaning | Fix |
   | --- | --- | --- |
   | `chain_closed` | a session ended this chain on purpose | `scripts/session-loop.sh <project> --reopen` (a human's call) |
   | `supervised_stage_only` | a supervisor is live — a supervised chain is staged, never launched | use `--emit` (below) |
   | `no_supervisor` | you were started by a supervisor but none is live now | start one, or roll over attached; from a sub-agent's shell, unset the four `TF_SESSION_*` variables — they are inherited from the parent's chain |
   | `owner_live` | another live session owns the item | roll over from it, or `scripts/context-budget.sh register --project <project> --takeover` |
   | `not_owner` | you never registered against this item, or already rolled over | `scripts/context-budget.sh register --project <project>` |
   | `worktree_unsynced` | invoked from a worktree with uncommitted/unpushed `work/<project>/` changes | commit and push first |
   | `launcher_stale` | git holds a newer `next-session.md` than this checkout | merge/pull it, or `--skip-freshness` |
   | `launcher_unchanged` | step 5 not done | write the successor's launcher |
   | `ledger_shape` / `ledger_seq_mismatch` | step 4 not done, or the top block is not yours | fix the ledger block |

   Then decide whether you are supervised — **from disk, not from the
   environment** (a forked agent does not inherit the env; the query reads the
   record's `chain.supervisor` and checks the process is alive):

   ```sh
   scripts/context-budget.sh supervised --project <project>
   ```

   | Exit | Meaning | What you do |
   |---|---|---|
   | 0 | supervised | **stage** — `--emit`; do not launch |
   | 1 | not supervised | launch: `--clear` (same process, preferred) or a plain call (fresh process) |
   | 2 | ambiguous | **stage anyway** (a spurious staged command is harmless, a missing one strands the chain), and say so in the handoff |

   Exit 3 means the query itself was malformed; fix it and ask again. The
   launcher runs the same query and refuses `supervised_stage_only` on exit 0
   only, so getting this wrong costs one turn and a loud error, never a forked
   chain.

   **Supervised (stage).** Record completion first —
   `scripts/context-budget.sh record --label "rollover complete: <project>"` —
   because the turn-end hook ends your session at the end of the `--emit` turn,
   so nothing sequenced after staging would run. Then:

   ```sh
   scripts/launch-next-session.sh <project> --emit \
     --loop-mode <interactive|handsoff> --loop-reason "<why you rolled>"
   ```

   **This is the last thing you do.** `--emit` writes the successor's command
   into the record's `staged` block (and prints it as `cmd: …`); the supervisor
   consumes it, and your runtime's turn-end hook sees `staged.by` is you and
   ends your session at the turn boundary. There is no sentinel, no
   confirmation step, nothing to write afterwards. Choose `--loop-mode` by what
   the moment is: `interactive` — you were mid-conversation with a human; the
   successor re-poses the open question (carry it **verbatim** in the launcher)
   and the supervisor waits for Enter between sessions; `handsoff` — you were
   mid-execution; the launcher carries only *position*. A human `touch
   work/<project>/.hands-off` or `.interactive` overrides you; do not check for
   those files yourself.

   **Not supervised — `--clear` (Claude Code only, same process).**
   `scripts/launch-next-session.sh <project> --clear` puts the bootstrap prompt
   into the record's `launch.pending` with this process's pid, and tells you to
   press `/clear`. **An agent cannot press `/clear`** — say so to the user; that
   keystroke is the one manual step. On `/clear` the `SessionStart` hook's
   `register` matches the pid, binds the new session id to the open launch, and
   prints the prompt into the cleared context: the human presses `/clear` and
   types nothing. Keeps the login and the connected MCP servers. Refused
   `runtime_path_unsupported` off claude or when your registration recorded no
   pid.

   **Not supervised — a fresh process.** `scripts/launch-next-session.sh <project>`
   (with `--runtime <rt>` to hand the work to another runtime, or when the
   successor needs a different MCP fragment — a running session cannot attach a
   new server). Under `ROLLOVER_RELAUNCH=off`, or from a tool shell (no
   terminal), it prints the ready-to-run line (`run: TF_SESSION_PROJECT=<p>
   TF_SESSION_SEQ=<n> claude …`) instead of executing it; tell the user where it
   is. **A committed `ROLLOVER_RELAUNCH=auto` IS your authorization to launch
   the successor. Do not ask for permission.** Before concluding you *cannot*
   launch, run `--dry-run` and read what it prints — a believed blocker is not a
   blocker until the dry-run confirms it. "I need input from the user" is
   expressed by rolling over (interactive mode under a supervisor; the question
   verbatim in the launcher's First actions otherwise), never by declining to
   launch, which burns the handoff you just wrote.

   Either path prints the bootstrap prompt, which is the whole handoff if
   nothing was launched:

   > Work item <project> - rollover session #N+1. Read
   > `work/<project>/next-session.md` and continue from **First actions**.

### Signals you can meet while running this rollover

- **`successor: NOT STAGED` in your own `record` output** — you are under a
  live supervisor, at WARN or STOP, and step 6 has not staged. Stage with the
  command the message prints on the next line, or quit deliberately to end the
  chain (a correct ending, not a fault — but one-way: the supervisor refuses to
  run that item again until someone passes `--reopen`).
- **`refused reason=not_owner` at `--emit` after a resume** — a resumed
  conversation (IDE restart, `--resume`) gets a NEW session id, and if the old
  one already staged or launched, the record's owner slot is open. Whoever
  registers against it becomes that session (no number is spent): run
  `scripts/context-budget.sh register --project <project>` and continue from
  the launcher file, or let the staged successor run. Never re-roll on top.

Full signal list, including the pages a human gets while you are running:
`docs/context-budget.md` → "What the chain tells you".

## Guardrails

- **Specialized workflow state files win.** If a skill (onboard-repo, rlm, …) keeps
  its own state/handoff files, they stay authoritative — so **update THOSE as the
  source of truth** before you write the rollover artifacts, and keep
  `handoff.md`/`next-session.md` as thin pointers to them, never a fork of their
  content.
- Prefer **file pointers over content summaries** — a summary spends the next
  session's budget on possibly-stale prose; a pointer lets it demand-load.
- **No secrets** in any rollover artifact.
- If no `work/<project>/` directory fits the current work, ask the user where
  to persist rather than inventing a location (per CONTEXT.md content-boundary
  rules).
- **Never edit `work/<project>/session-state.json` by hand.** The launcher,
  `register`, `release`/`close` and the supervisor are its only writers; a
  hand edit is how a chain ends up refusing `staged_invalid`.

## Verification

- `scripts/launch-next-session.sh <project> --check` exits 0 — the one check
  that covers the ledger block, the launcher file and ownership together.
- `grep -n '^# Session Handoff' work/<project>/handoff.md` shows at most 2
  blocks, yours on top with today's date and **your own** number.
- `scripts/check-ledger.py work/<project>` exits 0 (a heading swallowed by an
  unclosed purpose comment, or filed out of order, has reached a live ledger).
- The launcher was REPLACED, not appended: `next-session.md` describes only the
  next session's mission.

## Outputs

- Ledger entries bracketing the rollover (`.context-budget/context-ledger.jsonl`);
  learnings routed; disk fully current.
- `work/<project>/handoff.md` and `next-session.md`; the record advanced
  (`seq` + 1, `launch.predecessor` = you, `rolled_over`).
- The successor: staged (`staged` in the record), pending a `/clear`, running
  attached, or a paste-ready prompt.

End by telling the user how the successor starts (don't `/compact` — rollover
replaces compaction): under a supervisor, that it starts on its own; for
`--clear`, that they press `/clear` and the prompt is seeded for them; for a
fresh process, the terminal it runs in, or the printed `run:` line / pasted
prompt if nothing was launched.
