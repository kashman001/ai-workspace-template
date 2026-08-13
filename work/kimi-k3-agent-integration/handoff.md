<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-10 (session 1: work item created; research done; runtime decision PENDING)

Work item scaffolded. User wants to drive this workspace with Kimi K3 via an
agent. Constraint: Moonshot subscriptions unavailable — API-key
(pay-per-token) access only. User asked for a recommendation among OpenCode,
Kimi CLI, and Claude Code; research was completed but the user paused the
session before deciding. **Open item: the runtime decision** (options + our
recommendation in `next-session.md`).

## Research findings (web, 2026-08-10)

- **Kimi K3** (Moonshot AI, launched 2026-07-16): 2.8T-param open-weight
  flagship, 1M context, reasoning on by default. Pay-per-token via
  platform.kimi.ai API keys: ~$3/$15 per M tokens, ~$0.30 cache hits. No
  subscription required for any integration route.
- **Two Moonshot API surfaces** (built so existing agents work unmodified):
  OpenAI-compatible `https://api.moonshot.ai/v1`, Anthropic-compatible
  `https://api.moonshot.ai/anthropic` (model id `kimi-k3`).
- **OpenCode route**: `opencode auth login` → Moonshot AI in provider list →
  paste API key. Official guide: https://platform.kimi.ai/docs/guide/open-code.
  OpenCode is already a first-class runtime in this template (context-budget
  plugin, hooks, launcher/relaunch) → near-zero new template wiring.
- **Claude Code route**: set `ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic`
  + Kimi API key; official guide:
  https://platform.kimi.ai/docs/guide/claude-code-kimi. Whole template
  (skills/hooks) runs against K3. Caveats as a durable setup: Anthropic
  server-side features (web search, artifacts) break silently; harness tuned
  for Claude; identity/billing mixing in one binary.
- **Kimi CLI caution**: Moonshot has TWO CLIs — older Python `kimi-cli`
  (winding down) and new TypeScript **Kimi Code** CLI (fast churn, dozens of
  releases in 2 months; has Agent Swarm ≤100 parallel subagents). Adopting it
  = new seventh runtime (context-budget measurement, hooks, launcher) against
  unstable ground — advised against for now.
- **Recommendation given**: OpenCode + Moonshot as the durable integration;
  optional 10-minute Claude Code env-var trial first to judge K3 quality.

Repo state: only this work dir added, nothing else touched. Immediate next
step: user decides the route (see launcher), then design.
