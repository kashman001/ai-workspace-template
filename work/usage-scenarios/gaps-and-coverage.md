# Gaps & coverage — ai-workspace-template (2026-08-08, session 2)

Gap analysis derived from the scenario catalog (`scenarios.md`) and the
evidence base (`ground-truth.md`). Ranked by (impact on the brief's
requirements × distance from ✅). Each gap: what's missing, the concrete
recommendation, and which scenarios it moves (E/I codes from scenarios.md
§3–§4).

Ranking rationale in one line: gaps 1–4 are *requirements in the brief with
no artifact at all* (❌); gaps 5–8 are *unevenness or inversion* in things
that partially exist (◐).

---

## Gap 1 — Multi-user is greenfield (moves E17, E2, I4, I5)

**Missing:** any concept of a second person. No user identity in registry,
lock, or `work/` paths; lock liveness = local artifact mtime (another
person's lock always reads stale → silent steal); all coordination state
gitignored (zero cross-machine mutual exclusion); machine-local
`.session-seq` collides in committed ledgers; single-writer launcher/ledger
collides on merge; ADR numbering collides; `--takeover` assumes the other
holder can see the takeover record (no notification path to another human).
ADR-0004 documents the model as "one developer, many sessions" — the brief
(req 3) requires multiple people on multiple machines.

**Recommendation (phased, don't big-bang):**
1. *Identity first:* add a `user` field (`$USER@hostname`) to registry
   entries, lock files, and dispatch records. Cheap, unblocks everything.
2. *Non-local liveness:* lock arbitration across machines needs a heartbeat
   in shared storage (committed lease file or remote ref), not artifact
   mtime. Design in an ADR before code — this reverses part of ADR-0004/5.
3. *Collision-proof numbering:* session numbers and ADR numbers become
   `<user>-<n>` or allocation-on-merge; work-dir sharding
   (`work/<project>/` stays shared; per-user state moves under a
   user-scoped subpath or stays machine-local).
4. Write the missing **team-workspace doc** (also closes E2): remote
   creation, branch/PR policy for the workspace repo, merge expectations on
   `work/` files, public/private guidance.

**Not recommended:** trying to make the current mtime-lock multi-user-safe.
It is correct for its designed scope; extend by adding a second, shared
mechanism, not by weakening the local one.

## Gap 2 — Product onboarding & Z0 docs have no owner (moves E3, E15, E14, E1)

**Missing:** the entire Z0 pane. SPEC.md is a 5-line stub,
system-design.md a 15-line TODO; the S0 precondition interview gathers the
facts but nothing turns them into docs; no skill, no check, no runbook.
This is the weakest of the brief's three onboardings and the one the
zoom-level model (scenarios.md §1) most depends on — E14 (answer at the
right zoom level) can't work without a Z0 to start from.

**Recommendation:** an `/onboard-product` skill symmetric with
`/onboard-repo`: interview → generate Z0 artifacts (product overview +
architecture overview naming services and how they talk + build/run/debug
entry points) → populate repos registry as the Z0→Z1 index → a
`check-workspace-structure` extension that flags placeholder Z0 docs as
FAIL, not decoration. Also resolve the E1 contradiction it sits on:
template-usage says `rm -rf .git && git init`, workspace-setup assumes
`git clone <url>` — document the local-vs-remote fork explicitly as a
choice point with both paths.

## Gap 3 — No non-negotiable tooling manifest (moves E7, E6, E10, I7)

**Missing:** the brief's required-vs-optional split (req 4). Today the only
hard requirement anywhere is `req git`+`req gh` in check-dependencies.sh
(binaries only, workspace-global); recommended-tooling.md declares
everything optional; check-service-access.sh always exits 0; E10's own doc
depends on three skills the template doesn't guarantee.

**Recommendation:** a committed `required-tooling` manifest (one file,
e.g. `docs/required-tooling.md` with a machine-readable block, or a
`.toolchain.json`) declaring per-product: required binaries, required
skills, required MCP servers, required services — each with a check
command. `check-dependencies.sh`/`check-service-access.sh` read it and
exit non-zero on missing *required* entries. This also gives I7 its missing
installation check (hook wiring becomes a required, checkable item).

## Gap 4 — Shared secrets don't exist (moves E8, E5, E17)

**Missing:** the brief's shared-keyvault requirement (req 4). "Vault" in
the repo means the OS keychain only; no team-vault concept
(1Password/Vault/SOPS/cloud-SM — none mentioned), no shared-vs-personal
credential distinction, no secret bootstrap for a new member, no rotation
story. Personal-secret pattern is sound but macOS-detailed only and holds
one credential (gh).

**Recommendation:** don't pick a vault product in the template. Add to
service-access.md: (a) a `scope: personal | shared` field per service
registry entry; (b) a documented *interface* a team vault must provide
(fetch by name → env/keychain, bootstrap step in the new-member runbook,
rotation note); (c) one worked example (1Password CLI or SOPS-in-repo)
behind the interface. Add Linux/Windows keychain command equivalents while
in the file.

## Gap 5 — Personal layer is uneven across runtimes (moves E6, E5, I7)

**Missing:** the `*.example` → gitignored-local pattern is only fully real
for VS Code. Claude Code has *both* settings files gitignored (so even
shareable hooks/statusline are untracked, and setup.sh never wires hooks —
I7's install gap); `.mcp.json` is gitignored despite zero secrets, so the
shared core can't be enforced; OpenCode has no local layer at all (enabling
a server dirties a tracked file); Codex/Gemini push per-user MCP to global
home config (always-on for every project on the machine); Copilot's
trustedFolders step is checked by nothing. No merge/layer concept anywhere.

**Recommendation:** one decision (ADR): *shared baseline committed,
personal overlay gitignored, per runtime*. Then mechanically: track
`.claude/settings.json` (hooks/statusline; machine-independent) and
`.mcp.json` (no secrets), keep `settings.local.json` and personal fragments
gitignored; give OpenCode an overlay file merged at launch (or document the
dirty-tree cost as accepted); document Codex/Gemini global-config bleed as
a known limitation with the per-session `--mcp-config`-style workaround;
add Copilot trustedFolders to the check scripts (per Gap 3's manifest).

## Gap 6 — No template-level eval harness (moves I10, E1, E4, E5; guards all)

**Missing:** all 8 suites (~343 asserts) test the context-budget subsystem;
`setup.sh`, every `check-*.sh`, and `onboard-repo.sh` — the code paths every
new user/product actually runs first — have zero tests, and nothing
evaluates the template *as a template* (no clean-machine clone test, no
doc-accuracy check). Test effort is inverted relative to risk (scenarios.md
§5 reading). The backlog confirms the drift: last ~25 cards are one
subsystem; template-as-artifact questions unexamined since June.

**Recommendation:** a `template-eval` suite in `scripts/tests/`: (1)
clean-room instantiation — clone into mktemp, run setup.sh + all checks,
assert exit codes and produced structure; (2) doc-accuracy asserts for the
specific claims already caught false (workspace-structure.md:677
reconciliation claim; `--clone-repos` tier behavior vs its docs); (3) the
scenario catalog (this work item) as the checklist an eval run walks.
Cheap version first: even (1) alone would have caught the E1 contradiction
and the hooks-never-wired gap.

## Gap 7 — Doc architecture doesn't follow the zoom model (moves E14, E15, E10, E11)

**Missing:** the zoom-level structure (scenarios.md §1) exists as a
proposal, not as doc structure. usage-scenarios.html covers S1–S6 but omits
S0, S7, S8 (rollover — the template's most developed mechanism),
create-work-item, wayfinder, rlm, decision-log, and backlog maintenance;
it still says `work/<user>_<project>/` in three places (the repo's only
vestigial user-scoping); no doc states the zoom discipline or the
delegate-vs-zoom-in-place rule (§1c).

**Recommendation — and the decision on usage-scenarios.html's fate:**
**supersede it.** Promote the catalog's §1/§1b/§1c into a committed doc
(`docs/zoom-model.md` or a section of workspace-structure.md), and replace
usage-scenarios.html's S1–S6 spine with the E-catalog (E1–E17) as the
canonical external-scenario doc — the HTML becomes either a generated view
of it or is retired to the archive with a pointer. Rationale: the catalog
already supersets it (session-1 decision, option (a)), it is markdown
(agent-editable with targeted reads, unlike the HTML), and keeping both
guarantees drift. Fix the three `<user>_` references in whichever artifact
survives.

## Gap 8 — No authoring path for team capabilities (moves E18, E10, E7)

**Missing:** the brief's req 10 (added session 2): teams creating their own
skills/agents/runbooks/scripts for common product work — run the tests,
test component A, run the performance suite. The containers exist and are
agent-neutral (`skills/`, `.claude/agents/`, `docs/runbooks/`, `scripts/`),
but every shipped example is workspace-process tooling; nothing tells a
team which container fits a product capability, how to wire the
`.claude/commands/` mirror, how the hand-maintained CONTEXT.md skills list
gets updated, or how to mark a capability required (E7's manifest).

**Recommendation:** a short authoring doc (or `create-capability` skill)
with a container decision rule — *deterministic and runnable → `scripts/`;
agent workflow → `skills/` (+ commands mirror); needs its own toolset or
isolation → `.claude/agents/` profile; human-only steps → `docs/runbooks/`*
— plus the two mechanical steps (mirror + CONTEXT.md listing) automated or
checklisted, and a `required: true` hook into Gap 3's manifest so a team
can make "run the tests before finishing a branch" non-negotiable. E10's
feature loop then names team capabilities instead of external optional
skills.

---

## Cross-cutting observations

- **The ❌ column is the brief.** Every ❌ scenario (E2, E7, E17, plus
  E3/E15's ❌→◐) maps directly to a brief requirement (reqs 3, 4, 5, 7).
  The template is excellent at what it built (one person's session/context
  discipline, repo onboarding) and unbuilt at what the brief asks next.
- **Two of three onboardings need artifacts, not polish.** Repo ✅;
  person/machine needs a runbook + global-layer automation (◐); product
  needs everything (❌).
- **Instruction-only mechanisms (T:⊘) are a fifth of the catalog.** They
  are fine as instructions — but list them explicitly (I2, I8, I9, parts of
  I3) in the eval harness as "verified by agent review, not CI" so the
  boundary is deliberate, not accidental.
- **Un-carded findings CL-1/2/3** (ground-truth §A) should become backlog
  cards; CL-2 (worktree stales registry artifact) *reproduced during this
  session* — the budget `record` after EnterWorktree shows the artifact
  path switching to the worktree-scoped project directory.

## Recommended sequencing

1. Gap 6's cheap version (clean-room instantiation test) — it guards
   everything else's changes.
2. Gap 2 (product onboarding + E1 fork fix) — highest doc leverage, no
   design controversy.
3. Gap 3 (manifest) then Gap 5 (personal layer ADR) — 5 depends on 3's
   check plumbing; Gap 8 (capability authoring doc) rides along with 3
   (its `required:` hook) and is mostly documentation.
4. Gap 7 (zoom docs + supersede HTML) — after 2, so Z0 content exists to
   point at.
5. Gap 4 (shared-secrets interface) — needs a real second service to be
   honest; do when one exists.
6. Gap 1 (multi-user) — biggest, needs its own ADR cycle; phase 1
   (identity fields) can land any time, phases 2–3 deserve a wayfinder map.
