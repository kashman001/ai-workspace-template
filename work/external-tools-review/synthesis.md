# Synthesis — what the four outside tools mean for the template

Inputs: `research/t1-rea.md`, `research/t2-cli-anything.md`,
`research/t3-projects.md`, `research/t4-phonon.md`. The parent session
spot-checked each note's three main claims at the source (s2). Every claim
held. Corrections and side findings are listed at the end.

## Verdicts at a glance

| Track | Subject | Verdict | One-line reason |
|---|---|---|---|
| T1 | REA (`morluto/rea`, MIT) | learn-from | A heavy, fast-moving MCP tool. About 40 lines of method are worth borrowing; the tool and its skill are not. |
| T2 | CLI-Anything (`HKUDS/CLI-Anything`, Apache-2.0) | learn-from | The rules for CLIs that agents use are good. The generator is Claude-first and heavy, and its `cli-hub` is unsafe to recommend. |
| T3 | Claude Code redesigned Projects | learn-from | A Claude-only cloud version of the template's own coordinator/worker model. Its design choices are worth borrowing; it can't be the template's mechanism. |
| T4 | Phonon-2 (Fermion, CC-BY-4.0 weights) | skip (revisit) | No audio need in the template. English-only, 4-commit repo, accuracy figures mostly from the vendor. |

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
  `docs/context-budget.md` § Dispatching. Needs a test.
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
  can drift from the repo's files.
- **R15. (Low) A "no captions?" note.** (T4) Add it to `docs/mcp-setup.md` → YouTube
  transcript server: for recordings without captions, use a local
  speech-to-text CLI (whisper.cpp, Phonon-2) by hand. Name the capability,
  not one model. A scripted fallback is deferred until a work item needs it.
- **R16. (Trivial) One line in `docs/for-non-engineers.md`: OS dictation
  works in any agent chat box.** (T4)

### Explicitly not recommended

- Vendoring REA's `reverse-engineer-anything` skill. It is tied to REA's
  tools, it is at v42, and it had two releases on 2026-10-18 alone.
- Vendoring or shipping the CLI-Anything generator: it is Claude-plugin-first,
  has no Gemini port, and is heavy.
- Making Projects the template's coordination mechanism (Claude-only, cloud,
  memory outside git).
- Adding Phonon-2 (or any speech-to-text) as a dependency.

## Suggested grouping if accepted

- **One small work item** for Theme A, R2–R4: all three are edits to
  `fleet.sh dispatch-contract` with tests. R1 is a note into
  `work/concurrent-sessions/`, and R5 waits on R1.
- **Backlog cards**, each a doc edit: R6–R9 (could be one card, "CLI contract"),
  R10, R13, R14, R15+R16.
- R11/R12 only on an explicit yes.

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
