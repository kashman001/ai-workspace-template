# Decisions — context-decay

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
