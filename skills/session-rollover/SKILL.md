---
name: session-rollover
description: Use when the context budget hits WARN/STOP (hook message, `context-budget.sh` exit code 1/2, or the user asks) to roll work over to a fresh session via a deliberate, pruned handoff instead of uncontrolled automatic compaction. Rollover = reflect (route conversation-only learnings to disk) + flush (make disk fully current) + handoff (backward-looking handoff.md, forward-looking next-session.md) + bootstrap prompt.
---

# session-rollover

The session is approaching or past the **dumb zone** — the ~150K-token point where
LLM quality degrades regardless of advertised window size. Roll the work over to a
fresh session *deliberately*: decide what the next session loads, instead of
letting automatic compaction decide.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes
this as the `/session-rollover` slash command. This file plus the script output in
step 1 carry everything a rollover needs; `docs/context-budget.md` is
setup/debugging reference for other occasions.

## When to invoke (trigger policy: WARN asks, STOP goes)

- **STOP** (tokens ≥ `CONTEXT_DUMB_ZONE_TOKENS`, exit code 2, or a hook STOP
  message): finish only the current *atomic step* — nothing new — then run this
  **without asking**. Mid-discussion, the atomic step is the current exchange:
  answer the user's message first, then roll over, carrying the live question
  verbatim into the launcher's START HERE so the successor re-poses it.
- **WARN** (exit code 1, or a hook WARN message): finish the current *work unit*
  **only if it is small** (a doc edit, a review pass, bookkeeping — not an
  implement+test+commit unit), then **ask the user** "roll over now?". On yes,
  run this; on no, write ahead through the WARN→STOP grace window (the standing
  discipline below, at every natural pause) so the eventual STOP rollover is
  cheap. Ledger evidence (`docs/archive/ledger-analysis*.md`): the
  procedure costs ~1–7K in light sessions but ~20K median in heavy workflows —
  the gap is deferred bookkeeping, not handoff writing — so WARN leaves room
  for one small closing unit at most; "finish freely then roll" landed heavy
  sessions at 160–230K.
- **Pre-flight at work-unit boundaries:** before *starting* a major unit
  (observed cost 20–40K in light workflows, 50–130K in heavy ones), run
  `record` and check headroom. If current tokens + the unit's likely cost
  exceed the STOP threshold, roll over **first** — a heavy unit can span the
  whole WARN→STOP band, so starting one near WARN means blowing past STOP
  mid-unit (in the heavy deployment's ledger, 63% of STOP sessions never saw
  a WARN checkpoint).
- The user asks to roll over / hand off to a fresh session.

**Write-ahead is the standing discipline, not a WARN-time fallback:** route
learnings and decisions to their disk homes at incident time, and bring the
ledger/launcher current at each work-unit boundary, so steps 2–3 below are a
sweep for what slipped, not the primary capture. That discipline is the
difference between the 1–7K and 20K+ rollovers above
(`docs/archive/rollover-cost-analysis-2026-08-11.md`).

Never roll over mid-atomic-step (half-written file, unresolved merge, mid-migration).

**Hook-less cadence fallback:** in runtimes with no in-band WARN/STOP push, the
signal only arrives when you run `record` — in an extended discussion (no
work-unit boundaries), run `scripts/context-budget.sh record` every ~10
exchanges so STOP can't pass unnoticed.

## Which boundary skill? (first yes wins)

1. Context-budget WARN/STOP signal (hook message, or `context-budget.sh` exit code
   1/2)? → `session-rollover` (this skill).
2. Deliberate end of a work chunk, budget OK? → `checkpoint`.
3. Both true? → `session-rollover` — measurement wins; fold `checkpoint`'s step-1
   reconciliation (backlog, memory, docs, promotions) into steps 2–3 below.

## Steps

1. **Prep — one call.** `scripts/rollover-prep.sh <project> --reason "<trigger>"`.
   It records the "rollover start" ledger entry, prints a compact git summary,
   rotates older `handoff.md` blocks into `handoff-archive.md` (verified-lossless,
   anchored matching — prep owns the archive step), and prints
   the remaining top handoff block, `.session-seq`, and the freshly captured
   `.rollover-options`. Read its output; it replaces separate git-status /
   handoff-read / archive / options-capture calls.

   To change the successor's model or extra flags, call the script rather than
   editing the file — from a worktree a hand-edit lands in your own checkout:

   ```sh
   scripts/context-budget.sh opts-sync --project <project> --model <model>
   ```

   It rewrites the file whole, so pass every option you want the successor to
   keep; `--approval default|edits|auto|full` and `--extra "<raw args>"` are the
   other two keys (see `scripts/capture-rollover-options.sh` header for
   semantics).

2. **Reflect — route conversation-only learnings to disk.** Anything learned this
   session that lives only in conversation is unrecoverable after rollover:
   operational gotchas → `docs/operational-knowledge.md`; decisions with a rejected
   alternative → `work/<project>/decisions.md` (the `decision-log` skill); durable
   reference facts → the matching doc under `docs/`, with `repo/path:line` pointers
   where code-derived. For observations not obviously durable, park each as a
   one-line entry under `Learnings:` in the handoff block. A parked learning is
   promoted to a durable home the *second* time it bites (grep `handoff*.md` for a
   prior strike); single events die in the archive — the right fate for them.

3. **Flush — make disk fully current.** Update state/tracker files the session was
   maintaining; commit per convention or explicitly note uncommitted work in the
   handoff (the prep output's git summary shows what's dirty); verify any
   sub-agent-claimed outputs actually exist on disk (summaries are hints, not facts).
   (No-git workspace: saving the files IS the flush; the git summary is empty.)

4. **Write the new handoff block** — insert it in `work/<project>/handoff.md`
   directly below the PURPOSE comment, above the single block prep left behind.
   *Backward-looking*: what happened, what shipped, where things stand. Contract:
   **≤40 lines**; reference artifacts by path/URL (never duplicate their content);
   a **suggested skills** section for the next session; optional `Learnings:`
   line-list (step 2); redact secrets/PII.

5. **Write `work/<project>/next-session.md`** — *forward-looking and deliberately
   pruned*, REPLACING the old content:
   - **Mission** — the goal, one paragraph.
   - **Read these, in order** — the *smallest sufficient* set of file pointers.
   - **Do NOT reload** — settled side quests and dead ends, each with a one-line
     why, so the next session doesn't re-litigate them.
   - **State snapshot** — branch, uncommitted work, running processes, open items.
   - **First actions** — step 1 is always `scripts/context-budget.sh register`;
     then the concrete next steps.

   Under `handsoff` mode the launcher must carry only **position** — "ticket 4 of
   9, 3 done" against a named spec, plan, or ticket path. Over a 10-session
   unattended chain a re-narrated mission is a telephone game; disk anchors facts
   but not intent.

6. **Check the counter, emit the bootstrap prompt.** This step is an **assertion,
   not a write.** `work/<project>/.session-seq` holds the last-launched session's
   number — so if a launcher started you, it *already holds yours*. Compare it
   (prep printed the effective value in step 1) against the number in your own
   bootstrap prompt:

   - **Equal** → the normal case. **Write nothing.** The launcher already synced it.
   - **Different** → you started ad-hoc (hand-pasted prompt, launcher bypassed).
     Correct it to **your own** number and note the correction in your handoff block.
   - **No number in your prompt** → you are the prep-printed value + 1; write that.

   **A write that is not a correction is a bug.** Re-deriving the number here is
   exactly how session 3 of `session-loop-automation` wrote `4`, launched `#5`,
   and left no session 4 (2026-08-25). At step 6 your *successor's* number is the
   salient one and it is the wrong one: the counter holds **yours**, and
   `launch-next-session.sh` adds the one.

   **An error here is permanent, so get it right the first time.** Reconciliation
   across checkouts is numeric-max-wins, which can only increase — a counter set
   too high is ratified forever, and the self-heal below recovers only a counter
   set too *low* (ADR-0008).

   **You do not write this file.** Call the script, which resolves the common dir,
   validates your number against the stored one, and writes only when that is a
   correction:

   ```sh
   scripts/context-budget.sh seq-sync --project <project> --session <N>
   ```

   `<N>` is **your own** number — the one in your bootstrap prompt — never your
   successor's. The script reports what it did:

   | Action | Meaning | What you do |
   | --- | --- | --- |
   | `noop` | the counter already held your number | nothing; this is the normal case |
   | `created` | no counter existed | nothing |
   | `raised` | counter was low — you started ad-hoc | note the correction in your handoff block |
   | `lowered` | counter was **high** — a previous session over-counted | note it, and say which number was wrong |

   A `raised` or `lowered` result means something upstream was wrong. Record it;
   an unexplained correction in the ledger is how the next reader learns the
   lineage skipped a number.

   Because the script is now the only writer, the counter has exactly one copy and
   nothing strands. The read-time reconciliation in `launch-next-session.sh` is a
   safety net for pre-existing strays, not a mechanism to rely on. The same rule
   applies to `.rollover-options` in step 1 — see that step for its script call.

   The prompt + counter remain the canonical session-number source; on
   disagreement the ledger note gets repaired, never the counter (ADR-0007, as
   amended by ADR-0008). Then emit the successor's prompt in a fenced block:

   > Work item <project> - rollover session #N+1. Read
   > `work/<project>/next-session.md` and continue from **First actions**.
   > Governing skill: `skills/session-rollover/SKILL.md`.

   > **A committed `ROLLOVER_RELAUNCH=auto` IS your authorization to launch the
   > successor. Do not ask for permission. Do not stop and wait to be told.**
   >
   > Launching an unattended session that spends tokens trips the standing
   > instinct to confirm outward-facing or hard-to-reverse actions "unless
   > durably authorized." A knob committed to `context-budget.env` **is** that
   > durable authorization — the user set it precisely so the chain does not
   > stop. Across sessions 1–10 of `session-loop-automation` agents kept
   > declining to launch anyway, because the caution was in context and the
   > permission was only on disk. It is now in both places; there is nothing
   > left to check.
   >
   > **Before concluding you *cannot* launch, run
   > `scripts/launch-next-session.sh <project> --dry-run` and read what it
   > prints.** A believed technical blocker is not a blocker until the dry-run
   > confirms it. This is a separate failure from the permission one above: it
   > does not feel like hesitancy, it feels like a fact, so the authorization
   > rule never fires. The script is worktree-aware — invoked from a worktree it
   > ff-pushes the branch to main, syncs the main checkout, and proceeds — the
   > stale-launcher-guard paragraph a few lines below says so. Session 12 of
   > `session-loop-automation` reported it could not launch for exactly that
   > reason, with the disproving text open in the same session; the dry-run
   > printed `worktree-invoked: dry-run would sync the main checkout` in about
   > three seconds and the real launch worked first try. One cheap command turns
   > the assumption into an observation.
   >
   > **"I need input from the user" is expressed by rolling over with
   > `--mode interactive` (step 8), never by declining to launch.** Interactive
   > mode starts the successor and has it re-pose the question on a fresh
   > window, with full context. Declining to launch is strictly worse than that
   > in every case: it burns the handoff you just wrote, strands staged work,
   > and still requires the user to notice and intervene — the interruption
   > *plus* the delay.
   >
   > The one thing to get right: launch the successor **into work it can
   > actually start**. If the next unit is genuinely blocked on a human
   > decision, that is what interactive mode is for — carry the question into
   > the launcher's START HERE so the successor asks it first. Blocked is a
   > reason to roll over interactively, never a reason to halt the chain.

   The "Work item … session #" lead line names the lineage (session titles are
   auto-generated from early content). Honor `ROLLOVER_RELAUNCH` via
   `scripts/launch-next-session.sh <project>` — it builds exactly this prompt,
   tracks N, and owns all vendor launch specifics. Script absent or knob `off`:
   the pasted prompt is the whole handoff. The script refuses to launch when a
   newer committed `next-session.md` exists on a ref outside the launching
   checkout's history (stale-launcher guard, backlog L33) — merge/pull first;
   `--skip-freshness` overrides. Worktree-invoked launches self-heal this when
   the work branch is a clean fast-forward of `origin/main`: the script
   ff-pushes the branch to main, syncs the main checkout, and proceeds; only
   real divergence still refuses.

   **Under the supervisor (`TF_SESSION_LOOP=1`), you do not launch — you stage.**
   Instead of running the launcher bare, run it with `--emit`, which performs
   every real-run side effect and writes the successor's command to the file the
   supervisor is waiting on:

   ```sh
   scripts/launch-next-session.sh <project> \
     --emit "$(git rev-parse --path-format=absolute --git-common-dir)/../work/<project>/.next-command"
   ```

   The absolute path is not optional — the script refuses a relative one. A
   relative path resolves against *your* cwd, which under isolation is a worktree,
   and the supervisor reading the main checkout would find nothing and report a
   clean shutdown (spec, "Worktrees" -> layer 3, rule 1).

   `TF_SESSION_LOOP` unset => ignore this entirely and emit the paste-ready prompt
   as always.

7. **Record completion.** `scripts/context-budget.sh record --label "rollover complete: <project>"`.

8. **Under the supervisor only — write the sentinel, last.** If
   `TF_SESSION_LOOP` is set, the very last thing you do is:

   ```sh
   scripts/context-budget.sh rollover-complete --project <project> \
     --mode <interactive|handsoff> --label "<why you rolled>"
   ```

   **Last** is load-bearing. The sentinel means *"this session ended on purpose,
   with disk current."* Writing it before the flush would make a half-completed
   rollover indistinguishable from a clean one, and the supervisor would relaunch
   on top of stale disk (failure mode 8).

   Choose `--mode` by what the moment is, not what the launch was:

   | | `interactive` | `handsoff` |
   | --- | --- | --- |
   | You were | mid-conversation with a human | mid-execution of a plan, spec, or ticket |
   | The successor | re-poses the open question and waits | resumes executing |
   | Your launcher must | carry the live question **verbatim** | carry only *position* against a fixed artifact — never a re-told goal |

   A human `touch work/<project>/.hands-off` or `.interactive` overrides you; the
   script applies that itself, so do not check for those files.

   `TF_SESSION_LOOP` unset => skip this step entirely.

## Guardrails

- **Specialized workflow state files win.** If a skill (onboard-repo, rlm, …) keeps
  its own state/handoff files, they stay authoritative — `next-session.md` carries
  thin pointers to them, never a fork of their content.
- Prefer **file pointers over content summaries** — a summary spends the next
  session's budget on possibly-stale prose; a pointer lets it demand-load.
- **No secrets** in any rollover artifact.
- If no `work/<project>/` directory fits the current work, ask the user where to
  persist rather than inventing a location.

## Verification

- `grep -n '^# Session Handoff' work/<project>/handoff.md` shows exactly 2 blocks,
  yours on top with today's date (prep rotated the rest; you prepended one).
- `scripts/check-ledger.py work/<project>` exits 0. The grep above counts blocks
  but cannot see a heading swallowed by an unclosed purpose comment, nor one
  filed out of order — both have reached a live ledger. Prep rotates the archive
  unattended, so check the result rather than assuming it.
- The launcher was REPLACED, not appended: `next-session.md` describes only the
  next session's mission.
- Session number: the counter equals **your own** number, not your successor's —
  `cat "$(git rev-parse --path-format=absolute --git-common-dir)/../work/<project>/.session-seq"`
  prints the number in your bootstrap prompt. If it prints your number + 1, you
  wrote your successor's number; correct it *now*, before launching, because
  max-wins makes it unrecoverable afterwards (ADR-0008).
- Work-item lock: `scripts/launch-next-session.sh` releases it itself immediately
  before launching. If the script was not invoked, release manually:
  `scripts/context-budget.sh release --project <project>`.

## Outputs

- Ledger entries bracketing the rollover; learnings routed; disk fully current.
- `work/<project>/handoff.md`, `next-session.md`, and `.rollover-options`.
- A paste-ready bootstrap prompt.

End by telling the user: start a fresh session (don't `/compact` — rollover replaces
compaction) and paste the bootstrap prompt — unless `ROLLOVER_RELAUNCH` already
launched the successor, in which case tell them where it's running (attached
terminal, or `scripts/attach-session.sh <project>` for a `--bg` launch).
