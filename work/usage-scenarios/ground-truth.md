# Ground truth — what exists today (distilled subagent reports, 2026-08-08)

Distilled findings from four read-only exploration passes over the repo.
Inputs to `scenarios.md` and `gaps-and-coverage.md`. Pointers verified at
time of writing; re-verify before acting on any single fact.

## A. Backlog state (docs/template-workspace-backlog*.html)

- **Zero open cards**; 53 settled (49 resolved, 4 decided). Scorecard: 0 open.
- Three **un-carded Open findings** live only as change-log rows: (CL-1)
  subagent-fired WARN push swallowed under parent session id; (CL-2)
  EnterWorktree mid-session stales the registry artifact path — two live
  primary-takeover incidents; (CL-3) launcher staleness race when local
  checkout lags origin — prose mitigation only.
- Consistency defects: duplicate card IDs L19/L20 (each used twice in the
  archive); active file's status panel prose stale ("31 findings"), never
  updated past ~M13.
- **Trajectory:** backlog began as adversarial review of a reusable public
  template; last ~25 cards are almost all one subsystem (context-budget/
  rollover). Template-as-artifact questions (multi-user, multi-repo,
  per-user tooling, template-level evaluation) unexamined since June.
- Topic hits: multi-user — **nothing** (D3 even *removed* the `<username>_`
  work-dir prefix, the only multi-user affordance). Multi-repo — only L5, a
  link-integrity fix; repos-registry + `setup.sh --clone-repos` never
  adversarially reviewed. L12 = documented capitulation to
  single-session-per-runtime ("revisit only if concurrent same-runtime
  sessions become real" — CL-1/2/3 show the assumption already violated).
  Testing — 8 suites/343 asserts, all script-level; **no eval of the
  template as a template** (no clean-machine clone test, no doc-accuracy
  harness); L16 was a phantom-test-suite doc bug.

## B. Settings / secrets / tooling (docs + config files)

**Per-user settings pattern** — "shared committed, local gitignored,
`*.example` for new users" (workspace-structure.md) — applied unevenly:
- Claude Code: BOTH `.claude/settings.json` and `settings.local.json`
  gitignored — even machine-independent hooks/statusline are untracked;
  setup.sh copies example → settings.local.json only, so **hooks are never
  wired by script**. The hand-split settings.json (hooks) vs .local
  (permissions) on this machine is documented nowhere.
- `.mcp.json` gitignored despite zero secrets → core server set can't be
  shared/enforced.
- OpenCode: **no local-override layer**; enabling an MCP server means
  editing a tracked file (dirties tree; `opencode run` also rewrites
  `.opencode/opencode.json`).
- Codex/Gemini: per-user MCP lives in **global** home-dir config (always-on
  for every project on the machine); no project-local user override.
- Copilot: needs manual `trustedFolders` step covered by NO check script
  (only prose in context-budget.md ~line 533).
- VS Code `.vscode/` is the cleanest example of the intended pattern.
- **No merge/override concept**: nothing lets user personal choices layer on
  a shared baseline; Codex/Gemini/OpenCode/Copilot have no example→local
  flow at all.

**Secrets** — keychain-only, verify-don't-login runbooks, registry in
service-access.md + gitignored `.service-access.local.json` cache +
`check-service-access.sh` (always exit 0 — no hard fail). "Vault" = OS
keychain synonym only. Today effectively ONE credential (gh). **Absent:**
shared/team keyvault (no 1Password/Vault/SOPS/cloud-SM mention anywhere),
shared-vs-personal credential distinction, secret bootstrapping for a new
member, rotation coordination, required-vs-optional per service. Linux/
Windows keychain backends named but no commands given. NOTE: service docs
reference an enforcement test in `scripts/tests/` for env parameterization
that report says doesn't exist (verify — other report lists scripts/tests/*
as real; likely the specific parameterization test is missing, not the dir).

**Tooling layers** — ADR-0002 lean-by-default: CLI-first; core `.mcp.json`
(graphify only) vs `mcp-fragments/` (only youtube-transcript today; GitHub
MCP removed 2026-08-07 in favor of `gh`); asymmetric parent/child toolsets.
**Required-vs-optional exists only as** `req git`+`req gh` (exit 1) vs `rec`
(warn) in check-dependencies.sh — workspace-global, covers binaries only.
No manifest of non-negotiable skills/MCP/services per product; nothing
enforces a mandated skill set. recommended-tooling.md: "everything optional";
exceptions: two vendored skills (wayfinder, writing-for-agents, pinned to
upstream commits) and conditional per-repo Matt Pocock setup.

**ADRs** — 0001 three-tier decisions; 0002 lean tools; 0003 rollover via
workspace script not vendor mechanisms; 0004 multi-session model (session-
keyed state, per-project locks); 0005 session roles + lock as primary
marker; 0006 key coordination state to repo identity not checkout
(worktrees); 0007 .session-seq canonical session numbers. **No ADR** for
per-user settings model, secrets/keychain, or required-vs-optional tooling.

**Onboarding today** — two-layer canonical path (global-per-machine manual;
workspace-local: clone → check-dependencies → setup.sh → check-service-
access → check-workspace-structure). Checks verify-only; runbooks fix.
Only TWO runbooks exist (dependencies, authentication; the latter's README
row is stale re: MCP token). **No runbook for: new user/machine as such,
per-runtime setup (Codex/Gemini/OpenCode/Copilot), product onboarding.**
Repo onboarding exists (`skills/onboard-repo`). Windows weakest (bash-only
scripts, reactive symlink repair). Of the brief's three onboardings:
repo ✅, product ❌, new user/machine ◐ (scripts exist, no runbook, global
layer fully manual).

## C. External lifecycle docs

**Documented scenario spine** — usage-scenarios.html covers six (S1 pull &
bootstrap, S2 onboard existing repo, S3 new project, S4 feature loop, S5
checkpoint & resume, S6 finish branch) + lifecycle state machine. But the
shipped feature set exceeds the doc: **absent from it** are S0 (agent
scaffolds workspace from bootstrap instructions in workspace-structure.md:35-246),
S7 (recreate on new machine, workspace-setup.md), S8 (context-budget
rollover — the template's most developed mechanism!), create-work-item,
wayfinder, rlm, decision-log, backlog maintenance. Stale naming inside it:
`work/<user>_<project>/` at :372,:396,:459 contradicts canonical
`work/<project>/` (vestigial — the only user-scoped trace in the repo).

**Multi-repo**: storage/naming layer complete & thoughtful (repos/ gitignore
mechanics, 12-field registry, 3-doc repo-context model, tiers, mirror
convention for restricted networks). Automation layer partly aspirational:
(1) `setup.sh --clone-repos` clones ALL registry URLs — ignores tiers,
breaks mirror naming, despite docs promising primary-only + skip-restricted;
(2) check-workspace-structure.sh does NOT do the registry↔disk
reconciliation workspace-structure.md:677 claims; (3) docs/system-design.md
(cross-repo ownership map) is a 15-line TODO stub; (4) no batch onboarding,
no cross-repo dependency/ownership model beyond prose.

**Workspace-as-repo**: internally inconsistent. Bootstrap path says
`rm -rf .git && git init`, "do not commit anything" — local-only, no remote
creation ever described. Yet workspace-setup.md assumes `git clone
<clone-url>`; work/ is CHECKED IN (ledgers/handoffs as shared history —
only makes sense with a remote); scattered "your team"/"new users" language
presupposes a team no doc addresses. Absent: remote creation/push, branch/PR
policy for the workspace repo itself, merge expectations on work/ files,
public/private guidance.

**Onboarding coverage**: repo = strongest (skill+command+script+templates+
freshness check; minor gap: step-7 discoverability wiring unverified).
New user/machine = good runbook pattern but single-user in shape ("you on
your new machine", never "second person joining"). Product = weakest: no
artifact; S3 + S0 interview only; SPEC.md 5 lines, system-design.md TODO;
3 of 4 skills S3 depends on are external (recommended-tooling table only).

**Multi-user, stated plainly**: no user identity anywhere in the state model
(registry keys runtime+session-id; lock has no user; work/ paths unscoped).
ADR-0004/context-budget.md define operating model as "ONE developer, many
sessions". `.active-session` lock is gitignored + mtime-validated —
correct for one machine, cannot arbitrate across machines/people. work/
files are single-writer by construction (REPLACE launcher, prepend ledger)
→ two people collide every session; ADR NNNN- numbering is a collision
point. No team onboarding, no owner-vs-contributor distinction, no
cross-user visibility primitive. L12 closed as "revisit if concurrent
same-runtime sessions become real".

## D. Internal machinery + test coverage

**Mechanism groups** (full audit in the session-1 subagent report; pointers
in docs/context-budget.md unless noted):
- **A. Measurement/identity**: register (session-keyed artifact pinning,
  per-runtime session-id env vars), disk-sourced measurement (D1, never ask
  the model), `record --label` per work unit, six per-runtime adapters with
  bytes÷4 estimate fallback, `--runtime auto` detection.
- **B. Threshold response**: WARN=consent point; declined-WARN write-ahead
  mode (~30K grace window); STOP=no-ask roll (150K < Claude's ~200K
  auto-compact so deliberate rollover wins); 7+1-step rollover procedure;
  uniform thresholds across roles (YAGNI, revisit trigger documented).
- **C. Relaunch/lineage**: off/manual/auto modes; committed per-item
  override; verbatim bootstrap prompt across 6 runtimes; `.rollover-options`
  approval-mode inheritance (captured mechanically from transcript; model
  deliberately NOT captured); ADR-0007 session numbering + self-heal;
  successor confirm loop; attach-session re-attach front door.
- **D. Concurrency (one person)**: session-keyed registry; advisory
  per-item lock, liveness = holder artifact mtime, stale >3h reclaimed;
  roles primary/auxiliary/child/superseded (lock beats cached role);
  child locks granted only via parent chain to lock holder (≤10 hops);
  bottom-up release (I4); `--takeover` explicit recorded steal;
  superseded_by back-stamp + stale-primary sweep; release-before-launch;
  gemini single-session exception (shared telemetry log).
- **E. Subagent fleet**: `children` per-child sweep (sidechain-inclusive
  measure); R2 dispatch contract (report-file heartbeat, 15-line return
  cap, status vocabulary); R3 successor-dispatch-not-resume at child
  WARN/STOP; R4 dispatch records + generation fencing + `dispatch-list`
  drain check; fleet-safe parent rollover (close orphans KILLED,
  re-dispatch from recorded spec).
- **F. Delivery/wiring**: 4-layer warning delivery; shared hook lib
  (throttle/escalation-once/fail-open); six vendor hook channels each with
  quirks (codex hash trust, copilot trustedFolders silent no-op, VS Code
  stderr-only block, gemini first-turn spurious STOP accepted); statusline
  chains user's own; ADR-0006 worktree anchoring via git-common-dir.
- **G. Work-item/boundary**: launcher/ledger split + archival; create-work-
  item; checkpoint-vs-rollover precedence (measurement wins); decision
  promotion scan; 3-tier decisions + 16KB archival + heredoc-append (file
  never enters context); wayfinder (decision tickets, one per session,
  fog-or-ticket test); rlm (REPL holds context, LLM=semantics
  Python=arithmetic, root sees truncated stdout only).

**Multi-person breakage points** (sharpest first): (1) lock liveness =
LOCAL artifact mtime → another person's lock always reads stale → silent
steal; (2) all coordination state gitignored → zero cross-person mutual
exclusion; (3) no user identity anywhere (no $USER/hostname in any script);
(4) machine-local .session-seq → colliding session numbers in committed
ledger; (5) single-writer launcher/ledger enforced only by unshared lock;
(6) worktree ff-only sync checks fire on normal collaborative traffic;
(7) --takeover premise inverts (no notification path to the other human).
Fix shape: identity field + non-local liveness signal (heartbeat in shared
storage) + non-local numbering.

**Test coverage** (8 suites, ~343 asserts, all hermetic mktemp workspaces):
registry/locks/roles/children/takeover/worktree (18 groups); launcher
(27 groups incl. option inheritance, release-before-launch, seq/--name);
children sweep (9); dispatch contract (7); dispatch records (9); vendor
hooks (11, all six envelopes); attach (7); statusline (8).
**Zero coverage**: capture-rollover-options.sh (the capture half of C4!),
watch mode, most per-runtime measure adapters (only opencode fixture-
tested), estimate fallback, --transcript precedence invariant, discovery
fallbacks, non-macOS branches, ≤10-hop cap boundary, SessionEnd release
hook, E5 fleet-recovery end-to-end, KILLED-reap flow, setup.sh, all
check-*.sh, onboard-repo.sh, rlm REPL. **Untestable-by-construction today**
(instruction-only, verified by agent not CI): WARN/STOP trigger policy
compliance, rollover 7-step procedure, launcher REPLACE/ledger APPEND
discipline, archival rules, checkpoint precedence, decision AND-test,
wayfinder discipline, rlm checkpoint mandate.

**Context-discipline mechanisms**: 32 distinct mechanisms in four bands —
measure & gate (absolute thresholds, exit-code protocol, context-inspect
--phases, context-experiment, statusline), bound the session (rollover
replaces compaction, write-ahead, pruned launcher with do-NOT-reload
section, pointers-over-summaries), bound the files (launcher/ledger,
archival tiers, heredoc-append, content boundaries, don't-read-whole
banners), bound the tooling/fleet (ADR-0002 lean loading, repo-navigator,
graphify, rlm, child return caps, wayfinder ticket sizing).
