# Source notes — DeepSeek Harness

<https://github.com/deepseek-ai/deepseek-harness> ("DeepSeek Harness:
Everything is a Plugin", MIT). Read at commit
`5badb15009ae1756c3afe0ae0cef1faafc290ccc` (master, merged 2026-10-03), from
a shallow, blob-filtered clone outside this repo. Read-only: no upstream code
was run. Everything below is paraphrased (short quotes marked); paths are
relative to the upstream root. Written 2026-10-08, session 1, so later
sessions don't re-read the repo.

Three parts, one per reading pass. Part A was spot-checked against the clone
(`.rgignore` archive exclusion, archive `manifest.json` SHA-256 entries, the
`verify-agent-note-format` / `verify-archived-agent-notes` scripts); Part B
(`.claude/skills` → `../.agents/skills` symlink,
`verify-skill-invocation-metadata.ts`, "report only commands run" at
`AGENTS.md:115`); Part C (`no-unknown-casts.baseline.json`,
`lint-rule-fingerprint.spec.ts`, `approval-policy.json`, `git diff --cached
--check` at `lefthook.yml:35`).

## Root `AGENTS.md` (read directly; 182 lines, `CLAUDE.md` symlinks it)

- Opens with a one-line project description and two "read before" pointers
  (`docs/architecture.md` before changing `packages/`; `docs/AGENTS.md` for docs).
- Repository layout as an annotated tree, one line per package.
- Commands block: one line per `pnpm run` script with a short comment,
  including "ONLY when diagnosing" scoping for expensive ones.
- "Host sandbox failures": retry unchanged with the narrowest escalation,
  require evidence that the sandbox caused it; never bypass test failures.
- "Run relevant checks locally": match evidence to the surface changed;
  never default to the full suite or repeat a passing check; CI owns
  exhaustive coverage; report only commands run (`AGENTS.md:113-120`).
- Conventions are one bold rule per bullet, each self-contained with a
  link to its rationale note — e.g. "Model-visible ⟺ logged", "Misconfiguration
  fails loud", "An empty `catch` names the error", "Keep comments local",
  "Tests describe behavior, not correctness", "Create Agent Notes only for
  durable decision rationale".
- Prose rules: state contracts, not reasoning transcripts; no metaphors;
  ask whether a more exact word than "contract/boundary/shape" exists;
  "Wire mechanically checkable invariants into an executed top-level gate
  and prove each changed acceptance path rejects an invalid case."
- "Editing these instructions": edit the real file, not the symlink; keep
  each rule self-contained; condense when clarity survives; raise the
  `verify-doc-budgets` ceiling only when content genuinely needs it.
- Vendoring policy: pinned copies with upstream SHAs in `vendor/README.md`,
  logged local modifications re-applied or retired on sync.


## Part A — Agent Notes system and documentation rules

Source: the shallow clone (MIT, commit 5badb15). Read-only; nothing executed. Paths below are upstream-relative. "Enforced" = doc-only, a named gate script, or a git hook / CI job.

### Inventory (English notes; each note is a triplet `.md` + `.zh.md` + `.i18n.yaml` sidecar)

| Lifecycle | arch | bug-fix | feature | process | simplif. | testing | total |
|---|---|---|---|---|---|---|---|
| proposed | 12 | 1 | 7 | 6 | 9 | 2 | 37 |
| implemented | 141 | 4 | 33 | 25 | 9 | 15 | 227 |
| rejected | 1 | 0 | 0 | 0 | 7 | 0 | 8 |
| archived (frozen) | 185 | 182 | 306 | 120 | 92 | 39 | 924 |

So the archive is ~3x the active corpus: they keep pruning aggressively. Archive manifest `.agents/notes/archived/manifest.json` = `{ "version": 1, "files": { "<class>/<file>": "sha256:<hash>", ... } }`, one entry per triplet file (~2,770 entries).

### Decision-rationale lifecycle (Agent Notes)

- **What a note is for.** It records the *why* and *what we gave up* that code and docs cannot carry; agents treat them as RFCs. Path: `.agents/notes/README.md` L5; `.agents/notes/AGENTS.md` L3. Enforced: doc-only.
- **Two axes, both in the path.** `{lifecycle}/{class}/yyyy-mm-dd-topic.md`. Lifecycle = folder (`proposed/`, `implemented/`, `rejected/`); the note *moves* when its status changes. Date = when first proposed. README L9-17. Enforced: `scripts/agent-note-tree.ts` + `verify-agent-note-classification` (closed lifecycle/class sets, depth, filename shape).
- **Closed class set with a stated discriminator.** feature / bug-fix / simplification / architecture / process / testing. architecture = shipped source; process = tooling/workflow around it. `refactor` is deliberately left out because "does observable behavior change?" already sorts it into simplification. Adding a class means editing the code constant and the README together. README L21-34; `scripts/agent-note-tree.ts` L17. Enforced: classification gate.
- **No central index.** The folder tree *is* the inventory; an `INDEX.md` would duplicate path metadata and become a merge-conflict hotspot. README L19. Enforced: doc-only.
- **Fixed header, status agrees with folder.** First lines are `# Agent Note: <title>`, blank line, `Status: proposed|implemented|rejected — <one-line why>`. No dates or parentheticals in the status (filename + git carry those). Rejected is the only status with content, because the verdict is what readers come for. README L58-74. Enforced: `scripts/verify-agent-note-format.ts` (regex per lifecycle, L22-26).
- **Per-lifecycle body skeleton.** Every note opens with `## Problem`, written so it stands without the solution. proposed: Proposal / Alternatives / Acceptance criteria / Risks. implemented: Decision (present tense) / Alternatives / Consequences (what it cost *and* what it bought). Rejected: the proposal frozen as it was. Bespoke sections are allowed in between. README L76-107. Enforced: format gate `REQUIRED` map.
- **Spec-speak banned once shipped.** `## Proposal`, `## Plan`, `## Migration plan`, `## Acceptance criteria` are rejected in `implemented/`. README L103; `verify-agent-note-format.ts` `BANNED_IMPLEMENTED`. Enforced: format gate.
- **Alternatives considered is mandatory, and never invented.** Every alternative gets one bold-led paragraph or a `### Why not X?`. Notes older than the format date may carry an exact grandfather comment instead, and the gate accepts it only for files dated before 2026-07-05. README L109-117; `verify-agent-note-format.ts` L12-16. Enforced: format gate (date-bounded grandfathering).
- **Moving between lifecycles is a mechanical rewrite.** proposed to implemented turns Proposal into a present-tense Decision and folds Acceptance criteria and Risks into Consequences or Testing. proposed to rejected only adds the reason to Status and freezes the file. README L119-121. Enforced: the format gate fails a move that does not meet the new folder's skeleton.
- **Implemented notes are kept true to what shipped.** When code moves a path, renames a symbol or changes a default, the note is fixed in the same change: rewrite the stale fact in place, don't append history. A *reversal* of the decision needs a new note, cross-linked. `.agents/notes/implemented/AGENTS.md` L5-13; README L13, L48. Enforced: doc-only. `verify-doc-refs` only catches broken `docs/` or `.agents/notes/` paths cited in `packages/**/*.ts` comments.
- **When to write one.** Only for lasting rationale that code, tests and existing docs do not explain, in the same PR. Updating the note that already owns the decision counts; no duplicates. Mechanical and local UI edits are exempt. README L44-48; root `AGENTS.md` L153. Enforced: doc-only.
- **Supersession check on every new note.** Whoever writes the new note searches the active tree for overlapping notes and archives or consolidates them *in the same PR*. Waiting for a later audit was rejected: the author has the freshest evidence. `.agents/notes/AGENTS.md` L5; skill `dsh-archive-agent-notes` L14-16; rationale `implemented/process/2026-07-26-frozen-agent-note-archive.md` "Alternatives". Enforced: doc/skill only.
- **Consolidation rules.** A fully superseded note may be merged into its successor and deleted, but only after every unique rationale, alternative, consequence, verification and coverage gap is carried over, every inbound link is repaired, and git history is not relied on as the only copy. Partial supersession means keep both notes, cross-linked. A note that added a feature folds into the removal note only when the feature is gone from code, config, schemas, wire formats and docs. README L50-52. Enforced: doc-only.
- **Cross-references are relative markdown links, never prose or numbers**, so they survive folder moves and can be checked by machine. README L17; `docs/AGENTS.md` L74-76. Enforced: `verify-md-links`. `verify-repository-references` also rejects commit SHAs and disallowed org URLs in maintained files.

### Archiving and deletion (frozen history)

- **Three outcomes, judged on future value.** For implemented notes: *delete* (small UI or purely mechanical changes), *keep active* (still governs alternatives, ownership, negative guarantees, wire semantics, security, or a reintroduction condition), or *archive* (complete, unlikely to guide future work, but historically worth keeping). Proposed notes are never archived; reject them instead. Rejected notes stay only as guardrails against a tempting mistake, otherwise delete them. README L36-38; skill L18-29. Enforced: skill-driven judgment.
- **Calibrated examples instead of thresholds.** The skill lists real keep/delete/archive cases with word counts to show that size and age are not the test. Explicitly "do not archive toward a quota". Borderline calls go in the handoff. `.agents/skills/dsh-archive-agent-notes/SKILL.md` L29-52, L68. Enforced: doc-only.
- **Archival is a narrowly specified edit.** Move the whole triplet to `archived/{class}/` (the `implemented` segment is dropped), insert the same `Archived: YYYY-MM-DD` line under Status in both languages, re-record the sidecar, and fix inbound links. Nothing else is permitted. README L40; `archived/AGENTS.md` L5; skill L54-60. Enforced: `scripts/verify-archived-agent-notes.ts` (closed class tree, complete triplets, archive metadata, sidecar hashes).
- **Sealed and append-only.** Every archived file is SHA-256-hashed into `manifest.json`. `--write` mode first proves all existing seals still match, then appends only new hashes. Any change to a sealed file fails, except a few exact old-to-new hash exceptions coded in `scripts/archived-agent-notes.ts`, each with a documented reason. `archived/AGENTS.md` L7-9; skill L60. Enforced: archive verifier (quick tier of `doc-sync`).
- **Archived notes are outside current authority and outside the other gates.** All other doc gates skip the archive, including its outbound links: fixing them would rewrite history. Inbound links *into* the archive are still valid. README L42; `scripts/verify-concrete-terms.ts` `excludedPrefixes`; lefthook pre-commit excludes `.agents/notes/archived/**`. Enforced: gate exclusion lists.
- **Archive hidden from default search.** `.rgignore` excludes `/.agents/notes/archived/` so stale facts don't outrank current ones in a parent-directory grep. Historical queries name the directory explicitly. `.rgignore`; frozen-archive note "Decision" para 3. Enforced: tooling config.
- **The policy has its own rationale note** with seven rejected alternatives (delete everything, keep everything, leave in search, defer to audits, archive proposals too, keep gating the archive, allow factual refreshes). `implemented/process/2026-07-26-frozen-agent-note-archive.md`. The system documents itself with its own format.

### Documentation standard (`docs/AGENTS.md`, 76 lines / ~1,316 words)

- **One home per fact: a tier table.** Each tier lists its job *and* what does NOT belong there, with an arrow to where it goes. Examples: root AGENTS.md holds standing orders only, 1-3 lines each, linking to the rule's home. architecture.md is the map. Agent Notes hold rationale. postmortem/ is "the only tier where war-story narrative belongs". cookbook/ holds how-tos with numbered verify steps. Generated catalogs are never hand-edited. `docs/AGENTS.md` L15-35. Enforced: mostly review, plus generator freshness gates (`verify-tool-catalog`, `verify-config-catalog`, etc.).
- **One-line placement router.** "bugs → postmortems; rationale → Agent Notes; procedures → cookbooks; type definitions → subsystems; package contracts → READMEs; standing orders → root AGENTS.md with a rationale link". L35. Enforced: doc-only.
- **Scope by tree position.** A document covers its own subject in detail and its direct children only by purpose, linking down for anything lower. Every doc is classified as tutorial or reference, and the two are kept apart. Tutorials order concepts by prerequisite and difficulty. L7-13. Enforced: doc-only (skill `dsh-doc`).
- **Document current state.** History belongs in commits, PRs, notes, postmortems; other prose names live mechanisms, not changes. No "implemented!" or "future:" status annotations, because status rots. L39, L66. Enforced: doc-only / slop audit.
- **Word budgets with a relocate, condense, raise order.** `scripts/doc-budgets.manifest.json` maps 8 standing docs to `wc -w` ceilings (root AGENTS.md 1960, docs/AGENTS.md 1320, architecture.md 2410, ...). When over: first relocate to the right tier, then condense, and raise the ceiling only with a PR justification ("a too-low ceiling is a budget bug"). Ceilings are guardrails, not reduction targets: keep ≥5% headroom and freeze when over target. A missing or renamed budgeted file fails, so a rename can't silently escape the budget. `docs/AGENTS.md` L48-58; `scripts/verify-doc-budgets.ts` (58 lines). Enforced: `verify-doc-budgets` (quick tier). Gap: the prose names targets (e.g. subtree AGENTS.md ≤600) that the manifest does not list, and `packages/client/AGENTS.md` is ~3,474 words unbudgeted ("Review governs unbudgeted tiers").
- **Slop checklist.** Things to hunt for: duplicated rules (grep a distinctive phrase, keep one home), history outside its tier, status annotations, hand-restated catalogs or JSDoc, reasoning transcripts, rationale repeated across sibling methods, paragraph walls, emphasis inflation, spec-speak in implemented notes. L60-72. Enforced: doc-only; the `dsh-doc` skill runs it as an audit.
- **Prose: preserve the complete proposition.** Before trimming, list every actor, condition, modality, negative guarantee, ownership and failure mode, and keep them all. "A smaller word count alone is not an improvement." Coverage requirements per location (JSDoc, comments, tests, READMEs, notes, skills, diagnostics). `.agents/skills/dsh-prose-standard/SKILL.md` L28-61. Enforced: skill; `verify-export-jsdoc` for JSDoc presence.
- **Concrete terms over metaphor.** Name the exact check or API instead of "gate", "surface", "shape". Reserve `contract` for real obligations. One ambiguous word is banned outright by a gate. `docs/AGENTS.md` L46; root `AGENTS.md` L150, L172. Enforced: `verify-concrete-terms` (single banned term); otherwise doc-only.
- **Mechanical prose rules wired into gates.** One physical line per paragraph (`verify-md-wrap`). Fenced `ts` blocks must compile (`doc-typecheck`). Pasted types are checked for drift (`verify-type-equiv`). Bilingual pairs carry per-section hash sidecars (`verify-translation-pairing`, also run in pre-commit). L41-44. Root AGENTS.md L172 sets the meta-rule: wire mechanically checkable invariants into an executed top-level gate and show each one rejects an invalid case.
- **Fact-check by running, not remembering.** Every claim about an operation must have been run against the current checkout; delete what you couldn't reproduce ("fix the claim — not the test"). `.agents/skills/dsh-doc/SKILL.md` L39-47. Enforced: doc-only.
- **Docs ship with code.** Update the affected README, JSDoc and subsystem page in the same change. root `AGENTS.md` L174; `docs/AGENTS.md` L43. Enforced: partially (`verify-type-equiv`, `verify-subsystem-pages`).

### Gate wiring

- `pnpm run doc-sync` → `scripts/run-gates.ts doc-sync` (1,676-line orchestrator, gate list L795-852). It runs ~45 doc gates in parallel: doc-typecheck, docs-site build, md-links, md-wrap, type-equiv, translation-pairing, every generated-catalog freshness check, repository-references, concrete-terms, doc-refs, subsystem-pages, package README checks (summaries, model-experience, limitations), agent-note-classification, agent-note-format, archived-agent-notes, skill-invocation-metadata, doc-budgets, upgrade-guides, and `scripts/doc-standard.spec.ts` (vitest checks on the doc standard and the skill itself).
- `doc-quick` / `pnpm run test:docs` runs only the gates flagged `quick: true` (no builds) for fast local feedback. L858-860.
- Where it runs: CI `.github/workflows/docs-pages.yml` L74. Local `lefthook.yml` pre-commit is kept fast (translation pairing on staged sidecars, `git diff --cached --check`, vendor manifest); "CI owns the full repository-wide gate matrix" (lefthook L1-2).

### Scoped instructions (AGENTS.md tree)

- **22 AGENTS.md files.** Root; subtrees `.github/`, `benchmarks/`, `docs/`, `scripts/`, `snapshots/`, `vendor/`, `website/`, `native/system/`, `packages/` (+ `client/`, `experimental/`, `schedule/`, `web/`), `apps/cli/tests/profiles/`, `.agents/notes/` (+ `implemented/`, `archived/`). The other 4 are test fixtures under `snapshots/session/*/workspace/{,nested/}`, which exercise the harness's own nested-instruction loading.
- **Subtree file = only that subtree's orders.** Repo-wide rules stay in the root file. `docs/AGENTS.md` L22. Subtree files are short: scripts 116 words, vendor 84, notes 3-9 lines each. They usually say "follow root + docs standard" and add 1-3 local rules. Example: `.agents/notes/implemented/AGENTS.md` = "keep facts current, not a licence to rewrite the decision". Enforced: budgets cover root, docs/ and packages/ only.
- **CLAUDE.md is a symlink to AGENTS.md** in 4 places: root, `packages/`, `vendor/`, `.agents/notes/implemented/`. Root AGENTS.md L178: "edit the real file". Other subtrees have only AGENTS.md. `agent-note-tree.ts` `ROOT_ALLOWLIST` lets AGENTS.md/CLAUDE.md sit inside the notes tree.
- **Root AGENTS.md style.** Standing orders as bold one-liners, each linking its rationale (often an implemented Agent Note). Includes an "Editing these instructions" section: keep rules self-contained, condense when clarity survives, raise the budget only when needed. root `AGENTS.md` L128-178. Enforced: `verify-doc-budgets` (1,905 of 1,960 words).
- **`snapshots/AGENTS.md`** is a dense scope rule: only session-replay tests live there, everything else stays owner-local; filename and version conventions for fixtures; "fix fixtures, not normalizers". Enforced: `scripts/session-snapshot-corpus-policy.ts` corpus gate.

## Part B — Agent skills

Read-only study. All paths are relative to the clone root. Everything below is paraphrased; short quotes are marked.

### Layout and discovery

- Skills live in `.agents/skills/<name>/SKILL.md`, one level deep, with optional `references/`, `templates/`, `scripts/`.
- `.claude/skills` is a **symlink** to `../.agents/skills`, so Claude Code finds the same tree. That is the only item in `.claude/`. Root `.gitignore` ignores `.claude/commands/`, `.claude/settings.json`, `.claude/launch.json`, and `CLAUDE.local.md`, so per-user Claude config stays out of git.
- `.agents/skills/.gitignore` holds one line: `*/agents/openai.yaml`. Codex per-skill product metadata (`agents/openai.yaml` with `policy.allow_implicit_invocation`) is local-only. No such files exist in the clone.
- `scripts/verify-skill-invocation-metadata.ts` is a gate. For each skill that has a local `agents/openai.yaml`, it checks that Claude's `disable-model-invocation: true` matches Codex's `allow_implicit_invocation: false`, that both are booleans, and that a manual-only skill is not also `user-invocable: false`. It is part of `pnpm run test:docs` (dsh-doc → Validation, "skill-invocation metadata check").
- Root `AGENTS.md` links skills at the point of need. Examples: line 11 (upgrade guide on any break) and line 115 (before pushing, follow dsh-pre-push-checks; "report only commands run"). `docs/AGENTS.md:33` sets the scope rule: skills hold reusable workflows and decision standards, while product and runtime contracts go to docs or source.
- `.agents/notes/` (Agent Notes, i.e. decision records: proposed/implemented/rejected/archived, bilingual triplets) sits beside the skills. Many skills cite an archived note as the "why".

### Per-skill notes (15 skills; line counts are SKILL.md only)

### dsh-pre-push-checks — `.agents/skills/dsh-pre-push-checks/SKILL.md` (136)
- Trigger: before a push, force-push, ready-for-review, or any claim that checks pass. Also right after `gh stack sync`. Goal: the *smallest* covering checks, not "reflexively running the full repository suite".
- Steps: confirm the branch → run `change-scope --base <verified-base>`. The tool never guesses a base; the agent supplies a ref it verified → pick checks with a surface→evidence map (package behavior → owning Vitest file; docs → doc-sync; visible output → snapshot; manifests → build + smoke; real provider → e2e) → push → check that the remote ref equals HEAD → read `gh pr checks`.
- Distinctive points:
  - Separate test selection from coverage selection (`--coverage.include` scoped to the changed sources).
  - Do not re-run what the pre-push hook already runs.
  - "Full local rehearsal" only on explicit request, during CI diagnosis, or for a truly repo-wide change.
  - `--force-with-lease=<branch>:<observed-oid>`. Raw `--force` is never allowed.
  - Post-sync checklist: validation stays "pending" until it passes.
  - A gotcha: no CI runs on a PR means it is CONFLICTING, and empty commits will not fix it.
  - Reporting: pending is reported as pending; failures are inspected before blaming the environment; a hook is bypassed only with the user's consent.

### dsh-code-review — `.agents/skills/dsh-code-review/SKILL.md` (52)
- Trigger: reviewing a PR in this repo. It orients the reviewer to standards plus "the review-specific checks that code alone can't show".
- Opens with "guidance, not a complete checklist". First fetch the live base and exact head, then run `change-scope`; re-run both after a retarget. Priorities: correctness, lifecycle, security. One substantiated blocker beats a list of nits.
- Structure:
  - "Sources of truth" (links only).
  - 6 numbered **blocking requirements**: new prose gets semantic review, docs match code, core type docs, registrations clean up, required evidence exists, UI copy is locale-owned.
  - About 16 **manual checks** as bold-lead bullets: interface contracts, lifecycle, consumer fit (a new public method with one internal caller is "unnecessary API expansion"), necessity, model perspective (inspect the exact prompts and tool schemas the model sees), enforcement paths, bounds, real entry path, test strength, negative controls.
- Reporting: defect, location, impact, evidence. Inline on the tightest diff range; PR-level for cross-cutting points. Blockers separate from suggestions. Drop anything a green gate already enforces. When receiving review, verify each claim without performative agreement.

### dsh-find-simplifications — `.agents/skills/dsh-find-simplifications/SKILL.md` (65) + `references/historical-patterns.md` (45)
- Trigger: find evidence-backed removals across code, APIs, configuration, tests, and prose; assess another branch's simplifications.
- Frames a simplification as removing **maintained obligations**, not deleting lines. "Few well-supported candidates over a count." A survey is not permission to implement.
- Hard-coded protected designs: two LLM adapters and the persistence seam. Do not propose removing them unless the user overrides.
- For broad requests, fan out over 5 named domains via subagents. Each must bring consumer evidence and rejected alternatives.
- Six discovery questions:
  - Is there a complete effect path from producer to consumer?
  - Which distinctions change what a consumer does?
  - Would a smaller explicit behavior remove a whole subsystem?
  - Can the consumer derive the value at use instead of caching it?
  - Is composition being mistaken for policy?
  - What owns the full maintenance cost?
- For each candidate, record: owner, producer/consumer path, what disappears, what remains, and the strongest reason to keep it. Classify as unreachable / narrower behavior with an explicit loss / protected.
- Reject a candidate if it only relocates complexity.
- Report: surveyed areas, candidates, rejections, and commands actually run. Never call an unverified search exhaustive.
- historical-patterns.md: 7 calibration sections, each pairing a past accepted decision with a past *rejection*, linked to notes. "A past rejection is a scoped falsifier, not a permanent blacklist."

### dsh-prose-standard — `.agents/skills/dsh-prose-standard/SKILL.md` (81) + `references/examples.md` (169)
- Trigger: writing, reviewing, trimming, or auditing any prose. That includes comments, JSDoc, prompts, diagnostics, and UI strings, and deciding where docs or comments are *required*.
- Requires an explicit `scope`. If it is missing, report and stop; never infer a repo-wide scope.
- `mode: automatic|interactive` (default automatic). Mode controls questions, *not* write authority: review tasks only report; fix tasks edit.
- Core rule, "preserve the complete proposition": keep the actor, condition, timing, modality, negative guarantee, exception, ownership, and failure. Fewer words alone is not an improvement.
- "Required coverage by prose location" table: 12 surfaces, among them skills, which state guardrails and scope limits like "guidance, not a checklist".
- Borderline is defined strictly: two versions both preserve every proposition but trade off principles.
  - In interactive mode, present 2–3 viable versions with a recommendation and no weak distractors.
  - After the user decides, distill the result into examples.md and apply it to every analogous passage.
- Reports: scope, changes, deliberate keeps, deferrals, and checks actually run.
- examples.md: an over-trimmed / balanced / over-detailed triad per rule. One entry argues that "explicit skill scope is functional".

### dsh-trim-cot-leakage — `.agents/skills/dsh-trim-cot-leakage/SKILL.md` (45) + `references/examples.md` (275), `references/recall-batteries.md` (52)
- Trigger: prose that reads like a leaked reasoning transcript, e.g. "(decision N)", audit codes, "used to/no longer", "a later PR in this stack", "rejected in review", hedges.
- One test: can a reader at HEAD, with no session transcript, PR thread, or draft, resolve every reference? If not, restate the facts from the repo's vantage and delete the rest.
- 8-class taxonomy: dead session citations, PR/stack vantage, change narration, review choreography, reviewer-addressed justification, derivation transcripts, hedges, authoring-language slips. An explicit "What is not leakage" keep-list follows: issue refs, `TODO(name)`, suppression reasons, "measured:" bounds, counterfactual-present regression pins.
- Workflow: audit read-only first. The batteries are ripgrep probes. Calibrate each probe on a known positive *and* a near-miss negative before trusting zero hits. The batteries under-match, so also read the densest prose by hand. Check the **overcorrection traps** before deleting, e.g. a trim that turns an obligation into an endorsement.

### dsh-ci-test-reliability — `.agents/skills/dsh-ci-test-reliability/SKILL.md` (131) + `references/ci-flake-diagnosis.md` (60)
- Trigger: tests or fixtures at risk from concurrency, clocks, global state, subprocesses, or ports; flaky-CI work. Kept separate from pre-push (it decides *what* evidence, not which commands).
- Sections:
  - Model a 4-layer execution topology.
  - Allocate resources atomically (`listen(0)`, `mkdtemp`).
  - Contain process-global state.
  - Platform semantics (Windows).
  - Budget timeouts against the CI lane.
  - Synchronize on state, never sleeps.
  - Dispose to quiescence.
  - Prove the regression (negative control).
- "Reject flake-masking fixes" list: retries, longer timeouts, serializing everything, weakening assertions.
- A diagnosis-only request stays read-only.
- The reference freezes evidence (SHA, runner, signature) and classifies failures into 8 causes. A runner-infrastructure verdict needs direct evidence.
- Report exact commands. Never describe retries, skips, or pending CI as passing.

### dsh-doc — `.agents/skills/dsh-doc/SKILL.md` (132) + 5 references, 8 templates
- Trigger: create, restructure, audit, or migrate docs, READMEs, or the website.
- Long skill that carries its own Summary and ToC.
- 8-step workflow. Classify the page by one job and reader; place it at its nearest owner.
- **Fact-check procedure: "test, do not assume"**:
  - Run every claimed command against the checkout and write only what was observed.
  - Delete what you could not reproduce.
  - Compare old docs against origin/master.
- Kind system: the frontmatter `kind` maps 1:1 to a template file, and a gate derives the expected kind.
- Voice rules:
  - The Summary says what a reader can DO, not the subject's identity.
  - Developer sections explain rather than enumerate.
  - "Dev Note is the only slop zone": one marked non-authoritative section per page.
  - Current state only.
  - Controlled technical English (ASD-STE100-inspired).
- Quality criteria, defined: brief, intuitive, friendly, accurate, agent-readable, newcomer-complete.
- Word budgets are "guardrails, not reduction targets", with 5% headroom.
- The references section says each reference links directly from SKILL.md, so there is "no deep reference chain".

### dsh-create-upgrade-guide — `.agents/skills/dsh-create-upgrade-guide/SKILL.md` (54)
- Trigger: a change breaks an externally perceptible surface (the list is enumerated).
- Write the guide in the breaking change itself, never at release time.
- Fixed path: `docs/upgrade-guide/v<version>/<item>/guide.md` plus zh and the i18n sidecar.
- Exactly two sections, Change and Migration, at most 500 words, all gate-enforced. Over budget means moving text out (links, a note, a script).
- Older version directories freeze after a version bump.

### dsh-merging-stacked-prs — `.agents/skills/dsh-merging-stacked-prs/SKILL.md` (127)
- Trigger: stacked or dependent PRs.
- **Hard-stops**: no `gh stack` support, or a cross-fork chain. Never fall back to a manual merge-and-retarget.
- GraphQL `PullRequest.stack` is the membership authority, not inference from branch names.
- Auto-link only when every author matches; otherwise ask. Never dissolve or reorder a stack.
- Re-query the stack right before merging. A queued merge is not landed.
- Delete branches only after MERGED and zero dependents.
- Ends with a 7-item checkbox checklist.

### dsh-speed-up-perf — `.agents/skills/dsh-speed-up-perf/SKILL.md` (92)
- Trigger: performance work, benchmarks, CI performance gates.
- Agree on the endpoint, workload, and **stopping rule** first.
- A **measurement card** table (operation, workload, entry path, clock, memory, verdict, behavior) is filled in before implementation.
- Run the unoptimized workload first; change one causal factor at a time; require a negative control.
- Privacy rule: no user-corpus content goes into fixtures.
- Fixed summary shape: workload → before/after → semantics → behavior evidence → negative control → checks → exclusions. Keep historical, local, and CI numbers separate. Stop at the agreed scope and keep a ranked follow-up list.

### dsh-translate-docs — `.agents/skills/dsh-translate-docs/SKILL.md` (74)
- **The only manual-only skill**. Frontmatter: `disable-model-invocation: true`, `user-invocable: true`. The body adds an "Invocation boundary": run only when invoked by name, never from another skill or an inferred need.
- Triage by change type: update / new pair / delete.
- Update path: generate a briefing, then `--apply` for mechanical-only changes or delegate to a subagent with the briefing as its *whole* working set, so it does not re-read the corpus. Make the smallest edit; never re-translate the whole document.
- New pair: the orchestrator does not translate; a subagent does it in two passes (write natively, then verify clause by clause) and then reads the result alone.
- `--write` refuses to run bare. Its YAML diff is the reviewable statement "I confirmed these two say the same thing".

### dsh-client-ui-ux — `.agents/skills/dsh-client-ui-ux/SKILL.md` (62)
- Judgment that lint cannot make: token reuse, a font-weight cap of 500, feedback surface chosen by message lifetime (toast vs in-place vs empty state), overlays that are dismissable, viewport-fitting, and unclipped, and loading states.
- Escalate to a designer review. Includes a dated reviewer roster.

### record-browser-gif — `.agents/skills/record-browser-gif/SKILL.md` (172) + `scripts/encode_gif.py` (337) + its test
- Every GUI-changing PR MUST carry a GIF recorded from a real server, real API key, and real model rounds. State the demonstrated SHA next to it.
- Recording (local only) is kept separate from publishing (only when asked).
- One storyboard = one isolated run; never splice runs.
- Re-check the PR head before and after attaching.
- Verify the *encoded* GIF frames, not only the source frames.
- Never commit media to PR branches; use `gh --attach`, with an orphan assets branch as the fallback.
- Bundles a deterministic encoder whose JSON summary is checked.

### dsh-archive-agent-notes — `.agents/skills/dsh-archive-agent-notes/SKILL.md` (68)
- Every new decision note triggers a scoped supersession audit.
- Classify notes by future decision value (implemented: delete/keep/archive; rejected: keep only as a guardrail against a tempting mistake). "Never archive toward a quota."
- Includes calibrated examples with word counts, to show that size is not the test.
- Archived triplets are hash-sealed and append-only.

### agent-experience — `.agents/skills/agent-experience/SKILL.md` (19, no title heading)
- For tool definitions and skill or context design:
  - minimal context first;
  - explicit discovery for deferred resources;
  - critical constraints shown before the action;
  - bounded outputs;
  - locality;
  - judge by total work.
- Tool-definition rules: delete constraints the model learns from results; put parameter rules on the parameter; say each fact once; measure first-turn tokens before and after.

### .github templates

- `.github/pull_request_template.md`: Motivation (one line plus `Fixes #NN`), Changes (interface changes; observable behavior; "None" if empty), and Testing. Testing is one bullet per method, each with a collapsed `<details><summary>Proof</summary>` holding reviewable output, screenshots, or logs. Guidance comments are in Chinese.
- `.github/ISSUE_TEMPLATE/`: `bug.md` (Summary / Reproduction / Current / Expected / Environment), `feature.md` (Motivation / Behavior), `task.md` (Summary / Deliverables). Each uses the frontmatter `type:` field (GitHub issue types). `config.yml` sets `blank_issues_enabled: false`.

### Cross-cutting patterns

1. **Naming:** a project prefix `dsh-` on repo-specific skills. Generic ones (`agent-experience`, `record-browser-gif`) have no prefix. Names are verb-led or topic-led and kebab-case.
2. **Frontmatter:** minimal, `name` + `description` only. The description is a long trigger sentence ("Use when … / Use before …") that lists concrete triggers, sometimes including user phrases ("stacked PRs") and leaked-wording examples. Only the manual-only skill adds `disable-model-invocation` and `user-invocable`.
3. **One tree, two runtimes:** a `.claude/skills` symlink plus a gitignored per-skill Codex `agents/openai.yaml`. A verifier keeps the manual-only policy identical across Claude and Codex. The invocation policy is enforced by a gate, not only by documentation.
4. **"Guidance, not a checklist/script":** stated near the top of most skills as a functional guardrail (prose-standard examples defend it). Hard blocking requirements are then listed separately from judgment checks.
5. **Evidence reporting:** nearly every skill ends "Validate and report" with "report only commands actually run" (also in root AGENTS.md). Pending is pending. Never call retries, skips, or a search "exhaustive" or passing. Report deliberate keeps, deferrals, and borderline cases as well as changes.
6. **Read-only vs write authority:** stated explicitly. A survey or diagnosis does not authorize a fix; `mode` controls questions, not edits; a missing scope means stop.
7. **Negative controls everywhere:** a gate or test must be shown to fail on the bad case (CI reliability, perf, docs validation, code review).
8. **Sources of truth by link, never restated:** skills say "read, don't re-summarize" and point at AGENTS.md, docs, and notes. "One explanation has one home." References are one level deep.
9. **Skills cross-route by name:** e.g. code-review → prose-standard / ci-reliability / ui-ux, and everything → pre-push-checks. Each skill states what it owns and what it delegates ("this skill owns X; it does not replace Y").
10. **Calibration files:** examples.md with good/over/under triads, historical patterns paired with rejections, and recall batteries with positive and negative controls. The learning loop writes user rulings back into the examples.
11. **Freshness discipline:** re-fetch the live base, head, and OIDs before acting and again after any rewrite. Do not trust earlier reports.
12. **Subagent fan-out** with bounded domains and required evidence (find-simplifications, speed-up-perf). Translation delegates with a precomputed briefing as the whole working set, to save context.

### What a workspace template could borrow (vs its code-review / checkpoint / plans / writing-for-agents)

- A cross-runtime skill-invocation gate: a manual-only flag kept identical across Claude frontmatter and Codex metadata. This matters for the template's "user-invoked only" skills (research-wave, wayfinder).
- An explicit `scope` input and "stop if missing" rule, plus "mode controls questions, not write authority".
- "Report only commands run / pending is pending" as a standard closing section, and a PR template with a collapsed Proof block per test method.
- CoT-leakage taxonomy + one test ("resolvable at HEAD?") → useful for writing-for-agents and handoff/ledger hygiene.
- Code review: blocking requirements kept separate from judgment checks; skip findings a green gate already enforces; prefer one blocker over many nits.
- Simplification = removing maintained obligations; record the strongest reason to keep each candidate.
- Grep probes are calibrated against a positive and a near-miss before zero hits are trusted.

## Part C — checks, gates, CI, review policy, contributor docs

Source: DeepSeek Harness (MIT), commit 5badb15. Read-only study; nothing executed.
All bullets paraphrased; upstream paths in backticks.

### Local hooks (lefthook)

- Hooks are deliberately fast "local checkpoints"; the header says CI owns the full repo-wide gate matrix. `lefthook.yml`
- Hook install is automatic: `postinstall` runs an installer script, so every contributor gets hooks with no extra step. `package.json` (`postinstall`), `scripts/install-lefthook.mjs` (has its own spec)
- pre-commit runs only on staged files, via globbed jobs passing `{staged_files}`. `lefthook.yml`
- Staged lint uses a separate, cheaper lint profile (`.oxlintrc.staged.json`: extends the full config but turns type-aware analysis off and ignores more paths), runs with `--fix`, and re-stages fixed files (`stage_fixed: true`). Full type-aware lint runs only in CI / `pnpm run lint`. `lefthook.yml`, `.oxlintrc.staged.json`
- Regenerate-rather-than-reject: if a dependency manifest changes, the hook regenerates `THIRD_PARTY_NOTICES.md` and `git add`s it, so a forgotten derived file doesn't fail CI much later. Comment notes the one gap (deleted manifests don't trigger) falls through to a freshness test in CI. `lefthook.yml`
- Whitespace gate: `git diff --cached --check` on every commit; AGENTS.md states files end in exactly one trailing newline and names this hook as the enforcer. `lefthook.yml`, `AGENTS.md:162`
- Vendor discipline mechanized: any staged change under `vendor/*/src` must come with a `vendor/README.md` (local-modification log) change in the same commit. `scripts/check-vendor-manifest.sh`
- Translation pairing hook checks exact index bytes (`--cached`) of only the staged paired docs, not a full corpus scan. `lefthook.yml`, `scripts/verify-translation-pairing.ts`
- Archived agent notes are checked on commit and on merge commits (frozen archive with a hash manifest; "append-seal"). `lefthook.yml`, `scripts/verify-archived-agent-notes.ts`, `scripts/archived-agent-notes.ts`
- pre-push runs the full typecheck (slower check pushed one stage later than commit). `lefthook.yml`

### Gates (scripts/run-gates.ts and verify-*)

### Gate runner
- One runner owns every aggregate (`ci-primary`, `ci-static`, `ci-coverage`, `check-all`, `hygiene`, `doc-sync`, `doc-quick`, ...); package scripts are thin public names (`check:ci:*`, `check:all`, `test:docs`). `scripts/run-gates.ts`, `package.json`
- Gates form a validated dependency graph: `needs` (must pass first) vs `after` (must settle, pass or fail, first — preserves diagnostics from downstream gates even when an upstream reader fails). Graph is validated before running. `scripts/run-gates.ts` (`validateGateGraph`)
- Bounded parallelism: local doc-heavy modes cap at 4 workers to avoid memory blowups; CI modes split CPU between sibling gates; env overrides validated as positive integers and fail loud otherwise. `scripts/run-gates.ts`
- Optional fail-fast (`DSH_GATE_FAIL_FAST`); an aborted gate is never reported as passed even if the child trapped the signal and exited 0. `scripts/run-gates.ts` (`GateResult.aborted`)
- Skipped counts as failure for the aggregate verdict unless the gate is marked `allowFailure` (observational lanes, e.g. Windows diagnostics). `scripts/run-gates.ts` (`main`)
- `quick` flag on doc gates derives a build-free doc aggregate (`test:docs` = `doc-quick`) as a filter of the full `doc-sync` list — one list, two speeds. `scripts/run-gates.ts` (`docQuickLeafGates`)
- The runner itself has a spec. `scripts/run-gates.spec.ts`

### Ratchets / baselines
- No-new-`as unknown` ratchet: AGENTS.md rule says preserve or reduce the exact legacy baseline. Enforced by `verify-no-unknown-casts`, which compares current casts to `scripts/no-unknown-casts.baseline.json` keyed by file path + sha256 syntax fingerprint with counts. Any cast not in the baseline fails; baseline entries that no longer match also fail ("stale") until removed with `--prune`, which only runs after confirming nothing new was added. So the baseline can only shrink and must stay exact. Runs in shared hygiene (every CI primary/static run). `scripts/verify-no-unknown-casts.ts`, `AGENTS.md:145`
- Doc word budgets: per-file `wc -w`-style ceilings for standing docs (AGENTS.md 1960, testing.md 1350, ...) in a JSON manifest; missing file or excess fails. Policy: on red, relocate, then condense, and only then raise the ceiling with a justification in the PR; keep at least 5% headroom; ceilings ratchet down. `scripts/verify-doc-budgets.ts`, `scripts/doc-budgets.manifest.json`, `docs/AGENTS.md` (Wordcount Budgets)
- Lint-config fingerprint: rule sets per profile pinned by count + sha256, so a silent lint-rule change (dropping a rule) fails a test. `scripts/lint-rule-fingerprint.spec.ts`
- Executable lint-contract tests spawn the real linter to prove rules fire (e.g. unused-suppression reported, deprecated-API waivers only in tests) — a lint rule is proven by a failing probe, not assumed. `scripts/oxlint-contract.spec.ts`
- Coverage: per-file 100% on package src; uncovered line is treated as likely dead code to delete, not a test to bolt on; coverage called necessary but never sufficient. Heavy suites run uninstrumented beside the thresholded gate only if every file they touch is already fully covered elsewhere. `docs/testing.md`, `scripts/coverage-exempt.ts`
- Proposed (not shipped): mutation score ratchet "thresholds only ever tighten, same as coverage". `.agents/notes/proposed/testing/2026-06-11-mutation-testing.md`

### Generated-artifact freshness
- Pattern `gen-X` / `verify-X = gen-X --check`: every generated catalog (tool, config, dependency, module graph, tsconfig paths, doc graphs, third-party notices, ...) has a `--check` mode run in CI that fails if the committed output is stale. `package.json`

### Doc gates (doc-sync)
- `verify-md-links`: relative links/images resolve, and `#fragment`s must name a real heading slug or explicit anchor; symlinked instruction files deduped. `scripts/verify-md-links.ts`
- `verify-doc-site-fragments`: checks fragments against the built site HTML, since Markdown and the site generator slug headings differently. `scripts/verify-doc-site-fragments.ts`
- `verify-md-wrap`: rejects prose paragraphs spanning multiple physical lines (one line per paragraph), AST-based. `scripts/verify-md-wrap.ts`
- `verify-mermaid`: parses every Mermaid fence with Mermaid itself. `scripts/verify-mermaid.ts`
- `verify-doc-refs` / `verify-package-paths`: root-relative doc paths and `packages/...` references in prose and code must exist. `scripts/verify-doc-refs.ts`, `scripts/verify-package-paths.ts`
- `verify-type-equiv`: code blocks in docs that quote a type must match the source declaration (manifest maps block to symbol). `scripts/verify-type-equiv.ts`
- `verify-concrete-terms`: bans one ambiguous word repo-wide (the term is built by string concatenation so the checker doesn't match itself). `scripts/verify-concrete-terms.ts`
- `verify-public-repository-links` / `verify-repository-references`: reject links to a dead legacy repo and maintained references to raw commit SHAs. `scripts/verify-public-repository-links.ts`, `scripts/verify-repository-references.ts`
- `verify-translation-pairing`: every in-scope doc has an EN/ZH pair with matching structure and recorded per-section hashes; quality stays a reviewer job. `scripts/verify-translation-pairing.ts`
- `verify-translation-prompt`: committed translation prompt renders and parses as documented. `scripts/verify-translation-prompt.ts`
- README section gates: summary word limit (100), mandatory "limitations" section with exactly one bullet (or audited exemption), "Model Experience" section fields/order. `scripts/verify-package-readme-*.ts`
- `verify-subsystem-pages`: every package group links a subsystem doc or carries a justified exemption. `scripts/verify-subsystem-pages.ts`
- `verify-upgrade-guides`: layout/metadata/sections/word ceiling defined by an authoring skill. `scripts/verify-upgrade-guides.ts`
- Agent-note gates: lifecycle/class paths and dated filenames; required headers and sections incl. alternatives; grandfathering only for notes older than a format-adoption date constant. `scripts/verify-agent-note-classification.ts`, `scripts/verify-agent-note-format.ts`
- `verify-skill-invocation-metadata`: keeps Claude Code and Codex invocation metadata aligned for repo skills (cross-runtime skill parity). `scripts/verify-skill-invocation-metadata.ts`
- `verify-export-jsdoc`: every export has JSDoc with params/returns; unknown forms fail closed. `scripts/verify-export-jsdoc.ts`

### Code/architecture gates (one line each)
- `verify-client-domain-graph`: directory-level layering (domains may import `contract/`, never each other). `scripts/verify-client-domain-graph.ts`
- `verify-no-bare-dispatcher`: forbids per-package HTTP agents that would bypass the user's proxy (header cites the real defect). `scripts/verify-no-bare-dispatcher.ts`
- `verify-optional-dependency-imports`: no static import of an optional dep. `scripts/verify-optional-dependency-imports.ts`
- `verify-client-ui-i18n`: no hardcoded UI copy outside locale dictionaries. `scripts/verify-client-ui-i18n.ts`
- `verify-config-source-ownership`: no credentials/endpoints inlined in shipped config. `scripts/verify-config-source-ownership.ts`
- `verify-runtime-closure`, `verify-default-product-isolation`, `verify-application-entrypoints`, `verify-package-*`, `verify-dsh-package-licenses`, `verify-node-next-types`, `verify-npm-install-layout`, `check-workspace-constraints`: packaging/deploy invariants. `scripts/`
- `check-expected-filenames.sh`: bans "golden" in tracked filenames (use "expected"); terminology enforced by a bash gate and a path-filtered workflow. `scripts/check-expected-filenames.sh`, `.github/workflows/expected-filenames.yml`

### Lint & duplication config
- Lint: category defaults off, rules enabled explicitly per file-class override (src / tests / examples / scripts), each relaxation carrying an inline rationale comment. `.oxlintrc.json`
- Agent-loop motivated: no-floating-promises / no-misused-promises called out as "the repository's highest-value linted bug class" (lost promises in the agent loop). `.oxlintrc.json`
- Others: `reportUnusedDisableDirectives`, ts-comment suppressions need a ≥10-char description, no-explicit-any, switch-exhaustiveness, restricted `crypto.randomUUID` with a message pointing to the sanctioned helper, stylistic rules incl. `eol-last`. `.oxlintrc.json`
- sonarjs duplicate-logic rules (identical functions/branches/conditions, duplicate test titles). `.oxlintrc.json`
- jscpd copy-paste detection over `packages scripts` (min 60 tokens / 6 lines, tests ignored, explicit ignore-start/end markers), exit 1 on findings; runs in CI primary and `check-all`. `.jscpd.json`, `package.json` (`duplication`)

### CI

- PR CI is a handful of parallel jobs each calling one runner aggregate (`check:ci:static`, `check:ci:coverage`, `check:ci:bench`, `check:ci:consumers`, node-compat, Python, Windows); CI YAML holds little logic. `.github/workflows/ci.yml`
- Single required verdict job `all-checks-passed` fails if any needed job failed, was cancelled, or was skipped — branch protection requires one check. `.github/workflows/ci.yml`
- Superseded PR runs are cancelled via concurrency group. `.github/workflows/ci.yml`
- Runner failover via a repo variable (hosted / self-hosted / third-party) with a runbook note; standby pool re-proven on every master push. `.github/workflows/ci.yml`, `ci-master.yml`
- CI workflows are themselves unit-tested (runner selectors evaluated, permissions, trusted checkout, commands pinned). `scripts/ci-workflow.spec.ts`
- Telemetry disabled in CI by env. `.github/workflows/*.yml`
- GitLab CI is only a tag-triggered Python release pipeline, verifying tag matches `package.json` version. `.gitlab-ci.yml`
- Make is a thin alias layer; `package.json` scripts stay the source of truth. `Makefile`

### Review policy

- Weighted approval: a commit status requires 2 points; listed maintainers count 2, other write-capable reviewers 1; author's own review never counts. `.github/review-ownership/README.md`, `approval-policy.json`
- Blame ownership boost: a 1-point reviewer gets up to 2 points scaled by the share of modified/deleted old production lines they authored (git blame at merge base; tests/docs/comments/blank excluded via a lexer-based classifier). `.github/review-ownership/README.md`, `blame-production.py`
- Author credit: small capped bonus from merged-PR count (max 1.1), cannot satisfy the threshold alone. Same rule for bots. `.github/review-ownership/README.md`
- Any write-capable CHANGES_REQUESTED or draft state keeps it pending; `/delegate @user` comment transfers your points to another reviewer's approval, with detailed revocation rules. `.github/review-ownership/README.md`
- Security posture: status job checks out only the default branch, never runs PR code, no secrets, actions pinned to SHAs; policy changes take effect only after merge so a PR can't change the rules for its own run; partial data fails evaluation rather than producing a partial score. `.github/review-ownership/README.md`
- Policy code has its own test suite run in CI (`test:approval-policy`). `package.json`, `scripts/run-gates.ts`
- Issue policy: non-draft human PRs under review need a same-repo Issue reference, exactly one `kind/*`, ≥1 `area/*`, ≤1 priority; resolving refs must match Issue priority; refs inside code/comments don't count. Uses trusted default-branch code; tested (`test:issue-management`). `.github/issue-management/README.md`, `config.json`
- PR template: Motivation (with issue ref), Changes (interface + observable behaviour, or "None"), Testing with a collapsible "Proof" block per method holding reviewable evidence. `.github/pull_request_template.md`
- Review skill checklist includes "negative controls": for each changed acceptance rule, verify a deliberately invalid case fails through the real runner; also "omit issues already enforced by a green gate". `.agents/skills/dsh-code-review/SKILL.md`
- Testing doc: "a guard only guards if the regression fails it" — introduce the regression, watch red, revert. `docs/testing.md`

### Contributor / process docs

- External PRs not accepted; contributions directed to Discussions, plugins (`dsh-plugin` topic), docs/blogs. `CONTRIBUTING.md`
- SAFETY.md: experimental, unaudited; can run model-generated code; sandboxing doesn't guarantee isolation; least privilege, disposable VMs, backups. `SAFETY.md`
- BENCHMARK.md is two sentences pointing at the SDK guide. `BENCHMARK.md`
- README routes agents to AGENTS.md; CLAUDE.md is a symlink to AGENTS.md ("edit the real file"). `README.md`, `AGENTS.md`
- Anti-CoT-leakage: AGENTS.md says comments/docs state contracts, not reasoning transcripts; a dedicated skill defines leakage (session-vantage prose: dead decision citations, "used to"/"no longer", "this PR", reviewer-addressed justifications, hedges) with one test: could a reader at HEAD with no transcript resolve every reference? `AGENTS.md`, `.agents/skills/dsh-trim-cot-leakage/SKILL.md`
- Testing doc: "verify the world, not the self-report" — e2e re-reads files externally; keyword probes on agent output let a cheating agent pass; assert untouched files are byte-identical. `docs/testing.md`
- Snapshot policy: every non-trivial model-/protocol-/user-visible change adds or updates a recorded-session snapshot in the same PR; CI replays read-only, record/refresh are local with every diff reviewed. `docs/testing.md`
- Real-API tests aren't rationed ("inference is cheap here"); self-skip without a key keeps CI green. `docs/testing.md`
- Defensive patterns doc: each heading is a bug class that shipped, phrased as the preventing rule (report orthogonal outcomes separately, dispose to quiescence, contain callback exceptions, scrubbed env + private temp paths, unlink link-shaped paths). `docs/defensive-patterns.md`
- Agent Notes for durable decision rationale only; archived notes frozen and hash-sealed. `AGENTS.md`, `.agents/notes/README.md`
- Instruction-editing rule: condense where clarity survives; raise a doc budget ceiling only when content needs it. `AGENTS.md` (Editing these instructions)
