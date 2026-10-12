# Decisions — template-maintenance (Tier-2 notes)

## 2026-08-05 — Vendor writing-for-agents as a skill, not a docs page

- **Chose:** vendor upstream `writing-for-agents` into `skills/writing-for-agents/`
  (wayfinder pattern: pinned commit, provenance comment, refresh procedure;
  includes `SKILL-MECHANICS.md` + `agents/openai.yaml`).
- **Because:** its frontmatter triggers exactly when we want it loaded
  (creating/editing skills, touching AGENTS.md/CLAUDE.md) — active guidance;
  agent-agnostic for template downloaders.
- **Rejected:** copying it under `docs/` — passive reference nobody re-finds;
  loses model-invocation triggering.
- **Blast radius:** skills/, CONTEXT.md, docs/recommended-tooling.md, backlog.
- **Promote?:** no (pattern already ADR-adjacent via wayfinder precedent).

## 2026-08-05 — Inline the handoff contract instead of vendoring the handoff skill

- **Chose:** inline the three load-bearing rules of the global `handoff` skill
  (reference artifacts by path/URL; include a suggested-skills section; redact
  secrets/PII) directly into `skills/checkpoint/SKILL.md` and
  `skills/session-rollover/SKILL.md`, with a one-line "the global skill may draft,
  the contract binds" note.
- **Because:** both skills named `handoff` as a prerequisite that ships with
  mattpocock/skills, not with this template — downloaders got a broken dependency
  (violates the "template additions are first-class / agent-agnostic" rules).
- **Rejected:** vendoring the whole handoff skill — another pinned copy to
  maintain, for ~10 lines of rules that fit inline.
- **Blast radius:** skills/checkpoint/, skills/session-rollover/, CONTEXT.md
  checkpoint bullet.
- **Promote?:** no (small-scope consistency fix; reversible).

## 2026-08-06 — Demand-load trims: index over split, condense over delete
**Chose:** In-file section index + grep-the-header access note for docs/context-budget.md; shell-heredoc append + 16KB archive rule for decisions.md; condensing (not deleting) CONTEXT.md's graphify / tool-loading / backlog sections.
**Because:** Context audit showed the cost is whole-file loads, not file existence; an index fixes access without breaking the file's 11 inbound pointers, and condensed sections keep every rule reachable via a verified pointer target.
**Rejected:** Splitting context-budget.md into multiple files — churns 11 pointers across docs/skills for the same saving; deleting CONTEXT.md sections outright — graphify rules and backlog discipline are per-session guidance, and recommended-tooling.md §5 circularly pointed back at CONTEXT.md for removal steps.
**Blast radius:** CONTEXT.md, docs/context-budget.md, skills/decision-log/SKILL.md, docs/recommended-tooling.md §5, both backlog HTML files (L25–L27).
**Promote?:** no

## 2026-08-07 — GitHub access: gh CLI required, GitHub MCP fully removed
**Chose:** Delete the GitHub MCP fragment and all wiring (opencode block, PAT-export plumbing, docker dep); promote `gh` to a required dependency verified at setup (`check-dependencies.sh` req + `gh auth login` in the auth runbook).
**Because:** Largest per-server context cost (~900 tokens standing) for tools the ADR-0002 transcript scan showed are almost never used; gh CLI covers the capability at zero standing cost in every runtime.
**Rejected:** Keeping the fragment as a documented escape hatch — doc surface for a path nobody takes; re-add is one 8-line file (recipe kept in mcp-fragments/README.md). Keeping PAT export — its only consumer was the MCP server; gh manages its own keychain credential.
**Blast radius:** mcp-fragments/, opencode.json, .claude/settings.json.example, .mcp.json.example, .vscode/mcp.json.example, scripts/check-dependencies.sh, scripts/check-service-access.sh, docs/{mcp-setup,service-access,workspace-setup,template-usage,recommended-tooling,setup-guide.html,runbooks/*}, ADR-0002 amendment.
**Promote?:** no — implements existing ADR-0002 direction, recorded there as an amendment

## 2026-08-07 — L18 env-knob precedence: capture/restore over default-only env file
**Chose:** Per-variable precedence in `context-budget.sh` — capture explicit env values for the three knobs before sourcing `context-budget.env`, restore after (the `launch-next-session.sh` ROLLOVER_* pattern); plus regression test T16.
**Because:** The old guard keyed on `CONTEXT_DUMB_ZONE_TOKENS` alone, so the env file silently clobbered any other knob's explicit override (bit the M14 lock reclaim live).
**Rejected:** Switching `context-budget.env` to default-only assignments (`: "${VAR:=…}"`) — fixes all consumers in one place but inverts the per-item `work/<proj>/context-budget.env` override chain in `launch-next-session.sh` (global sourced first would win over per-item), and per-item env files are user-authored plain assignments.
**Blast radius:** scripts/context-budget.sh lines 42–52; scripts/tests/test-context-budget-registry.sh (T16).
**Promote?:** no

## 2026-08-12 — M26 no-git mode: paste-in posture block over an optional CONTEXT.md section
**Chose:** Document no-git ("private") mode as a third instantiation variant in `docs/template-usage.md` §1 with a "No-git mode" subsection carrying a ready-to-paste Privacy Posture block for CONTEXT.md, the Tier-1→Tier-2 decision-capture rewrite, and the N/A list; one-line N/A notes at each point of use (CONTEXT.md Tier-1 bullet, decision-log/checkpoint/session-rollover SKILL.md). No code changes.
**Because:** The card's own evidence shows the core loop is already git-free — the fix is labeling. Point-of-use one-liners keep the always-loaded context cost near zero while the full variant doc lives at the instantiation choice point, which is when it's actually read.
**Rejected:** Shipping a full optional "Privacy Posture" section inside the CONTEXT.md template itself (marked delete-if-git) — burdens every git-using instance's always-loaded front door until pruned, for a mode most instances don't take; the paste-in block gives no-git instances the same end state.
**Blast radius:** docs/template-usage.md §1, CONTEXT.md Decision Records, skills/{decision-log,checkpoint,session-rollover}/SKILL.md, both backlog HTML files.
**Promote?:** no (documentation labeling; reversible)

## 2026-08-12 — L36 prune offer: setup.sh reminder + doc checklist over a destructive prune flag
**Chose:** `scripts/setup.sh` prints a one-line prune reminder (gated on the backlog pair being present — the template-development marker) pointing at the broadened `template-usage.md` §5 checklist; the deletions themselves stay copy-paste commands in the doc.
**Because:** setup.sh is an idempotent bootstrap script every runtime and CI test runs — deletion logic there needs git/no-git handling, an interactivity story agents can't answer, and test surface; a reminder is 4 lines, safe, and the checklist carries judgment calls (LICENSE swap, non-code trims) a script can't make.
**Rejected:** `--prune-template` flag or interactive TTY prompt in setup.sh performing the deletions — destructive code in the bootstrap path for a once-per-instance action; the card's "offer the prune interactively" is satisfied by the unmissable reminder at the moment of instantiation.
**Blast radius:** scripts/setup.sh, docs/template-usage.md §5, scripts/tests/test-template-instantiation.sh (T1c), both backlog HTML files.
**Promote?:** no

## 2026-08-12 — L37 portable brief: convention-only over a portable-brief skill
**Chose:** Document the portable-agent-brief pattern as a convention section in `docs/work-directory-conventions.md` (sealed one-file-per-version `briefs/<audience>-vN.md`, supersession header, never-reveal section, ledger notes at issue/staleness, skeleton) plus an optional-files-table row. No skill.
**Because:** One real occurrence so far (house-sale sessions 6–7); the pattern is pure file discipline with no steps a skill would automate — a convention beside the other work-directory file conventions is where an agent scaffolding a brief would look. Simplicity-first: a skill can be promoted later if the pattern recurs.
**Rejected:** A small `skills/portable-brief/SKILL.md` + `/portable-brief` shortcut — adds an always-loaded CONTEXT.md skills-list line and a skill to maintain for a workflow that is one template file; premature until a second instance reinvents or misapplies the convention.
**Blast radius:** docs/work-directory-conventions.md, both backlog HTML files.
**Promote?:** no

## 2026-08-16 — Vendor the full Matt Pocock skill set in-repo

**What:** All 27 curated skills (engineering + productivity + 2 misc setup) now ship
vendored at `skills/<name>/`, pinned to upstream `068b6e0`, refreshed via
`scripts/sync-vendored-skills.sh` (pristine re-copy vs adapted body-swap classes).

**Why:** Template downloaders previously got only 5 of 27 skills; the rest required
the author's personal global clone+symlink setup. Vendoring makes them available to
anyone downloading the template, agent-agnostically (every runtime reads the same
SKILL.md; upstream's agents/openai.yaml ships too).

**Rejected:** (a) git submodule — breaks on zip downloads, poor runtime support;
(b) upstream Claude Code plugin — Claude-Code-only, violates agent-agnostic rule;
(c) setup script that clones+symlinks per user — leaves downloaders a manual step
and nothing works offline/out-of-the-box.

## 2026-08-29 — M31: commit Claude Code hook wiring rather than reconcile it
**What:** Track `.claude/settings.json` (hooks + statusLine only); strip hooks from
`settings.json.example`, which becomes the personal `settings.local.json` starter.
**Why:** `setup.sh` `copy_if_missing` meant existing installs never received new hook
wiring (missing session-loop Stop hook → supervisor blocks in eval → "auto relaunch
didn't happen"). Committing makes Claude Code update-with-pull like every other runtime.
**Rejected:** teaching setup.sh to reconcile template-owned blocks, and/or a drift check
in check-workspace-structure.sh — both detect or repair the failure class instead of
removing it; committing the file removes it. (Tier-1 trailer on commit a660150.)

## 2026-08-29 — L43: explicit lineage-restart marker, not renumbering (context-decay)
**What:** Teach `check-ledger.py` a `<!-- ledger-lineage-restart: … -->` marker that
restarts the session-number chain at the block below it; dates still check across the
seam. One marker placed in `work/context-decay/handoff-archive.md` where the numbering
restarted; mutation-tested (marker-less restart and marker-hidden date regression both
still fail).
**Why:** The restart is real history — the later lineage (#3–#4, then live 5–6) is
referenced by launchers/commits, and the conventions say grandfathered headings are
never rewritten. A marker keeps the gate honest while declaring the anomaly explicitly.
**Rejected:** (a) renumbering either lineage's headings — rewrites history and ripples
into live-ledger/cross-references; (b) silently widening the ordering rule to tolerate
restarts — already rejected in session #9 (an undeclared restart is indistinguishable
from a misfiling); (c) resetting the date chain at the marker too — wider than needed,
would let a misfiled date hide behind the seam.

## 2026-08-31 — exit-UX: heal/diagnose at next launch, not at exit
Session-end handling (S1 empty session poisons next launch; S2 silent quit):
chose lineage-gate diagnosis + auto-heal at NEXT LAUNCH plus notify-on-quit
in session-loop. Rejected: SessionEnd-time warnings (agent gone, output not
reliably visible), forced rollover on exit (hostile), treating sentinel-less
clean exits as errors (punishes checkpoint-quit). Statusline "unrecorded"
indicator deferred, not declined. Design: work/template-maintenance/exit-ux-plan.md.

## 2026-08-31 — M16: id-keyed artifact glob over a worktree-entry re-register hook

EnterWorktree relocates a claude transcript mid-session, staling the pinned
registry artifact path (wrongful stale-primary sweeps, two live incidents).
Chose: `glob_artifact_for()` — resolve `~/.claude/projects/*/<sid>.jsonl` at
every read (discovery, check/record self-re-pin, lock_holder_age liveness);
newest match wins so a stale copy left behind loses. Rejected: a
worktree-entry hook that re-registers — claude-only, heals only the entry
moment, and does nothing for other sessions' liveness reads of a record the
holder never refreshed.

## 2026-10-09 — L70: how to carry a local change to a vendored skill
**Chose:** a third vendored-skill class, "patched". `scripts/sync-vendored-skills.sh` re-copies upstream, then applies a saved patch (`skills/<name>/workspace.patch`), and fails loudly when the patch no longer applies. L70 (code-review: group each axis into blockers and suggestions) is its first user.
**Because:** upstream issue mattpocock/skills#1242 may never be merged. A patch survives refreshes, works for every agent runtime, and costs effort only when upstream rewrites the patched lines.
**Rejected:** a rule outside the skill (CONTEXT.md or a doc) — the skill would not point to it, and CONTEXT.md is at 15.5K of its 16K limit; forking code-review — upstream improvements stop arriving; won't fix — the gap stays.
**Blast radius:** scripts/sync-vendored-skills.sh, its test, skills/vendored-skills.md (class list), skills/code-review/, backlog L70.
**Promote?:** maybe — if a second skill adopts the patched class (L67 could move back into writing-for-agents).

## 2026-10-09 — Adopt upstream's GLOSSARY.md (glossary leaves CONTEXT.md)
**Chose:** follow mattpocock/skills (#876) and move the project glossary (`## Language`) out of `CONTEXT.md` into a root `GLOSSARY.md`, which `CONTEXT.md` links to. The vendored skills sync unpatched.
**Because:** after the rename, the upstream skills look for the glossary in `GLOSSARY.md`. Moving it costs one move, frees part of CONTEXT.md's 16K budget, and keeps the refreshes clean.
**Rejected:** keep the glossary in CONTEXT.md and patch about 15 vendored files from GLOSSARY.md back to CONTEXT.md — a large patch that every upstream edit could break; pin the affected skills at 068b6e0 — they go stale.
**Blast radius:** CONTEXT.md, new GLOSSARY.md, docs naming the `## Language` section, `init-project-ai-infra`/global CLAUDE.md wording (outside this repo; report it).
**Promote?:** done → ADR-0014

## 2026-10-09 — Vendor implement-spec despite its overlap with plans
**Chose:** vendor upstream `implement-spec` as pristine and user-invoked only; its catalog line routes tracker-backed specs/tickets to it and multi-session work items to `/plan`.
**Because:** downloaders who use the Matt Pocock flow (to-spec → to-tickets) expect the closing step.
**Rejected:** skipping it — the vendored flow would have a missing last step.
**Blast radius:** skills/implement-spec/, sync script list, vendored-skills.md, recommended-tooling §3.
**Promote?:** no.

## 2026-10-09 — M48: isolated nodes merge back before `done`, not at the reconcile node
**Chose:** the orchestrator merges an isolated child's branch into its own checkout, then verifies and runs `done <id>`; the plan state is committed after `start` so the worktree sees it.
**Because:** the child's Log lines and Acceptance ticks live in its worktree's copy of the node file; `done` and the reconcile's on-disk verification need them in the main checkout. Matches upstream implement-spec step 5 (merge on completion).
**Rejected:** merge at the wave's reconcile node (the card's proposal) — the reconcile would verify node files that don't yet hold the child's claims.
**Blast radius:** skills/plans/SKILL.md ("Subagent prompt template", Verification), docs/plans.md `isolated` row.
**Promote?:** no.

## 2026-10-11 — Skill packs: vendor pstack from cursor/plugins, not from a port
**Chose:** vendor pstack skills from the canonical `github.com/cursor/plugins` repo, directory `pstack/` (MIT © 2026 Lauren Tan, who is "poteto"), pinned to the last commit touching `pstack/`.
**Because:** it is the author's source with its own LICENSE; the seven skills we take are plain text that needs no port.
**Rejected:** `michael-denyer/pstack-claude` — 47 local forks and a second copyright holder; `backnotprop/pstack` — a mirror, one step removed.
**Blast radius:** scripts/sync-vendored-skills.sh (pstack upstream block), skills/vendored-skills.md.
**Promote?:** no.

## 2026-10-11 — Skill packs: name collisions go to the existing skill
**Chose:** do not vendor pstack `tdd` and `teach`, Addy `interview-me` (fires on "grill me"), `planning-and-task-breakdown` (Claude command `/plan`), `using-agent-skills` and pstack `poteto-help` (routers beside `ask-matt`), Addy `code-review-and-quality` (beside `code-review`). `create-verification-skill` writes `skills/verify-<app>/`, which does not collide with Claude Code's built-in `/verify`.
**Because:** the brief's rule: prefer the existing skill, never shadow one; each has an equivalent already.
**Rejected:** renaming the incoming skill (two skills for one job) or replacing ours (loses the patched `code-review`, the grilling primitive, the plans machinery).
**Blast radius:** none in code; recorded in the analysis and catalog.
**Promote?:** no.

## 2026-10-11 — Skill packs: Addy's shared checklists live at the repo root `references/`
**Chose:** copy the six checklists the adopted skills link to as `references/<file>.md`, with a `!references/*.md` gitignore exception, so the skills' `../../references/...` links resolve unchanged and the skills stay pristine.
**Because:** the folder already exists for external references; no link rewrite means no patch to break at every upstream refresh (322 commits in 90 days).
**Rejected:** rewriting links by `workspace.patch` (fragile); a sub-folder under `references/` (still needs a rewrite); copying the checklists into each skill (duplicates, and the links still break).
**Blast radius:** .gitignore, references/README.md, scripts/sync-vendored-skills.sh (stamps the copies), check-drift item 5.
**Promote?:** no.

## 2026-10-11 — Skill packs: one sync script for three upstreams
**Chose:** extend `scripts/sync-vendored-skills.sh` with per-upstream blocks (repo, clone, source prefix, pin rule) instead of sibling scripts; patches apply to adapted skills too; adapted skills keep a workspace `agents/openai.yaml`.
**Because:** one provenance format, one drift check, one refresh command for downloaders; the logic is identical per upstream.
**Rejected:** a sibling script per upstream (three copies of the same loop); a manifest file (more machinery than three arrays).
**Blast radius:** the sync script and its suite, check-drift and its suite, skills/vendored-skills.md refresh paragraph.
**Promote?:** maybe — if a fourth upstream arrives, promote the "vendored skill classes and refresh" scheme to an ADR.

## 2026-10-11 — Skill packs: poteto-mode and the 24 principles are not adopted
**Chose:** skip pstack's operating mode, its 23 playbooks, and all `principle-*` skills.
**Because:** poteto-mode needs Cursor (Custom Mode, `Task` with named models, `/loop`, cloud workers, 6,700 lines of Bun scripts) and its autonomy rule ("just do it") contradicts the workspace's "ask when uncertain" and "push of main is the user's call". The principles are inert without it; six repeat our coding principles and four contradict "surgical changes".
**Rejected:** a trimmed poteto-mode (a fork we would own); vendoring the principles as reference cards (24 skills nothing points at).
**Blast radius:** none.
**Promote?:** no.

## 2026-10-11 — Skill packs: `why` is rewritten, not patched
**Chose:** write `skills/why/SKILL.md` in the workspace's words, crediting pstack, with upstream's `references/epistemics.md` verbatim; not covered by the sync (like `rlm`).
**Because:** upstream's text is built on Cursor's `Task` tool, model lines and an `mcps/` directory in most paragraphs; a patch would touch more than it keeps and break at every refresh.
**Rejected:** patched vendoring; skipping it (nothing else recovers rationale when no ADR exists).
**Blast radius:** skills/why/, catalog line.
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `unslop` is narrowed in its frontmatter, not by patch
**Chose:** change `skills/unslop/SKILL.md`'s `description:` directly. The brief asked for a `workspace.patch`.
**Because:** `unslop` is in the *adapted* class: `scripts/sync-vendored-skills.sh` keeps the workspace frontmatter and re-copies only the body, so the frontmatter is already workspace-owned. A patch hunk against the frontmatter would be applied once and then fail the sync's `patch -N --dry-run` on the next refresh (already applied), stopping the sync.
**Rejected:** a `workspace.patch` (breaks the second sync); moving `unslop` to the pristine class plus a patch (loses the user-/model-invoked switch the adapted class exists for).
**Blast radius:** skills/unslop/SKILL.md frontmatter; the catalog line in skills/vendored-skills.md.
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `ask-matt` stays pristine; the guide and `CONTEXT.md` carry the pointer
**Chose:** leave `skills/ask-matt/` untouched; `docs/stakes-to-ceremony.md` points at `ask-matt` for the detailed route, and `CONTEXT.md` points at the guide.
**Because:** `ask-matt` is user-invoked, so whoever opens it has already chosen the full map; the always-loaded `CONTEXT.md` pointer reaches every agent first, which a line inside the router cannot. The router is upstream's highest-churn file, so a patch there is the one most likely to stop applying at a refresh.
**Rejected:** a one-line `workspace.patch` ("Size the change first: docs/stakes-to-ceremony.md") near the top of the router — one more re-apply per refresh for a pointer the agent already holds.
**Blast radius:** none to the vendored tree; the sync round trip stays an empty diff. Revisit if ledgers show agents routing tweaks through the full flow despite the pointer.
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `unslop` is a final pass on human-facing prose
**Chose:** `description: Final editing pass that cuts AI-prose tells from human-facing text (docs, READMEs, PR text, reports); not code, commit messages, or agent-facing skill text.` (156 bytes, in the adapted frontmatter).
**Because:** "Must always apply" made it fire on every token of output, including code and skill files, where its catalog of tells (no em dashes, no triads) conflicts with `writing-for-agents`; an editing pass is the shape upstream's body describes ("Edit text to remove AI patterns").
**Rejected:** user-invoking it (then nobody runs it: the whole point is a pass the author forgets); keeping "always" with a shorter list (still fires on code).
**Blast radius:** skills/unslop/SKILL.md frontmatter; the catalog line in skills/vendored-skills.md ("Model-invoked so it applies whenever prose is produced" needs rewording).
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `checkpoint`, `session-rollover`, `design-for-testability` become user-invoked
**Chose:** `disable-model-invocation: true` + a workspace `agents/openai.yaml` with `allow_implicit_invocation: false` for the three; their `.claude/commands/` shortcuts already exist. Short identifying descriptions; the trigger policy stays in each body.
**Because:** none is reached by description matching. `session-rollover` is named by the hook WARN/STOP text, by `context-budget.sh` exit codes 1/2 and by CONTEXT.md, all by file path; `checkpoint` is the user's word or a launcher instruction; `design-for-testability` is an advisory interrogation beside the already user-invoked grill skills, and an accidental fire costs the user six questions. Together they are 1,421 bytes weighed every turn for zero description-driven invocations. `plans` is the precedent: user-invoked, still followed from `plan.sh` prompts by reading the file.
**Rejected:** keeping `session-rollover` model-invoked as a safety net (the net is the hook/exit-code path, which names the file; a description cannot fire on a token count the model cannot see); tightening the three instead (still a per-turn tax for a skill that is never triggered by text).
**Blast radius:** the three SKILL.md frontmatters, three new openai.yaml files, skills/vendored-skills.md footnote, docs/workspace-structure.md and CONTEXT.md where "model-invoked" is claimed; the `(slash)` markers are already right.
**Promote?:** no.

## 2026-10-11 — Skill ceremony: vendored descriptions are patched only where a patch already exists
**Chose:** tighten `constraint-driven-development` and `doubt-driven-development` by adding a frontmatter hunk to their existing `workspace.patch`; leave every other pristine vendored description as upstream wrote it (`security-and-hardening` at 581 bytes and `code-review` at 421 included); pstack adapted frontmatters (`unslop`, `technical-writing`) are edited directly.
**Because:** a patch is re-applied at every refresh and breaks whenever upstream touches the hunk (Addy's repo: 322 commits in 90 days); for a skill that already carries a patch the marginal cost is one hunk on a line upstream rarely edits, and those two were the only vendored descriptions that over-trigger ("any time a confident output…", "when an agent writes more code than anyone will read"). The long keepers are long because they list real situations, not synonyms.
**Rejected:** new patches for brevity alone; user-invoking `git-guardrails-claude-code` / `setup-pre-commit` (needs the adapted class in the sync script to own their openai.yaml, for 480 bytes whose trigger already requires an explicit ask).
**Blast radius:** the two patches and SKILL.md files; the sync round trip must still produce an empty diff (patches verified with `patch -p1 -R -F0 --dry-run` and a forward apply onto the reconstructed upstream file).
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `technical-writing` drops the slash and commit messages from its trigger
**Chose:** `description: "Standard for human-facing technical prose: … Use when writing or reviewing a doc, README, RFC, or PR description."` (197 bytes).
**Because:** "Use for /technical-writing" names a Claude Code command as a trigger, which means nothing to Codex or Gemini; "commit messages" made it fire on every commit, where the four-layer standard is overkill and `pr` already owns PR bodies.
**Rejected:** user-invoking it (it should catch a README being written without being asked).
**Blast radius:** skills/technical-writing/SKILL.md frontmatter; vendored-skills.md catalog line mentions commit text.
**Promote?:** no.

## 2026-10-11 — Skill ceremony: `SKILL_DESC_MAX_BYTES` = 7500
**Chose:** set the budget in `scripts/check-skill-descriptions.sh` to 7500: the projected total after all verdicts (7,303 bytes) rounded up to the next 500.
**Because:** the budget is a ratchet, not a ceiling with slack; ~200 bytes of headroom means adding a model-invoked skill forces a trim or a user-invoke swap, with the reason in the commit, which is the discipline the video argued for.
**Rejected:** 9000 (the initial value; leaves room for four more untrimmed skills); 8000 (room for one long one, which is how the pack grew to 10 KB).
**Blast radius:** scripts/check-skill-descriptions.sh constant and its comment; the test's fixture budget is set per case and is unaffected.
**Promote?:** no.
