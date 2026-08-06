# Decisions — automatic-session-rollover

Tier-2 decision notes, newest last. Format: `skills/decision-log/SKILL.md`.

## 2026-08-05 — Automate the rollover→relaunch pipeline (the effort itself)
**Chose:** A workspace-owned script (`scripts/launch-next-session.sh`) that
bakes the canonical bootstrap prompt in verbatim and launches a fresh runtime
session seeded with it, governed by workspace parameters offering a
consent-gated mode (agent asks, then launches and continues) and a fully
automatic mode (WARN/STOP triggers rollover + relaunch unprompted).
Interactive seeded launch is the agent-agnostic core; detached background
launch is a claude-only tier.
**Because:** Stage 3 of the rollover pipeline (relaunch) is a manual
copy-paste today, and the prompt wording is load-bearing — hand-typed looser
phrasings make the new session summarize-and-wait instead of execute. Keeping
disk (launcher + ledger) as the source of truth means any runtime can pick the
work up; the script only accelerates the launch.
**Rejected:** upstream `claude-handoff` wholesale — its content rules already
landed via the inlined hand-off contract; its prompt-only background-handoff
mechanism — loses disk-as-source-of-truth and is Claude-only; nohup+yolo
background emulation for codex/gemini — trades permission safety for symmetry;
inlining vendor launch commands in the `session-rollover` skill — violates the
CLI-first rule (vendor specifics live only in scripts).
**Blast radius:** `scripts/launch-next-session.sh` (new),
`context-budget.env`, `skills/session-rollover/SKILL.md` (closing step),
`docs/context-budget.md`, `docs/workspace-structure.md`.
**Promote?:** done → ADR-0003

## 2026-08-05 — Multi-session identity redesign (approved, session 3)
**Chose:** Session-keyed registry state
(`.context-budget/sessions/<runtime>-<session-id>.json`, each session writes
only its own file; resolve-self via runtime env-var identity first) plus one
*active* session per project enforced by an advisory lock
(`work/<proj>/.active-session`; dying session releases after the D5
verification gate, successor's register acquires, stale locks reclaimable).
Gemini exception documented (exact counts are single-session-per-workspace;
per-session fallback is estimate-only). D8 restated: successor confirmed =
new session file with same project + different session-id.
**Because:** The operating model is one developer running multiple
projects/work items concurrently, each with its own main session — and the
scalar per-runtime registry (`session-<runtime>.json`) is a live bug under
that model: `check`/`record` prefer the registry over re-discovery, so
session A measures session B's artifact (fired live 2026-08-05 when the
`--bg` demo clobbered the design session's registry entry).
**Rejected:** keeping a global "active project" scalar — breaks with
concurrent sessions by construction; making the launcher/ledger backbone
multi-writer instead of locking — REPLACE semantics on `next-session.md` are
single-writer by construction, and concurrent rollovers on one work item
would silently destroy each other.
**Blast radius:** `scripts/context-budget.sh` (register/check/record/resolve),
`.context-budget/` layout, `work/*/.active-session` (new),
`docs/context-budget.md`, `skills/session-rollover/SKILL.md` (D5/D8 gates).
**Promote?:** done → ADR-0004

## 2026-08-05 — Relaunch knobs: home, shape, defaults (session 3)
**Chose:** `ROLLOVER_RELAUNCH=off|manual|auto` + `ROLLOVER_RUNTIME` in
`context-budget.env`, workspace-level. Default `manual` (consent-gated: agent
asks at rollover, then runs `launch-next-session.sh` itself). `off` = today's
paste-prompt behavior; `auto` = STOP background-launches the successor
unprompted where supported (claude; falls back to manual elsewhere), WARN
still asks per the hybrid. `ROLLOVER_RUNTIME` is only a fallback default —
the actual relaunch runtime comes from the dying session's own registry
record (codex session → codex successor).
**Because:** The knobs govern behavior at a context-budget threshold and are
consumed by the same actors that read WARN/STOP — `context-budget.env` is
already the checked-in home for those. `manual` as default exercises the full
pipeline while keeping a human decision at every session boundary. Consent
lives in the *trigger* policy (WARN asks / STOP goes), not a separate
per-launch confirmation.
**Rejected:** a new `workspace.env` — second knobs file whose only tenant
overlaps the first's domain; create it only when a genuinely non-budget knob
arrives. Per-project knob override — the multi-session operating model varies
*sessions* per project, not relaunch policy; per-project policy would make
rollover behave differently depending on which terminal fires first. A second
"really launch?" gate at STOP in `auto` — recreates `manual` inside `auto`.
**Blast radius:** `context-budget.env`, `scripts/launch-next-session.sh`,
`skills/session-rollover/SKILL.md` (closing step), `docs/context-budget.md`.
**Promote?:** done → ADR-0004 (this note keeps the defaults' fuller rationale).

## 2026-08-05 — Detection + runtime scope after smoke tests (session 3)
**Chose:** All four hook deployments (codex `UserPromptSubmit`, gemini
`BeforeAgent`, opencode `chat.message` plugin, copilot CLI
`sessionStart`/`agentStop`) IN SCOPE for this project; the only spun-out
ticket is VS Code agent-mode hook verification (+ `copilot_vscode_measure`)
on a Copilot-licensed machine. Launcher covers all five runtimes with seeded
interactive (`claude`, `codex`, `gemini -i`, `opencode --prompt`,
`copilot -i`); detached background stays claude-only (`--bg`); opencode
serve/attach noted as a possible future tier, not v1. Cadence rule shrinks
to a fallback note for hook-less environments.
**Because:** Smoke tests (`smoke-test-opencode.md`, `smoke-test-copilot.md`)
confirmed the push channels LIVE on real installs and produced working
hook/plugin code, collapsing the deployment cost that justified deferral;
`copilot -i` refuted the headless-only claim that had excluded copilot from
the launcher; opencode's sqlite artifact makes it the easiest runtime to
measure.
**Rejected:** separate tickets for opencode/copilot CLI hooks — their
rationale (CLI not installed, channel untested) no longer holds; excluding
copilot from the launcher — based on a refuted docs claim; including VS Code
agent-mode verification in scope — impossible on this machine (no Copilot
extension/license) and Preview-status contract may shift.
**Blast radius:** `scripts/launch-next-session.sh` (5 runtimes),
`.codex/config.toml`, `.gemini/settings.json`, `.opencode/plugins/`,
`.github/hooks/`, `docs/context-budget.md`, a new ticket for VS Code
verification.
**Promote?:** done → ADR-0004

## 2026-08-05 — Promote the session-3 cluster as ONE companion ADR (session 4)
**Chose:** A single companion ADR-0004 ("multi-session model, trigger policy,
knobs, runtime scope") in the ADR-0003 family, with all three session-3 notes
in its Provenance block and a "Refined by" forward link added to ADR-0003.
**Because:** The three notes describe one coherent behavioral model (how the
ADR-0003 automation behaves), and accepted ADRs should stay immutable —
supersede/companion, don't rewrite.
**Rejected:** amending ADR-0003 in place — substantially rewriting an accepted
ADR breaks record immutability; four separate ADRs — ceremony without a fork
per document, and the launcher explicitly capped promotion at one.
**Blast radius:** `docs/adr/0004-multi-session-rollover-model.md` (new),
`docs/adr/0003-*.md` (one Refined-by line), `docs/adr/README.md` index.
**Promote?:** no — it *is* the promotion record.

## 2026-08-05 — Session-id derivation: env-first, artifact-derived fallback (item #1)
**Chose:** `session_id_for()` resolves identity from the runtime's own env var
first (`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`,
`VSCODE_TARGET_SESSION_LOG` basename), else derives the same id from the
artifact path (transcript basename / rollout UUID suffix / session-state dir).
Gemini gets the fixed id `workspace`.
**Because:** the same session must map to the same registry file whether or not
the env var is present, or one session grows two files and resolve-self breaks.
Gemini exports no per-session identity — the fixed id *is* the documented
single-session-per-workspace exception.
**Rejected:** mtime-heuristic keying (still races — identity is the only
reliable key); refusing to register without an env var (kills the fallback
runtimes entirely).

## 2026-08-05 — Advisory lock warns, never blocks measurement (item #1)
**Chose:** `register --project` finding the lock held by a live session warns
and skips acquisition but still registers and emits the check; `release` only
ever removes a lock held by self. Staleness = holder artifact untouched >
`CONTEXT_LOCK_STALE_SECS` (default 3h, in context-budget.env).
**Because:** hard-failing register would kill budget tracking for exactly the
session that most needs measuring; enforcement is the agent honoring the
warning before single-writer launcher/ledger writes.
**Rejected:** hard-fail register on held lock; lock-free multi-writer
launcher/ledger (REPLACE semantics are single-writer by construction).

## 2026-08-05 — Gemini concurrent guard: freshness heuristic on the shared log (item #1)
**Chose:** at gemini register, a non-empty telemetry log modified <10 min ago
is treated as another live session's — skip the reset, register against the
newest chat log (estimate-only), warn.
**Because:** register is a session-start action, so a fresh own-session log
cannot exist yet; freshness is the only signal gemini offers (no session id).
**Rejected:** always-reset (corrupts the live session's exact counts);
per-session telemetry filtering (nothing to filter on).

## 2026-08-05 — TTY guard for attached relaunch (item #2)
**Chose:** `launch-next-session.sh` in manual mode `exec`s the runtime only
when stdin+stdout are a terminal; otherwise it prints the ready-to-run
command (`run: …`) and exits 0.
**Because:** the agent invokes the script from a non-tty tool shell — exec'ing
a TUI there hangs; relaunch-analysis already prescribed "print the
ready-to-run command (others)" for that case.
**Rejected:** always exec (hangs agent shells); refusing to run outside a tty
(loses the paste-me fallback).

## 2026-08-05 — copilot-vscode degrades to prompt-only (item #2)
**Chose:** runtime `copilot-vscode` prints the bootstrap prompt with a warning
and exits 0 — no launch attempted.
**Because:** VS Code agent mode has no CLI seeded launch; verification is spun
out (issues/01-vscode-agent-mode-hooks.md); the dying session still needs the
prompt emitted for the user to paste.
**Rejected:** hard error (kills the rollover's paste-me fallback).

## 2026-08-05 — D8 successor confirmation only after --bg launches (item #2)
**Chose:** after a `--bg` launch, poll `.context-budget/sessions/` for a file
absent before launch with matching project and a different session-id;
timeout `ROLLOVER_CONFIRM_SECS` (default 120s), non-fatal
(`successor=unconfirmed` + advice).
**Because:** attached launches occupy the terminal — nothing to poll from; a
confirmation timeout must not fail an otherwise-complete rollover.
**Rejected:** mandatory confirmation on all launch paths.

## 2026-08-05 — Bootstrap prompt block always prints first (item #2)
**Chose:** every mode (including error-free `off` and dry runs) prints the
verbatim bootstrap prompt block before any launch logic.
**Because:** the paste-me fallback must survive any launch failure; the script
is the single source of the load-bearing wording (ADR-0003).
**Rejected:** printing it only in `off` mode.

## 2026-08-05 — Extract a shared hook lib before writing four more wrappers (item #3, Task 1)
**Chose:** pull the throttle/escalation/fail-open core (used once for the
Claude hook already) into `scripts/hooks/context-budget-hook-lib.sh`, sourced
by every per-runtime wrapper; the Claude wrapper keeps its exact stderr +
`exit 2` envelope and byte-identical messages.
**Because:** one copy of that logic beats four near-duplicates once codex,
gemini, opencode, and copilot each need their own thin wrapper — divergent
throttle/escalation bugs across five copies would be far more expensive than
extracting first.
**Rejected:** copy-pasting the Claude hook's logic into each new wrapper
(exactly the duplication the extraction avoids); folding the vendor-envelope
formatting into the shared lib too (each vendor's stdout/stderr contract is
different enough that this would just move the duplication, not remove it).
**Blast radius:** `scripts/hooks/context-budget-hook-lib.sh` (new),
`scripts/hooks/context-budget-claude-hook.sh` (refactored to source it).
**Promote?:** no — small refactor, no rejected-alternative weight beyond the
obvious.

## 2026-08-05 — opencode measurement source and runtime-detection scope (item #3, Task 2)
**Chose:** measure from sqlite `message.data` per-turn `tokens.total` (the
same reading a live opencode session shows), falling back to a session-column
token sum — no bytes÷4 estimate fallback, because the opencode db is shared
across all sessions in the workspace and an estimate over the wrong slice
would be actively misleading. `detect_runtime` (auto mode) recognizes
opencode only via `OPENCODE_SESSION_ID` being set, not via the newest-artifact
fallback loop the other runtimes share.
**Because:** exact per-turn token counts already exist in the db; degrading
to a size estimate would throw away real precision. Joining the
freshest-artifact auto-detect loop would let a stale opencode db shadow a
genuinely active claude/codex/gemini session that happens to be newer by
mtime — opencode only self-identifies when its own env var says so.
**Rejected:** size-estimate fallback for opencode (misleading over a
shared, multi-session db); adding opencode to the freshest-artifact
auto-detect loop (shadowing risk against other runtimes).
**Blast radius:** `scripts/context-budget.sh` (`opencode_discover`,
`opencode_measure`, `detect_runtime`).
**Promote?:** no — adapter-level implementation detail, same shape as the
other per-runtime adapters already in `docs/context-budget.md`.

## 2026-08-05 — Gemini hook measures from telemetry, not the transcript payload (item #3, Task 4)
**Chose:** the gemini `BeforeAgent` hook measures from the workspace
`.gemini/telemetry.log` (exact token counts), never from the hook payload's
`transcript_path` (the chat transcript carries no token counts at all —
using it would silently degrade every gemini hook check to a bytes÷4
estimate). The telemetry log's existing workspace-scoped, single-session
limitation (documented pre-Task-4 in `docs/context-budget.md`) is accepted
as-is for the hook path rather than solved here.
**Because:** the hook's whole job is to push an accurate number in-band;
choosing the payload path over telemetry would trade exactness for
convenience for no reason — the telemetry log is already the adapter's
source of truth for `check`/`record`, so the hook should agree with them.
**Rejected:** measuring from `transcript_path` (no token counts, forces an
estimate); building a gemini-hook-specific concurrency guard now (the
existing telemetry limitation already has an accepted-limitation writeup —
solving it only for the hook path would leave `check`/`record` inconsistent
with the hook).
**Blast radius:** `scripts/hooks/context-budget-gemini-hook.sh`,
`.gemini/settings.json` (`hooks.BeforeAgent`).
**Promote?:** no — consistent application of an existing, already-documented
limitation, not a new design fork.

## 2026-08-05 — Copilot CLI blocks only at STOP, via agentStop (item #3, Task 6)
**Chose:** `sessionStart` pushes WARN/STOP as `additionalContext` (best
effort — the model may discount tooling-status context); `agentStop` blocks
the turn (`{decision:"block",reason}`) but **only** when status is STOP,
guarded by `stop_hook_active` so a repeated block never fights the CLI's
8-block continuation limit.
**Because:** `additionalContext` is the only channel available mid-session
and it's a weak lever (model-discounted); `block` is the strong lever but
also the CLI's finite one (8 blocks then it gives up) — spending it at every
WARN would exhaust the budget before STOP ever needed it. STOP is exactly
the threshold where losing the lever must not happen.
**Rejected:** blocking at WARN too (burns the 8-block budget on the weaker
threshold, risking no lever left at STOP); blocking unconditionally without
the `stop_hook_active` guard (a still-STOP session would re-block itself on
every continuation attempt, tripping the CLI's own guard rail).
**Blast radius:** `scripts/hooks/context-budget-copilot-hook.sh`,
`.github/hooks/context-budget.json` (`sessionStart`, `agentStop`),
`~/.copilot/config.json` `trustedFolders` (must list this workspace, or the
hooks silently no-op).
**Promote?:** no — same escalation-only shape as the other four hooks, tuned
to one runtime's specific continuation-limit constraint.

## 2026-08-05 — opencode plugin must be explicitly registered (item #3, Task 5)
**Chose:** register `.opencode/plugins/context-budget.js` in
`.opencode/opencode.json`'s `"plugin"` array, alongside `graphify.js`, rather
than relying on directory-convention auto-discovery.
**Because:** empirical testing in this repo showed `.opencode/plugins/*.js`
is **not** auto-discovered — `graphify.js` only loads because it's
explicitly listed in `opencode.json`; a new plugin dropped into the directory
without the same registration silently never runs (fails open in the worst
way: no error, just nothing happens).
**Rejected:** trusting directory-convention auto-discovery (refuted by the
graphify precedent already in this repo — if it worked, graphify wouldn't
need explicit registration either).
**Blast radius:** `.opencode/opencode.json` (`plugin` array),
`.opencode/plugins/context-budget.js` (new).
**Promote?:** no — a documented opencode quirk (recorded in
`docs/context-budget.md`), not a design decision with real alternatives.

## 2026-08-06 — Successor option inheritance: persist-and-replay (item #3, Task 7)
**Chose:** the dying session writes `work/<project>/.rollover-options`
(normalized `ROLLOVER_OPT_APPROVAL=default|auto|full`, optional
`ROLLOVER_OPT_MODEL`, optional raw-extra `ROLLOVER_OPT_EXTRA` escape hatch —
`session-rollover` step 6, written only from what the dying session actually
knows about its own launch); `launch-next-session.sh` maps the normalized
approval level to each runtime's own flag and replays it plus model/extra on
the successor launch. Vendor flags stay in the script; the skill and the
options file itself stay runtime-neutral.
**Because:** the rolling session already knows how it was launched (approval
mode, model) — that's free, reliable information the successor would
otherwise lose and have to be relaunched by hand to restore. Persist-and-
replay needs no new detection machinery per runtime; it just carries forward
what's already known.
**Rejected:** auto-detecting the predecessor's options from session
artifacts — unverified per runtime (each vendor's session format is an
undocumented internal, per `docs/context-budget.md` → "Per-runtime
adapters"), and strictly worse than the dying session simply stating what it
already knows.
**Flag-verification findings (re-verified live against `--help`,
2026-08-06):** the plan's table had guessed codex `--full-auto` for the
`auto` approval level — that flag **does not exist** in codex-cli 0.142.4;
shipped `--ask-for-approval never` instead. opencode's `--auto` flag does
exist (same flag serves both `auto` and `full` levels), so opencode stayed in
the approval mapping — the plan's contingency to drop opencode from the
mapping if `--auto` turned out missing was not needed.
**Blast radius:** `scripts/launch-next-session.sh` (`OPT_ARGS` mapping),
`skills/session-rollover/SKILL.md` (step 6), `docs/context-budget.md` →
"Relaunch knobs".
**Promote?:** no — implementation detail of the already-promoted ADR-0003
relaunch pipeline; the rejected-alternative weight (artifact auto-detection)
is captured here, not new ADR-worthy ground.

## 2026-08-06 — Dedicated attach-session.sh helper (Task 9, user-added)
**Chose:** a new `scripts/attach-session.sh <project>` verb: resolve the
latest session for a work item (`.active-session` lock, falling back to the
newest registry record for the project), and when it is alive and holds the
lock, connect this terminal to it (`claude --resume <session_id>` on a real
TTY; `run: <cmd>` in `--dry-run`/non-TTY, same idiom as
`launch-next-session.sh`).
**Because:** shipped at explicit user request — overrides the earlier YAGNI
call to leave re-attach as a documented-only manual procedure. `docs/context-
budget.md`'s "Chained rollovers & re-attach" passage also named a `claude
attach` subcommand that does not exist (re-verified live against `claude
--help`/`claude agents --json` 2026-08-06: no `attach` subcommand; `-r/
--resume <session_id>` is the closest supported form) — the manual procedure
it described was itself unverified, another reason to make the front door a
tested script instead of prose.
**Rejected:** (1) manual lock inspection only (the prior documented-only
path) — leaves the unverified-flag risk in prose nobody re-checks; (2)
folding attach into `launch-next-session.sh` — launch and attach are
different verbs: the launcher must stay safe to call from a dying session's
non-TTY shell (it never `exec`s there, per its own manual-mode branch),
while attach is inherently interactive (its whole job is handing the
terminal to a live session) — conflating them would either weaken the
launcher's non-TTY safety or leave attach half-built inside it.
**Blast radius:** `scripts/attach-session.sh` (new),
`scripts/tests/test-attach-session.sh` (new), `docs/context-budget.md` →
"Chained rollovers & re-attach", `docs/template-workspace-backlog.html`
(change-log row).
**Promote?:** no — same shape as the other ADR-0003 companion scripts
(implementation detail of the already-promoted relaunch/re-attach pipeline).

## 2026-08-06 — Research doc review rendition: standalone in-repo HTML (session 12)

**Decision:** render `subagent-rollover-research.md` for human+agent review as a
standalone, self-contained HTML file in the work dir
(`subagent-rollover-research.html`, commit `d93daea`), restructured
problem → model (with 5 hand-authored inline-SVG diagrams) → existing
machinery → findings → proposal → evaluation. The markdown note stays the raw
research record; the HTML is the review front door.
**Why:** user asked for an HTML doc whose information flow suits review;
inline SVG + token-based light/dark CSS keeps it dependency-free and
renderable anywhere (matches the in-repo precedent of
`docs/template-workspace-backlog.html`).
**Rejected:** (1) publishing only as a claude.ai Artifact — not in-repo, not
runtime-agnostic, invisible to downloaders; (2) mermaid diagrams — need
external JS, which a self-contained in-repo file can't load offline.
**Blast radius:** one new file in this work dir.
**Promote?:** no.

## 2026-08-06 — Scenario catalog: separate authoritative md, mirrored in HTML §7 (session 13)

**Decision:** the rollover scenario catalog (S11–S52, nine dimension groups)
lives in a new `rollover-scenarios.md` — authoritative, greppable, and the
file where harness results will accrue — mirrored as §7 of
`subagent-rollover-research.html` for the review reading flow. Research md
§13.3 keeps S1–S10 as the seed with a pointer.
**Why:** the catalog is a living deliverable (test results, additions) while
the research note is a finished record; a separate file avoids churning the
note and gives the future harness a single source. HTML mirror follows the
md-raw/HTML-rendition pattern already established for the doc itself.
**Rejected:** (1) extending research md §13.3 in place — bloats a finished
note and renumbers nothing cleanly; (2) HTML-only — not greppable, awkward to
derive tests from, breaks the "md is raw record" convention.
**Blast radius:** one new file; one new HTML section (+ §7→8, §8→9 renumber).
**Promote?:** no.

## 2026-08-06 — Parent kinds modeled as node position, not a type enum (session 13)

**Decision:** the root (main work-item session) vs intermediate (subagent that
parents) distinction is modeled as **node position** — the parent *role* is
position-invariant; only the node's own lifecycle differs (delta table in
research §3 / HTML §2.2). No `parent_type` field in records: position is
derivable from R4's `depth`/`parent_session_id`.
**Why:** the uniformity of parenting duties at every depth is what makes I4
recursive and the model composable; a type enum would suggest two behavioral
variants of parenting and duplicate information the dispatch record carries.
**Rejected:** a first-class parent-type field/enum (user's initial suggestion,
refined in discussion).
**Blast radius:** doc-only (HTML §2.2, research §3, scenarios S53/S54).
**Promote?:** no — travels with the research note; revisit if implementation
ever needs position-specific record fields.

## 2026-08-06 — Work-item lock release moved into launch-next-session.sh, pre-launch (session 14)

**Decision:** `scripts/launch-next-session.sh` releases the dying session's
own `.active-session` lock immediately before launching the successor
(identity-matched against the session's own registry record; a foreign
holder's lock is never removed; `--dry-run` never mutates; `mode=off` still
releases). The skill's post-verification `release` step becomes a fallback
for rollovers that never invoke the script.
**Why:** fired live on this work item's first `ROLLOVER_RELAUNCH=auto`
relaunch (backlog M14): the skill's ordering — launch at step 7, release
after post-launch verification — makes the successor's `register` race an
unreleased lock by construction in auto mode, and can never release at all
in attached-manual mode (`exec` replaces the predecessor). The script is the
only place that runs strictly before every launch path.
**Rejected:** (1) reordering the skill's steps only — cannot fix the
attached-manual `exec` path and relies on prose ordering rather than
mechanism; (2) successor-side retry/poll on `register` — treats the symptom,
adds a wait loop, and leaves the manual-mode lock leak; (3) stealing the
lock successor-side when the holder is the launching predecessor — requires
the successor to know the predecessor's identity, which only the launch
script has.
**Blast radius:** `scripts/launch-next-session.sh`,
`skills/session-rollover/SKILL.md` (closing step),
`docs/context-budget.md` (work-item ownership passage), tests T16–T19.
**Promote?:** no — mechanism detail within ADR-0003/0004's scope.

## 2026-08-06 — ROLLOVER_OPT_APPROVAL `auto` re-pointed to classifier tier; old level renamed `edits` (session 15)

**Decision:** the normalized approval ladder becomes `default < edits < auto
< full`. `auto` now means "the most autonomous mode this runtime offers with
a safety net" — claude `--permission-mode auto` (classifier-vetted; verified
against live `--help`, claude 2.1.223); runtimes without a classifier
equivalent fall back to their `edits` mapping with a stderr note. `edits`
carries the old `auto` mappings (acceptEdits tier). This work item's
`.rollover-options` switches `full` → `auto`.
**Why:** the script's old `auto` (acceptEdits) collided with the UI's
classifier-driven "auto mode"; no level inherited the classifier — arguably
the best default for autonomous chains (high autonomy + tripwire on
dangerous actions, observed live). `auto`-as-capability-tier is
agent-agnostic: non-claude mappings are unchanged, so the semantic change
touches claude only, and no existing file used `auto` (lineage file said
`full`).
**Rejected:** (1) adding a `classifier` level alongside `auto` — bakes a
claude-specific mechanism name into the vendor-neutral vocabulary and keeps
the ambiguous `auto`; (2) retiring `auto` as a loud unknown — the warning
goes to stderr mid-chain where nobody reads it, and the launch degrades to
manual mode, recreating the incident this issue documented; (3) refusing
(die) on non-classifier runtimes — breaks cross-runtime chains; (4) falling
back up to full bypass — silently drops the tripwire.
**Blast radius:** `scripts/launch-next-session.sh` (OPT_ARGS + header),
tests T14a–T14p, `docs/context-budget.md` "Option inheritance",
`skills/session-rollover/SKILL.md` step 6, this item's `.rollover-options`
(machine-local).
**Promote?:** no — mapping detail within ADR-0003's flag-verification rule.

## 2026-08-06 — Session roles: primary / auxiliary / superseded, lock as the primary marker (session 15)

**Decision:** each session engaging a work item holds one of three roles —
primary (lock holder; sole launcher/ledger writer and rollover authority),
auxiliary (concurrent helper alongside a live primary; associated, never
contends), superseded (former primary after rollover; terminal). The lock
file IS the primary marker; registry `role` fields are cached claims that
lose to the lock on conflict. Rollover succession is emergent (release →
launch → successor register acquires), so the newest lineage session is
always primary with no extra mechanism. Display: in-band `role=` on
register/attach + a Claude Code statusline; SessionEnd hook releases the
lock on plain exit.
**Why:** the M14 discussion exposed that a plainly-exited session squats its
lock for the stale window, and that "non-primary" conflates two states — a
live helper and a dead predecessor — which need opposite treatment.
**Rejected:** (1) primary/secondary/retired — "secondary" reads as a backup
primary; (2) storing the role only in records without lock authority — two
sources of truth that can diverge; (3) terminal-tab-title + `sessions`
listing displays — deprioritized by the user; (4) `superseded_by` back-link
at stamp time — the launcher cannot know the successor's id (runtime
generates it); deferred to a successor-side back-stamp.
**Blast radius:** `context-budget.sh` (register/acquire_lock),
`launch-next-session.sh` (superseded stamp), `attach-session.sh` (role=),
`statusline-context-budget.sh` (new), `.claude/settings.json.example`
(SessionEnd + statusLine), docs (context-budget.md "Session roles",
work-directory-conventions.md), tests T6/T7/T20 + statusline suite.
**Promote?:** promoted 2026-08-06 → ADR-0005 (with the session-16/17 child
registry + lineage notes; criterion met — slice 1 landed, role schema
final).

## 2026-08-06 — Slice-1 child registry: artifact-keyed identity, role `child`, blocked-release I4 guard (session 16)

**What:** `register --parent-session <sid> [--agent-id]` derives the child's
session id from the artifact, never the env; role set extends to `child`;
per-child locks in `work/<p>/.agent-locks/<runtime>-<sid>.json` granted only
when the parent chain terminates at the project-lock holder; `release`
sweeps stale child locks then refuses bottom-up violations (die, exit 3).
**Why:** the registering process is the parent, so env identity would claim
the child record for the parent (caught designing T7); a child holds a lock
and writes reports while an auxiliary must not — materially different
authority.
**Rejected:** overloading `auxiliary` for children (loses the write-authority
distinction issues/03 defined); keying child locks by agent_id alone
(non-claude children may have none; runtime-sid matches every other
identity in the system); liveness checks inside `parent_chain_holds_lock`
(stale sweep at release keeps one liveness rule, I7).
**Blast radius:** `context-budget.sh`, registry tests T7–T12, `.gitignore`
(`work/*/.agent-locks/`). See `plans/slice-1-registry-schema.md`.
**Promote?:** promoted 2026-08-06 → ADR-0005 (with the session-15/17 notes).

## 2026-08-06 — Rollover lineage completed successor-side; takeover is a recorded steal (session 17)

**What:** (1) `superseded_by` is back-stamped by the *successor* at primary
acquisition — newest same-project `role=superseded` record without one gets
`superseded_by=<runtime>-<sid>`. (2) `register --takeover` steals the
project lock even from a live holder, stamping the old holder's record
`superseded` + `superseded_at` + `superseded_by` and announcing loudly.
**Why:** the launcher cannot stamp the successor id — the runtime generates
it after the stamp (issues/03 deferral rationale); scenario S33 puts human
authority above liveness heuristics, but a steal that isn't recorded is
indistinguishable from the M14 clobber class, so the takeover must leave an
auditable trail on the loser's record.
**Rejected:** launcher-side successor stamping (id unknowable at stamp
time); takeover blocked by a live holder (defeats its S33 purpose — the
non-takeover path already refuses); stamping every unclaimed superseded
record instead of the newest (older lineage tails belong to earlier
successors; one register = one predecessor claimed).
**Blast radius:** `context-budget.sh` (backstamp_superseded, acquire_lock,
`--takeover` flag), registry tests T13–T14, `docs/context-budget.md`,
issues/03 closed. Tests: registry 54 asserts green.
**Promote?:** promoted 2026-08-06 with the session-15/16 role notes →
ADR-0005 (role model + parent/child registry, schema final).

## 2026-08-06 — Child sweep is a `children` subcommand, sidechain-inclusive (session 18)

**What:** slice 2 (R1) landed as a new `children` subcommand:
`context-budget.sh children [--parent-session <sid>] [--all]` enumerates
`<parent-uuid>/subagents/agent-*.jsonl`, measures each with a
sidechain-*inclusive* variant of the Claude measure, prints escalation-only
(WARN/STOP) check-style lines with `age=` (artifact mtime) and `type=`
(`.meta.json` agentType), and exits with the worst child status.
**Why:** a subagent transcript's rows are all `isSidechain:true` — the
self-measure filter (correct for a parent excluding its children's windows)
would silently degrade every child to a bytes÷4 estimate; verified against a
real fleet, where the sweep surfaced the 141.8K child that motivated R1.
Escalation-only keeps a busy parent from being spammed by N OK children.
**Rejected:** a `--children` flag on `check` (check's contract is one
artifact → one line → exit = own status; the sweep is N artifacts +
filtering — a different contract); non-claude adapters (no other runtime
has a verified per-child artifact layout — loud die instead of silent
wrong answers); throttling and ledger writes (belong to the hook-wiring
slice, not the CLI helper); live-only filtering (age is reported, callers
filter).
**Blast radius:** `context-budget.sh` (`cmd_children`,
`claude_child_measure`, `--all`), new suite
`scripts/tests/test-children-sweep.sh` (27 asserts), `docs/context-budget.md`
(Per-child sweep section + quickstart line). All six suites green.
**Promote?:** no — implementation detail within ADR-0005's model; revisit
if the hook-wiring slice changes the escalation contract.

## 2026-08-06 — Coordination state keyed to repository identity, not checkout path (session 19)

**What:** issue 05 landed: `WORKSPACE_ROOT` in all five coordination
scripts (`context-budget.sh`, `launch-next-session.sh`, `attach-session.sh`,
`statusline-context-budget.sh`, `context-budget-hook-lib.sh`) now resolves
via `git rev-parse --git-common-dir` → parent of the common `.git`, so every
worktree of one repository converges on one `.context-budget/`, one lock per
work item, one ledger, one `.session-seq`. Fallback to the old
script-relative (statusline: input-dir) resolution when not in a git repo or
when the git root is not this workspace (marker: the script's own path under
`scripts/`). Paths normalized with `pwd -P` (macOS `/var` symlink). Plus:
`launch-next-session.sh` invoked from a worktree now syncs the main
checkout first (worktree committed+pushed, main clean under `work/<proj>/`,
`pull --ff-only`; loud die on each) and launches from the main root —
retiring the "no auto-relaunch from worktrees" ban and the
register-before-isolate discipline.
**Why:** every worktree/rollover divergence of sessions 16–17 was workspace
identity silently equaling checkout identity; keying state to the repository
(stable across checkouts) removes the class instead of patching symptoms.
**Rejected:** per-checkout state with sync (recreates the divergence as a
merge problem); state under `~` keyed by repo-id (less discoverable, breaks
the disk-state-in-workspace convention — and it IS how vendors do it, with
Claude Code's cwd-derived transcript slug as the cautionary tale); a shared
sourced lib for the resolver (test suites and vendor-hook deployment copy
scripts as self-contained units — ~12 duplicated lines is the cheaper cost).
**Blast radius:** the five scripts; new tests G1/G2 (registry), W1–W5
(launcher), T8 (statusline); docs/context-budget.md Worktrees subsection;
operational-knowledge worktree entry superseded. All six suites green
(registry 60, attach 22, launcher 81, statusline 16, vendor 37, children 27).
**Promote?:** done → ADR-0006 (promoted 2026-08-06, session 21).

## 2026-08-06 — Slice 3: R2 dispatch contract as an emitter subcommand, R3 as documented policy (session 21)

**Chose:** a stateless `context-budget.sh dispatch-contract --report <path>
[--brief <path>] [--gen <n>]` subcommand emitting the R2 contract block
(checkpoint-at-boundaries, 15-line return cap, five-status vocabulary with
ROLLOVER_NEEDED-only-on-request, gen>=2 read-report-first clause) for parents
to inject into child dispatch prompts; R3 (successor dispatch is the only
rollover verb, resume = continuation that stacks history) stays parent-side
policy in docs/context-budget.md + a CLAUDE.md dispatch-time pointer.
**Because:** the contract text is load-bearing (research §8: the disk
protocol must survive any lost in-band leg) — hand-copied prose drifts per
dispatch, an emitter is the single source of truth and gives the slice its
testable surface; R3 is a decision rule the *parent* applies, so it belongs
in guidance, not in the emitted child prompt.
**Rejected:** prose-only guidance (drifts, untestable, invisible at dispatch
time); a full skill file for orchestration (standing context tax, and R4/R6
mechanics that would justify it are deferred); emitting the R3 rule into the
child prompt (the child can't act on it — it can't measure itself, D1).
**Blast radius:** `scripts/context-budget.sh` (new subcommand + 3 flags),
new suite `scripts/tests/test-dispatch-contract.sh` K1–K7 (24 asserts),
docs/context-budget.md new section + quickstart line + children cross-ref,
CONTEXT.md Context Budget bullet. All seven suites green (267 asserts).
**Promote?:** no — implementation of research §14.3 within ADR-0005's model;
revisit when R4 (dispatch records/fencing) makes the protocol contractual.

## 2026-08-06 — R4: dispatch records as stateful subcommands layered on the stateless contract emitter (session 22)

**Chose:** three new `context-budget.sh` subcommands owning persistence —
`dispatch-open` (appends generation N+1 status=`open` to
`work/<proj>/.agent-dispatch/<task>.json` and emits the R2 contract for that
generation in one step; refuses while the previous generation is open;
`--gen` rejected, computed from the record), `dispatch-close --status
<five yield statuses|KILLED>` (closes the open generation, merges
`--agent-id` post-hoc), `dispatch-list` (per-task `task= gen= status=
report=` lines, exit 1 while any generation open — the parent's drain
check). Records are dot-prefixed gitignored runtime state anchored to the
workspace root (ADR-0006), same class as `.agent-locks/`. The contract
emitter gains one clause: progress blocks are labeled `[gen N]`.
**Because:** R4's fencing ("gen N+1 only after gen N's lock cleared") needs
a single enforcement point — the moment a generation comes into being — and
unifying record-write with contract-emit means the parent can't forget the
record and the gen on disk can't drift from the gen in the prompt. Records
are what make parent rollover fleet-safe: a successor parent can't resume
predecessor children (resume is keyed to the dead parent's session id) but
can reconstruct from records + reports and re-dispatch fresh.
**Rejected:** folding persistence into `dispatch-contract` (its
statelessness was a slice-3 decision — usable unregistered from any
runtime/checkout); a single `dispatch` verb with modes (flat hyphenated
commands match the existing CLI surface); research §5's literal
`work/<proj>/agents/` placement (undotted reads as durable content; the
dot-prefix + gitignore matches the established runtime-state convention);
storing records in `.context-budget/` (the registry stays a registry, not a
store of dispatch specs); tying fencing to `.agent-locks` liveness (ad-hoc
Task-tool children never register — record status is the portable signal,
with `KILLED` as the explicit parent ruling for children that never yield).
**Blast radius:** `scripts/context-budget.sh` (three subcommands + five
flags + one contract clause), new suite
`scripts/tests/test-dispatch-records.sh` L1–L9 (51 asserts), `.gitignore`
runtime-state block, docs/context-budget.md R2–R4 section rewrite +
quickstart bullet, CONTEXT.md dispatch bullet. All eight suites green (318
asserts).
**Promote?:** no — R4 completes research §5/§8 within ADR-0005/0006's model;
revisit at drain mode (R6) when the protocol becomes contractual across
parent rollover.

## 2026-08-06 — Registry hygiene: stale primaries stamped at register, not deleted (session 23)

**What:** primary acquisition in `context-budget.sh register` now sweeps
other same-project `role=primary` records whose artifact liveness is stale
(same `LOCK_STALE` rule as the lock), stamping them `role=superseded` +
`superseded_at` + `superseded_by=<new primary>` — the takeover stamp shape.
Live records and other projects' records are untouched; auxiliary/child
registrations never sweep. Retires the parked sessions-19/21 learning.
**Why:** sessions that die without release/rollover (or lose the lock to a
stale reclaim — `acquire_lock` noted the reclaim but never stamped the old
holder) left `role=primary` records lingering until the 7-day mtime GC;
cosmetic (lock is authoritative) but misleading to humans and
`attach-session.sh` readers.
**Rejected:** deleting the swept files (loses succession provenance and
diverges from how every other role transition is recorded — records still
GC at 7 days); a new `role=stale` value (role schema was finalized in
session 19: primary/auxiliary/child/superseded); sweeping at `release` time
(the dying session may never release — register-time is the one moment a
new primary is guaranteed to run).
**Blast radius:** one function + one call site in
`scripts/context-budget.sh`; registry suite T15 (8 asserts, 68 total);
one paragraph in docs/context-budget.md. All eight suites green (326
asserts).
**Promote?:** no — hygiene within ADR-0004/0005's role model.

## Session 24 (2026-08-06) — wayfinder tickets 06 + 07 resolved

- **Ticket 06 refutation method:** tested mid-flight hook injection with the
  *production* wiring + a natural WARN crossing (parent at 117.5K → 120K with
  a live child racing the shared 60s throttle), instead of a synthetic
  nested-claude testbed (rejected: the permission classifier blocks
  `claude -p --settings`/`--dangerously-skip-permissions` spawns; and the
  production path is the one the accelerator would use anyway). Evidence:
  `research/06-midflight-hook-injection.md`.
- **Ticket 07:** copilot adapter buildable; artifacts keyed by parent
  toolCallId (events.jsonl + session-store.db). Graduated to ticket 09
  rather than specifying inline (rejected: same-session design at >120K
  tokens violates WARN discipline).
