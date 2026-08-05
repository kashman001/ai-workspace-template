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

| Runtime | Detection (stage 1) | Interactive seeded launch | Detached background |
|---|---|---|---|
| **claude** | Exact (session JSONL) + in-band WARN/STOP hook push | `claude "<prompt>"` | `claude --bg "<prompt>"` — first-class; manage via `claude agents` / `attach` / `logs` / `stop`. **No `--name` flag exists** (earlier notes remembering `--bg --name` were wrong). |
| **codex** | Measured (`codex_discover`/`codex_measure` in context-budget.sh); no in-band push — agent discipline only | `codex "<prompt>"` | none — `codex exec` is headless but foreground |
| **gemini** | Exact via workspace telemetry log (`.gemini/settings.json`); no in-band push — agent discipline only | `gemini -i "<prompt>"` | none — `gemini -p` is headless but foreground |
| **opencode** | **Not measured** by context-budget.sh | `opencode run "<prompt>"` — CLI absent on this machine, untested | none known |

(context-budget.sh also measures copilot-vscode / copilot-cli; no seeded-launch
story evaluated for those.)

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

## Open questions (the discussion to have)

1. **Knob shape** — does `off / manual / auto` match the intended "optional
   based on workspace parameters"? Is `context-budget.env` the right home, or a
   new `workspace.env`?
2. **Auto-mode consent** — in `auto` on claude, the dying session launches its
   own successor. Is the normal Bash permission gate in the dying session
   enough, or should `auto` require per-rollover user confirmation?
3. **Detection reliability scope** — codex/gemini rely on agent discipline to
   run `record`; closing that (e.g. `gemini hooks`, codex equivalents) is
   arguably a separate work item. In scope here or queued separately?
4. **Scope of runtimes** — is opencode (uninstalled, untested) worth a
   best-effort branch, and do copilot-* need a launch story at all?
