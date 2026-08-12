# QA Persona — Cold-Start QA Review (raw report)

> Produced 2026-08-11 by a persona agent role-playing a QA engineer with two
> hats: (A) QA of the template's own machinery, (B) QA-role fit as a workspace
> user, including the user-directed spec → test-plan traceability checks.
> Read-only walkthrough. Part of `work/devex-review/`.

**Persona summary:** I spent this session as a QA engineer doing a cold-start pass over the template: first testing the workspace's own machinery (script syntax and live smoke tests, hook wiring across all six runtimes, doc/skill cross-references), then asking where my job — bug triage, repro, specs, test plans, verification records — actually fits in these conventions. The machinery is in unusually good shape: every path I chased resolved, both core scripts survived read-only smoke tests, and the docs are honest even about their own warts. The gaps are almost all on the QA-role side: the template is built around feature-flow (spec → tickets → sessions → handoffs) with verification treated as conversation-level discipline rather than a recorded artifact.

---

## Template QA findings (hat A)

**A1. Test-suite count drifted in the docs index** — *papercut*
`docs/README.md:40` says "nine suites"; `scripts/tests/` contains **ten**. Evidence: `test-rollover-prep.sh` was added in commit `23f3b9b` (the most recent feature commit), while `docs/README.md` was last touched 2026-08-08 (`533eb36`). Fix: change to "ten" or drop the count ("see `scripts/tests/`") so it can't drift again.

**A2. Two conflicting copy targets for the Claude settings example** — *minor*
`.claude/settings.json.example`'s `_comment` says "Copy to `.claude/settings.json` (gitignored)". But `scripts/setup.sh:43` copies it to `.claude/settings.local.json`, and `docs/template-usage.md:61` instructs the same. `docs/context-budget.md:546` says copy to `.claude/settings.json`. Both targets work in Claude Code, but a downloader following the comment plus setup.sh ends up with *both* files, and future edits (e.g. raising a hook timeout) can silently land in the one that isn't loaded last. Fix: pick one target and align the example comment, setup.sh, template-usage.md, and context-budget.md.

**A3. "Committed hook wiring" claim is loose for Claude Code** — *minor*
`CONTEXT.md` (Context Budget section) claims all six runtimes get the WARN/STOP push "via their committed hook wiring". For Claude Code the wiring is **gitignored** (`.gitignore:15`, confirmed via `git check-ignore`) — only the `.example` is tracked, and it materializes only if `scripts/setup.sh` runs. A fresh clone that skips setup gets codex/gemini/opencode/copilot hooks but no Claude hooks or statusline. `docs/context-budget.md:523,546` states this accurately; CONTEXT.md oversells it. Fix: qualify the CONTEXT.md sentence ("committed or setup-materialized; Claude Code requires the setup.sh copy step").

**A4. Measurement ledger hardcoded to a dev-effort directory** — *minor*
`scripts/context-budget.sh:40` — `LEDGER="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"` — and `.gitignore` has a matching hardcoded entry. Every adopter's `record` calls write their measurement history into a directory named after the template developers' own work item (`cmd_record` will `mkdir -p` it back into existence if deleted). Works, but is surprising and unclean in a template; five template-dev work dirs (`context-decay`, `automatic-session-rollover`, `usage-scenarios`, `per-item-relaunch-override`, `template-maintenance`) also ship committed, and `skills/session-rollover/SKILL.md:33,49` cites files inside `work/context-decay/` as evidence — soft dangling references the moment an adopter prunes those dirs. Fix: move the ledger to `.context-budget/context-ledger.jsonl` (or a neutral `work/.context-ledger.jsonl`) and mark the template-dev work dirs as prunable in `docs/template-usage.md`.

**A5. Launcher's `own_record()` omits opencode/gemini env identity** — *minor*
`scripts/launch-next-session.sh:137-145`: the env-first identity loop covers claude/codex/copilot-cli/copilot-vscode but not **opencode** (`OPENCODE_SESSION_ID` exists and is used by `context-budget.sh:342`) or gemini — yet both are supported launch runtimes (lines 269-270). An opencode session rolling over falls through to the "newest record for this project" fallback (lines 150-155), which can pick a different session's record when several sessions have touched the item, mis-deriving `DYING_SID` and skipping the lock release/supersede stamp. Fix: add opencode (env) and gemini ("workspace") arms to mirror `session_id_for()`.

**A6. Unvalidated numeric inputs in context-budget.sh** — *papercut*
`--interval` is never validated: `watch` with `--interval abc` enters an infinite loop of `sleep: invalid time interval` errors (line 783). Non-numeric `CONTEXT_DUMB_ZONE_TOKENS` in `context-budget.env` crashes arithmetic at lines 54/413 with an opaque bash error instead of a `die`. (`--gen` *is* validated — line 793 — so the pattern exists; it just wasn't applied to the others.) Fix: apply the same `[!0-9]` case-guard to `--interval` and the two env thresholds.

**A7. copilot-vscode discovery fallback is macOS-only** — *minor (partially unverified)*
`scripts/context-budget.sh:150-151` hardcodes `$HOME/Library/Application Support/{Code,...}/User/workspaceStorage`. On Linux (`~/.config/Code/...`), discovery without `VSCODE_TARGET_SESSION_LOG` always fails. The env-var path (lines 133-147) is cross-platform, and `stat -f%m || stat -c%Y` elsewhere shows Linux was considered, so this looks like an oversight rather than a scoping decision. I did not find an explicit "macOS-only" scoping statement in `docs/context-budget.md` for this runtime — if one exists deeper in that 600-line doc, downgrade this to papercut. (Related, handled well: `watch`'s `osascript` notification is properly guarded by `command -v`.)

**A8. Untracked work item violates the workspace's own discipline** — *papercut (hygiene, not shipped defect)*
`git status` shows `?? work/kimi-k3-agent-integration/` while `docs/work-directory-conventions.md:102` mandates "everything a future session must read to continue the work is committed". A rollover of that item would leave a successor with nothing. Not a template file defect — but it is exactly the failure mode the conventions warn about, observed in the flagship instance.

---

## QA-role fit findings (hat B)

**B1. The entire QA skill chain is external and optional** — *major*
The global context routes bug work to `triage`, `diagnosing-bugs`, `tdd`, and spec work to `to-spec`/`to-tickets` — none ship with the template. They live in `~/.claude/skills/` on this machine, symlinked from the Matt Pocock repo per `docs/recommended-tooling.md:42,93` — which files them under *optional* toolchain, outside the "Required for everyone" manifest. A teammate who clones the template and runs only required setup has `docs/agents/issue-tracker.md` conventions but **no skill that operates on them**: no triage state machine, no repro loop, no spec generator. Fix: either promote the triage/diagnosing chain to the required manifest, or ship minimal vendored equivalents under `skills/` (the workspace's own memory note says integrations should work for downloaders, agent-agnostically).

**B2. Specs: a place exists, a format does not (in-repo)** — *major*
(1) *Place:* yes — `work/<effort>/spec.md`, defined at `docs/agents/issue-tracker.md:27`. That part is solid and QA-relyable. (2) *Format:* the only format definition lives in the **external** `to-spec` skill (Problem Statement / Solution / numbered user stories "As an X, I want Y…"). The repo itself commits no spec template — `docs/work-directory-conventions.md:97` says only "The effort's spec/PRD, per docs/agents/issue-tracker.md", and issue-tracker.md defines only the *path*. A QA engineer without the optional toolchain has no acceptance-criteria structure to test against. Fix: commit a spec template (even 20 lines) next to `docs/adr/0000-template.md`, so the format survives without the external skill.

**B3. No spec-item → ticket → test traceability convention** — *major*
The pieces half-exist: to-spec produces *numbered* user stories; tickets are `issues/NN-<slug>.md` with `Status:` lines. But nothing defines a link between them — no "Covers: story 3, 7" field on tickets, no ID scheme a test plan could cite. Contrast with the template's own backlog HTML, which *does* have stable severity-scoped IDs (H/M/L + scorecard) — the discipline exists in-house but wasn't extended to product tickets. Fix: add a `Covers:`/`Refs:` line to the ticket format in `docs/agents/issue-tracker.md` (it already has `Blocked by:` — same shape) and state that spec story numbers are stable IDs.

**B4. Spec-less work leaves QA with no test basis** — *minor*
`spec.md` is Optional (`work-directory-conventions.md:97`), and the workspace's verification story for spec-less work is "Goal-driven execution: define verifiable success criteria" (CONTEXT.md principle 4) — criteria that live in *conversation* and die at rollover unless they happen to land in a handoff block. Handoff blocks are capped at ≤40 lines and archived after two sessions, so success criteria are structurally ephemeral. For a solo-dev template this is a defensible default; for a team with a QA role it means unverifiable claims of "done". Fix: one sentence in work-directory-conventions.md: "if no spec.md exists, record the effort's success criteria in README.md" (the one durable, never-archived file).

**B5. No home for test plans or test results** — *major*
`grep -ri "test plan|test result|QA"` across `docs/*.md`, `CONTEXT.md`, and all `skills/*/SKILL.md` returns **zero** hits. The closest accommodations: the catch-all "keep everything else named for what it is" (`work-directory-conventions.md:99`) and optional `STATUS.md`. So a test plan *can* live at `work/<effort>/test-plan.md` without violating anything — but nothing tells two QA engineers to converge on the same name, no skill ever reads or updates it, and verification evidence ("ran suite X at commit Y, 3 failures") has no append-only home the way decisions (`decisions.md`) and sessions (`handoff.md`) do. The template deeply believes "capture the why behind decisions"; it has no equivalent for "capture the evidence behind done". Fix: add `test-plan.md` / `verification.md` rows to the optional-files table, mirroring how `decisions.md` got its row and skill.

**B6. Bug reporting maps acceptably, but loses fields the template's own backlog has** — *minor*
Product bugs land as `work/<effort>/issues/NN-<slug>.md` with `Status:` + `## Comments` — workable, and the wayfinder `Blocked by:`/`claimed`/`resolved` machinery generalizes to verification tickets fine. But severity, repro steps, and found-in/fixed-in have no defined fields, while the template-only backlog (explicitly deleted on adoption per CONTEXT.md) models severity + stable IDs + `Fixed:` provenance well. Fix: fold a severity/repro line-format into issue-tracker.md's Conventions so the good pattern survives adoption.

**B7. Template CONTEXT.md doesn't scaffold the promised `## Language` section** — *minor*
Global CLAUDE.md: "Every project has a root CONTEXT.md … carries a `## Language` section — the project's domain glossary. `grill-with-docs` and `improve-codebase-architecture` read this." `grep -n Language CONTEXT.md` → no match; the template's placeholder sections omit it, so every instantiated workspace starts without the section two skills depend on. Fix: add a placeholder `## Language` section to the CONTEXT.md template.

---

## What checked out clean

- **All ~40 shell scripts pass `bash -n`** (scripts/, scripts/hooks/, scripts/lib/, scripts/tests/).
- **Live smoke tests passed:** `scripts/context-budget.sh check` measured this very session (exact method, 71,799 tokens, correct OK status and exit 0); `scripts/launch-next-session.sh context-decay --dry-run` produced the correct prompt, incremented seq (#8), replayed `.rollover-options` approval → `--permission-mode auto`, and wrote nothing.
- **Every hook wiring points at an existing script**, all six runtimes: `.claude/settings.json{,.example}` → `context-budget.sh` + `context-budget-claude-hook.sh`; `.codex/config.toml`, `.gemini/settings.json`, `.github/hooks/context-budget{,-vscode}.json`, `.opencode/plugins/context-budget.js` → their respective `scripts/hooks/context-budget-*-hook.sh`, all present. Hook design is throttled, escalation-only, fail-open.
- **CONTEXT.md reference integrity:** all 8 `skills/*/SKILL.md`, all 7 `.claude/commands/*.md`, `.claude/agents/repo-navigator.md`, every named doc, `mcp-fragments/README.md`, `context-budget.env`, and all named scripts exist at stated paths. `docs/README.md` index links all resolve.
- **Sampled skills' internal references all resolve** (session-rollover → `rollover-prep.sh`/`capture-rollover-options.sh`; create-work-item; decision-log → `docs/adr/0000-template.md` + ADR index; the cited `work/context-decay/*-analysis*.md` evidence files are committed and present).
- **Tracked/gitignored split is coherent and deliberate** (locks, `.session-seq`, `.rollover-options`, telemetry excluded; `.example` files tracked; `.opencode/node_modules` correctly scoped by `.opencode/.gitignore`).
- **`scripts/setup.sh` is genuinely robust:** idempotent symlink repair for Windows-flattened templates, JSONC-comment-preserving Copilot trust seeding with graceful degradation, informational dependency check.
- **`docs/context-budget.md` is honest** — it documents its own awkward truths (gitignored Claude wiring, Copilot silent-no-op trust gate, unverified copilot-cli paths) rather than papering over them.

## Top 3 fixes

1. **Ship or require the QA skill chain (B1) + commit a spec template with a traceability field (B2/B3)** — one change-set turns `docs/agents/issue-tracker.md` from a convention only this machine can execute into one any adopter's QA engineer can use.
2. **Give verification a durable home (B5)** — add `test-plan.md`/`verification.md` to the work-directory optional-files table; the launcher/ledger machinery already supports it, it just needs a named seat.
3. **Move the measurement ledger off `work/context-decay/` (A4) and align the settings-copy story (A2/A3)** — the three findings a downloader hits in their first hour, all cheap to fix.
