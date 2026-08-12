# PM Persona — Cold-Start Review (raw report)

> Produced 2026-08-11 by a persona agent role-playing a technically-literate,
> non-engineering product manager doing a cold-start review of this template.
> Read-only walkthrough; ~90 simulated minutes. Part of `work/devex-review/`.

**Persona summary.** I'm a product manager who reads markdown comfortably, can run a command someone gives me, and is expected to use AI agents for specs, tickets, status, and decision archaeology — but I don't write code. My honest verdict after ~90 minutes in this repo: this workspace is a *superbly engineered artifact built by engineers and agents, for engineers and agents*. There is no PM entry point anywhere — no doc, section, or index row acknowledges that a non-engineer might open this repo. And yet, once I forced my way past the front doors, I was genuinely surprised by how much of the *content* I could use: the ADRs are the most PM-readable decision records I've seen in any repo, each `work/<project>/README.md` told me what the effort was and its status in one screen, and the rendered backlog page looks like a real (if engineer-authored) issue tracker. The bones of a PM-usable workspace are here; what's missing is a thin layer of signage and translation. Today, a PM dropped into this repo cold would bounce within 20 minutes — not because the material is unreadable, but because every path in assumes you speak agent-infrastructure fluently and will be committing via git.

---

## Findings

### Area 1 — Orientation

**1.1 No PM-facing entry point exists anywhere** — **Major** (blocker for a solo cold-start PM)
- Files: `README.md`, `CONTEXT.md`/`CLAUDE.md`, `docs/README.md`
- Experienced: `README.md` is the friendliest human document, but its four "start here" paths are: instantiate the template, read the zoom model, read the full structure guide, or improve the template. `docs/README.md` indexes every doc "by need" — and every listed need is an engineering/agent need ("Configure MCP servers", "Measure context and roll sessions over"). Not one row maps to "understand what the team is building", "see status", or "find out why we chose X" — even though the repo *can* answer all three. I searched for "product manager", "non-technical", "stakeholder" across docs, CONTEXT.md, and skills: zero hits.
- Fix: Add a short `docs/for-non-engineers.md` (or a "Which reader are you?" section atop `docs/README.md`) with three rows: status → `work/*/README.md` + backlog page; decisions → `docs/adr/` + `work/*/decisions.md`; contributing → ask an agent, with 3 copy-paste prompts.

**1.2 CONTEXT.md, the "front door," is written to agents, not humans** — **Minor**
- Files: `CONTEXT.md`
- Experienced: It's explicitly the master context "for any agent session." As a PM I can skim it, but sections like "Agent Context Discipline" and "Tool & Context Loading" read as machine configuration. That's fine *by design* — but nothing tells the human reader "this file isn't for you; go to X instead." `README.md` partially plays that role but routes to setup, not to participation.
- Fix: One line at the top of CONTEXT.md: "Humans: start at README.md; non-engineers: docs/for-non-engineers.md."

**Pleasant surprise:** the rendered GitHub Pages guides (`setup-guide.html`, `workspace-structure.html`) mean a PM never has to read raw markdown-with-placeholders to understand the structure. The `docs/README.md` "one row per need" pattern is exactly right — it just needs PM rows.

### Area 2 — Status ("what's the team working on?")

**2.1 Per-project status is genuinely recoverable — but only if you already know the launcher/ledger convention** — **Minor**
- Files: `work/context-decay/README.md`, `work/context-decay/next-session.md`, `work/context-decay/handoff.md`, `work/kimi-k3-agent-integration/README.md`
- Experienced: This was the pleasant shock of the review. `work/context-decay/README.md` told me in one paragraph what the project is, where the shipped output lives, and `**Status:** dormant — all backlog findings resolved; remaining items are externally gated`. That's a status report. `kimi-k3-agent-integration/README.md` told me a brand-new effort's goal and constraint (API-key-only Moonshot access) in plain English. Total time to a portfolio-level answer: ~15 minutes across 6 directories — acceptable. What slowed me: I had to *learn* that README = identity, `next-session.md` = plan, `handoff.md` = history, and the launcher/ledger files themselves are dense with jargon ("rollover complete deltas", "WARN/STOP", "session #6's delta ~4.2K").
- Fix: Require a one-line `**Status:**` field in every work README (context-decay has it; kimi-k3 doesn't), and add a "for humans: how to read a work directory in 60 seconds" note to `docs/work-directory-conventions.md` or the PM entry doc.

**2.2 No roll-up view across work items** — **Minor**
- Files: `work/` (directory listing only)
- Experienced: To answer "what is the team working on?" I had to open six directories one by one. `ls work/` gives names but not state (active? dormant? done?). `template-maintenance` vs `usage-scenarios` vs `per-item-relaunch-override` — no way to tell which are alive without diving in.
- Fix: A tiny `work/README.md` index — one line + status per work item, updated at checkpoint/rollover (the skills already touch these files at exactly the right moments).

**2.3 The backlog is an 80KB hand-authored HTML file — great rendered, hostile as a source artifact** — **Major** (for a PM asked to *maintain* it), **Minor** (for reading)
- Files: `docs/template-workspace-backlog.html`, `docs/template-workspace-backlog-archive.html`
- Experienced: Rendered (the GitHub Pages URL in README.md), this is honestly the most PM-shaped artifact in the repo — scorecard tiles (3 Open / 52 Resolved / 4 Decided), status badges, stable IDs, Evidence/Impact/Fix per card. But as a *file*, it's raw HTML with CSS; the maintenance convention is "edit both files with targeted reads, grep the ID, never load whole" — instructions for agents, unfollowable by a PM in an editor. And the card *content* (registry clobber under concurrent sessions, hook throttle races) is pure infrastructure engineering — appropriately, since it's the template's own backlog, but a real project adopting this pattern for product work would inherit the same PM-hostile format.
- Fix: Don't change the format (agents maintain it fine) — change the framing: document that humans read the *rendered* page and file new items *through an agent* ("ask your agent to add a backlog card"), and put the rendered URL in `docs/README.md`'s row, not just README.md.

**2.4 Git log is unreadable as a status source for a PM** — **Papercut**
- Files: git history (`git log --oneline`)
- Experienced: `work(context-decay): session-6 rollover — audit + email rewrite logged, watch continues`, `fix(context-budget): trust authoritative copilot-vscode session id, never newest-mtime`. I can tell things are *happening*; I cannot tell *what shipped for whom*. This is normal for engineering repos and the work READMEs compensate — but nothing tells a PM "don't read git log; read the ledgers."
- Fix: Covered by the PM entry doc (1.1) — one sentence redirecting status questions to `work/` and the backlog.

### Area 3 — Decisions ("why did we choose X?")

**3.1 The decision-record system actually works for a PM reader** — **Strength, with one Minor gap**
- Files: `docs/adr/0001-three-tier-decision-capture.md` (and 0002–0007), `work/context-decay/decisions.md`, `docs/adr/README.md`
- Experienced: I read ADR-0001 cold and understood it completely — context, the decision, four rejected alternatives *with reasons*, and consequences, in plain prose. This is better decision hygiene than most product orgs I've worked in. The Tier-2 notes (`decisions.md`) are more technical but the **Chose / Because / Rejected / Blast radius** structure means I can extract the "why" even when I can't parse the "what" (e.g., I understood *why* the model isn't auto-pinned on rollover — "would silently opt successors out of default-model upgrades" — without understanding transcripts). The Minor gap: discovery. Tier-2 notes are scattered across six `work/*/decisions.md` files with no index; to answer "why did we choose X" I must first guess which work item X belonged to, or ask an agent. The three-tier scheme itself (trailer → note → ADR) is explained only in agent-facing docs.
- Fix: The PM entry doc gets a "decisions" section: ADRs for lasting choices at `docs/adr/`, per-project notes at `work/<project>/decisions.md`, and the canonical agent prompt for anything else ("why did we choose X? check decisions.md files and ADRs").

### Area 4 — Contributing (specs, tickets, work items)

**4.1 The advertised spec/ticket workflow (`to-spec`/`to-tickets`) isn't in this repo and requires an engineer to install** — **Major**
- Files: `docs/recommended-tooling.md` (lines 42, 183, 267), `~/.claude/CLAUDE.md` (global), `docs/archive/usage-scenarios.html`
- Experienced: The global context and the archived usage walkthrough both point to `to-spec`/`to-tickets` as *the* way to turn discussion into tracked work — exactly my job. But they are optional third-party global skills ("Matt Pocock engineering skills"), gated behind per-repo config (`setup-matt-pocock-skills`), documented in a tooling doc full of install commands. A PM cannot self-serve this; on a machine without the toolchain, the workflow named in the docs simply doesn't exist, with no fallback stated.
- Fix: In the PM entry doc, give the degraded-mode instruction: "no `to-spec` installed? Ask the agent: 'turn this discussion into a spec in `work/<project>/` and file tickets in `<tracker>`'" — the agent can do the work without the skill.

**4.2 A PM could plausibly drive `/create-work-item` and `/decision` — this is the closest thing to a PM-usable workflow, and it's unadvertised** — **Minor**
- Files: `skills/create-work-item/SKILL.md`, `skills/decision-log/SKILL.md`, `CONTEXT.md` "Workspace Skills"
- Experienced: These slash commands are conversational: `/create-work-item competitive-analysis`, `/decision <what + why + rejected>`. Nothing about them requires engineering knowledge to *invoke* — the agent does the file scaffolding and git mechanics. But the docs never say "these are safe for anyone"; they sit in a skills list alongside `session-rollover` and `onboard-repo`, which absolutely are not PM territory.
- Fix: Tag skills by audience — even just "(anyone)" vs "(engineering)" annotations in the CONTEXT.md skills list.

**4.3 Getting to a working seat assumes engineering throughout** — **Major** (for unaccompanied setup)
- Files: `docs/template-usage.md`, `docs/workspace-setup.md`, `docs/runbooks/`, `scripts/check-*.sh`
- Experienced: Every onboarding path starts with `git clone`, `rm -rf .git`, copying `settings.json.example`, keychain credentials, hook wiring. The runbook/check-script pairing is excellent *for engineers*. A PM cannot get from zero to a working agent session without an engineer or a very patient agent driving.
- Fix: Realistically, accept it — but say so: "Non-engineers: have an engineer (or an agent on a set-up machine) provision your clone; your work starts at `docs/for-non-engineers.md`." Also worth noting: `SPEC.md` is a clean, jargon-free fillable template ("what it does, for whom, the problem it solves") — the single most PM-native artifact in the repo, and nothing routes a PM to it as *their* deliverable.

### Area 5 — Vocabulary

**5.1 Participation requires absorbing a large, unglossaried jargon stack** — **Major**
- Files: `CONTEXT.md`, `docs/context-budget.md`, `docs/zoom-model.md`, `docs/work-directory-conventions.md`
- Experienced: To read a work directory I needed: launcher, ledger, rollover, handoff, compaction, WARN/STOP, "dumb zone", context tokens. To read CONTEXT.md: MCP, hooks, graphify, fragments, worktrees. To read zoom-model: Z0–Z3 *and* O0–O4. Each term *is* explained somewhere — `docs/context-budget.md`'s opening paragraph is genuinely accessible ("LLM performance degrades past ~150K context tokens… rolls work over via a deliberate handoff"), and zoom-model's map metaphor ("earth view shows continents; street view shows houses") is lovely — but the explanations are embedded in 10+ engineering docs totaling tens of thousands of words, with no glossary and no separation of "concepts you need to converse" from "mechanics only agents need."
- Fix: A ~15-line glossary in the PM entry doc. Honest triage: a PM needs *rollover, handoff, launcher/ledger, work item, ADR/decision note, backlog card* (~6 terms); they never need MCP, hooks, graphify internals, or O-levels.

---

## What works for a PM today

- **Decision provenance is outstanding.** ADRs with rejected-alternatives sections (`docs/adr/`) and structured Chose/Because/Rejected notes answer "why" better than most orgs' Confluence. A PM can read these unaided.
- **Work-directory READMEs are real status reports.** One screen per effort: what it is, where output lives, current status (`work/context-decay/README.md` is the model).
- **The rendered artifacts** (setup guide, structure guide, backlog page with scorecards and status badges) give humans a no-markdown path into the material.
- **The `docs/README.md` "one row per need" index pattern** is exactly the right shape — it just lacks non-engineering rows.
- **`SPEC.md`** is a plain-language, PM-native template hiding in plain sight.
- **Conversational skills** (`/create-work-item`, `/decision`) mean the git/file mechanics can be fully delegated to the agent — the enabling condition for PM participation already exists.

## Smallest changes with biggest PM impact (top 3)

1. **Add `docs/for-non-engineers.md` (~1 page) and index it in `docs/README.md` and `README.md`.** Three job-shaped sections — *status* (read `work/*/README.md` + the rendered backlog URL), *decisions* (`docs/adr/` + `work/*/decisions.md`), *contributing* (own `SPEC.md`; use `/create-work-item` and `/decision`; ask-the-agent prompts as the fallback for `to-spec`/`to-tickets`) — plus a 6-term glossary. This single file converts the repo from "engineer-only" to "PM-capable with an agent."
2. **Add a `work/README.md` status index** (one line + `Status:` per work item, refreshed by the checkpoint/rollover skills that already touch these files). Turns "what's the team doing?" from a six-directory dig into one glance.
3. **Tag audience on skills and docs.** "(anyone)" vs "(engineering)" annotations in CONTEXT.md's skills list, and a one-line human redirect atop CONTEXT.md. Near-zero token cost, and it stops PMs from wandering into `session-rollover` or `mcp-setup.md` and concluding the whole workspace isn't for them.
