<!--
File: docs/agents/issue-tracker.md
Purpose: This workspace's issue-tracker conventions for the Matt Pocock
         engineering skills (wayfinder, to-tickets, triage, …) — local
         markdown, adapted to the work/ directory convention.
See: docs/work-directory-conventions.md, skills/wayfinder/SKILL.md
-->

# Issue tracker: Local Markdown (under `work/`)

Issues, specs, and wayfinder maps for this workspace live as markdown files
under `work/<effort>/` — the same directories described in
`docs/work-directory-conventions.md`, so tracker artifacts sit alongside the
effort's `README.md`, launcher, ledger, and `decisions.md`.

> Upstream's local-markdown default uses `.scratch/`; this workspace uses
> `work/` instead so there is one home for multi-session effort state. If your
> project tracks issues on GitHub or GitLab, replace this file with the
> matching variant from
> `github.com/mattpocock/skills` → `skills/engineering/setup-matt-pocock-skills/`
> (`issue-tracker-github.md` / `issue-tracker-gitlab.md`).

## Conventions

- One effort per directory: `work/<effort-slug>/`
- The spec (PRD) is `work/<effort-slug>/spec.md`
- Implementation issues are one file per ticket at
  `work/<effort-slug>/issues/<NN>-<slug>.md`, numbered from `01` — never a
  single combined tickets file
- Triage state is a `Status:` line near the top of each issue file
- Comments and conversation history append to the bottom of the file under a
  `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `work/<effort-slug>/` (creating the directory if
needed — prefer scaffolding it with the `create-work-item` skill so the
standard backbone comes along).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or
the issue number directly.

## Wayfinding operations

Used by the `wayfinder` skill (`skills/wayfinder/SKILL.md`). The **map** is a
file with one **child** file per ticket.

- **Map**: `work/<effort>/map.md` — the Destination / Notes /
  Decisions-so-far / Not-yet-specified / Out-of-scope body.
- **Child ticket**: `work/<effort>/issues/NN-<slug>.md`, numbered from `01`,
  with the question in the body. A `Type:` line records the ticket type
  (`research`/`prototype`/`grilling`/`task`); a `Status:` line records
  `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is
  unblocked when every file it lists is `resolved`.
- **Frontier**: scan `work/<effort>/issues/` for files that are open,
  unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set
  `Status: resolved`, then append a context pointer (gist + link) to the
  map's Decisions-so-far in `map.md`.

### Decision-log tie-in

A resolved wayfinder ticket **is** a decision with a rejected alternative —
i.e. a Tier-2 decision note in this workspace's decision-record scheme
(`CLAUDE.md` → *Decision Records*). The map's Decisions-so-far plays the role
of `decisions.md` for the effort; there's no need to duplicate entries between
them. When a resolution has lasting weight beyond the effort, promote it to an
ADR with `/decision promote` (or at `checkpoint`).
