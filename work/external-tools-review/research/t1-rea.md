# T1 — Reverse Engineer Anything (REA)

Checked 2026-10-18. Primary source: GitHub `morluto/rea` (cloned at `32f0e51`,
package `rea-agents` 6.7.0), read as data only, nothing executed.

## What it is

**Owner confirmed.** `gh repo view morluto/rea`: "Reverse engineer anything with
agents, from app behavior down to native binaries." Created 2026-04-14, MIT
(`LICENSE`, "Copyright (c) 2026 morluto"). The README names `morluto/rea`,
rea.tools and the `rea-agents` npm package as the only official sources, and
warns that look-alike repos are not official. `gh search repos "reverse engineer
anything"` finds several copies with the same description (e.g.
`NabilRFG12/Reverse-Engineer-anything`) and spin-offs (`aicodeking/leanrea`).

**It is mostly a tool, not a method.** The brief called it "a staged method".
The repo is a large TypeScript **MCP server + CLI** (about 4,400 tracked files)
with one agent skill on top:

- **MCP server / CLI** (`README.md` → "How REA works", "What you can analyze"):
  local analysis of native binaries (through Hopper, Ghidra or IDA), JS/Electron
  ASARs, .NET, Android APK/devices, websites (Chrome), HAR/pcap captures, SQLite,
  firmware, WASM, EVM and more. Every result is an "Evidence" record with
  limitations and unknowns. Install with `npx rea-agents setup`, which registers
  the MCP server and the skill with "Claude Code, Codex, Cursor, Gemini CLI, Grok
  Build and other agents".
- **Skill** `.agents/skills/reverse-engineer-anything/SKILL.md` (355 lines,
  `metadata.version: "42"`, plus 5 reference files, 827 lines in all). Also
  listed on skills.sh. Most of it is about routing to REA tools and recovering a
  broken MCP connection. The tool-independent method is two short sections:
  - **Evidence tagging** (SKILL.md ~line 290): "Every conclusion must
    distinguish observations, inferences, and unknowns. Cite Evidence IDs,
    preserve limitations and incomplete coverage, and never imply that static
    analysis observed execution." The upstream words are
    *observation / inference / unknown*. "seen / inferred / unknown" is the
    brief's paraphrase.
  - **"Plan broader investigations"** (~lines 300–335), a 7-step staged workflow:
    (1) turn the request into a checklist of questions, each with the evidence
    it needs; (2) reuse existing session state and evidence; (3) start with the
    smallest overview, then follow each question from entry point to result;
    (4) check resources and config, and don't infer behavior "from filenames,
    strings, or layout alone"; (5) back each conclusion with the kind of
    evidence it needs, using runtime observation only when static evidence
    can't answer; (6) split independent questions across parallel workers;
    (7) keep a **finding ledger** that links each conclusion to its evidence,
    its confidence, how far the search went, and the unknowns left. At the end,
    go back to the checklist and mark each question answered, partly answered or
    unresolved. A bounded negative search is not reported as complete.
  - **"Finish the task"**: when building, "separate observed behavior from
    design choices".
  - `references/evidence-workflows.md`: an unknowns register
    (`record_unknown` / `update_unknown`, where "only qualifying observed
    evidence can verify a resolution"), plus `verify_reconstruction`, where "a
    pass covers only declared comparable claims, not global equivalence".
- **Responsible use** (`DISCLAIMER.md`): only for lawful research,
  interoperability and software you are authorized to examine. It explicitly
  excludes DRM/licence bypass, cheats, and "copying proprietary software or
  reproducing its protected code and assets".
- **Activity**: 20 of the last 30 commits are by `morluto`, the rest by 3 other
  people plus a bot. Releases 6.5.0 (10-14), 6.6.0 and 6.7.0 (both 10-18), so it
  moves very fast. The README says to "keep your installation up to date".
- **Popularity (unverified)**: the GitHub API reports about 320k stars and 81k
  forks for a six-month-old repo, and the README celebrates "300,000 GitHub
  stars". Those numbers are unusually high. I have not checked them and they
  carry no weight in this review.

## What the template already has

- **Confidence tiers for claims**: `skills/why/references/epistemics.md`
  (Direct / Supported / Inferred / Speculative / Unknown, with phrasing rules,
  and "Unknown" spelled out as *what you searched*). It is scoped to
  decision-history questions about our own code (`skills/why/SKILL.md`).
- **Source-backed research with honest unknowns**: `skills/research/SKILL.md`
  (primary sources only). `skills/research-wave/references/pass-brief.md`
  ("'Unknown' is the honest answer"; each claim notes what is *documented* vs
  *implied*). `skills/research-wave/references/fact-check-brief.md` adds an
  independent fact-checker.
- **Driving a real app and capturing evidence**:
  `skills/create-verification-skill/SKILL.md` and
  `skills/maintain-verification-skill/SKILL.md`. These cover *our own* app.
- **Rebuilding / trying a design**: `skills/prototype/SKILL.md` (throwaway
  prototype). `skills/diagnosing-bugs/SKILL.md` (reproduce → hypothesise →
  instrument).
- **Splitting work into questions and running it in parallel**:
  `skills/research-wave/`, `skills/plans/`, `skills/wayfinder/`.
- **Doubt / not overclaiming**: `skills/doubt-driven-development/SKILL.md`, and
  the CLAUDE.md rule "pending is pending and a skip is a skip, never a pass".
- **Nothing** in skills/, docs/ or scripts/ covers studying a *third-party*
  app's feature (closed source, binary or packaged) in order to rebuild it.
  `grep -ri "reverse.engineer"` over skills/ and docs/ finds no workflow.

## Gaps it would fill

1. **A "study someone else's feature, then rebuild it" workflow.** The template
   covers our own code (`why`, `onboard-repo`), outside *documents*
   (`research`), and our own app (`verify-*`), but not outside *software
   behavior*.
2. **Keeping observed facts apart from design choices during a rebuild.** No
   current skill makes a rebuild record which parts copy observed behavior and
   which parts are our own invention.
3. **Search bounds on negative findings.** `epistemics.md` has this for
   "Unknown". REA applies the same rule to absence claims in general: "a missing
   match in partial source Evidence does not establish absence". It is a small
   but useful addition to `research` and `doubt-driven-development`.
4. **A finding ledger that closes the checklist** (step 7, then "revisit the
   original checklist"). `research-wave` comes close but has no
   answered / partly answered / unresolved closeout per question.

## Cost / risk of adopting

- **Agent-agnosticism.** The method text is plain markdown and works with any
  runtime. The *tool* needs a local MCP client and Node 22+. Setup claims to
  support codex, gemini_cli, copilot_cli, vscode, opencode and others (SKILL.md
  step 1 client list), and the CLI works without MCP. I have not tested any of
  these (**unverified**). Deep native analysis also needs Hopper, Ghidra or IDA,
  which a downloader is unlikely to have.
- **Licence.** REA's own code is MIT, which is fine to vendor with provenance,
  as we do for `skills/vendored-skills.md`. Third-party pieces keep their own
  licences (`THIRD_PARTY_NOTICES.md`, GPL-3.0 and LGPL texts in `licenses/`),
  and commercial tools need their own licences. That is a reason not to bundle
  the tool.
- **Maintenance.** The skill is tightly tied to REA's tool names and schema (it
  is at version "42", with two releases in one day), so a vendored copy would go
  stale within days. Only the short method sections are stable enough to borrow.
- **Legal / ethics.** A template that ships a reverse-engineering workflow by
  default puts that capability in front of every downloader. Any borrowed
  wording should carry REA's authorized-use boundary and its "separate observed
  behavior from design choices" rule. The rule matters because rebuilding a
  feature is not the same as copying protected code.
- **Supply chain.** There are look-alike repos, and `npx rea-agents@latest`
  fetches a fast-moving package on every call. If we ever document the tool, the
  pointer should be pinned and official-source only.

## Verdict: **learn-from**

REA is a heavy, fast-changing MCP toolchain for binary and app analysis. Most
template users won't need it, and its skill is mostly tied to REA's own tools,
so adopting or vendoring it would mean a big dependency and constant churn for
a niche need. The reusable part is about 40 lines of tool-independent method:
tag each claim as observation, inference or unknown; state how far a negative
search went; keep a finding ledger that closes the checklist; separate observed
behavior from design choices when rebuilding. Those ideas fit into skills we
already have (`why`'s epistemics, `research`, `research-wave`) at almost no
cost. A standalone "reverse-engineer a feature" skill is worth adding only if
the user wants that workflow. REA could then be listed as an optional tool, not
bundled.

## Candidate recommendations

1. Add one line to `skills/research/SKILL.md`: tag each claim *observed /
   inferred / unknown*, and give every "not found" the search bound behind it
   (credit REA SKILL.md ~line 290).
2. Add an end-of-run checklist step to `research-wave`: mark each original
   question answered / partly answered / unresolved before synthesis (from REA
   "Plan broader investigations").
3. In `skills/prototype/SKILL.md` (or a future rebuild skill), require a short
   "copied behavior vs our design choices" split whenever the prototype copies
   an outside feature.
4. Optional, if the user wants it: a small agent-agnostic `study-feature` skill
   (checklist → smallest overview → evidence-tagged ledger → closeout), with
   REA's authorized-use boundary, and REA listed in
   `docs/recommended-tooling.md` as an optional, pinned, official-source-only
   tool.
5. Do not vendor REA's `reverse-engineer-anything` skill. Its tool coupling and
   release pace would make it go stale quickly.
