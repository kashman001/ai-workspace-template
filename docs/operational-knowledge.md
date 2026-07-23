<!--
File: docs/operational-knowledge.md
Purpose: Distilled rules that prevent silent failures (shell, tooling, gotchas).
Fill in: accumulate hard-won operational knowledge as you encounter it.
See: docs/workspace-structure.md → "docs/ — Workspace Documentation"
-->

# Operational Knowledge

Gotchas and rules that prevent silent failures. Each entry: the symptom, the
cause, and the rule that avoids it. Add to this as you hit new ones.

## Agent workflow — bound your background poll loops

- **Symptom:** `run_in_background` poll loops never exit and pile up as zombie
  shells, hammering an API every few seconds.
- **Cause:** a condition like `until [ "$(... build .commit)" = "$HEAD" ]` can
  never match after rapid successive pushes / force-rebuilds — the service
  advances its "latest" past the commit the loop was launched to wait for.
- **Rule:** wait on a **terminal status** (`built|errored`, `success|failure`)
  with a **hard iteration cap** (`for i in $(seq 1 40); … case $st in built|errored) break;; esac`),
  not on equality to a moving target. Every backgrounded waiter must be able to
  self-terminate.

## GitHub Pages — "Page build failed" is often transient

- **Symptom:** a Pages build shows `status: errored` / "Page build failed.",
  and the newly-added pages 404 while previously-built pages still serve.
- **Cause:** the "deploy from branch" build pipeline is intermittently flaky;
  identical content builds fine on retry (observed across several commits here).
- **Rule:** don't assume bad content. Verify the files locally first, then
  retrigger: `gh api -X POST repos/<owner>/<repo>/pages/builds`, and re-check
  with a bounded waiter (see above). `.nojekyll` is already in `docs/` so files
  serve as-is — a failure is the pipeline, not Jekyll.

## Gemini CLI on this machine — auth is the blocker, not the wiring

(2026-07-23) Findings from trying to run `gemini` headlessly for the
context-budget telemetry verification:

- **`oauth-personal` (Login with Google) is dead** on gemini-cli 0.46: login
  succeeds, then `IneligibleTierError: This client is no longer supported for
  Gemini Code Assist for individuals` (Google says migrate to Antigravity).
  Don't retry this path; a `GEMINI_API_KEY` (AI Studio) is the practical route.
- **Vertex via ADC 403s**: `GOOGLE_GENAI_USE_VERTEXAI=true` with the default
  gcloud project (`quran-hifdh-tracker-497421`) fails — Vertex API not
  enabled/permitted. Don't enable cloud APIs just for this.
- Headless runs in an untrusted dir need `GEMINI_CLI_TRUST_WORKSPACE=true`.
- First-ever run asks `Opening authentication page… [Y/n]` on stdin — a
  backgrounded/`!` command hangs there. Pre-feed it: `printf 'Y\n' | gemini -p …`.
