# Video notes — three Jev + Claude Code tutorials (2026-09-27, session 12)

Read by the user's request during the wave-6 UAT pause. Transcripts read in
full (auto-captions via YouTube's transcript panel; yt-dlp was rate-limited).
Not a research pass: no claims verified, no fact-check. Input for a possible
later seam decision only; the fit decision (`decisions.md`, note 2) stands.

## 1. Kev Builds Apps — "How to add Jev AI to Claude Code in 6 minutes" (ULKX0bnNQZY, 2026-09-19)

- Seam: `UserPromptSubmit` hook. Every prompt goes to Jev first; Jev picks
  from a closed, growing set of tool calls over the author's own data (11
  tools, 22 date ranges, 6 sort orders, 8 platforms, 4 statuses). If it can
  answer with one tool call, the hook prints the answer in a colour and the
  model never runs.
- Setup: TypeSafe console "agent setup prompt" + their skill file (the one we
  vendored), then a hook-wiring prompt. The hook prompt is not linked; six
  top comments say so; one warns the author to rotate the key shown on screen.
- Claude Code only. Key storage left to the agent.

## 2. Nuno Tavares — "I Let Jev AI Make 2,600 Decisions. Here's the Bill." (jO8uzewZGwo, 2026-09-25)

- Ships a `jev-decisions` skill (Google Drive link in the description): a
  prompt router with `/jev on`, `/jev off`, `/jev status`, and a selftest.
  Off = nothing sent, and that is the shipped default.
- Five tests, numbers on screen, none graded against a marked answer set
  (the author says so): model routing 10/12 prompts skipped the top model;
  100 emails hot/warm/cold agreed with Claude 89/100 at $0.002 vs $0.27;
  150 yes/no decisions for a fifth of a cent; find-files-by-meaning over 60
  file names (not pixels); 312 YouTube comments × 7 questions in 72 s for
  ~1 cent, 90–96% agreement on type, 98–100% on spam, disagreement on 1–5
  scales.
- Explicit "must never" list: write, count, do math, compare dates, judge
  another model's answer, summarise, decide anything that moves money.
- Privacy warning: not SOC 2, no privacy gate; do not route sensitive data.
- Available via TypeSafe directly or OpenRouter (same price).

## 3. MG — "Jev Claude Code: Quick Setup" (Cnos5qLUfrE, 2026-09-20)

- Three harness seams, all Claude Code: (a) model router per prompt (easy →
  Haiku, hard → Fable); (b) tool/MCP/skill pre-filter so the model sees only
  the relevant candidates (claims 5–10× less context on 29k-token skill
  lists); (c) guardrail on destructive commands before the model runs (block
  in ~0.5 s vs 5 s / 124 tokens).
- Setup: OpenRouter key saved locally, then "tell Claude Code to add Jev as
  my router". No files shared.
- Author's own caveat: no benchmarks, accuracy unverified, "overhyped";
  evaluate with the frontier model first, then roll out gradually.
- Pinned comment (unanswered in the transcript): switching the main model
  per prompt loses the prompt cache and re-reads the conversation, so it can
  cost more than it saves; Haiku's 200K window can fail on a long session.

## What this adds to the seam inventory

Four harness-level seams none of the six in `seam-inventory.md` covered:
prompt router over a closed tool set (1), main-model router per prompt
(2, 3a), tool/skill pre-filter (3b), destructive-command guardrail (3c).
All would sit in a `UserPromptSubmit` or `PreToolUse` hook calling
`scripts/jev.sh` (Choice or Noul), gated on the key like `classify()`.
Template constraints that bite: agent-agnostic wiring (Codex/Gemini/OpenCode/
Copilot hooks differ), and 3a's cache-loss objection. 3c overlaps
`git-guardrails-claude-code`, which is deterministic and free. Video 2's
router skill is the closest ready-made artefact; none of the three is a
source for a claim without a fact-check.

## Deferred: assessment of what the videos could change in our implementation

The user asked (session 12) for a critical assessment weighed against context
budget and usefulness, then said to finish the plan first. Not assessed yet.
Candidates found, with what a quick grep showed on disk, for the session that
picks this up:

- Data-handling / privacy note (video 2: no SOC 2, no privacy gate). Nothing in
  `skills/jev/SKILL.md` or `docs/service-access.md` says record text leaves
  the machine when a key is present. Cheap (one bullet each), zero always-on
  context; likely worth doing.
- Score reliability (video 2: agreement poor on 1–5 scales, good on type and
  spam). `skills/jev/SKILL.md` line 46 describes Score without a caution.
  Cheap; fits node 15 (which tunes on Choice only via `classify()`).
- Agreement measurement (video 3: "let the frontier model evaluate Jev
  first"). Node 15 could run one batch through both paths and record the
  agreement rate as our own "89/100". One paid batch; fits node 15's remit.
- Off switch for a keyed user (video 2: `/jev off` is the shipped default).
  No `JEV_DISABLED`-style switch exists; a keyed user must rename the
  keychain entry. Spec says `--check`/`--help` are the only flags, so this
  would be an env var and a spec amendment. Small; decide, do not assume.
- Tier routing at dispatch (videos 2, 3a) is already the noted later slice
  (`spec.md` "Tier routing at subagent dispatch"); the per-prompt variant is
  rejected by the cache-loss objection. No change.
- Prompt router, tool pre-filter, guardrail (videos 1, 3b, 3c): harness-level
  hooks, Claude Code only as shown; guardrail duplicates the deterministic
  git-guardrails hook. Not for this item.
- OpenRouter as a second endpoint (videos 2, 3): unknown request shape;
  needs research before any change to `scripts/jev.sh`.
Always-on cost of every candidate above: zero beyond the existing Service
Access bullet; the costs are per-call latency and money, not context.
