---
name: session-rollover
description: Use when the context budget hits WARN/STOP (hook message, `context-budget.sh` exit code 1/2, or the user asks) to roll work over to a fresh session via a deliberate, pruned handoff instead of uncontrolled automatic compaction. Rollover = reflect (route conversation-only learnings to disk) + flush (make disk fully current) + handoff (backward-looking handoff.md, forward-looking next-session.md) + bootstrap prompt.
---

# session-rollover

The session is approaching or past the **dumb zone** — the ~150K-token point where
LLM quality degrades regardless of advertised window size (see
`docs/context-budget.md`). Roll the work over to a fresh session *deliberately*:
decide what the next session loads, instead of letting automatic compaction decide.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes
this as the `/session-rollover` slash command (`.claude/commands/session-rollover.md`,
a thin wrapper around this skill).

## When to invoke (trigger policy: WARN asks, STOP goes)

- **STOP** (tokens ≥ `CONTEXT_DUMB_ZONE_TOKENS`, exit code 2, or a hook STOP
  message): finish only the current *atomic step* — nothing new — then run this
  **without asking**. Mid-discussion, the atomic step is the current exchange:
  answer the user's message first, then roll over, carrying the live question
  verbatim into the launcher's START HERE so the successor re-poses it.
- **WARN** (exit code 1, or a hook WARN message): finish the current *work unit*,
  then **ask the user** "roll over now?". On yes, run this. On no, arm
  **write-ahead mode** for the WARN→STOP grace window: route state to disk
  incrementally at each natural pause (settled points → `decisions.md`/docs;
  open threads → the launcher), so the eventual STOP rollover is cheap.
- The user asks to roll over / hand off to a fresh session.

Never roll over mid-atomic-step (half-written file, unresolved merge, mid-migration).

**Hook-less cadence fallback:** in runtimes with no in-band WARN/STOP push,
the signal only arrives when you run `record` — and pure discussions have no
work-unit boundaries. In an extended discussion, run
`scripts/context-budget.sh record` every ~10 exchanges so STOP can't pass
unnoticed.

## Which boundary skill? (first yes wins)

1. Context-budget WARN/STOP signal (hook message, or `context-budget.sh` exit code
   1/2)? → `session-rollover` (this skill).
2. Deliberate end of a work chunk, budget OK? → `checkpoint`.
3. Both true? → `session-rollover` — measurement wins; fold `checkpoint`'s step-1
   reconciliation (backlog, memory, docs, promotions) into steps 2–3 below.

## Prerequisites

- `scripts/context-budget.sh` (measurement) — see `docs/context-budget.md`.

## Steps

1. **Record the trigger.** `scripts/context-budget.sh record --label "rollover start: <reason>"`.

2. **Reflect — route conversation-only learnings to disk.** Anything learned this
   session that lives only in conversation is unrecoverable after rollover. Route it
   now, per workspace convention: operational gotchas → `docs/operational-knowledge.md`;
   decisions with a rejected alternative → `work/<project-name>/decisions.md` (the
   `decision-log` skill); durable reference facts → the matching doc under `docs/`,
   with `repo/path:line` pointers where code-derived.
   Ideally learnings were routed at incident time (when the failure was hit and fixed),
   making this step a sweep for what slipped, not the primary capture. For observations
   not obviously durable, don't force a routing decision now: park each as a one-line
   entry under `Learnings:` in the handoff block. A parked learning is promoted to a
   durable home the *second* time it bites (grep `handoff*.md` for a prior strike);
   single events die in the archive — which is the right fate for them.

3. **Flush — make disk fully current.** Update state/tracker files the session was
   maintaining; run `git status` in every touched repo; commit per convention or
   explicitly note uncommitted work in the handoff; verify any sub-agent-claimed
   outputs actually exist on disk (summaries are hints, not facts).

4. **Write `work/<project-name>/handoff.md`** — *backward-looking*: what happened,
   what shipped, where things stand. The hand-off contract: reference artifacts by
   path/URL (never duplicate their content); include a **suggested skills** section
   for the next session; an optional `Learnings:` line-list of parked observations
   (step 2); redact secrets/PII. If the global `handoff` skill is
   installed (`docs/recommended-tooling.md`) you may use it to draft the doc; the
   contract above binds either way.

5. **Write `work/<project-name>/next-session.md`** — *forward-looking and
   deliberately pruned*:
   - **Mission** — the goal, one paragraph.
   - **Read these, in order** — the *smallest sufficient* set of file pointers.
   - **Do NOT reload** — settled side quests and dead ends, each with a one-line
     why, so the next session doesn't re-litigate them.
   - **State snapshot** — branch, uncommitted work, running processes, open items.
   - **First actions** — step 1 is always `scripts/context-budget.sh register`;
     then the concrete next steps.

6. **Capture `work/<project-name>/.rollover-options`** recording how THIS
   session was launched, so the successor inherits it. Run
   `scripts/capture-rollover-options.sh <project-name>` — on claude it reads
   the session transcript's recorded `permissionMode` (last value wins) and
   writes `ROLLOVER_OPT_APPROVAL=default|edits|auto|full` (normalized
   approval/permission level — `edits` = auto-approve file edits only;
   `auto` = the runtime's classifier-vetted autonomous mode where one
   exists, nearest-level fallback elsewhere; `full` = bypass); on other
   runtimes it no-ops, leaving the file's last known values. Hand-edit only
   the fields capture can't know: optional `ROLLOVER_OPT_MODEL=<model-id>`
   (deliberately not auto-captured — the transcript can't distinguish an
   explicit `--model` from the runtime default) and optional
   `ROLLOVER_OPT_EXTRA=<raw flags for this runtime>`; the script preserves
   both across re-captures. `scripts/launch-next-session.sh` maps these to
   each runtime's flags.

7. **Emit the bootstrap prompt** for the user to paste into the fresh session, in a
   fenced block, e.g.:

   > Work item <project-name> - rollover session #N. Read
   > `work/<project-name>/next-session.md` and continue from **First actions**.
   > Governing skill: `skills/<skill>/SKILL.md`.

   The "Work item … session #N" lead matters: session titles are
   auto-generated from early content, so the first line names the lineage
   (`launch-next-session.sh` builds exactly this prompt, tracks N in
   `work/<project>/.session-seq`, and passes claude `--name "<project> #N"`).

   **First, sync the counter to yourself** (numbering canon, ADR-0007):
   write the number from your **own** bootstrap prompt to
   `work/<project>/.session-seq` — `echo <your-number> > work/<project>/.session-seq`
   — then let the launcher compute the successor as yours + 1 (the emitted
   prompt's #N above). `.session-seq` + the prompt are the canonical
   session-number source: ledger block titles and worktree names copy the
   prompt number verbatim, and on disagreement the ledger note gets repaired,
   never the counter. This sync is what makes drift self-heal — a session
   launched from a hand-pasted prompt (launcher bypassed) never incremented
   the counter, and the write repairs it before the next launch. If your own
   prompt carried no number, use the counter's value + 1 as your number.

   Then honor `ROLLOVER_RELAUNCH` (global `context-budget.env`, overridable
   per work item by a committed `work/<project>/context-budget.env`) via
   `scripts/launch-next-session.sh <project>` — the script owns all vendor
   launch specifics. If the script is absent or the knob is `off`, the pasted
   prompt above is the whole handoff.

8. **Record completion.** `scripts/context-budget.sh record --label "rollover complete: <project>"`.

## Guardrails

- **Specialized workflow state files win.** If a skill (onboard-repo, rlm, …) keeps
  its own state/handoff files, they stay authoritative — `next-session.md` carries
  thin pointers to them, never a fork of their content.
- Prefer **file pointers over content summaries** — a summary spends the next
  session's budget on possibly-stale prose; a pointer lets it demand-load.
- **No secrets** in any rollover artifact.
- If no `work/<project-name>/` directory fits the current work, ask the user where
  to persist rather than inventing a location.

## Verification

- The new handoff block is on TOP (newest-first is the ledger contract):
  `grep -n '^# Session Handoff' work/<project-name>/handoff.md | head -3` — the first
  hit is this session's block, with today's date.
- Archive rule applied: if that grep lists more than 2 blocks, the older ones were
  moved to `handoff-archive.md`.
- The launcher was REPLACED, not appended: `next-session.md` describes only the next
  session's mission — no leftover sections from the previous rollover.

The work-item lock is released by `scripts/launch-next-session.sh` itself,
immediately before it launches (release-before-launch: the successor's
`register` must not race an unreleased lock, and the attached-manual path
`exec`s, after which nothing can release). It removes only THIS session's own
lock, never a foreign holder's. If the script was not invoked (absent, or the
rollover ends without it), release manually after verification passes:
`scripts/context-budget.sh release --project <project-name>`.

## Outputs

- Ledger entries bracketing the rollover (`work/context-decay/context-ledger.jsonl`).
- Learnings routed to their workspace homes; disk fully current.
- `work/<project-name>/handoff.md`, `next-session.md`, and `.rollover-options`.
- A paste-ready bootstrap prompt.

End by telling the user: start a fresh session (don't `/compact` — rollover replaces
compaction) and paste the bootstrap prompt — unless `ROLLOVER_RELAUNCH` already
launched the successor, in which case tell them where it's running (attached
terminal, or `scripts/attach-session.sh <project>` for a `--bg` launch).
