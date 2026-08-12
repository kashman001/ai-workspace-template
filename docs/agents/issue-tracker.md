<!--
File: docs/agents/issue-tracker.md
Purpose: This workspace's issue-tracker and spec conventions for the
         engineering skills (wayfinder, to-spec, to-tickets, triage — all
         vendored under skills/) — local markdown, adapted to the work/
         directory convention.
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
- Triage state is a `Status:` line near the top of each issue file. The
  `triage` skill's canonical role names (`bug`/`enhancement` categories;
  `needs-triage`/`needs-info`/`ready-for-agent`/`ready-for-human`/`wontfix`
  states) are used **verbatim** as line values — no label mapping needed.
- Bug tickets carry a `Severity:` line (`critical`/`major`/`minor`) and a
  `Repro:` section (steps to reproduce, expected vs. actual)
- **Traceability (advisory):** when the effort has a spec, tickets should
  carry a `Spec:` line naming the spec item(s) they implement (`Spec: S3` —
  or an external key like `Spec: PROJ-1234`); test plans and verification
  docs list the items their evidence covers as `Covers: S1, S3` (see
  `docs/work-directory-conventions.md` → verification.md)
- Comments and conversation history append to the bottom of the file under a
  `## Comments` heading

## Spec conventions

The effort-level spec is `work/<effort-slug>/spec.md`. **Not the same file as
root `SPEC.md`** — that one is the product-level (Z0) "what and why" for the
whole project; this one is one effort's requirements. Both carry a header
naming their level.

### When a spec is required

Required when the effort's success criteria can't fit the README's one-line
goal — multi-feature work, user-facing behaviour changes, anything where
"done" is genuinely debatable. Ops-flavoured efforts (a review sweep, a batch
of small fixes) skip it. **No spec → the success criteria must still be
written down**, as a `## Success criteria` section in the effort's
`README.md`. The `create-work-item` skill asks this question at scaffold time.

**External spec of record:** an external tracker item (JIRA, GitHub issue, …)
with real acceptance criteria *is* the spec — don't duplicate it. Record the
reference in the header's `Spec-of-record:` line (and in ticket `Spec:`
fields, e.g. `Spec: PROJ-1234`). When agent sessions may lack tracker access,
mirror the acceptance criteria into `spec.md` marked as a mirror ("source of
record: PROJ-1234, mirrored YYYY-MM-DD") — the mirror is read-only; sharpen
vague criteria in the tracker itself, then re-mirror.

### Skeleton

```markdown
<!--
Effort-level spec for work/<effort>/ — distinct from root SPEC.md
(product-level Z0). Convention: docs/agents/issue-tracker.md → "Spec conventions".
-->

# Spec — <effort name>

Status: draft            <!-- draft | in-review | approved -->
Approved-by: —           <!-- who signed off; set when Status: approved -->
Date: <YYYY-MM-DD>
Spec-of-record: —        <!-- external ticket ref + link, if the spec lives
                              in an external tracker (this file then mirrors
                              its acceptance criteria) -->

## Requirements

<!-- Stable IDs — never renumber; strike through retired items. Tickets
     reference these as `Spec: S3`; verification docs as `Covers: S1, S3`. -->

- **S1** — <requirement or numbered user story>
- **S2** — …

## Non-goals

- <what this effort deliberately does not do>
```

The `to-spec` skill generates richer content (problem statement, user
stories, implementation/testing decisions) — keep the skeleton's header and
stable `S<n>` IDs when it does; its numbered user stories are the `S<n>`
items.

### Approval

Default (single human + agents): flip the in-file `Status:` line —
`draft → in-review → approved` — and fill `Approved-by:` when approving.
For genuinely multi-person specs, use a **branch review loop**: draft the
spec on a branch, the reviewer reads the diff (PR or local), and merging is
the approval — fill `Approved-by:` at merge.

## When a skill says "publish to the issue tracker"

Create a new file under `work/<effort-slug>/` (creating the directory if
needed — prefer scaffolding it with the `create-work-item` skill so the
standard backbone comes along).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or
the issue number directly.

> **Implementing the tickets:** the spec chain (`to-spec`, `to-tickets`,
> `triage`, `wayfinder`) is vendored under `skills/` and always available.
> Engineering-practice skills it pairs with (`tdd`, `diagnosing-bugs`,
> `grilling`, `domain-modeling`) are recommended but optional — install
> pointers in `docs/recommended-tooling.md`.

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
(`CONTEXT.md` → *Decision Records*). The map's Decisions-so-far plays the role
of `decisions.md` for the effort; there's no need to duplicate entries between
them. When a resolution has lasting weight beyond the effort, promote it to an
ADR with `/decision promote` (or at `checkpoint`).
