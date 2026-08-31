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
