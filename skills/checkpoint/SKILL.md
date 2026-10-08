---
name: checkpoint
description: Use at a session boundary between major chunks of work to wrap up what shipped and prepare a clean hand-off into the next chunk — reconcile the backlog/issue tracker, project memory, and reference docs; write a hand-off doc; confirm clean branch state; and emit a catch-up prompt for the next (post-context-compaction) session. Trigger when finishing a work chunk, before compacting/clearing context, or when the user says "checkpoint".
---

# checkpoint

You are at a **checkpoint between major chunks of work**. Wrap up what just shipped and
prepare a clean hand-off into the next chunk — so the user doesn't retype this each time.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes this as
the `/checkpoint` slash command (`.claude/commands/checkpoint.md`, a thin wrapper around this
skill). Optional input — the **next focus** (e.g. "Phase 3 Trends"); if omitted, infer it
from the backlog's active sequence.

## When to use
- Finishing a major chunk of work, before starting the next.
- Before compacting or clearing the context window (Claude Code `/compact`, or your
  runtime's equivalent).
- When the user says "checkpoint".

## Which boundary skill? (first yes wins)

1. Context-budget WARN/STOP signal (hook message, or `context-budget.sh` exit code
   1/2)? → `session-rollover`.
2. Deliberate end of a work chunk, budget OK? → `checkpoint` (this skill).
3. Both true? → `session-rollover` — measurement wins; fold this skill's step-1
   reconciliation into its reflect/flush steps.

## Prerequisites
- `skills/handoff/SKILL.md` — owns the hand-off document structure.
- `skills/decision-log/SKILL.md` — owns decision capture and ADR promotion.
- A project memory location and an issue-tracker/backlog convention (per
  `docs/agents/issue-tracker.md` if the Matt Pocock skills were set up).

## Steps

Do these in order, concisely (reference artifacts by path — do NOT duplicate plans/specs/diffs):

1. **Reconcile the record.** Make sure what just shipped is reflected in:
   - the project's **issue tracker / backlog** — per `docs/agents/issue-tracker.md` if
     configured, else the repo's own convention (GitHub Issues, a `BACKLOG.md`, `.scratch/`).
     Mark finished items `Done` (date + how / PR + any deploy versions); add newly-discovered
     work. If committed docs change, follow the repo's branch/PR pattern — don't push to the
     default branch unless that's the convention.
   - **project memory** (the agent's per-project memory dir, e.g.
     `~/.claude/projects/<project-id>/memory/` for Claude Code) — update the running-arc
     memory and add durable, non-obvious learnings (gotchas, decisions, preferences); update
     `MEMORY.md` pointers. A human-driven retrospective ("what failed that we shouldn't
     repeat?") is best run here or at the *start* of a successor session — fresh context,
     ledger and git history in hand — never squeezed into a token-starved rollover.
   - the matching **reference docs** under `docs/` if a feature shipped or changed.
   - **decision notes** — scan `work/*/decisions.md` for entries flagged `Promote?: yes`
     (or a `maybe` whose condition now holds), **and** `work/*/map.md` "Decisions so far"
     entries — a resolved wayfinder ticket is a Tier-2 decision and the map substitutes
     for `decisions.md` (per `docs/agents/issue-tracker.md` → "Decision-log tie-in").
     For each, follow `skills/decision-log/SKILL.md`'s promotion steps (draft the
     ADR in the home its **scope** dictates — cross-repo or workspace →
     `docs/adr/`; contained in one product repo → `repos/<repo>/docs/adr/`, per
     `docs/adr/README.md` → "Where it lives (scope)" — fill its Provenance
     block, flip the note to `done → ADR-NNNN`). This is
     where the session's ephemeral *why* becomes a durable, committed record — do it
     before context compacts.
   - **operational knowledge** — before adding a gotcha to
     `docs/operational-knowledge.md`, classify it (see "Classify before you write"
     below). Then list the entries past the doc's 6-month review age:
     ```bash
     cutoff=$(date -v-6m +%F 2>/dev/null || date -d '6 months ago' +%F)
     awk -v c="$cutoff" '/^## /{h=$0} /^\*\*Last confirmed:\*\*/{if ($3 < c) print $3, h}' docs/operational-knowledge.md
     ```
     Put any hits in the hand-off for a person to look at. Don't act on them
     yourself. A person re-confirms an entry (bumps its date), updates it, or
     retires it. Never delete one.

2. **Write a hand-off doc** for the next chunk, under `work/<project-name>/` (the
   workspace convention). The hand-off contract:
   - reference artifacts by path/URL — never duplicate plans/specs/diffs into the doc;
   - include a **suggested skills** section for the next session;
   - redact secrets/PII.
   Draft the doc with `skills/handoff/SKILL.md`, which ships in this repo and owns
   the document's structure; the contract above binds either way. Frame it around
   the next focus, or — if none given — the next item in the backlog's active
   sequence.
   When the hand-off is a new block in the ledger (`work/<project-name>/handoff.md`),
   insert it after the purpose comment's closing `-->` — never anchor on the first
   `# Session Handoff` text, which is the comment's own example — and if you are
   redoing an earlier write, delete the stale block rather than prepending again.
   Then run `scripts/check-ledger.py work/<project-name>`; it must exit 0.

3. **Confirm repo/branch state** is clean and recorded: current branch, working tree clean,
   merged branches tidied or noted. If the project deploys, record the live deployment versions.
   **Also run `git status --short work/`** and commit (or explicitly note) any
   untracked/uncommitted `work/` state files — a new manifest or tracker left
   untracked silently strands the next session, which sees a clean tree and no file.
   (No-git workspace: skip — record instead that all state files under `work/` are current.)
   If a plan is open (`scripts/plan.sh status` exits 0 and says `open`), run
   `scripts/plan.sh sync` first so the launcher's Position block is fresh.
   **If the project maintains a persistent launcher** (`work/<project-name>/next-session.md`),
   re-read it before emitting the catch-up prompt and check that any "TOP block =
   session N" annotation still names the current session — a surgical edit easily
   leaves it stale.

4. **Emit a ready-to-paste catch-up prompt** (for the next session, after context is
   compacted/cleared) in a fenced block — it must name the hand-off doc path and tell the next
   session to catch up + continue with the right starting skill (often
   `superpowers:brainstorming`). Keep it ~3–5 lines.

## Classify before you write

This applies before you append to `docs/operational-knowledge.md` or a
`work/*/decisions.md`. First grep the target for the subject, using two or
three key words from the new item (`grep -n -i '<word>' <file>`). The same
subject can be worded differently, so also scan the headings
(`grep -n '^## ' <file>`) for one that means the same thing. Read any entry
that matches. Then pick one:

- **ADD** — nothing covers it. Append a new entry. In
  `operational-knowledge.md`, give it a `**Last confirmed:** $(date +%F)` line
  under the heading.
- **UPDATE** — an entry covers it and the new item refines it without
  reversing it. Edit that entry in place. In `operational-knowledge.md`, bump
  its `Last confirmed` date too.
- **SUPERSEDE** — the new item contradicts or replaces an entry. Write the new
  entry. Under the old entry's heading, add `**Retired:** YYYY-MM-DD —
  superseded by "<new heading>"`. Leave the old body in place. Never delete it.
- **NOOP** — the item only matters to this session (a one-off error, a
  transient state). Don't write it.

If you can't tell UPDATE from SUPERSEDE, choose SUPERSEDE. A retired entry
keeps its history. An overwritten one loses it.

## Verification

- Hand-off doc is on disk: `ls work/<project-name>/` shows it.
- If a ledger block was written: `scripts/check-ledger.py work/<project-name>` exits 0
  (no heading inside the purpose comment, no block filed twice, newest on top).
- Promotion scan ran to completion: `grep -n 'Promote?: yes\|Promote?: maybe' work/*/decisions.md work/*/map.md`
  — every hit is either promoted this checkpoint (flipped to `done → ADR-NNNN`) or its
  `maybe` condition checked and still unmet.
- Branch state matches step 3's claim: `git status --short` is clean, or the exceptions
  are named in the hand-off doc.

## Outputs
- Reconciled backlog/issue tracker, project memory (+ `MEMORY.md`), and reference docs.
- A hand-off doc under `work/<project-name>/`.
- A catch-up prompt the user pastes into the next session.

End by telling the user to compact/clear context, then paste the catch-up prompt to continue.
Keep the whole response tight — this is a transition, not a status essay.
