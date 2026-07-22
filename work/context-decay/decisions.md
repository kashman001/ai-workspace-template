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
