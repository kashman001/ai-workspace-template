# Should the three Jev videos change our integration? (assessment, 2026-09-27, session 15)

One page, self-contained. Written at the user's request after the plan
finished. Source material: `video-notes-2026-09-27.md` (auto-captions, no
claim verified). Weighed on two axes only: **context budget** (what an
agent must carry on every turn) and **usefulness** (does it change what we
ship or how safely we use it).

## Glossary

- **Jev** — TypeSafe's model that answers a typed question (pick one option,
  rate on a scale, yes/no) with a confidence number instead of writing text.
- **Leaf** — the small model (`claude -p haiku`) the `rlm` skill already uses
  to label records; Jev sits in front of it and hands low-confidence records
  back to it.
- **Threshold** — the confidence (now 0.5) below which a Jev answer is
  discarded and the leaf decides instead.
- **Always-on context** — text every session reads before doing anything
  (rules, tool lists). The scarce resource; per-call money and latency are
  not.
- **Hook** — a script a coding agent runs before a prompt or a tool call.
  Each agent brand wires hooks differently.

## Verdict in one line

Two sentences of documentation are worth adding; one small knob is the
user's call; everything else is either already done or not for this
workspace. Nothing here adds always-on context.

## The candidates

| # | Idea from the videos | Verdict | Why (short) |
|---|---|---|---|
| 1 | Say that record text leaves the machine when a key is present | **Do** | Nothing in `skills/jev/SKILL.md` or `docs/service-access.md` says so today. One sentence each: with a key, the records you classify are sent to TypeSafe; the vendor reportedly has no SOC 2 attestation (one uploader's claim, unverified); do not route personal or confidential records. Zero context cost, real safety value. |
| 2 | Warn that 1–5 scale answers are less reliable than pick-one or yes/no | **Do** | One uploader saw good agreement with Claude on type and spam, poor on 1–5 scales (ungraded runs). Our tuning covered Choice only. One clause in the `Score` row of the skill: prefer a Choice or one yes/no per level when it matters. Zero context cost. |
| 3 | Measure Jev-vs-frontier agreement before trusting it | **Already done** | Node 15a compared Jev to the leaf on 100 ledger bullets: 22/100 overall, rising with confidence (5/41 below 0.25, 14/53 in 0.25–0.5, 3/6 at or above 0.5). That is what set the 0.5 threshold. Not measured on the crisp commit corpus; one more paid batch (well under a cent, ~30 s of leaf time) would confirm 0.5 there. Optional. |
| 4 | An off switch for a keyed user (`/jev off` is the shipped default in one video) | **User decides** | Today a keyed user can only rename the keychain entry. A `JEV_DISABLED=1` env var honoured by `scripts/jev.sh` (exit 3, exactly the no-key branch) is a few lines plus one test; it is not a new flag, so the CLI contract holds, but the spec's key-resolution item would gain a line. Worth it only as the concrete action behind #1 ("to keep this corpus local, set …"). Default-off itself is a different philosophy from our gate-on-key and is not recommended. |
| 5 | Route each prompt to a cheap or strong main model | **No change** | Already listed as a later slice in `spec.md` (tier routing at subagent dispatch, which our `plan-tiers.env` does deterministically and for free). The per-prompt version loses the prompt cache and re-reads the conversation, so it can cost more than it saves. |
| 6 | Prompt router over your own data; tool/skill pre-filter; destructive-command guardrail | **Not for this item** | All three are Claude Code hooks, which breaks the agent-agnostic rule. The pre-filter is the only one that saves context, and Claude Code now defers tool schemas natively while this workspace already keeps tools lean by design, so the win is mostly gone. A probabilistic guard on destructive commands is the wrong tool (a miss is unrecoverable); the deterministic `git-guardrails-claude-code` hook is free. The data router is not our use case. |
| 7 | OpenRouter as a second endpoint | **No** | Unknown request shape, no user need (a direct key exists). Research first if it ever matters. |

## What to do with this

- Bundle #1 and #2 (and #4 if wanted) as one small ticket. It is one
  session's documentation work with the existing test suite as the check;
  it does not need a plan. Do it after closing plan `01-gated-integration`,
  not as a wave 8.
- Do not spend on #3 unless the crisp-corpus number is wanted for the record.
- Leave #5–#7 as they are; the notes file keeps the seams for a later item.
