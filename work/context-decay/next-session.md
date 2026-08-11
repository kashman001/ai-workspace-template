> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

**No active mission.** Session #4 closed out the audit's follow-ups:

- Trim candidates: analyzed (`trim-estimates.md`) and **declined by user
  decision** (2026-08-07 note in `decisions.md`) — bar is "unused AND no
  negative implications"; nothing repo-side qualifies. Do NOT re-propose
  trims unless the user reopens; the estimates file is the menu if they do.
- Warp attribution question: **settled** — hook_success stdout never enters
  model context; only `content` does. `context-inspect.sh` fixed to attribute
  content-only (backlog L31).

## Read these, in order

1. This file.
2. TOP block of `handoff.md` (session #4) — only if picking up related work.

## Do NOT reload

- `plan-snapshot-tool.md`, `context-decay-spec.md`, `design.html`,
  `trim-estimates.md` — reference only.
- **Gemini auth on this machine** — settled dead ends
  (`docs/operational-knowledge.md`); do not retry.
- `ledger-analysis.md` — re-read only at the next analysis pass.

## Open items

1. Gemini live-response verification — needs a user `GEMINI_API_KEY`.
2. Copilot CLI adapter live verification — needs Copilot CLI installed.
3. Next ledger analysis — after ~40 entries / first `method=estimate` rows /
   first non-claude rows.
4. User-global context cleanup (option 3: superpowers SessionStart, unused
   `~/.claude/skills`, plugins) — deferred by user 2026-08-07; revisit only
   if they raise it. (Items 1–4: externally gated.)
5. Rollover-cost savings validation — R1–R5 from
   `rollover-cost-analysis-2026-08-11.md` were applied 2026-08-11
   (`scripts/rollover-prep.sh` + slimmed skill). Predicted floor ~10K →
   ~6-7K. After the next ~5 real rollovers, compare
   `rollover start`→`complete` ledger deltas against the pre-change
   medians (~11K local / ~20K heavy) and record the verdict in the
   analysis doc.

## State snapshot

Session #4 worked on branch `worktree-context-decay-s4` (worktree),
committed + pushed; **verify it's merged to `main` before trusting this
launcher** (`git log main..origin/worktree-context-decay-s4` non-empty →
merge first; a draft PR may exist). `.rollover-options` carries
`ROLLOVER_OPT_APPROVAL=auto`.

## First actions

1. `git fetch origin` + confirm the s4 branch is merged and
   `git log HEAD..origin/main` is empty.
2. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
3. With no active mission: ask the user what's next for this work item, or
   close it out via `checkpoint` if they're done with it.
