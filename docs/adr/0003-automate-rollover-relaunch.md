# ADR-0003: Automate the rollover→relaunch handoff with a workspace script, not vendor prompt mechanisms

- Status: accepted
- Date: 2026-08-05
- Deciders: Kashif + Claude Code session (automatic-session-rollover project)

## Context

The workspace's context-budget discipline rolls work over to a fresh session
before quality degrades (~150K tokens): the dying session runs the
`session-rollover` skill, writes the launcher (`next-session.md`) and ledger
(`handoff.md`), and emits a bootstrap prompt. The last step — starting the new
session — was manual: the user copy-pastes (or retypes) the prompt. Two forces
made this a real decision:

1. **The prompt wording is load-bearing.** "Read
   `work/<project>/next-session.md` and continue from **First actions**." makes
   the new session execute; hand-typed looser phrasings make it
   summarize-and-wait. Relying on humans to reproduce exact wording at every
   rollover is a recurring failure point.
2. **The workspace is multi-runtime.** Claude Code, Codex, Gemini, and OpenCode
   all resume from the same on-disk launcher/ledger. Any automation must not
   couple the rollover convention to one vendor's session-transfer feature.

An upstream alternative existed: the `claude-handoff` skill (mattpocock/skills,
clone `8b36d4f`), which hands off by prompting a background Claude session
directly — conversation, not disk, as the carrier.

## Decision

We automate the relaunch with a workspace-owned script,
`scripts/launch-next-session.sh <project> [--runtime …] [--bg]`, which bakes
the canonical bootstrap prompt in **verbatim** and launches the chosen runtime
seeded with it. Disk stays the source of truth; the script only accelerates
the launch. Behavior is governed by workspace parameters supporting a
consent-gated mode (the agent asks, then launches the successor) and a fully
automatic mode (hitting WARN/STOP triggers rollover + relaunch unprompted).
Interactive seeded launch is the agent-agnostic core available on every
runtime; detached background launch (`claude --bg`) is a Claude-only tier.
Vendor launch specifics live only in the script; the `session-rollover` skill
carries a single runtime-neutral pointer to it.

## Alternatives considered

- **Adopt upstream `claude-handoff` wholesale** — rejected: its three content
  rules were already absorbed into `session-rollover`'s inlined hand-off
  contract, and its transfer mechanism is prompt-only.
- **Prompt-only background handoff (conversation as carrier)** — rejected:
  loses disk-as-source-of-truth (a crashed or confused successor has no
  authoritative state to re-read) and works only for Claude.
- **Emulate background launch on codex/gemini via `nohup` + auto-approve
  flags (`--yolo`)** — rejected: trades permission safety for cross-vendor
  symmetry; those runtimes get the interactive core instead.
- **Inline vendor launch commands in the `session-rollover` skill** —
  rejected: violates the workspace's CLI-first rule (ADR-0002 direction);
  vendor specifics belong in scripts, keeping skills runtime-neutral.

## Consequences

- Rollover continuity stops depending on humans reproducing load-bearing
  prompt wording; the script is the single place that wording lives.
- The capability gap between runtimes becomes explicit and honest: Claude gets
  detached auto-handoff, others get consent-gated interactive relaunch. The
  script must not paper over this with unsafe emulation.
- The script becomes flag-coupled to fast-moving vendor CLIs; every remembered
  flag must be re-verified against `--help` at change time (verification
  already caught a nonexistent `claude --bg --name`).
- Fully automatic mode makes the dying agent responsible for triggering its
  own succession — detection reliability on non-Claude runtimes (no in-band
  WARN/STOP push; agent discipline only) becomes a dependency to harden.

## Provenance

- Refined by: ADR-0004 (multi-session model, trigger policy, knobs, runtime scope)
- Promoted from: `work/automatic-session-rollover/decisions.md#2026-08-05--automate-the-rolloverrelaunch-pipeline-the-effort-itself`
- Commits: 69dd976
- Refs: `work/automatic-session-rollover/relaunch-analysis.md` (verified vendor
  matrix, demo, open questions); upstream comparison in
  `work/template-maintenance/handoff.md` (2026-08-05 blocks)
