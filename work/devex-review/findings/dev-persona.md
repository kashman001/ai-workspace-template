# Developer Persona — Cold-Start DevEx Review (raw report)

> Produced 2026-08-11 by a persona agent role-playing a busy, skeptical
> mid-to-senior developer cold-starting this template for a real product repo.
> Read-only walkthrough across the development lifecycle. Part of
> `work/devex-review/`. A spec-workflow addendum was requested separately.

All paths below are under `/Users/kashif/Developer/experiments/ai-workspace-template/`.

## Persona summary

I cloned this expecting a README, a setup script, and some conventions; I got a genuinely impressive, battle-tested coordination system — and also a template that hasn't fully separated itself from the project that built it. Within ten minutes I knew what it was and what to run first (README → template-usage.md → setup.sh is a clean funnel). The launcher/ledger convention and the check-script/runbook pairing are the best-documented agent-workflow patterns I've seen in a template. But my skepticism kicked in hard in two places. First, the clone ships ~1MB of the maintainer's own research history under `work/`, core scripts write telemetry into one of those research directories, and shipped skills cite the maintainer's analysis files — so I genuinely couldn't tell where "the template" ends and "someone's lab notebook" begins. Second, the context-budget system, while the crown jewel, has grown a conceptual surface (session roles, child locks, dispatch generations, takeover semantics) that a solo dev on a small team will never use but must wade through to find the three commands that matter. I'd adopt the skeleton and the budget quickstart tomorrow; I'd spend my first hour deleting things, and I resent that the template didn't tell me which things.

## Findings

### Stage 1 — First contact

**1. Two competing instantiation stories, and one of them is a trap** — **major**
- Files: `docs/template-usage.md`, `docs/workspace-structure.md` (lines 35–269, "Agent Bootstrap Instructions")
- Experience: README funnels me to template-usage.md (clone/"Use this template" — correct path). But README also bills workspace-structure.html as "the full workspace guide", and that doc *opens* with "If you are an AI agent reading this file, follow these steps to scaffold a new workspace from scratch." An agent pointed at it will scaffold stub files, with "`skills/` starts empty" and `setup.sh` as a `TODO: implement` stub — producing a workspace *without* the shipped context-budget machinery, skills, or working scripts. The bootstrap section is a from-scratch legacy path that contradicts what the template now ships.
- Fix: Demote the bootstrap section to an explicit "Appendix: scaffolding without cloning (degraded path — prefer template-usage.md)", and make its skills/scripts lists match reality or state they diverge deliberately.

**2. Hard-coded personal GitHub Pages links in the front door** — **papercut**
- Files: `README.md` (lines 16, 36, 46)
- Experience: The primary "start here" links go to `kashman001.github.io`. Fine until the upstream moves; for a fork, they point at someone else's rendered docs. The local sources are linked too, so it's recoverable.
- Fix: Note in the "Fill in" header that adopters should strip/replace the Pages links, or make setup-guide.html the local-first link.

### Stage 2 — Setup

**3. The documented setup order guarantees a red failure on first run** — **minor**
- Files: `docs/workspace-setup.md` (lines 61–77), `scripts/check-dependencies.sh` (lines 43–48)
- Experience: Step 2 says run `check-dependencies.sh` *before* `setup.sh`. But the "hooks" check is a required item that can only pass after `setup.sh` copies `.claude/settings.json.example` → `.claude/settings.local.json`. So a fresh clone's very first documented command exits 1. The error message does say "run scripts/setup.sh", so it self-heals, but a first impression of "your checks fail on a pristine clone" undermines trust in the checks — and `setup.sh` re-runs the dependency check itself anyway (lines 77–79).
- Fix: Swap steps 2 and 3 in workspace-setup.md (setup first, check after), or make the hooks check informational on first run.

**4. The required "hooks" dependency is Claude-Code-only, violating the template's own agent-agnostic principle** — **major**
- Files: `scripts/check-dependencies.sh` (lines 43–48), `docs/recommended-tooling.md` ("Required for everyone")
- Experience: I'm a Codex/Copilot shop. `check-dependencies.sh` hard-fails (exit 1, "MISSING (required)") unless `context-budget-claude-hook` appears in `.claude/settings*.json` — a file that only matters if I run Claude Code. Meanwhile the genuinely-committed hook wiring for Codex/Gemini/OpenCode/Copilot (`.codex/config.toml`, `.gemini/settings.json`, `.github/hooks/`) isn't checked at all. The stated rule ("must work for Codex/Gemini/Copilot, not just Claude Code") is broken by the required-manifest.
- Fix: Check for *any* runtime's hook wiring (most ship committed, so this mostly passes for free), and only require the Claude copy when `claude` is on PATH.

**5. Typo in a copy-pastable install hint: `graphifyy`** — **papercut**
- File: `scripts/check-dependencies.sh` (line 52: `"graphify install (uv tool install graphifyy)"`)
- Experience: An agent following the runbook pattern ("follow the fix text") will run `uv tool install graphifyy` and get a package-not-found.
- Fix: Correct the spelling.

### Stage 3 — Onboarding a product repo

**6. Onboarding leaves the placeholder example entry rotting in the registry** — **minor**
- Files: `docs/repos-registry.md` (lines 18–31), `scripts/onboard-repo.sh` (`add_registry_entry`)
- Experience: The script appends a new `## <repo>` section but never removes the shipped `## <repo-name> (primary)` example. The instruction to delete it lives only in an HTML comment at the top of the file. After my first onboard I have a registry with one real repo and one placeholder — and `setup.sh --clone-repos` greps the whole file for clone URLs, so leftover example URLs (if a user half-fills them) would get cloned.
- Fix: Have `onboard-repo.sh` detect and offer to remove the `<repo-name>` placeholder block, or move the example into an HTML comment.

**7. The mandatory per-step budget checkpoint makes a one-repo onboard feel like filing a flight plan** — **minor**
- File: `skills/onboard-repo/SKILL.md` (lines 30–34)
- Experience: "Measured checkpoint (mandatory, after each step below)" — that's 8 `record` invocations for onboarding a single small repo. The mechanism is cheap (one bash call), but labeling it *mandatory* at every step for a workflow that might take 20 minutes reads as ceremony. The rationale (onboarding can be genuinely long) is real but undifferentiated.
- Fix: Scope the mandate: "after each *repo* and after the expensive steps (3–5)"; the WARN/STOP hook already covers Claude Code in-band.

### Stage 4 — Daily feature work

**8. Core plumbing writes into a template-development work directory** — **major**
- Files: `scripts/context-budget.sh` (line 40: `LEDGER="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"`), `docs/context-budget.md` ("Ledger")
- Experience: Every `record` in *my* workspace appends telemetry to `work/context-decay/` — the maintainer's research project directory. If I prune `work/` (any sane adopter's first move), the dir silently reappears with one JSONL file in it, named after a research effort I deleted. I spent real time deciding whether `context-decay` was infrastructure or residue. It's both, which is the problem.
- Fix: Move the ledger to `.context-budget/ledger.jsonl` (it's already gitignored machine-local telemetry — same class as everything else in `.context-budget/`).

**9. The template never tells adopters what to do with the shipped `work/` history** — **major**
- Files: `docs/template-usage.md` (whole file), `work/` (~1MB: `automatic-session-rollover/` 640K, `context-decay/` 196K, `usage-scenarios/` 108K, plus three more)
- Experience: Step 2 of template-usage.md walks every placeholder file — but never mentions that `work/` arrives pre-populated with six of the maintainer's research projects (handoffs, decisions, research dumps, smoke tests). `CONTEXT.md` says active work lives in `work/<project>/`; a skeptical dev's first question — "is this mine to delete?" — has no documented answer. Worse, `README.md` (line 28) cites `work/usage-scenarios/scenarios.md` as *documentation*, so deleting isn't obviously safe either.
- Fix: Add a step to template-usage.md: "delete `work/*` except …" — and promote anything doc-worthy (the scenario catalog) into `docs/` or `docs/archive/` first so `work/` can be cleanly emptied.

**10. Shipped skills cite the maintainer's analysis files as evidence** — **minor**
- File: `skills/session-rollover/SKILL.md` (lines 30–34, 49: `work/context-decay/ledger-analysis*.md`, `work/context-decay/rollover-cost-analysis-2026-08-11.md`)
- Experience: The skill's WARN policy justifies itself with pointers into `work/context-decay/` — dangling references the moment an adopter prunes. The *numbers* (1–7K light vs ~20K heavy rollovers) are valuable; the pointers are not portable.
- Fix: Keep the figures inline, drop or relocate the evidence pointers (e.g. to a committed doc under `docs/archive/`).

**11. The context-budget conceptual surface far exceeds what a small team needs on day 1** — **major** (adoption risk, not a defect)
- Files: `docs/context-budget.md` (620 lines), `docs/workspace-structure.md` ("Before You Add a Teammate"), `docs/work-directory-conventions.md` (session numbering / ADR-0007)
- Experience: The daily loop is actually cheap — in Claude Code, `register` is a hook, `record` is one bash call, and the rollover costs are honestly measured. But to *trust* it I had to absorb: four session roles, advisory locks with mtime liveness, per-child `.agent-locks/`, dispatch records with generation fencing, `--takeover` semantics, `.session-seq` verbatim-number rules, and a six-runtime hook matrix. The doc's own "don't read this whole file" banner and grep-index are a good mitigation, but there's no statement of the *minimal viable subset*. A busy dev will either adopt it whole (and drown) or ignore it (and lose the actual value: register/record/rollover).
- Fix: Add a "Minimal mode" section near the top: "Solo dev, one session at a time? You need exactly: `register` (automatic in Claude Code), `record` at work-unit boundaries, and the `session-rollover` skill at WARN/STOP. Everything below the Quickstarts is for concurrent sessions and subagent fleets — skip until you run those."

**12. Documentation drift in three self-describing counts** — **minor**
- Files: `docs/template-usage.md` (line 74: "five reusable workflows" — eight ship), `docs/README.md` (line 40: "nine suites" — ten exist in `scripts/tests/`), `docs/workspace-structure.md` (scripts tree, lines 739–758, omits `rollover-prep.sh`, `attach-session.sh`, `capture-rollover-options.sh`, `context-inspect.sh`, `context-experiment.sh`, `statusline-context-budget.sh`)
- Experience: Small, but this template's whole pitch is doc discipline — and its hand-maintained inventory lists are already stale in the shipped state. It's exactly the rot mode CONTEXT.md warns about ("this list is hand-maintained; a skill absent from it is invisible").
- Fix: Replace literal counts with "the workflows below"; add a check to `check-workspace-structure.sh` that diffs `skills/*/` against the CONTEXT.md skills list.

### Stage 5 — Collaboration & handoff

**13. `checkpoint` leans on the optional toolchain without guarding for its absence** — **minor**
- Files: `skills/checkpoint/SKILL.md` (lines 31–32, 65–67, 75), `docs/agents/issue-tracker.md`
- Experience: A vanilla adopter (no superpowers plugin, no Matt Pocock setup, no global `handoff` skill) runs `/checkpoint` and hits references to `docs/agents/issue-tracker.md` conventions, "the global `handoff` skill (`docs/recommended-tooling.md`)", and a catch-up prompt that suggests `superpowers:brainstorming` as the starting skill. Each has an "if configured/installed" hedge, but the vanilla path is defined by subtraction rather than stated.
- Fix: One line per dependency naming the fallback explicitly ("no tracker configured → use `BACKLOG.md`; no handoff skill → write the doc per the contract below; suggest a starting skill from `skills/` only").

Positive note on this stage: the launcher/ledger split itself is *very* learnable. `docs/work-directory-conventions.md`'s side-by-side table (replace vs append, forward vs backward, read-whole vs read-top-block) plus the mandatory purpose headers in each file means even an agent that never read the doc gets the discipline from the files themselves. This is the strongest single convention in the template.

### Stage 6 — Maintenance

**14. Predicted rot order: hand-maintained inventories, then the vendor hook matrix, then repo-context freshness** — **minor**
- Files: `CONTEXT.md` ("Workspace Skills" list), `docs/context-budget.md` ("Vendor hook deployments" — claims pinned to "verified 2026-08-06/2026-08-11, VS Code 1.132.0"), `scripts/check-repo-context.sh`
- Experience: (a) The skills list and doc counts are already drifting (finding 12) with no check. (b) The six-runtime hook table encodes vendor internals ("`{decision:"block"}` is IGNORED by VS Code, exit-2 is the only working channel") that vendors will silently change; the doc admirably dates every claim but nothing re-verifies them — the first sign of rot will be hooks silently not firing, which the Copilot row itself documents as the failure mode. (c) Repo-context docs have a freshness checker, but it's warn-only and only wired into the ending echo of `setup.sh` — nothing runs it routinely.
- Fix: Add the skills-list reconciliation to `check-workspace-structure.sh`; add a `scripts/tests/` smoke that at least asserts each wired hook script exists and is executable per runtime; mention `check-repo-context.sh` in the checkpoint skill's reconcile step.

## What works well

1. **`scripts/setup.sh` is real-world-hardened, not aspirational.** It repairs symlinks flattened by Windows clones and GitHub's copy-based "Use this template" flow (lines 24–30), seeds Copilot's `trustedFolders` while preserving JSONC comments (lines 52–72), and is idempotent throughout. This is scar tissue from actual failures, encoded.
2. **The check-script / runbook pairing** (`scripts/check-*.sh` + `docs/runbooks/`) cleanly separates "verify, never mutate" from "sanctioned fix steps per OS", with `docs/runbooks/README.md` stating the agent protocol in five lines. Both check scripts print exact fix commands on failure. This is the right shape for agent-driven machine setup.
3. **`docs/work-directory-conventions.md`** — the launcher/ledger table, the "past-tense → ledger; future-tense → launcher" rule, and the in-file purpose headers make the convention self-enforcing. `skills/create-work-item/SKILL.md` scaffolds it with verifiable postconditions.
4. **The onboard-repo mechanical/judgement split**: `scripts/onboard-repo.sh` does the deterministic half (registry entry, template copies, provenance stamps, graphify wiring, `--refresh`) idempotently and never fails on missing graphify; `skills/onboard-repo/SKILL.md` owns the judgement half; `scripts/check-repo-context.sh` closes the staleness loop. Also `docs/repo-context/README.md`'s "library vs index at the back of the book" framing for docs-vs-graph is genuinely clarifying.
5. **Honest self-measurement.** `docs/context-budget.md` flags its own unverified paths ("**unverified** against a live session"), the rollover skill quotes measured costs rather than vibes, `docs/workspace-structure.md` ships a "Before You Add a Teammate" section candidly listing where the single-user model breaks silently, and `check-workspace-structure.sh` even verifies the rendered HTML is in sync with its markdown source (it is). Rare intellectual honesty for a template.

## Top 3 changes I'd make first

1. **Ship a clean day-1 state**: add a "prune the template's own work" step to `docs/template-usage.md`, move the ledger from `work/context-decay/context-ledger.jsonl` to `.context-budget/ledger.jsonl`, promote `work/usage-scenarios/scenarios.md` into `docs/archive/`, and strip `work/context-decay/*` evidence pointers from `skills/session-rollover/SKILL.md`. (Findings 8, 9, 10 — the single biggest trust repair.)
2. **Make the required-dependency manifest match the agent-agnostic promise**: runtime-aware hooks check in `scripts/check-dependencies.sh`, and swap the check/setup order in `docs/workspace-setup.md` so a pristine clone's first command succeeds. (Findings 3, 4.)
3. **Add "Minimal mode" to `docs/context-budget.md`** — three commands and one skill for the solo case, with everything else explicitly labeled as concurrent-session/fleet machinery — and defuse the from-scratch bootstrap trap in `docs/workspace-structure.md` by marking it a degraded appendix path. (Findings 1, 11.)

---

# Addendum — Spec Workflow

> Requested follow-up (user directive: a spec for a major initiative should be
> produced by a PM+dev collaboration, mix varying by project).

**Persona gut reaction:** when I asked "where does a spec for a major initiative live and how do my PM and I write one together?", the workspace gave me a one-line file-path convention, a product-level template at the wrong altitude, and a toolchain that turns out to live in the maintainer's home directory, not in the repo. The spec story is the least-built lifecycle stage in an otherwise over-built workspace.

## Findings: Spec workflow

**S1. The initiative-level spec is a one-line convention with no template, structure, or workflow** — **major**
- Files: `docs/agents/issue-tracker.md` (line 26: "The spec (PRD) is `work/<effort-slug>/spec.md`" — the entire convention), `docs/work-directory-conventions.md` (line 97: `spec.md` "Optional"), contrast `SPEC.md` (root)
- Experience: The workspace has *two* things called a spec at different altitudes. Root `SPEC.md` is the Z0 product-identity doc — and it gets a real template (What/Requirements/Constraints/Out-of-scope) plus an interview procedure in `docs/workspace-structure.md` ("Z0 product interview"). The per-initiative PRD — the thing a major feature actually needs — gets a filename and nothing else: no template, no required sections, no lifecycle, and nothing shipped in `skills/` ever reads or produces it. `create-work-item` lists it under "create only if the project needs them now" with no guidance on what "needs" means. The name collision (`SPEC.md` vs `spec.md`) means "where's the spec?" has two answers, one of them wrong.
- Fix: Ship a `spec.md` skeleton (Problem / Solution / numbered user stories / Out of scope / Status header) — either in `docs/repo-context/_templates/`-style form or inlined in `skills/create-work-item/SKILL.md` step 6 — and one paragraph distinguishing it from root `SPEC.md`.

**S2. The spec-authoring toolchain isn't in the repo — it's the maintainer's personal global setup** — **major**
- Files: `~/.claude/skills/to-spec/`, `~/.claude/skills/to-tickets/`, `~/.claude/skills/grilling/` (outside this repo); `~/.claude/CLAUDE.md` (the workflow table that says when to use them); vendored contrast: `skills/wayfinder/SKILL.md`
- Experience: The path from discussion to spec to tickets (`grill-with-docs` → `to-spec` → `to-tickets`) exists only as the user's private Matt Pocock global skills, referenced from a personal `~/.claude/CLAUDE.md` no teammate or adopter will have. The template *did* vendor `wayfinder` (with a clean provenance comment and refresh procedure — good pattern), and `docs/agents/issue-tracker.md` explicitly wires "the Matt Pocock engineering skills (wayfinder, to-tickets, triage, …)" to local paths — but two of the three skills that config exists to serve aren't in the box. `docs/recommended-tooling.md` files them under optional global toolchain. This directly violates the workspace's own memory-recorded principle ("integrations must be agent-agnostic … vendor in-repo with provenance when needed"): a Codex-only teammate on a fresh machine has an issue-tracker config for skills they don't possess, and no spec workflow at all.
- Fix: Vendor `to-spec` and `to-tickets` alongside `wayfinder` (same provenance-comment pattern), or state in `docs/agents/issue-tracker.md` that they are prerequisites installed per `docs/recommended-tooling.md` — currently that dependency is silent.

**S3. There is no PM+dev collaboration surface — single author is baked in at every layer** — **major**
- Files: `docs/workspace-structure.md` ("Before You Add a Teammate", lines 308–330; ADR-0004), `~/.claude/skills/to-spec/SKILL.md` ("Do NOT interview the user — just synthesize"), `docs/agents/issue-tracker.md` (Status vocabulary: `claimed`/`resolved` only), `docs/work-directory-conventions.md` (STATUS.md row)
- Experience: Evaluated against the premise (spec = PM+dev collaboration), the tooling assumes one dev plus their agent everywhere. `to-spec` is pure synthesis of one dev's conversation — it forbids interviewing. Wayfinder's HITL tickets involve exactly one human. The workspace's coordination model is explicitly "one developer, many sessions", and its own docs warn that a second *person* breaks locks, session numbering, and launcher/ledger single-writer semantics *silently*. There is no draft/in-review/approved state anywhere, no sign-off field, no reviewer convention, and no documented way for a PM to comment or iterate. `STATUS.md` — "for humans reviewing progress" — is the only PM-facing artifact and it's one-way reporting. The one thing that would work — spec authored on a branch, PM reviews via PR — is safe precisely because specs are committed files rather than session runtime state, but no doc says so, and `work/` files are normally committed straight to main by the primary session.
- Fix: Don't build collaboration machinery; ride on git. Document a lightweight loop in the spec skeleton itself: a `Status: draft | in-review | approved` + `Approved-by:` header, spec changes go through a branch/PR when a second stakeholder exists, and the PR conversation *is* the PM iteration channel. Explicitly exempt committed spec/ticket files from the single-writer session-lock warnings so a PM editing via PR doesn't look forbidden.

**S4. Spec → tickets → tests traceability is by directory proximity, not by link** — **minor**
- Files: `docs/agents/issue-tracker.md` (ticket conventions), `SPEC.md` ("Keep each item verifiable"), `~/.claude/skills/to-tickets/SKILL.md`
- Experience: The downstream chain *shape* is good: spec and its `issues/NN-*.md` tickets live in the same `work/<effort>/` directory, wayfinder resolutions flow into Decisions-so-far and can promote to ADRs, and commits carry `Decision:`/`Refs:` trailers that graphify can walk. But nothing requires a ticket to name the spec section or user story it implements — the ticket conventions (Status, Type, Blocked-by, Comments) have no `Spec:` field — and spec requirements/user stories carry no stable IDs to point tests at. So "which tickets cover requirement 3?" and "which spec item does this failing test trace to?" are answerable only by reading everything. And with the global skills absent (S2), nothing shipped consumes `spec.md` at all — it's a dead-end file.
- Fix: Add a `Spec: spec.md#<anchor>` line to the ticket conventions in `docs/agents/issue-tracker.md`, and number requirements/user stories in both spec templates so tickets, tests, and commit trailers have something stable to cite.

**S5. A dev has no way to know when a spec is required vs. optional** — **minor**
- Files: `docs/work-directory-conventions.md` (line 97: "Optional — the effort's spec/PRD"), `skills/create-work-item/SKILL.md` (step 6), `CONTEXT.md`
- Experience: The only "non-trivial work needs a spec first" guidance in my session came from the maintainer's personal `~/.claude/CLAUDE.md` workflow table — invisible to any adopter or teammate. Inside the template, `spec.md` is just "Optional", `create-work-item` doesn't ask "does this effort need a spec?", and `wayfinder` mentions a spec only as one possible destination. A busy dev starting a major initiative will scaffold a work item, skip the spec (it's optional and shapeless), and discover the gap at review time.
- Fix: One sentence of policy where work items are born — `create-work-item` step 1: "If the effort is a major initiative (multi-session, cross-repo, or user-visible behavior change), create `spec.md` from the skeleton before drafting tickets; otherwise skip it." Mirror the line in `CONTEXT.md`'s Work Directory Convention paragraph.

## Revised Top 3 changes (spec workflow factored in)

1. **Ship a clean day-1 state** (unchanged): prune-`work/` step in `docs/template-usage.md`, move the ledger out of `work/context-decay/` to `.context-budget/`, strip maintainer work-item references from shipped skills and README. (Findings 8, 9, 10.)
2. **Make the spec workflow real and in-repo**: vendor `to-spec`/`to-tickets` beside `wayfinder`, ship a `spec.md` skeleton with a `Status/Approved-by` header and the git-branch PM review loop, add the `Spec:` ticket field and the "when a spec is required" trigger sentence to `create-work-item`. This is one coherent change and it unblocks the entire PM+dev premise. (Findings S1–S5.)
3. **Fix the setup manifest and add minimal mode**: runtime-aware hooks check in `check-dependencies.sh`, swap check/setup order in `workspace-setup.md`, and add the "Minimal mode" tier to `docs/context-budget.md`; demote the from-scratch Agent Bootstrap section to a clearly-labeled appendix. (Findings 1, 3, 4, 11.)
