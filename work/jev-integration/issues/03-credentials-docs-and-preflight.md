# 03 — Credentials docs and the service-access preflight

**What to build:** A person adding Jev finds the service entry, the key name, the per-OS keychain command, the verify command, and the cost and limits in the service-access doc, and a runbook step for adding the key; `scripts/check-service-access.sh` reports the key present or absent as an optional service, never its value, and stays "ok" when it is absent.

**Blocked by:** 01 — Gate, `jev.sh` CLI (Choice), and the offline test.

**Status:** resolved — plan 01-gated-integration node 10-credentials-docs (s9) done; marked at the wave 7 join (s15, 2026-09-27)

**Spec:** S15, S16

- [ ] `docs/service-access.md` has a Jev entry in the existing entry shape: credentials (`jev-api-key` in the OS keychain; `JEV_API_KEY` override for keychain-less hosts and tests, never a `.env`), per-OS read command, verify command (`scripts/jev.sh --check` or equivalent), used-by (`rlm`, `jev` skill), and the cited cost/limits ($42/Btok input, output free; 250k tok/s, 1,200 req/min, 429 beyond; no SLA)
- [ ] `docs/runbooks/authentication.md` has a numbered optional step for adding the key per OS, with the verify command
- [ ] `scripts/check-service-access.sh` has an optional Jev block: `✓ jev key present` / `– jev key absent (optional)`; absence never sets the status to degraded or exits 1; the value is never echoed; the generated `.service-access.local.json` gains a `jev` entry with the verify command
- [ ] `scripts/tests/test-jev.sh` (or the existing check test) covers present and absent using the fake `security` on `PATH`
