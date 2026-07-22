---
name: decision-log
description: >-
  Capture the WHY behind a decision so it survives context compaction and is
  recoverable later. Code records what exists, not how it got there — the reasoning,
  the rejected alternatives, and the constraints evaporate unless written down at the
  moment of deciding. Use this WHENEVER you pick one approach over a real alternative,
  make a non-obvious tradeoff, or the user asks "why did we do it this way?" and the
  answer isn't in the code. Three tiers by permanence: a commit trailer (always), a
  cheap decision note in work/<proj>/decisions.md (for anything with a rejected
  alternative), and — only for decisions with lasting weight — a promoted ADR under
  docs/adr/. Trigger it even without the word "decision": "let's go with", "instead of",
  "we could either… but", "the reason is", and any architecture/contract/convention
  fork are all signals. Promotion of notes to ADRs happens here or at `checkpoint`.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# decision-log — capture the *why*, promote the important bits

> **Vendor-neutral skill.** Plain markdown any agent (Claude Code, Codex, Gemini CLI,
> OpenCode) can read and drive — it lives in this workspace's shared `skills/` dir per
> the convention in `CONTEXT.md`. Claude Code also exposes it as the `/decision` slash
> command (`.claude/commands/decision.md`, a thin wrapper around this skill).

Code is a snapshot with the decision history erased — `git blame` gives *what/when/who*,
never *why*. Intent is unrecoverable after the fact; you can only capture it *as you
decide*. This skill is that capture, at the cheapest tier that fits.

## The three tiers (capture cheap, promote the keepers)

```
Tier 3  ADR            docs/adr/NNNN-slug.md         committed · permanent · linkable
   ▲    promote at checkpoint (or on demand)
Tier 2  Decision note  work/<proj>/decisions.md      in-flight · per-project · ephemeral
   ▲    distilled from
Tier 1  Commit trailer git commit message            permanent · in-repo · machine-read
```

Default policy — deliberately light, so it doesn't die of ceremony:

- **Tier 1 — always.** Every non-trivial commit carries a one-line `Decision:` reason.
- **Tier 2 — for any choice with a rejected alternative.** If there was a real fork,
  append a note. This is the wide net: cheap, append-only, lives beside the work.
- **Tier 3 — only on promotion.** An ADR is earned, not automatic (see the bar in
  `docs/adr/README.md`). Most notes never become ADRs, and that's correct.

## Capture a decision (Tier 2 — the common case)

Append to `work/<project-name>/decisions.md` (create it if absent), newest last:

```markdown
## YYYY-MM-DD — <what the decision is about>
**Chose:** <the approach>
**Because:** <the reason — the constraint or force that decided it>
**Rejected:** <alternative> — <one-line why it lost>; <alternative> — <why>
**Blast radius:** <files / symbols / flows this touches>
**Promote?:** no | maybe — <condition> | yes — <why it's ADR-worthy>
```

Write it *when you decide*, not in a cleanup pass — the reasoning is freshest (and only)
in the moment. Keep it to the fork that mattered; skip decisions with no real alternative.
Never put secrets in it.

Get the date from the system (`date +%F`) — don't guess it.

## Record it in the commit (Tier 1)

When the change lands, add trailers to the commit body so a graph can walk `commit → ADR`:

```
Decision: <the one-line reason>
Rejected: <the main alternative and why> <!-- optional -->
Refs: ADR-NNNN                            <!-- only if an ADR exists -->
```

## Promote a note to an ADR (Tier 3)

On demand, or when `checkpoint` flags a `Promote?: yes|maybe` note. Steps:

1. `ls docs/adr/` → next free `NNNN` (zero-padded, never reuse a number).
2. Copy `docs/adr/0000-template.md` → `docs/adr/NNNN-kebab-slug.md`; fill Context /
   Decision / Alternatives / Consequences from the note (expand, don't just paste).
3. Fill the **Provenance** block: `Promoted from:` the note anchor, `Commits:` the shas,
   `Supersedes:` any ADR this replaces (and set that ADR's status to
   `superseded by ADR-NNNN`).
4. Set `Status: accepted` and today's date; add it to the index in `docs/adr/README.md`.
5. Flip the note's `Promote?:` to `done → ADR-NNNN` so it isn't re-promoted next checkpoint.
6. If a graph exists (`graphify-out/graph.json`), run `graphify update .` so the ADR's
   edges enter the graph.

## graphify — closing the loop

Once ADRs and commit trailers exist, they become **context-graph nodes**: the ADR's
`Provenance`/`Supersedes`/`Refs` lines and the commit `Refs:` trailers are the edges that
let `graphify query "why does <X> work this way?"` traverse
`code symbol → commit → ADR → alternatives-rejected` — the "how did it get there" path
plain code can't answer. Keep it fresh with `graphify update .` after adding an ADR.

## Outputs

- A Tier-2 note appended to `work/<project-name>/decisions.md` (the common case).
- Commit trailers on the implementing commit.
- On promotion: a new `docs/adr/NNNN-*.md` + updated `docs/adr/README.md` index, and a
  refreshed graph if graphify is live.
