---
id: 10-credentials-docs
title: Ticket 03 — Credentials docs and the service-access preflight
status: done
kind: work
wave: 5
blocked_by: [07-gate-cli-test]
tier: cheap
check: bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh"
sessions: [9]
---

## Goal

Ticket: issues/03-credentials-docs-and-preflight.md
Spec: S15, S16

A person adding Jev finds the service entry, the key name, the per-OS keychain command, the verify command, and the cost and limits in the service-access doc, and a runbook step for adding the key; `scripts/check-service-access.sh` reports the key present or absent as an optional service, never its value, and stays "ok" when it is absent.

## Acceptance

- [x] `docs/service-access.md` has a Jev entry in the existing entry shape: credentials (`jev-api-key` in the OS keychain; `JEV_API_KEY` override for keychain-less hosts and tests, never a `.env`), per-OS read command, verify command (`scripts/jev.sh --check` or equivalent), used-by (`rlm`, `jev` skill), and the cited cost/limits ($42/Btok input, output free; 250k tok/s, 1,200 req/min, 429 beyond; no SLA)
- [x] `docs/runbooks/authentication.md` has a numbered optional step for adding the key per OS, with the verify command
- [x] `scripts/check-service-access.sh` has an optional Jev block: `✓ jev key present` / `– jev key absent (optional)`; absence never sets the status to degraded or exits 1; the value is never echoed; the generated `.service-access.local.json` gains a `jev` entry with the verify command
- [x] `scripts/tests/test-jev.sh` (or the existing check test) covers present and absent using the fake `security` on `PATH`

## Log
- s9 · started, tier cheap
- s9-b · scripts/jev.sh added --check flag (resolves key, prints presence on stdout with source, exits 0/3); scripts/tests/test-jev.sh added T6/T7 cases (--check present/absent); docs/service-access.md added Jev entry (credentials, per-OS commands, verify, used-by, cost/limits); docs/runbooks/authentication.md added step 3 (optional Jev setup); scripts/check-service-access.sh added optional Jev block (reports present/absent as optional, generates .service-access.local.json entry); all tests pass (test-jev.sh 45/45, test-check-dependencies.sh 7/7, test-doc-consistency.sh 17/17), check-service-access.sh runs with "Status: ok"
- s9 · check passed → done
