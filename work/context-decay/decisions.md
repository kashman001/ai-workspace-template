# Decisions — context-decay

## 2026-08-07 — Rollover option capture: approval mode only, never model
**Chose:** `capture-rollover-options.sh` mechanically captures only `ROLLOVER_OPT_APPROVAL` (from the claude transcript's last recorded `permissionMode`); `ROLLOVER_OPT_MODEL`/`ROLLOVER_OPT_EXTRA` stay hand-set and are preserved across re-captures.
**Because:** the transcript's model id can't be distinguished from "the runtime default at the time", so auto-pinning it would silently opt successors out of default-model upgrades; approval mode has no such ambiguity — the recorded `permissionMode` IS the session's live mode.
**Rejected:** capturing model from assistant `message.model` — ambiguity above; capturing nothing and keeping step 6 knowledge-only — sessions rarely know their own launch flags, which is exactly why inheritance silently failed (a background auto-mode session's successors launched in default mode).
**Blast radius:** `scripts/capture-rollover-options.sh` (new), `skills/session-rollover/SKILL.md` step 6, `docs/context-budget.md` option-inheritance + Quickstart.
**Promote?:** no

## 2026-08-07 — Phase snapshots are computed post-hoc, not captured live
**Chose:** the three-snapshot protocol (S1 session-start prediction / S2 post-first-message / S3 post-workload) is implemented as transcript analysis (`context-inspect.sh --phases`) plus a headless driver (`context-experiment.sh`), not as a snapshot-taking daemon or hook.
**Because:** every assistant turn already carries an exact context total in the transcript's usage envelope — snapshots need marking, not taking; and S1 *cannot* be exact (no API call exists before the first message), so it is honestly a disk-side prediction whose delta vs S2 is itself a finding.
**Rejected:** live snapshot hooks per phase — duplicates what the transcript records, adds standing hook cost to every session.
**Blast radius:** `scripts/context-inspect.sh` (`--phases`), `scripts/context-experiment.sh` (new), `docs/context-budget.md` Quickstart — agent.
**Promote?:** no

## 2026-07-22 — Threshold env file name/location
**Chose:** new checked-in root file `context-budget.env`, sourced by `context-budget.sh`.
**Because:** this workspace has no checked-in env file (`.env` is gitignored and reserved for secrets); thresholds are non-secret and must ship with the template, raised in one place.
**Rejected:** putting the vars in `.env.example` — values wouldn't be live without user copying; reusing the spec's `insight-environments.env` — origin-workspace name, meaningless here.
**Blast radius:** `context-budget.env`, `scripts/context-budget.sh`, `docs/context-budget.md`, `docs/workspace-structure.md`, `CONTEXT.md`.
**Promote?:** no

## 2026-07-22 — Hook wiring placement
**Chose:** live hook block in gitignored `.claude/settings.json`; the same block shipped in tracked `.claude/settings.json.example`.
**Because:** this template gitignores `.claude/settings.json`; the spec's rule for that case is example-file + local copy, and downloaders opt in by copying.
**Rejected:** tracking `.claude/settings.json` — would flip the template's existing gitignore decision, out of scope.
**Blast radius:** `.claude/settings.json`, `.claude/settings.json.example`, `docs/context-budget.md`.
**Promote?:** no

## 2026-07-22 — Ledger path stays `work/context-decay/`
**Chose:** keep the spec's ledger path `work/context-decay/context-ledger.jsonl`.
**Because:** the ledger is this project's research data (D9); the path is one variable (`LEDGER`) in `context-budget.sh`, documented as adaptable.
**Rejected:** a neutral `.context-budget/` location — gitignored state dir would hide research data; a generic `work/context-budget/` — invents a work dir for a non-project.
**Blast radius:** `scripts/context-budget.sh` (`LEDGER`), `docs/context-budget.md`.
**Promote?:** no

## 2026-07-22 — Checkpoint clauses in onboard-repo + rlm only
**Chose:** add the measured-checkpoint clause to `onboard-repo` (per step/repo) and `rlm` (per loop phase); skip `checkpoint`/`decision-log`/`session-rollover`.
**Because:** the spec targets long-running/orchestrator skills; the other three are short boundary rituals and rollover already records at both ends.
**Rejected:** adding it to every skill — ceremony without long-running risk.
**Blast radius:** `skills/onboard-repo/SKILL.md`, `skills/rlm/SKILL.md`.
**Promote?:** no

## 2026-07-22 — M9 fix: `register` bypasses the session registry
**Chose:** `resolve_session()` skips the registry lookup only when the command is `register`, forcing fresh discovery; `check`/`record`/`watch` still trust the registry.
**Because:** `register`'s purpose is to (re)bind the current session; trusting the previous binding made every post-first session measure the prior session's transcript (observed live: false WARN at 146,794 tokens in a fresh session).
**Rejected:** deleting the registry file during session-rollover — fixes only rollover-initiated sessions, not `/clear` or plain new sessions; mtime-comparing registry artifact vs newest discovery — heuristic, and `register` has no legitimate use for a stale binding anyway.
**Blast radius:** `scripts/context-budget.sh` (one guard in `resolve_session`), backlog entry M9.
**Promote?:** no

## 2026-07-22 — Gemini exact counts via workspace-local telemetry
**Chose:** telemetry block in the *tracked workspace* `.gemini/settings.json` (`target: local`, `logPrompts: false`, outfile `.gemini/telemetry.log`, gitignored); adapter parses the last response's input tokens, accepting both `input_token_count` (documented api_response event) and `gen_ai.usage.input_tokens` (OTel semconv — the 0.46 log observed live uses `gen_ai.*` names); when the telemetry log has no response yet, estimate from the chat log, never from the telemetry file's size.
**Because:** workspace-level settings ship with the template so every clone gets exact Gemini counts with zero per-user setup; local-file target sends nothing off-machine; a real (auth-failed) run proved the wiring activates and revealed the semconv attribute names.
**Rejected:** user-level `~/.gemini/settings.json` — per-machine setup the template can't ship; parsing the cumulative `gemini_cli.token.usage` metric — measures lifetime total, not live context; bytes÷4 of the telemetry log as fallback — its size reflects telemetry volume, not context (observed: 223KB from one failed call).
**Blast radius:** `.gemini/settings.json`, `.gitignore`, `scripts/context-budget.sh` (gemini discover/measure), `docs/context-budget.md`, `CONTEXT.md` + `docs/recommended-tooling.md` (graphify-deletion guidance now preserves the file), `docs/workspace-structure.md`.
**Promote?:** no

## 2026-08-07 — Decline turn-1 context trims (options 1+2)
**Chose:** no trims — leave skill_listing descriptions and project CLAUDE.md as-is; `trim-estimates.md` stands as the record.
**Because:** user's bar is "unused AND no negative implications"; measurement showed no repo-side candidate meets it — workspace share of skill_listing is only ~307 tok (trigger-accuracy risk to cut), and every sizable CLAUDE.md section is load-bearing for non-Claude runtimes, template downloaders, or always-on behavioral rules. Combined saving (~0.7–1.45K of 43.9K turn-1) doesn't justify the downsides.
**Rejected:** CLAUDE.md moderate (~600–800 tok) and aggressive (~1,000–1,300 tok) link-out passes; workspace skill-description tightening (~100–150 tok); user-global cleanup (option 3, superpowers/hooks/user skills — deferred by user, not evaluated for action).
**Blast radius:** none (no files changed); closes mission steps 1–2 of session #4's launcher.
**Promote?:** no

## 2026-08-11 — rollover-prep.sh is a sibling script, not a context-budget.sh subcommand

Rollover-cost R1 (one-shot mechanical prep) shipped as `scripts/rollover-prep.sh`
calling context-budget.sh/capture-rollover-options.sh, rejecting a
`context-budget.sh rollover-prep` subcommand: that file is measurement-only
and already large; prep is orchestration, not measurement. Also: rotation
leaves handoff.md at ONE block pre-write (rejected: rotate-after-write —
would need a second call and re-introduce the agent-side splitting hazard).
