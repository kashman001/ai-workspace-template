# Trim Estimates — skill_listing & project CLAUDE.md (2026-08-07, session #4)

Measured live on this session's transcript via `scripts/context-inspect.sh`
(turn-1 exact = 43,855 tok). Estimates are chars/4. **Analysis only — no
trims implemented yet** (user asked for savings + implications first).

## Trim 1: skill_listing (~4,026 tok this session)

Per-entry measurement of the injected listing, classified by who controls
each entry:

| Source | Entries | ~Tokens | Repo-trimmable? |
|---|---|---|---|
| Built-in (Claude Code ships them: dataviz 286, claude-api 270, update-config 176, claude-in-chrome 136, artifact-* …) | 15 | ~1,511 | **No** — harness-fixed |
| User-global `~/.claude/skills` (karpathy-examples 152, code-review 108, graphify 91, wizard 80 …) | 14 | ~954 | No — user machine action |
| Plugins (superpowers ≈585, claude-md-management 117, skill-creator 87, frontend-design 59, code-review 13) | 19 | ~872 | No — user plugin config |
| **Workspace repo** (`skills/` + `.claude/commands/`: checkpoint 112, create-work-item 32, writing-for-agents 31, onboard-repo 28, session-rollover 28, wayfinder 28, rlm 23, decision 22) | 8 | **~307** | **Yes** |

**Verdict: the audit's "largest workspace lever" framing does not survive
the source breakdown.** Only ~307 tok of the 4K is repo-controlled.

- Realistic repo-side saving: **~100–150 tok** (halve the 8 descriptions;
  `checkpoint` alone is 112).
- Implication: descriptions are the model's *trigger surface* — over-terse
  descriptions degrade auto-invocation accuracy (skill-creator guidance).
  Also skills ship to template downloaders (memory:
  template-additions-are-first-class), so cuts affect every consumer.
- The real levers inside skill_listing are **user-global** (option-3
  territory, deferred): pruning unused `~/.claude/skills` (≤ ~954) and
  disabling unused plugins (≤ ~872).

## Trim 2: project CLAUDE.md / CONTEXT.md (~3,157 tok this session)

Per-section (chars/4):

| Section | ~Tok | Trim candidate? |
|---|---|---|
| Workspace Skills | 483 | Compress to one-liners+pointer (−250). BUT: exists for non-Claude runtimes (Codex/Gemini get no skill_listing); for Claude Code it double-pays vs the injected listing. |
| Context Budget | 480 | Compress to rules+pointer (−200). Risk: drives WARN/STOP behavior; pointer-following is weaker than inline for behavioral rules. |
| graphify | 244 | Tighten (−100); rules only matter once a graph exists. |
| Tool & Context Loading | 235 | Tighten (−100). |
| Agent Context Discipline | 219 | Keep — cheap, high-leverage behavior. |
| Decision Records | 219 | Tighten (−80); skill carries the detail. |
| Work Directory Convention | 189 | Tighten (−60); doc carries detail. |
| Agent Coding Principles | 188 | Duplicates global CLAUDE.md for THIS user (−188), but is the only copy for template downloaders. |
| Template Backlog | 187 | Template-dev-only by design ("delete when adapting"). Compress to ~50 (−140) — full delete would stop agents maintaining the backlog. |
| Preamble + Purpose | 257 | Template note shrinks after adaptation (−80). |
| Others (Layout/Covered/Structure/Service/First-run/Tooling) | ~412 | Mostly already pointers; marginal. |

- Moderate pass: **~600–800 tok** saved (file → ~2.4K).
- Aggressive link-out pass: **~1,000–1,300 tok** (file → ~1.9–2.1K).
- Implications: (a) every inlined rule moved behind a pointer trades
  always-on compliance for demand-loading — fine for reference detail, risky
  for behavioral rules (context budget, backlog upkeep); (b) sections that
  look duplicated are duplicated *only in Claude Code sessions* — they are
  the sole context path for Codex/Gemini/Copilot (memory:
  integrations-must-be-agent-agnostic); (c) downloader-facing onboarding
  value shrinks.

## Combined honest picture

Repo-side (options 1+2 together): **~0.7–1.45K tok off a 43.9K turn-1 ≈
2–3%** — real but small vs the harness-fixed ~31.6K remainder. The larger
levers stay user-global (option 3: superpowers SessionStart ~0.9–1.9K,
hook_success ~1.4K turn-1, user skills ~954, plugins ~872, built-ins fixed).

Verification once any trim lands: `scripts/context-experiment.sh`
before/after S1/S2/S3.
