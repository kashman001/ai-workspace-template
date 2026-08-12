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
   handoff-read / archive / options-capture calls. Hand-edit `.rollover-options`
   only for `ROLLOVER_OPT_MODEL` / `ROLLOVER_OPT_EXTRA` (see
   `scripts/capture-rollover-options.sh` header for semantics).

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

6. **Sync the counter, emit the bootstrap prompt.** Write the session number from
   your **own** bootstrap prompt to `work/<project>/.session-seq`
   (`echo <N> > …`; no number in your prompt → use the prep-printed value + 1).
   The prompt + counter are the canonical session-number source; on disagreement
   the ledger note gets repaired, never the counter (ADR-0007). Then emit the
   successor's prompt in a fenced block:

   > Work item <project> - rollover session #N+1. Read
   > `work/<project>/next-session.md` and continue from **First actions**.
   > Governing skill: `skills/session-rollover/SKILL.md`.

   The "Work item … session #" lead line names the lineage (session titles are
   auto-generated from early content). Honor `ROLLOVER_RELAUNCH` via
   `scripts/launch-next-session.sh <project>` — it builds exactly this prompt,
   tracks N, and owns all vendor launch specifics. Script absent or knob `off`:
   the pasted prompt is the whole handoff. The script refuses to launch when a
   newer committed `next-session.md` exists on a ref outside the launching
   checkout's history (stale-launcher guard, backlog L33) — merge/pull first;
   `--skip-freshness` overrides.

7. **Record completion.** `scripts/context-budget.sh record --label "rollover complete: <project>"`.

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
- The launcher was REPLACED, not appended: `next-session.md` describes only the
  next session's mission.
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
