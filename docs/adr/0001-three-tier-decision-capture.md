# ADR-0001: Capture decision provenance in three tiers, promoting notes to ADRs

- Status: accepted
- Date: 2026-07-14
- Deciders: Kashif, Claude (design session)

## Context

Code is a snapshot of *what* exists with the decision history erased — `git blame`
gives *what/when/who* but never *why*. The reasoning behind a choice, the alternatives
rejected, and the constraints that forced it are unrecoverable after the fact unless
written down as the decision is made. That "why" is also scattered across systems a
coding agent can't see (PR threads, issues, chat) and, most often, was never written
down at all. This workspace needs a way to capture decision provenance that an agent
will actually follow session-to-session and that graphify can link back to the code —
without so much ceremony that it gets abandoned.

## Decision

Capture the *why* in three tiers by permanence, capturing cheap and promoting the keepers:

- **Tier 1 — commit trailer** (always): a one-line `Decision:` reason in the commit body.
- **Tier 2 — decision note** (for any choice with a rejected alternative): appended to
  `work/<username>_<project-name>/decisions.md`. Ephemeral, per-project — the wide net.
- **Tier 3 — ADR** (only for lasting-weight decisions): a committed record under `docs/adr/`,
  **promoted** from a Tier-2 note on demand or at `checkpoint`.

Driven by the `decision-log` skill; promotion is wired into the `checkpoint` skill. ADRs
and commit trailers are registered as graphify provenance inputs.

## Alternatives considered

- **An ADR for every decision** — rejected: dies of ceremony within a month; the important
  records drown in trivia. Promotion keeps ADRs scarce and meaningful.
- **Commit messages only** — rejected: too thin, no place for rejected alternatives, not
  promotable, and hard to discover later. Kept as Tier 1, not the whole scheme.
- **Commit every note (no ephemeral tier)** — rejected: buries the handful of decisions that
  matter under a swamp of half-formed in-flight thoughts. `work/` keeps signal high; only
  promoted reasoning becomes permanent.
- **An external decision-tracking tool/service** — rejected: adds a dependency and a system
  the agent can't see; this workspace favours self-contained files + graphify (cf. D1's
  self-containment-over-DRY stance).

## Consequences

- Adds a lightweight discipline every non-trivial change should follow (Tier 1 always).
- The `checkpoint` flow gains a promotion step — the point where ephemeral *why* becomes a
  durable record, done deliberately before context compacts.
- ADRs must be kept from rotting: supersede, never delete; run `graphify update .` after adding
  one so `graphify query "why…"` can walk `code → commit → ADR → alternatives-rejected`.
- The bar for "is this ADR-worthy?" is a judgement call each time — under-promoting loses
  provenance, over-promoting recreates the ceremony problem. `docs/adr/README.md` states the bar.

## Provenance

- Promoted from: design session 2026-07-14 (this conversation) — direct to ADR as the
  scheme's own founding decision; no prior Tier-2 note existed.
- Introduced in: the same commit that adds the `decision-log` skill, `docs/adr/`, and the
  `checkpoint` promotion hook.
- Refs: `docs/template-workspace-backlog.html` (2026-07-14 feature row), decision D2.
