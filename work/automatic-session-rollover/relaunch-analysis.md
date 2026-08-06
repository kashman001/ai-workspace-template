# Rollover Relaunch — Analysis (as of 2026-08-05)

Grounding facts for the automatic-session-rollover discussion. Flags below were
**verified against the installed CLIs' `--help` on 2026-08-05** — re-verify
before shipping; CLIs move fast.

## The problem

The rollover pipeline has three stages:

1. **Detect** — `scripts/context-budget.sh` measures real token counts from the
   runtime's session artifacts; WARN ≥120K, STOP ≥150K (`context-budget.env`).
2. **Roll over** — the dying session runs `skills/session-rollover/SKILL.md`:
   learnings routed to disk, ledger block appended, launcher replaced.
3. **Relaunch** — a fresh session starts, seeded with the bootstrap prompt:
   *"Read `work/<project>/next-session.md` and continue from **First actions**."*

Stage 3 is manual today: the dying session prints the prompt in a fenced block;
the user copy-pastes it. Hand-typed looser phrasings underperform — the session
summarizes-and-waits instead of executing. The exact wording is load-bearing:
the full path disambiguates (multiple work dirs have launchers), and the
imperative "continue from" drives execution.

Stage 1 also has a cross-vendor reliability gap (see matrix): only Claude Code
pushes the WARN/STOP signal in-band via a hook; other runtimes rely on the
agent's discipline to run `record` at work-unit boundaries.

## The proposed script: `scripts/launch-next-session.sh`

`launch-next-session.sh <project> [--runtime claude|codex|gemini|opencode] [--bg]`
— bakes the canonical bootstrap prompt in **verbatim** and launches the chosen
runtime seeded with it. Two invocation models:

- **User-invoked accelerator** (agent-agnostic): after rollover, the user runs
  the script instead of copy-pasting. Just a shell script spawning an
  interactive CLI — works identically for every vendor.
- **Agent-invoked auto-handoff**: the *dying session itself* runs the script
  with `--bg` as session-rollover's closing step; the successor spawns detached
  and the user attaches when ready. Vendor capabilities diverge here.

### Mode refinement (user, 2026-08-05)

The user reframed the two models — **both are agent-driven; the real axis is
consent, plus how much of the chain is automated**:

1. **Consent-gated relaunch** — at rollover the agent *asks the user's
   permission*, then starts the new session itself and the work continues.
   (Supersedes the original "user types the script command" framing — the
   script is still the mechanism, but the agent drives it.)
2. **Fully automatic rollover** — on approaching (WARN) *or* passing (STOP)
   the limit, the agent performs the whole chain unprompted: run
   `session-rollover` **and** relaunch the successor. Note this automates
   stage 2 as well, not just stage 3 — the trigger fires the entire
   trigger→rollover→relaunch pipeline.

Knob mapping consequence: `manual` ≈ consent-gated (ask → launch), `auto` ≈
fully automatic (no ask). `off` remains today's paste-the-prompt behavior.

## Verified per-vendor matrix

> **Detection column superseded (2026-08-05):** `vendor-hooks-research.md`
> found codex, gemini, opencode, and copilot ALL ship hook/plugin mechanisms
> that can push WARN/STOP in-band — the "agent discipline only" entries below
> are stale. Opencode also gained a seeded-interactive launch
> (`opencode --prompt`) and a composable background story (serve/attach).

| Runtime | Detection (stage 1) | Interactive seeded launch | Detached background |
|---|---|---|---|
| **claude** | Exact (session JSONL) + in-band WARN/STOP hook push | `claude "<prompt>"` | `claude --bg "<prompt>"` — first-class; manage via `claude agents` / `attach` / `logs` / `stop`. **No `--name` flag exists** (earlier notes remembering `--bg --name` were wrong). |
| **codex** | Measured (`codex_discover`/`codex_measure` in context-budget.sh); no in-band push — agent discipline only | `codex "<prompt>"` | none — `codex exec` is headless but foreground |
| **gemini** | Exact via workspace telemetry log (`.gemini/settings.json`); no in-band push — agent discipline only | `gemini -i "<prompt>"` | none — `gemini -p` is headless but foreground |
| **opencode** | **Not measured** by context-budget.sh | `opencode run "<prompt>"` — CLI absent on this machine, untested | none known |

(context-budget.sh also measures copilot-vscode / copilot-cli; the CLI's
seeded launch is `copilot -i "<prompt>"`. **copilot-vscode (2026-08-06,
issue 01):** `code chat -r -m agent "<prompt>"` is a verified seeded launch —
opens a new agent session in the last-active VS Code window, but exits 0
before the session responds, so `launch-next-session.sh` always routes it
through the BG confirm loop and treats registration as the success signal.)

**Consequence:** interactive seeded relaunch is the universal, agent-agnostic
core; detached auto-handoff is a claude-only tier. For codex/gemini the closest
auto-handoff equivalent is the dying session printing the exact ready-to-run
script *command* (fixed shape) instead of a *prompt* (load-bearing wording).
Emulating background via `nohup codex exec … &` / `nohup gemini -p … &` would
additionally require auto-approval flags (`--yolo` etc.) — trades permission
safety for symmetry; leaning **rejected**.

## Demo (2026-08-05, this workspace)

`claude --bg "Read work/template-maintenance/next-session.md and reply with
only a two-sentence summary of the Mission section…"` — returned immediately
with session ID `01f0a657` + attach/logs/stop handles; detached session started
in the same cwd, read the launcher, produced a correct Mission summary in ~11s,
stayed attachable until stopped. `claude logs` emits raw TUI escape codes;
`claude attach` is the practical review path.

### Rollover conduct under the hybrid (discussed 2026-08-05, user-agreed direction)

**Settled: WARN asks, STOP goes automatic.** Mechanics worked out so far:

- **WARN flow:** signal arrives (in-band hook on claude; `record` exit 1
  elsewhere) → agent finishes the current work unit → asks "roll over now?".
  On yes, the **dying agent conducts the rollover itself** — mandatory, since
  the reflect step routes conversation-only state to disk and only the dying
  context has it. The existing `session-rollover` steps run unchanged; only
  the final step swaps the paste-me prompt for `launch-next-session.sh
  <project> --bg` (claude) or printing the ready-to-run command (others).
- **Declining at WARN arms write-ahead mode** for the ~30K grace window
  (WARN→STOP): the agent routes discussion state to disk *incrementally*
  (settled points → decisions/analysis; open threads → launcher) at each
  natural pause, so the eventual STOP rollover is cheap and nearly lossless.
- **STOP mid-discussion:** the atomic step of a discussion is the current
  exchange — answer the user's message first, then append a rolling-over
  notice and conduct the rollover. The live question goes into the launcher's
  START HERE verbatim; the successor's first action is to re-pose it, so the
  discussion continues across the boundary. Accepted cost: unwritten
  conversational nuance dies with the old session — still better than
  conducting the discussion from inside the dumb zone.
- **Detection gap this exposes:** pure discussions have no work-unit
  boundaries, so non-claude runtimes may never run `record` and never see
  STOP. Needs a cadence rule ("record every N exchanges in extended
  discussions") or vendor hooks — feeds open question 3.

### Codification walkthrough (discussed 2026-08-05)

Goal: evaluate every decision point locally (script/hook), reserving the LLM
for what only it can do. Verdicts:

- **D1 detect** — LOCAL (exists: `context-budget.sh` exit codes). Gap is
  *when it runs* → watcher/vendor hooks.
- **D2 safe-to-interrupt** — MOSTLY LOCAL: turn-boundary placement (Stop-style
  hook = "answer first" enforced structurally) + mechanical git gates
  (merge/rebase markers). Small mid-refactor residue accepted.
- **D3 ask-or-go** — LOCAL: pure policy table (`status × ROLLOVER_RELAUNCH`).
- **D4 handoff content** — **LLM, irreducible.** Only the dying context holds
  the conversation-only state. Script verifies, never generates.
- **D5 rollover valid?** — LOCAL: the skill's Verification greps as a hard
  gate; refuse to relaunch until they pass.
- **D6 which project/runtime** — LOCAL after redesign (below).
- **D7 launch** — LOCAL: `launch-next-session.sh`.
- **D8 successor confirmed** — LOCAL: successor's own register is the
  heartbeat.

Conductor state machine: MEASURE → SAFE? → POLICY → [LLM writes] → VERIFY →
RESOLVE → LAUNCH → CONFIRM. The LLM's role collapses to D4 + relaying the
WARN-time ask.

### Multi-session identity redesign (user challenge, 2026-08-05)

User caught that "global active project" D6 breaks with concurrent sessions,
and that the current design assumes one session per runtime per workspace.
Confirmed in `scripts/context-budget.sh`:

- Discovery is already **session-exact** via runtime env vars
  (`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`) —
  added precisely because newest-mtime races concurrent sessions.
- But the registry is **scalar per runtime** (`.context-budget/
  session-$RUNTIME.json`), and `check`/`record` prefer the registry over
  re-discovery → under concurrency, session A can measure session B's
  artifact. A live wrong-measurement bug, not just a D6 flaw.
- Gemini's exact path (workspace telemetry log, truncated at register) is
  architecturally single-session-per-workspace.

**APPROVED by user 2026-08-05 (session 3)** — implementation item #1. The
governing operating model (user-stated, same session): **one developer works
multiple projects/work items concurrently, each with its own running main
session** in the same workspace, possibly across different runtimes. Every
design element must hold under N concurrent sessions: measurement is
per-session (session-keyed registry), work-item ownership is per-project
(advisory lock = "each work item has one main session"), and relaunch targets
the dying session's own project (D6 = read my own record). Decision note in
`decisions.md`.

Redesign direction (as approved):

1. **Session-keyed state:** `.context-budget/sessions/<runtime>-<session-id>
   .json` with `{runtime, artifact, project, registered_at}`; register writes
   its own file; resolve-self via env-var identity first. D6 becomes "read my
   own record".
2. **One *active* session per project, enforced by advisory lock**
   (`work/<proj>/.active-session`: runtime + session-id + timestamp) rather
   than making the launcher/ledger backbone multi-writer (REPLACE semantics
   are single-writer by construction; concurrent rollovers on one work item
   would silently destroy each other). Dying session releases after the D5
   gate; successor's register acquires; stale locks (artifact untouched N
   hours) reclaimable.
3. **Gemini exception documented:** exact counts remain single-session-per-
   workspace; per-session fallback is estimate-only.
4. **D8 restated:** new session file with same project + different session-id.

**Live evidence (same day):** the design session itself hit the bug. The
`claude --bg` demo session clobbered `.context-budget/session-claude.json`;
the design session's later `record` then measured the dead demo transcript
(47,750 tokens, OK) while the hook correctly showed the real session at
~128K WARN (the hook resolves per-session; the registry doesn't). Corrected
ledger entry recorded with an explicit `--transcript`. Scalar registry
clobbering is not theoretical.

## Proposed optionality knobs

Natural home: `context-budget.env` (already the checked-in, non-secret knobs
file both the script and docs point at):

```sh
# Relaunch behavior at session-rollover's closing step:
#   off    — emit the paste-ready bootstrap prompt only (today's behavior)
#   manual — also print the ready-to-run launch-next-session.sh command
#   auto   — background-launch the successor where the runtime supports it
#            (claude); fall back to manual elsewhere
ROLLOVER_RELAUNCH=manual
ROLLOVER_RUNTIME=claude   # default --runtime when not passed
```

`session-rollover`'s closing step gains one runtime-neutral line ("honor
`ROLLOVER_RELAUNCH` via `scripts/launch-next-session.sh`"); vendor specifics
stay confined to the script (CLI-first rule).

## Constraints already decided (upstream provenance)

From the template-maintenance claude-handoff comparison (clone `8b36d4f`):
adopting upstream `claude-handoff` wholesale — **rejected** (its three content
rules already landed via the inlined hand-off contract); its prompt-only
background-handoff mechanism — **rejected** (loses disk-as-source-of-truth;
Claude-only); the one adopted concept is **launch acceleration**. Inlining
vendor commands in the skill — **rejected** (CLI-first).

## Open questions — state as of 2026-08-05 session 3

1. **Multi-session identity redesign** — **CLOSED: approved as proposed**
   (see section above; decision note in `decisions.md`).
2. **Knob shape/home** — **CLOSED (user accepted, session 3):**
   `context-budget.env`, `off/manual/auto` with `manual` default,
   workspace-level (no per-project override — the operating model varies
   *sessions*, not relaunch policy). Consent lives in the trigger policy
   (WARN asks, STOP goes); no extra per-launch gate in `auto`.
3. **Detection reliability** — **smoke tests DONE (session 3):
   `smoke-test-opencode.md` + `smoke-test-copilot.md` — both PUSH-CONFIRMED
   LIVE** (opencode `chat.message` part-append with the mandatory
   `id`/`sessionID`/`messageID` shape; copilot `sessionStart`
   `additionalContext` + `agentStop` block-`reason`). The earlier
   separate-ticket rationale (needs install + smoke test) has evaporated:
   working hook/plugin code exists for both. **Revised bucketing — CLOSED
   (user confirmed, session 3):** ALL FOUR hook deployments (codex, gemini,
   opencode, copilot CLI) in scope here; the only ticket left is live
   verification of **VS Code agent-mode** hooks (shipped v1.109, Preview;
   needs a Copilot-licensed VS Code — this machine has none) and the
   `copilot_vscode_measure` branch (plausible, unverified). Frictions to
   honor in implementation: copilot folder-trust gate (repo hooks silently
   no-op untrusted), additionalContext may be discounted → use `agentStop`
   reason at STOP; codex hash-based hook trust; gemini JSON-only stdout.
4. **Runtime scope** — **smoke tests DONE; revised — CLOSED (user
   confirmed, session 3):** copilot JOINS the launcher — research's headless-only claim
   REFUTED: `copilot -i "<prompt>"` is a seeded interactive launch
   (+ `--session-id`, `--resume=<name>`). Opencode branch CONFIRMED
   (`--prompt` in shipped help; free `opencode/*` provider means zero-auth).
   All five runtimes get seeded-interactive; detached background remains
   claude-only (`--bg`); opencode `serve`/`run --attach`/`attach` is a
   composable near-equivalent, noted as a possible future tier, not v1.
   Bonus: opencode session/token measurement is one sqlite query
   (`~/.local/share/opencode/opencode.db`, per-turn `tokens.total`) —
   upgrades opencode from "not measured" to easiest-to-measure; copilot-cli
   measurement verified exact against the live UI (73.0k match).

**Agreed sequence (user, session 3):** smoke tests (done) → documentation
first → then implementation.
