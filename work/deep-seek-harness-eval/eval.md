# Evaluation — this template vs. DeepSeek Harness practices

Session 2, 2026-10-08. Input: `source-notes.md` (upstream commit `5badb15`).
Upstream paths are relative to the upstream repo root; template paths to this
repo's root. Template evidence was checked on disk this session. Verdicts:
**Already have**, **Partial**, **Worth adopting**, **Not for us**.

## One-page summary

DeepSeek Harness is a large TypeScript project whose maintainers lean
heavily on AI coding agents. Its agent rules are strict and almost every rule
is backed by an automatic check. This template already does many of the same
things: one shared instruction file for all agents, one place per fact, short
"current state only" instruction files, pinned copies of borrowed skills, and
a habit of turning repeated mistakes into checks.

Four ideas are worth taking, all small:

1. **Keep "only when asked" skills consistent across agents.** Some skills
   should run only when a person types their name. Claude Code is told this
   for 20 skills; Codex is told it for only 14. The other 6 were written in
   this template, and Codex may start them by itself. Upstream has a check
   that keeps the two settings in step. We should add one.
2. **Report only what you actually ran.** Upstream ends almost every
   workflow with "list the commands you ran; anything still waiting is
   waiting, not passed". It pairs this with "prove a check works by breaking
   the thing and watching it fail". The template asks for this in one bug
   workflow only.
3. **A test for leaked reasoning in written notes.** Upstream asks one
   question of every comment and doc: *could someone reading the repo today,
   without the chat that produced it, understand every reference?* Phrases
   like "as decided above" or "no longer" fail it. Our hand-off notes and
   decision notes are where this matters most.
4. **Skipped checks shouldn't look like passes in CI.** Our check runner
   counts a skipped check as fine. That is right on a laptop missing an
   optional tool. In CI it can hide a check that never ran.

Two smaller ones: a fixed repair order when a size-limited file is over its
limit, and hiding archive folders from default search so old facts don't
outrank current ones.

Most of the rest is **not for us**. Weighted reviewer votes, bilingual docs,
100% test coverage, hash-sealed archives and a 45-check documentation suite
suit a big team shipping a product. They don't suit a starter kit for one
person or a small team.

**Glossary.** *Skill* — a written workflow an agent loads by name
(`skills/<name>/SKILL.md`). *Check* — a script that fails when a rule is
broken. *CI* — the checks GitHub runs on every push. *Codex, Claude Code* —
two AI coding agents this template supports. *Frontmatter* — the settings
block at the top of a skill file.

## Scorecard

### Instructions and documentation

| # | Upstream practice | Verdict | Upstream evidence | Template evidence | Notes |
|---|---|---|---|---|---|
| 1 | `CLAUDE.md` symlinks `AGENTS.md`; "edit the real file" | **Already have** | `AGENTS.md` L178 | `CONTEXT.md` header; `scripts/tests/test-agent-entrypoints.sh` | We go further: four entrypoints, one check. |
| 2 | One home per fact; placement router (bugs → postmortems, rationale → notes, …) | **Already have** | `docs/AGENTS.md` L15-35 | `skills/writing-for-agents/SKILL.md` → "Pruning" (single source of truth); `docs/README.md` "by need" index; `docs/postmortems/` | Our router is the docs index rather than one line, which is fine. |
| 3 | Document current state; no "implemented!"/"future:" status in standing docs | **Already have** | `docs/AGENTS.md` L39, L66 | `CONTEXT.md` → "keep this file … free of dates, status, and counters"; launcher REPLACED each rollover (`docs/work-directory-conventions.md`) | |
| 4 | Word budgets per standing doc, with repair order relocate → condense → raise-with-reason | **Partial** | `scripts/verify-doc-budgets.ts`, `docs/AGENTS.md` L48-58 | `scripts/check-drift.sh` L21-23, L69-73: `CONTEXT.md` ≤ 16,000 bytes (now 15,364, 96%) | We have the limit, not the repair order. At 96% the next edit will hit it. See R5. |
| 5 | Fact-check by running every claimed command | **Partial** | `.agents/skills/dsh-doc/SKILL.md` L39-47 | `skills/research-wave/references/fact-check-brief.md`; `CONTEXT.md` "Disk is the source of truth" | Applied to research, not to doc edits in general. Folded into R2. |
| 6 | Concrete terms; one banned word enforced by a check | **Partial** | `scripts/verify-concrete-terms.ts` | `CONTEXT.md` → "## Language" (aliases to avoid, in italics) | Aliases are listed but nothing checks them. Low value at our size. |
| 7 | Reasoning-leakage test: "resolvable at HEAD with no transcript?" + 8-class taxonomy | **Worth adopting** | `.agents/skills/dsh-trim-cot-leakage/SKILL.md`; `AGENTS.md` (prose rules) | None: no match for "transcript"/"at HEAD" in `skills/writing-for-agents/` | Ledger and `decisions.md` entries are written mid-session, which is where leakage happens. See R3. |
| 8 | Scoped subtree `AGENTS.md` (only that subtree's rules) | **Not for us** | 22 `AGENTS.md` files, `docs/AGENTS.md` L22 | One `AGENTS.md` at root | Our subtrees are small; per-folder rules live in each folder's `README.md`. Revisit if `scripts/` grows its own rules. |
| 9 | Mechanical prose checks (one line per paragraph, compiled code blocks, type drift, Mermaid parse) | **Not for us** | `scripts/verify-md-wrap.ts`, `verify-type-equiv.ts`, `verify-mermaid.ts` | — | Built for a TypeScript product docs site. |
| 10 | Bilingual doc pairs with hash sidecars | **Not for us** | `scripts/verify-translation-pairing.ts` | — | English only. |
| 11 | Link checker incl. `#fragment` anchors | **Partial** | `scripts/verify-md-links.ts` | `scripts/check-drift.sh` step 1 (dead path references, not anchors) | Anchor breakage is rare here; not worth a recommendation. |

### Decision records and archives

| # | Upstream practice | Verdict | Upstream evidence | Template evidence | Notes |
|---|---|---|---|---|---|
| 12 | Decision notes record the why and the rejected alternatives | **Already have** | `.agents/notes/README.md` L5 | `skills/decision-log/SKILL.md` (Tier 2 template has a `**Rejected:**` line); ADRs carry "Alternatives considered" (`docs/adr/0004-…`, `0010-…`) | |
| 13 | Lifecycle by folder (proposed/implemented/rejected), fixed header, checked format | **Not for us** | `scripts/verify-agent-note-format.ts`, `agent-note-tree.ts` | `docs/adr/README.md` L43-44 (status line, supersede and link forward) | 1,200 notes need folders and a format check. Our ~12 ADRs and one `decisions.md` per item don't. |
| 14 | Supersession check when writing a new note | **Partial** | `.agents/notes/AGENTS.md` L5; `dsh-archive-agent-notes` L14-16 | `docs/operational-knowledge.md` L17-18 (ADD/UPDATE/SUPERSEDE/NOOP before writing); `docs/adr/README.md` L43-44 | Done for gotchas and ADRs, not for `decisions.md`. Cheap to add a line to `decision-log`; low priority. |
| 15 | Implemented notes kept true to the code; a reversal gets a new note | **Already have** | `.agents/notes/implemented/AGENTS.md` L5-13 | `docs/adr/README.md` L43-44 (supersede, never delete) | |
| 16 | Frozen, hash-sealed archive (append-only manifest) | **Not for us** | `scripts/verify-archived-agent-notes.ts`, `archived/manifest.json` | `docs/archive/`, `handoff-archive.md`, backlog archive file | Git already makes edits to archives visible. Sealing pays off only at upstream's scale. |
| 17 | Archive hidden from default search (`.rgignore`) | **Worth adopting** | `.rgignore` | No `.rgignore`/`.ignore` at the root | Stale facts in `docs/archive/` and `handoff-archive.md` turn up in plain greps. See R6. |

### Skills

| # | Upstream practice | Verdict | Upstream evidence | Template evidence | Notes |
|---|---|---|---|---|---|
| 18 | One skill tree for all runtimes (`.claude/skills` → `.agents/skills` symlink) | **Already have** | `.claude/skills` symlink | `skills/` read by every runtime; thin `.claude/commands/` wrappers (`docs/recommended-tooling.md` ~L223) | Different mechanism, same result. |
| 19 | Check that "manual-only" matches across Claude and Codex metadata | **Worth adopting** | `scripts/verify-skill-invocation-metadata.ts` | 20 skills set `disable-model-invocation: true`. 14 vendored ones also carry `agents/openai.yaml` with `allow_implicit_invocation: false`. 6 workspace skills have no Codex metadata: `create-work-item`, `doc-review`, `onboard-repo`, `plans`, `research-wave`, `rlm`. | A real gap found today. `CONTEXT.md` calls `research-wave` and `wayfinder` "user-invoked only", but in Codex `research-wave` isn't. See R1. |
| 20 | Every skill ends "report only commands run; pending is pending" | **Worth adopting** | `AGENTS.md` L113-120; most `.agents/skills/*/SKILL.md` | No match for "commands run"/"pending is pending" in `skills/` | The superpowers plugin covers this for Claude only. See R2. |
| 21 | Negative controls: prove a check by breaking it and watching it fail | **Partial** | `dsh-code-review`, `docs/testing.md` ("a guard only guards if the regression fails it") | `skills/diagnosing-bugs/SKILL.md` L132 ("Watch it fail"); our test suites seed bad fixtures (e.g. `test-agent-entrypoints.sh` E5a) | Practised in tests, not stated as a rule. Folded into R2. |
| 22 | Explicit `scope` input; "missing scope → stop"; mode controls questions, not write authority | **Partial** | `dsh-prose-standard` SKILL.md | `skills/doc-review/` takes a path; no general rule | Useful mainly for audit skills. Not recommended on its own. |
| 23 | Code review: blockers separate from judgment calls; drop findings a passing check already enforces | **Partial** | `.agents/skills/dsh-code-review/SKILL.md` | `skills/code-review/SKILL.md` (two axes + smell baseline; no blocker/suggestion split) | `code-review` is vendored, so changing it makes it "adapted" (`skills/vendored-skills.md`). See R7. |
| 24 | Grep probes tested on a known hit and a near-miss before trusting zero hits | **Partial** | `dsh-trim-cot-leakage/references/recall-batteries.md` | None as a rule | Good habit; bundle with R3's audit if adopted. |
| 25 | Calibration files (good/over/under examples; user rulings written back) | **Already have** | `dsh-prose-standard/references/examples.md` | `skills/karpathy-examples/`; `skills/writing-for-agents/` | |
| 26 | Re-fetch base/HEAD before acting, again after any rewrite | **Partial** | `dsh-pre-push-checks`, `dsh-merging-stacked-prs` | Held in Claude auto-memory only ("Re-check HEAD before rewriting other items") | Lives in a Claude-only store, which breaks the agent-agnostic rule. Could move to `docs/operational-knowledge.md`. Low priority. |
| 27 | Subagent gets a precomputed brief as its whole working set | **Already have** | `dsh-translate-docs` | `skills/research-wave/references/*-brief.md`; `skills/rlm/` | |
| 28 | Project prefix (`dsh-`) on repo-specific skills | **Not for us** | `.agents/skills/` names | — | Downloaders rename the project anyway. |

### Checks and CI

| # | Upstream practice | Verdict | Upstream evidence | Template evidence | Notes |
|---|---|---|---|---|---|
| 29 | Fast local hooks; CI owns the full suite | **Already have** | `lefthook.yml` L1-2 | `scripts/run-checks.sh --fast` in `scripts/git-hooks/pre-commit`; full in `.github/workflows/checks.yml` | |
| 30 | Hooks auto-installed for every contributor | **Not for us** | `scripts/install-lefthook.mjs` | Opt-in: `docs/template-usage.md` L135 (`git config core.hooksPath scripts/git-hooks`) | Opt-in is deliberate for a template people adapt. |
| 31 | One runner owns every aggregate; skipped counts as failed unless marked optional | **Partial** | `scripts/run-gates.ts` (`main`, `allowFailure`) | `scripts/run-checks.sh` L11, L52-53, L62: exit 77 → SKIP; only `failed` sets the exit code | One runner: yes. A skip never fails, even in CI. See R4. |
| 32 | Generated files have a `--check` freshness mode | **Already have** | `gen-X` / `verify-X` pairs in `package.json` | `scripts/check-workspace-structure.sh` (guide HTML freshness) | |
| 33 | Gotcha-to-check: wire checkable rules into the gate | **Already have** | `AGENTS.md` L172 | `docs/operational-knowledge.md` L19-23 (`**Enforced by:**`, 4 entries) | |
| 34 | Ratchet baselines that may only shrink | **Not for us** | `scripts/verify-no-unknown-casts.ts` | — | We have no legacy pile to shrink. |
| 35 | `git diff --cached --check` whitespace check on commit | **Not for us** | `lefthook.yml` L35 | — | Trivial to add, but it fixes no failure we've seen. |
| 36 | Lint, coverage, copy-paste detection, lint-rule fingerprints | **Not for us** | `.oxlintrc.json`, `.jscpd.json`, `lint-rule-fingerprint.spec.ts` | — | TypeScript-product tooling. |
| 37 | CI: one required verdict job; cancel superseded runs | **Not for us** | `.github/workflows/ci.yml` | `.github/workflows/checks.yml` (one job, no `concurrency`) | One job is already one verdict. |
| 38 | "Verify the world, not the self-report"; untouched files byte-identical | **Already have** | `docs/testing.md` | `scripts/tests/test-session-lib.sh` S3c, `test-probe-twins.sh` H2e/H2j (`cmp -s`) | |

### Process and contribution

| # | Upstream practice | Verdict | Upstream evidence | Template evidence | Notes |
|---|---|---|---|---|---|
| 39 | Vendored code pinned to upstream SHAs; local changes logged | **Already have** | `vendor/README.md`, `scripts/check-vendor-manifest.sh` | `skills/vendored-skills.md` (pristine vs adapted, pinned commits); `scripts/sync-vendored-skills.sh` | Upstream also checks that a vendored change updates the log in the same commit; we don't. Not worth it at our churn. |
| 40 | Weighted reviewer approval, blame-share boosts, `/delegate` | **Not for us** | `.github/review-ownership/README.md` | — | Large-team policy. |
| 41 | Issue policy (one `kind/*`, ≥1 `area/*`, priority) checked in CI | **Not for us** | `.github/issue-management/README.md` | `skills/triage/` (labels by convention) | |
| 42 | PR template with a collapsed "Proof" block per testing method | **Not for us** | `.github/pull_request_template.md` | No PR template | Fits R2's spirit, but the template ships no PR flow; the downloader's project decides. |
| 43 | Upgrade guide written in the breaking change itself | **Not for us** | `dsh-create-upgrade-guide` | — | No versioned release for downstream copies. |
| 44 | "Host sandbox failures": retry narrowly, need evidence the sandbox caused it | **Not for us** | `AGENTS.md` L31-32 | — | Runtime-specific; the runtimes' own prompts cover it. |
| 45 | Defensive-patterns doc: each heading a bug class phrased as the rule | **Already have** | `docs/defensive-patterns.md` | `docs/operational-knowledge.md` (symptom → cause → rule) | |

**Tally:** Already have 14 · Partial 11 · Worth adopting 4 (7, 17, 19, 20) ·
Not for us 16. Some Partial rows feed a recommendation (noted inline).

## Ranked recommendations

Each is small. None is filed yet; each becomes a backlog card only if the
user accepts it.

**R1 — Check that manual-only skills agree across Claude and Codex.**
*Script change.* Add a case to `scripts/tests/test-agent-entrypoints.sh`: for
every `skills/*/SKILL.md` with `disable-model-invocation: true`, require
`agents/openai.yaml` with `allow_implicit_invocation: false`, and the
reverse. Then add the missing yaml to the six workspace skills (row 19).
Seed one bad fixture to prove the case fails (as E5a does). *Why first:* a
real gap today, a one-file fix, and it backs the "agent-agnostic" rule with
a check.

**R2 — "Report what you ran" as a standing closing rule.** *Doc change.* One
rule in `CONTEXT.md` → Agent Coding Principles (rule 4), mirrored where
skills end with a report (`checkpoint`, `research-wave`, `plans` reconcile):
list the commands actually run; waiting is waiting, a skip is a skip, never
a pass; a new check counts only after it has been seen to fail on a bad case.
*Why:* it's the most repeated upstream rule. Today it reaches Claude only,
through a plugin. Mind the `CONTEXT.md` byte budget (row 4), so keep it to
two lines.

**R3 — The "readable without the transcript" test.** *Doc change.* Add the
one-question test and a short list of tell-tale phrases ("as decided above",
"no longer", "this session", "per review") to
`skills/writing-for-agents/SKILL.md` → Pruning. Point to it from the ledger
and decision-note write steps (`docs/work-directory-conventions.md`,
`skills/decision-log/SKILL.md`). *Why:* hand-offs and decision notes outlive
the session that wrote them, so leaked context costs most there.

**R4 — Skips fail in CI unless marked optional.** *Script change.* In
`scripts/run-checks.sh`, when `CI` is set, a skip fails the run unless that
check is on a short "may skip" list (e.g. `check-service-access.sh`, which
needs credentials). Locally, skips stay non-fatal. *Why:* a check that
silently stops running in CI looks exactly like a passing one. Needs a quick
look at which checks skip in CI today before choosing the list.

**R5 — Repair order for the `CONTEXT.md` budget.** *Doc change.* Next to the
16,000-byte limit (`scripts/check-drift.sh` L21, and where the budget is
documented), say: when over, first move content to its proper home, then
condense, and raise the limit only with a stated reason. *Why:* the file is
at 96%, so the next session to hit the limit needs this rule.

**R6 — Hide archives from default search.** *Config change (one file).* Add
a root `.rgignore` listing `docs/archive/`, `**/handoff-archive.md` and the
backlog archive file. *Why:* old facts stop outranking current ones in
ripgrep-based searches (most agents' grep tools). *Caveat:* it only affects
ripgrep. `grep -r` and `git grep` still see everything, so this is a nudge,
not a wall.

**R7 — Blockers vs. suggestions in code review.** *Doc change to a vendored
skill.* In `skills/code-review/SKILL.md` step 5, sort findings into blockers
and suggestions, and drop any finding a passing check already enforces.
*Lowest rank:* it changes `code-review` from pristine to adapted
(`skills/vendored-skills.md`), which costs effort at every refresh. Could go
upstream instead.

**Deliberate non-goals** (rows marked Not for us): weighted approval and
issue-label policy, bilingual docs, hash-sealed archives, lifecycle folders
for decision notes, ratchet baselines, lint/coverage/duplication tooling,
auto-installed hooks, upgrade guides, scoped subtree `AGENTS.md`. Each one
answers a problem of scale or product type this template doesn't have. If
any is rejected outright, it goes in `decisions.md`.

## Open question for the user

Which of R1–R7 to accept? Accepted ones become backlog cards in
`docs/template-workspace-backlog.html`. Rejected ones, and any non-goal you
disagree with, go in `decisions.md`.
