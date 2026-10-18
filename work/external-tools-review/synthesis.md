# Synthesis — what the six outside subjects mean for the template

Inputs: `research/t1-rea.md`, `research/t2-cli-anything.md`,
`research/t3-projects.md`, `research/t4-phonon.md`, and (added s3 at the
user's request) `research/t5-claude-changes-video.md`,
`research/t6-openviking.md`. The parent session spot-checked each note's main
claims at the source (s2 for T1–T4, s3 for T5–T6). Every claim held, except
one T5 claim that could not be sourced (see the end). Corrections and side
findings are listed at the end.

## Verdicts at a glance

| Track | Subject | Verdict | One-line reason |
|---|---|---|---|
| T1 | REA (`morluto/rea`, MIT) | learn-from | A heavy, fast-moving MCP tool. About 40 lines of method are worth borrowing; the tool and its skill are not. |
| T2 | CLI-Anything (`HKUDS/CLI-Anything`, Apache-2.0) | learn-from | The rules for CLIs that agents use are good. The generator is Claude-first and heavy, and its `cli-hub` is unsafe to recommend. |
| T3 | Claude Code redesigned Projects | learn-from | A Claude-only cloud version of the template's own coordinator/worker model. Its design choices are worth borrowing; it can't be the template's mechanism. |
| T4 | Phonon-2 (Fermion, CC-BY-4.0 weights) | skip (revisit) | No audio need in the template. English-only, 4-commit repo, accuracy figures mostly from the vendor. |
| T5 | "Claude Changed Completely" video (Simon Scrapes) | learn-from | 10 of its 15 changes are Claude-only features. What carries across agents is method: test whether a skill earns its place, and prove "done" with command output. |
| T6 | OpenViking (`volcengine/OpenViking`, AGPL-3.0) | learn-from | A memory server that needs two models, sends content to the cloud by default, and keeps memory outside git. Copilot, Gemini and Antigravity get only a generic MCP path. Its three-level loading idea is worth naming. |

**Nothing gets adopted or vendored.** Every useful part is a *method* that
fits into machinery the template already has, as a few lines in each place.

## Recommendations, ranked by value

Ranked by value to the template divided by cost. Each one names the track(s)
it came from. IDs are stable for dispositioning.

### Theme A — Coordinating parallel workers (highest value)

The template's open `work/concurrent-sessions/` question is the one place an
outside design directly answers a live problem.

- **R1. Feed the "workers own nothing" design into `work/concurrent-sessions/`.**
  (T3) In Projects, only the coordinator owns the work. Threads are full
  sessions with no ledger of their own, and they report back. This suggests a
  cheap path: keep one owner, and promote long-running children to separate
  worktree sessions that report through dispatch records instead of
  co-owning. *Cost:* one cross-link note into that item's research. *Value:*
  high. It may remove the need for multi-owner `seq`/ledger machinery.
- **R2. Dispatch contract: add a "read these first" list.** (T3) Make
  `fleet.sh dispatch-contract` output name the standing-context files a child
  must read (CONTEXT, GLOSSARY, item README, `decisions.md`). This mirrors
  Projects' `MEMORY.md`-at-start. *Cost:* a few lines in `scripts/fleet.sh` +
  `docs/context-budget.md` § Dispatching. Needs a test. *(s3, T5:)* a
  concrete reason: Claude's built-in Explore and Plan subagents start
  without `CLAUDE.md` (verified, Claude Code sub-agents docs).
- **R3. Dispatch contract: add a `Remember:` section to the child's report.** (T3) If a
  child was corrected in a way that should outlive its task, it lists that
  under `Remember:`. The parent routes it to `decisions.md` or
  `docs/operational-knowledge.md`. This mirrors "corrections become memory".
  *Cost:* small, same files as R2.
- **R4. Dispatch contract: worktree children commit work in progress at each
  checkpoint.** (T3) Projects warns that sandboxes lose uncommitted work. The
  same risk applies to worktree children. *Cost:* one clause.
- **R5. (Low) A single "needs me" view.** (T3) Merge `hitl` plan nodes,
  BLOCKED/NEEDS_CONTEXT returns and open dispatches into one line
  (`plan.sh`/`fleet.sh`). *Cost:* moderate; worth it only if R1 brings more
  parallel workers.

### Theme B — CLIs that agents use (the CLI-first rule, made concrete)

The template says "CLI-first" but has no written standard for what a good
agent-facing CLI is, and one of its own examples is mislabelled.

- **R6. Fix the mislabelled yt-dlp example.** (T2 side finding, verified)
  `docs/mcp-setup.md:60-61` lists `scripts/mcp/`'s yt-dlp wrapper under
  CLI-first. In fact `youtube_transcript_mcp.py` is a stdin JSON-RPC MCP
  server with no CLI mode. Either correct the wording (trivial) or add a plain
  CLI mode (small). *Value:* removes a real inaccuracy.
- **R7. Write a short "Agent-facing CLI contract".** (T2) Add it to
  `docs/workspace-structure.md` → "Authoring a Team Capability": `--json`
  output, documented exit codes, a `--check` preflight, loud errors,
  introspection commands, and verify real output rather than the exit code.
  `scripts/jev.sh` is the worked example; CLI-Anything's HARNESS.md is prior
  art (paraphrased, so no Apache obligations). *Cost:* a section.
- **R8. One line in the CLI-first rule: "no CLI? wrap it."** (T2) If a
  capability exists only as MCP or an API, wrap it in a small `scripts/`
  CLI before adding an MCP fragment. *Cost:* one line in `docs/mcp-setup.md`.
- **R9. Convention: an agent-facing `scripts/` CLI ships a sibling
  `skills/<name>/SKILL.md`.** (T2) jev already does this. Write the
  convention down. *Cost:* one line, next to R7.

### Theme C — Evidence discipline in research

The template already has confidence tiers (`skills/why/references/epistemics.md`).
REA adds two portable rules. **Constraint found in s2:** `skills/research/` and
`skills/prototype/` are vendored (keep-unmodified), so T1's recommendations to
edit them are redirected to workspace-owned files.

- **R10. `research-wave`: close every question as answered / partly
  answered / unresolved before synthesis, and give each "not found" the bound
  of the search behind it.** (T1) `research-wave` is workspace-owned. *Cost:*
  a step + one line in `skills/research-wave/SKILL.md`.
- **R11. (Low) A "copied behaviour vs our design choices" split when a
  prototype copies an outside feature.** (T1) Because `prototype` is vendored,
  this would live in a workspace convention doc, or in R12, rather than in
  the skill. *Value:* matters only if R12 happens.
- **R12. (Optional, user's call) A small agent-agnostic `study-feature`
  skill**: checklist → smallest overview → evidence-tagged ledger → closeout,
  with REA's authorized-use boundary. Then list REA in
  `docs/recommended-tooling.md` as optional, pinned and official-source-only.
  (T1) *Cost:* a new skill. It is worth it only if you want to study outside
  apps' features to rebuild them.

### Theme D — Tooling documentation and warnings

- **R13. Do not recommend `cli-hub`; record why.** (T2, verified) It fetches
  a live remote registry and runs entries' `install_cmd` with `shell=True`
  (`curl … | bash` entries exist). It also sends PostHog analytics by default
  (opt-out `CLI_HUB_NO_ANALYTICS=1`). *Cost:* a backlog/decision note.
- **R14. One paragraph on Projects as an optional Claude-only layer.** (T3) Put it
  in `docs/recommended-tooling.md`. Threads load `CLAUDE.md`, skills and
  `.claude/agents`. Hooks (the budget measurement) apply only in single-repo
  projects. Plugins aren't loaded. Project memory lives outside git, so it
  can drift from the repo's files. *(s3, T5:)* also check the model and
  effort that Projects threads run on, and trim connectors in routines.
- **R15. (Low) A "no captions?" note.** (T4) Add it to `docs/mcp-setup.md` → YouTube
  transcript server: for recordings without captions, use a local
  speech-to-text CLI (whisper.cpp, Phonon-2) by hand. Name the capability,
  not one model. A scripted fallback is deferred until a work item needs it.
- **R16. (Trivial) One line in `docs/for-non-engineers.md`: OS dictation
  works in any agent chat box.** (T4)

### Theme E — Skills that earn their place, and "done" that is proved (s3, T5)

Models now do much of what step-by-step skills used to spell out. The
template ships many skills, mostly vendored. And Claude's `/goal` checker only
reads the conversation: it "doesn't run commands or read files" (verified,
Claude Code goal docs), so "done" is only as good as the evidence printed.
Both lessons are method and work in any agent.

- **R17. A "does this skill earn its place" test.** (T5) Add to
  `docs/stakes-to-ceremony.md` → "Adopting the skills": run 3 tasks three
  ways — no skill, a dummy file of the same length, the skill — in fresh
  headless runs; keep the skill only if it beats both. *Cost:* small (a
  section). *Value:* high. The video's "7 of 9 skill packs no better than a
  dummy" is **unverified**, but Anthropic's skill guidance says to measure
  against a no-skill baseline, and SkillsBench (arXiv 2602.12670) found
  self-written skills add nothing on average.
- **R18. (Optional) Pilot R17 on 3–5 skills** that mostly restate what the
  model does anyway; log results in a work item. *Cost:* moderate, spends
  real tokens. Script it only if the pilot pays off.
- **R19. "Done" is proved by command output.** (T5) Each `## Acceptance`
  line in `docs/plans.md` names its check command (replace the example "Done
  when the orchestrator says so", `docs/plans.md:298`), and a `DONE` return
  under the `fleet.sh` dispatch contract quotes the check and its result.
  *Cost:* small. *Value:* high. Pairs with R2–R4.
- **R20. (Trivial) One line in `docs/context-budget.md`:** don't switch
  models mid-session; lower the effort instead. (T5)
- **R21. (Low) Check an overnight-chain risk.** (T5) Claude Code silently
  waits for a usage limit to reset; that wait could trip a non-zero
  `SESSION_LOOP_KILL_AFTER` in `scripts/session-loop.sh`. First check whether
  chain sessions are interactive (the auto-wait runs only there). *Cost:* an
  investigation, then one doc line or a fix.

### Theme F — Layered memory (s3, T6)

OpenViking loads context in three tiers: a one-line abstract, an overview,
then full detail. The template already does this in spirit
(`docs/zoom-model.md`, `Purpose:` headers, launchers vs ledgers) but never
names it.

- **R22. Name the three-level pattern in `docs/zoom-model.md`** and point at
  the template's existing one-line summaries. (T6) *Cost:* ~10 lines, in our
  own words (OpenViking's README forbids rewriting without permission).
- **R23. Add the missing `Purpose:` header** to the 4 of 17 `docs/*.md` that
  lack one; cap it at one sentence. (T6) *Cost:* small.
- **R24. A short warning entry for OpenViking in
  `docs/recommended-tooling.md`.** (T6) AGPL-3.0 (relicensed from Apache-2.0
  on 2026-03-30, verified via `gh api`), needs a server plus an embedding
  model and a vision model, cloud by default, and its auto-capture sends tool
  output verbatim. *Cost:* a paragraph.

### Explicitly not recommended

- Vendoring REA's `reverse-engineer-anything` skill. It is tied to REA's
  tools, it is at v42, and it had two releases on 2026-10-18 alone.
- Vendoring or shipping the CLI-Anything generator: it is Claude-plugin-first,
  has no Gemini port, and is heavy.
- Making Projects the template's coordination mechanism (Claude-only, cloud,
  memory outside git).
- Adding Phonon-2 (or any speech-to-text) as a dependency.
- (T5) Building on Claude-only features (advisor, forks, routines, cloud
  sessions, `/goal`), using an LLM-judged Stop hook as the quality gate, or
  deleting vendored skills wholesale on the strength of the unverified
  "7 of 9" claim — R17 is the way to decide, one skill at a time.
- (T6) Integrating OpenViking: no `mcp-fragments/openviking.json`, nothing
  vendored. It is not agent-agnostic, its memory lives outside git, and AGPL
  would follow it into every copy of the template.

## Suggested grouping if accepted

- **One small work item** for Theme A, R2–R4: all three are edits to
  `fleet.sh dispatch-contract` with tests. R1 is a note into
  `work/concurrent-sessions/`, and R5 waits on R1.
- **Backlog cards**, each a doc edit: R6–R9 (could be one card, "CLI contract"),
  R10, R13, R14, R15+R16.
- R11/R12 only on an explicit yes.
- (s3) R19 can join the R2–R4 work item (same dispatch-contract files).
  R17 (+R18), R20, R21, R22+R23, R24 are backlog cards.

## Corrections and side findings

- T1: REA is mainly a tool (TypeScript, about 4,400 files), not a staged
  method. Its tags are "observations, inferences, and unknowns". Its star count
  (about 320k for a six-month-old repo) is treated as **unverified** and given
  no weight. Look-alike repos exist.
- T3: the article says local-machine threads are "coming very soon". The
  current docs already describe them (via Remote Control) and say they don't
  load project memory. Whether the template's hooks work in a cloud sandbox
  is **unverified**.
- T4: the independent leaderboard number (7.23% WER) comes only from the
  video and one blog. **Unverified.**
- T2 → template: the `docs/mcp-setup.md` yt-dlp wording (R6).
- T5: "someone ran 9 skill packs against a dummy file; 7 did no better" —
  **unverified**; four searches found no such study. R17 rests on Anthropic's
  baseline guidance instead, not on that number.
- T6: aggregators disagree on the license because it changed: Apache-2.0 at
  the first commit, AGPL-3.0 since PR #1085 (2026-03-30). The LoCoMo gains
  (24–57% → 80–83%) are self-reported, on Volcengine's own models with an
  LLM judge.
