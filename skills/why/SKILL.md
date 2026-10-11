---
name: why
description: Trace the decision history behind code into a cited, confidence-graded answer. Use for "why does X work this way", "why we picked Y", design rationale, regressions, postmortems, or where a data-backed threshold came from. Use `research` for questions about outside sources, and `decision-log` to record a new decision.
---

<!--
Adapted from github.com/cursor/plugins — pstack/skills/why/ at commit
978ca6e (2026-10-10), MIT © 2026 Lauren Tan (license text in
skills/vendored-skills.md). Rewritten here so it runs on any agent runtime
(no named models, subagent tool, or Cursor paths); not covered by
scripts/sync-vendored-skills.sh. references/epistemics.md is upstream's
file, verbatim.
-->

# Why

Find the forces that gave code its shape: the decisions, tradeoffs, incidents, and constraints behind it. Code shows what it does, not why it exists; the why lives in commits, PRs, tickets, docs, and conversations, all incomplete.

Act as a careful investigator: separate what the record says from what you infer. Read [`references/epistemics.md`](references/epistemics.md) before synthesizing; its confidence tiers and phrasing rules govern the answer.

## 1. Pin the target and the question

The **target** is a chunk of code, a pattern, a feature, a constant, or a named design decision. The **question** is a rationale, a tradeoff, a motivating edge case, an external constraint, suspected dead code, or a broad history sweep.

If the referent is vague ("why do we do it this way?"), take your best reading from the conversation (open files, recent edits, what was just discussed), state it in one line so the user can redirect, and proceed.

## 2. Build the code anchor

Collect the seed context every later step uses: file paths and line ranges, key symbols, the commits that touched the target, PR numbers, linked ticket IDs.

```bash
git blame -L <start>,<end> <file>          # last-touch commits
git log --follow -p -- <file>               # full history with patches, through renames
git log --oneline -20 -- <file>             # recent commits; PR numbers show as (#1234)
git log -1 --format=%B <commit>             # full message: PR numbers, trailers, ticket IDs
gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews
```

Pull the PR body and discussion for every substantive commit, not only the latest.

## 3. Check what the workspace already records

Before searching further, read what this workspace captures on purpose:

- `docs/adr/`: an ADR on the target may answer the question outright.
- `work/<item>/decisions.md`: Tier-2 decision notes, with rejected alternatives.
- `Decision:` trailers in the anchor commits' messages.
- `GLOSSARY.md`: whether the name carries a settled meaning.
- If `graphify-out/` exists: `graphify query "why <target>"`.

If an ADR or note answers the question directly, cite it and stop unless the user wants the full history.

## 4. Investigate each reachable evidence source

Each source is best placed to surface one shape of "why":

| Source | Best at |
|---|---|
| Source control (git, PRs, comments, tests) | Implementation-time rationale captured in review. Always available. |
| Issue tracker (GitHub Issues, Jira, Linear, …) | The product or business forcing function. |
| Long-form docs (Notion, Confluence, Google Docs, …) | Design rationale written before it became code. |
| Team chat (Slack, Teams, Discord, …) | Deliberation that never reached a doc. Matters most when the paper trail is thin. |
| Observability (Datadog, Grafana, Honeycomb, …) | Runtime reality behind timeouts, retries, rate limits, circuit breakers. |
| Error tracking (Sentry, Rollbar, …) | The exceptions that motivated catch blocks, null guards, retries. |
| Analytics warehouse (Snowflake, BigQuery, Databricks, …) | Data behind flag-gated code, experiments, migrations, and magic numbers. |

Find what is reachable here: `docs/service-access.md` (and `.service-access.local.json` if generated), the MCP servers configured for this session (`.mcp.json` plus any loaded `mcp-fragments/`), and CLIs on PATH (`command -v gh jira linear`). Source control is always reachable.

If the target looks defensive (null checks, retries, timeouts, rate limits, feature flags, OOM handling), search every source for an incident or postmortem near the commit dates.

Where the runtime has subagents, give each reachable source its own subagent, run them in parallel, and brief each tightly: the code anchor, the user's question, the one source it owns, and the instruction to return cited findings, including what it searched and found nothing for. Without subagents, work source by source yourself with the same brief.

Default to the full sweep: a complete coverage map beats a minimal one. Skip a source only with a written reason that goes into Sources Consulted:

- **Not reachable** here: a gap, not a choice ("Team chat: no access configured; the conversational record was not searched").
- **Provably irrelevant**, not just probably ("Error tracking: target is a build-time script with no runtime path").

A null result is a finding. Record what you searched for and where.

## 5. Synthesize

Sort every claim into a tier from `references/epistemics.md` and phrase it to match. Present:

1. **The question**: as you understood it.
2. **The code in question**: paths, line ranges, key commits.
3. **What we found**: Direct and Supported claims, each with its citation beside it.
4. **What we can reasonably infer**: Inferred claims, with the chain of reasoning explicit.
5. **Competing hypotheses**: Speculative readings side by side; contradicting sources both shown.
6. **What we don't know**: each gap, with the sources and search terms tried.
7. **Sources consulted**: one line per source, including empty ones and skipped ones with the reason.
8. **Confidence summary**: one or two lines on how solid the overall answer is.

If the question precedes a change to the code, end with a constraint set for planning it:

- **Preserve**: behaviour the history shows is load-bearing.
- **Change**: what the history shows is free to move.
- **Avoid**: approaches already tried and reverted, or rejected with a reason.
- **Risk**: what could break that the record does not fully explain.

If the investigation settles a decision worth keeping, offer to record it with `decision-log`.

## Failure modes

- **Recency bias.** Treating the latest commit as authoritative. The current shape is usually an accretion of earlier decisions; trace back past the last touch.
- **Inventing a rationale.** Retrofitting a clean reason onto messy history, or reading the code as evidence of its own intent.
- **Trusting one commit message.** A subject line like "cleanup" or "fix" is the author's framing, not the motive. Corroborate with the PR, ticket, or discussion.
- **Confirming the user's guess.** "I assume it's for performance?" is one hypothesis to test, not a conclusion to validate.
- **Silent gaps.** An answer with no "What we don't know" section is suspect.
