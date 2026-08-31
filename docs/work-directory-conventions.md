# Work Directory Conventions

Every project under `work/<project-name>/` is developer-scoped and made of plain
Markdown / JSON / scripts, so any agent runtime (Claude Code, Codex, Gemini,
OpenCode, …) or a human can pick it up. This doc defines the **standard files**
each work directory should have and the **write discipline** that keeps them
useful over long, multi-session, compaction-prone work.

To scaffold a new work directory that follows these conventions, use
`skills/create-work-item/SKILL.md`.

## The two-file backbone: launcher + ledger

The single most important convention is the split between the **launcher** and
the **ledger**. They answer different questions and have opposite write
disciplines. Conflating them is the main cause of context-token accretion across
sessions. The `session-rollover` skill already emits these two files; this doc
formalizes their roles.

| | **Launcher** (`next-session.md`) | **Ledger** (`handoff.md`) |
|---|---|---|
| **Question it answers** | "What do I do next, and the minimum I must know to start?" | "What happened, in what order, and why?" |
| **Direction** | Forward (imperative) | Backward (provenance) |
| **Write pattern** | **Replace** — rewritten each rollover to describe only the current front | **Append** — one dated block per session, newest on **top** |
| **Growth** | Bounded (~1 screen); should not accumulate history | Bounded by archival, not by size (see below) |
| **Read pattern** | Read in **full** | Read the **top block only**; older blocks are archive |
| **Never contains** | Session history / past-tense narrative | Forward "what to do next" plans |

**The rule that keeps them separate:** past-tense → ledger; future-tense →
launcher; a still-binding constraint → a one-line summary + pointer in the
launcher, with the full record in the ledger. Because the bootstrap ritual reads
**both** files, the launcher never needs to inline history to be self-sufficient
— it points into the ledger and the state files instead.

**One primary session per work item.** The launcher/ledger REPLACE/APPEND
semantics assume a single writer. That writer is the **primary** session —
the holder of the `work/<proj>/.active-session` lock, acquired at engagement
via `scripts/context-budget.sh register --project <proj>`. Any other session
registering against the item while the primary is live becomes an
**auxiliary**: it may read and work, but must not write the launcher/ledger
or roll the item over. At rollover the predecessor is stamped **superseded**
and the successor becomes primary. Full model:
`docs/context-budget.md` → "Session roles".

### Launcher (`next-session.md`)

The catch-up prompt you paste into a fresh session. Top of file states its
purpose (see header block below). Contents, in order:

1. One-line "resuming `<project>`; works in any runtime" preamble.
2. A **START HERE** block: the current objective and the concrete next actions
   (ideally a short numbered todo).
3. Still-binding **constraints / decisions** as one-liners + pointers ("do not
   re-litigate X — see `<file>`").
4. A **read-these-first** list of the project's durable files, in order.

Rewrite it at every rollover. Anything that has become history moves to the
ledger; anything superseded is deleted, not annotated as "superseded".

### Ledger (`handoff.md`)

The append-only provenance log. Each session prepends one
`# Session Handoff — <n> (<YYYY-MM-DD>): <one-line summary>` block containing:
what got done, repo/state at rollover, and the immediate next step. Read only
the top block; the rest is history. That title form is the preferred one for
**new** blocks; older forms found in live ledgers (legacy date-first
`— <date> (session N: …)`, `session #N`, dateless `sNNN`, date-only) are
grandfathered — the checker accepts them, so don't rewrite history to
"modernize" headings.

**Session numbering — one source of truth (ADR-0007):** N is the number from
your own bootstrap prompt, **verbatim**. The canonical source is machine-local
`work/<project>/.session-seq` (the launcher derives the prompt number from it);
ledger block titles and worktree/branch names copy the prompt number — never
re-derive N from ledger prose. If the ledger disagrees with your prompt number,
repair the ledger note; seq wins. Drift self-heals at rollover: the dying
session syncs `.session-seq` to its own number before launching the successor
(`session-rollover` step 6). If your prompt carries no number (ad-hoc start),
use `.session-seq` + 1 as your N and the sync write counts you in.

**Archival (prevents unbounded growth):** keep only the two most recent session
blocks live in `handoff.md`; move older blocks to `handoff-archive.md` (read on
demand only). The archive uses the same newest-on-top ordering.

**Gate (`scripts/check-ledger.py`):** the ledger is a provenance record written
unattended by rollover tooling, so its shape is machine-checked rather than
trusted. The check validates that every `# Session Handoff` heading parses
(yields a session number, a date, or both — all the grandfathered title forms
above are accepted), that none is buried inside the purpose comment by an
unclosed `<!-- -->`, that blocks run newest-first by session number *and* date
(each checked against the nearest block above carrying that key), and that
`handoff-archive.md` holds nothing newer than `handoff.md`. Run it after any
rotation — `scripts/check-ledger.py [work/<project>]`, exit 0 when clean. Two
misfiled blocks reached a live ledger before this existed, in exactly the first
two of those ways.

**Lineage restart (rare):** if a project genuinely restarted its session
numbering mid-history, declare it with a
`<!-- ledger-lineage-restart: <why> -->` comment placed between the lineages
(newer lineage above, older below). The checker restarts its session-number
chain at the block below the marker; dates must still run newest-first across
the seam. Never use the marker to paper over an ordinary misfiling — re-file
the block instead.

**Alternative pattern — dated handoff files.** Some projects use one file per
session, `handoff-YYYY-MM-DD-topic.md`, instead of a single append-only file.
This is naturally bounded (no archival step) but needs the launcher to point at
the latest. Either pattern is acceptable; pick one per project and be consistent.

## How a session ends: two doors

A primary session on a work item ends through one of two doors, both of which
write the ledger before the lights go out:

- **session-rollover** — the work continues: prune, hand off, stage (or
  launch) the successor.
- **checkpoint** — the work stops here: reconcile the backlog/memory/docs and
  close the ledger block.

A plain exit (`/exit`, closing the terminal) is neither door, but it is
**recoverable**, not fatal. The launcher's lineage gate notices the signature
it leaves — a counter one ahead of the ledger's top block — and splits on
evidence: a session that left **no trace** (no work-unit records, no commits,
a clean work item) gets its number silently reclaimed at the next launch; a
session that **did work** but wrote no ledger block makes the launcher refuse
with a reconstruction brief (the evidence it found, and the `seq-sync` rewind
as the alternative). Under `session-loop.sh`, a quit additionally pushes a
chain-ended notification saying whether the ledger recorded the session.
Mechanics: `docs/context-budget.md`.

## Required and optional files

| File | Required? | Role |
|------|-----------|------|
| `README.md` | **Required** | Project identity: what it is, governing skill(s), and the start-here pointer. Durable — changes rarely. |
| `next-session.md` | Recommended | The **launcher** (see above). |
| `handoff.md` (+ `handoff-archive.md`) | Recommended | The **ledger** (see above). |
| `decisions.md` / `docs/adr/*` | Optional | Decision records, per `skills/decision-log/SKILL.md`. |
| `STATUS.md` | Optional | Shareable program/status snapshot (per-area state, blockers). Distinct from the launcher: STATUS is for humans reviewing progress; the launcher is for an agent resuming work. |
| `glossary.md` | Optional | Project-scoped terms/acronyms. |
| `map.md` + `issues/NN-<slug>.md` | Optional | Wayfinder map + decision tickets for the effort, per `docs/agents/issue-tracker.md` → "Wayfinding operations" (governing skill: `skills/wayfinder/SKILL.md`). |
| `spec.md` | Required when "done" is debatable | The effort's spec/PRD — skeleton, when-required rule, approval flow, and external-tracker (spec-of-record) handling: `docs/agents/issue-tracker.md` → "Spec conventions". Distinct from root `SPEC.md` (product-level Z0). **No spec → success criteria go in a `## Success criteria` section of `README.md`.** |
| `verification.md` | Recommended when there's anything to verify | The evidence behind "done": test plan (before) + results (after) in one file (skeleton below). |
| `briefs/<audience>-vN.md` | Optional | Sealed, versioned export of project state to an out-of-workspace agent (see "Portable agent brief" below). |

Keep everything else (state trackers, registries, run logs, specs) named for
what it is; the governing skill owns the full file-level detail.

## Verification evidence (`verification.md`)

Decisions get `decisions.md`, sessions get `handoff.md` — `verification.md`
is the equivalent for **the evidence behind "done"**. Without it,
verification lives in conversation ("tests pass") and archives away. One file
holds both halves so gaps are visible (planned 6 checks, ran 4):

```markdown
# Verification — <effort>

Covers: S1–S4   <!-- spec items this evidence covers, when a spec exists -->

## Plan
<!-- written BEFORE implementing: what will prove this works -->

- [ ] V1 — <check> (covers S1)
- [ ] V2 — …

## Evidence
<!-- filled as checks run: date, command/action, observed result (or a
     pointer to CI run / transcript) -->

- V1 — PASS 2026-01-15 — `<command>` → <observed result>
```

**Tracked vs. untracked:** everything a *future session* must read to continue
the work is committed (the whole table above, plus a per-item
`context-budget.env` policy file). Live-session runtime state is gitignored —
`.active-session` (advisory lock; validity = holder's artifact mtime, so a
committed copy is a stale claim waiting to be checked out) and
`.rollover-options` (per-launch flags for this machine's runtime, rewritten
each rollover).

## Portable agent brief (`briefs/<audience>-vN.md`)

Dispatch records (`docs/context-budget.md` → "Dispatching long-running
children") cover children launched on the same machine, able to read these
files. A **portable brief** is the opposite export: project state handed to
an agent *outside* the workspace — a phone-app chat, another person's
assistant, any runtime with no file access. The brief must be self-contained,
and once a copy is out the workspace can neither update nor retract it, so
staleness is managed by convention:

- **One file per version, sealed.** `work/<proj>/briefs/<audience>-vN.md`.
  Issued means frozen: corrections ship as v(N+1), because the consuming
  agent holds a copy an edit here cannot reach.
- **Supersession header.** Version, issue date, and the line
  "Supersedes all earlier briefs; discard them." — the discard instruction
  is the only retraction mechanism available.
- **Never-reveal section.** An explicit list of facts the agent must not
  disclose, each with what to say if asked. The private-data boundary lives
  in this section, stated — the consuming agent has no other way to know it.
- **Ledger notes at issue and at staleness.** The issuing session's ledger
  block records that vN went out; when a later decision changes the picture,
  the ledger flags the brief stale and the next brief is v(N+1). The ledger
  note is what makes the export visible to future sessions — without it the
  brief goes stale silently.

Skeleton:

```markdown
# Brief — <audience / purpose> (v2, issued 2026-08-12)

Supersedes all earlier briefs; discard them.
Role: <what the receiving agent is doing with this>

## Never reveal
- <fact> — if asked, say: <deflection>

## Situation
<self-contained current state: no pointers into the workspace>

## How to respond
<the response format the situation calls for, e.g. terse live prompts>
```

## Naming

- Canonical backbone for new work directories: **`handoff.md`** (ledger) +
  **`next-session.md`** (launcher) — the same names the `session-rollover` skill
  produces.
- Use hyphens between words in the project directory name (matches the `skills/`
  naming convention), e.g. `work/my-project/`.

## Purpose headers

Both backbone files should declare their role at the very top so a fresh reader
(or a new runtime) treats them correctly. The launcher uses a visible blockquote
(it is meant to be read/pasted); the ledger uses an HTML comment (it is a log,
kept clean for prepending).

Launcher header (top of `next-session.md`):

```markdown
> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.
```

Ledger header (top of `handoff.md`):

```markdown
<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->
```

## Content boundaries

Work directories are developer-scoped. Keep the split clean:

- Global workspace files (`CONTEXT.md`, `docs/workspace-structure.md`) may
  **name** a work directory as a location pointer but must not list its internal
  files, schemas, or state.
- The **governing skill** owns the full file-level detail for its workflow's
  directory.

## Why this matters (context hygiene)

Launcher-and-ledger discipline directly limits per-session token cost:

- A launcher that **replaces** instead of appends stays ~1 screen instead of
  becoming a second handoff.
- A ledger that **archives** old blocks stays small in the read path instead of
  growing unbounded.
- Full-text duplication of the same lesson across multiple early-loaded files is
  a multiplier leak; keep the detail in **one** on-demand doc and use one-line
  pointers everywhere else.

See the **Agent Context Discipline** and **Context Budget** sections of
`CONTEXT.md`, and the `session-rollover` skill, for the surrounding discipline.
