# Subagent context-window stats — ai-workspace-template

Project: `/Users/kashif/Developer/experiments/ai-workspace-template`
Analysis date: 2026-08-06

## Directories inventoried

- `~/.claude/projects/-Users-kashif-Developer-experiments-ai-workspace-template/` (main project dir) — 19 top-level `*.jsonl` main-session transcripts, plus per-session subdirectories (one per parent session that spawned subagents) each containing a `subagents/` folder.
- `~/.claude/projects/-Users-kashif-Developer-experiments-ai-workspace-template--claude-worktrees-vendor-hook-deployments/` (worktree checkout `vendor-hook-deployments`) — 1 main-session `*.jsonl`, no `subagents/` subfolder (no Task-tool calls in that session).

```
find ~/.claude/projects -maxdepth 1 -iname '*ai-workspace-template*'
```
found exactly the two dirs above. No other sibling worktree dirs existed.

## Storage layout (verified)

- **Main sessions**: `<project-dir>/<session-uuid>.jsonl`. Checked every main-session file with `grep -c '"isSidechain":true'` — **all returned 0**. Main transcripts never inline subagent turns.
- **Subagent sessions**: stored entirely separately, at `<project-dir>/<parent-session-uuid>/subagents/agent-<hash>.jsonl`, each paired with a sibling `agent-<hash>.meta.json` carrying `{agentType, description, toolUseId, spawnDepth, model}` — `description` is the short task label passed to the Task tool, useful for classification without opening the transcript.
- First line of each subagent file has `"parentUuid":null,"isSidechain":true,"agentId":"<hash>"` — confirms these are the sidechain/subagent transcripts, and the parent session is recoverable structurally (containing directory name) rather than from an in-line field.
- 6 parent sessions had subagents: `7f7f9f78…` (3), `e64a50f3…` (2), `f2612050…` (3), `4ccca600…` (10), `be795ea7…` (4), `f398089a…` (8) — total **30 subagent transcripts**.
- 20 main-session transcripts total (19 in main project dir + 1 in the worktree project dir).

## Method

For every `*.jsonl` file (main and subagent):
```bash
jq -r 'select(.message.usage != null) |
  (.message.usage.input_tokens // 0)
  + (.message.usage.cache_read_input_tokens // 0)
  + (.message.usage.cache_creation_input_tokens // 0)' "$f" | sort -n | tail -1
```
= peak context per transcript (max over all lines carrying a `usage` block). Also recorded line count, count of usage-bearing lines, and mtime (`stat -f "%Sm"`). Full script logic:

```bash
process_file() {
  local f="$1" kind="$2" parent="$3"
  peak=$(jq -r 'select(.message.usage != null) | (.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)' "$f" | sort -n | tail -1)
  lines=$(wc -l < "$f")
  mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f")
  echo -e "${f}\t${kind}\t${parent}\t${peak:-0}\t${lines}\t${mtime}"
}
```
Applied to all main-dir top-level `.jsonl` (kind=main), all `<parent>/subagents/*.jsonl` (kind=subagent, parent=dirname), and the worktree dir's `.jsonl` (kind=main).

## Full table — all 50 transcripts, sorted by peak context descending

| Peak tokens | Kind | Parent session | mtime | File |
|---|---|---|---|---|
| 215039 | main | - | 2026-07-22 17:51 | 10a8d1b2-c45a-4aaf-ae6b-962ca15f0a97.jsonl |
| 197821 | main | - | 2026-08-06 01:00 | (worktree) 04cc4627-2b93-4364-a099-a06a5e919783.jsonl |
| 177455 | main | - | 2026-07-24 17:11 | 7f7f9f78-1b1f-41ca-87e4-a8ee4cd56380.jsonl |
| 169332 | main | - | 2026-08-05 15:24 | 9242945f-7a68-4510-9455-fb3fc6c63b95.jsonl |
| 163756 | main | - | 2026-08-05 18:32 | 2811ca4f-8133-4f56-8512-8a77f6bd7072.jsonl |
| 156078 | main | - | 2026-08-06 07:12 | be795ea7-64c2-4c72-aeb8-aabe354c2f64.jsonl |
| 152746 | main | - | 2026-08-05 19:29 | e11a6f9f-3d3e-4c31-8932-2a542f3b370e.jsonl |
| 151130 | main | - | 2026-08-05 23:38 | 34047fac-e9a8-4dee-a262-656b29cb3e62.jsonl |
| 148241 | main | - | 2026-08-05 23:30 | 485edb7d-8cf2-466b-b3d0-b45607169005.jsonl |
| 146794 | main | - | 2026-07-22 18:09 | 796d0e8a-f1b0-4d92-9432-f4dc11be5402.jsonl |
| 144542 | main | - | 2026-08-06 01:07 | 4ccca600-3493-4b6f-82c4-39a073d7e42a.jsonl |
| 143226 | main | - | 2026-08-05 21:24 | 90710a32-c4c9-4efa-8817-d206d442c729.jsonl |
| 142131 | main | - | 2026-07-29 19:37 | 6c638c37-d211-4a1e-94ef-6220480f742e.jsonl |
| **141800** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:20 | agent-adcf2e2b070604b91.jsonl |
| 138314 | main | - | 2026-08-05 20:35 | 8e633452-52c4-470d-a7ec-28db31163322.jsonl |
| 137826 | main | - | 2026-07-23 08:09 | f87f7778-661e-4219-821d-5b58f7b8ea76.jsonl |
| **133592** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:25 | agent-a8440a14d94e5f351.jsonl |
| **133578** | **subagent** | be795ea7-64c2-4c72-aeb8-aabe354c2f64 | 2026-08-06 00:59 | agent-a50aefa1e51c9096f.jsonl |
| 129571 | main | - | 2026-08-05 17:31 | e64a50f3-4d9e-4cfe-9333-e9760520e609.jsonl |
| 121228 | main | - | 2026-08-05 20:13 | f2612050-6cf0-445b-a146-0792f40d3cb0.jsonl |
| 119963 | main | - | 2026-08-06 07:30 | f398089a-a3b2-4c58-9ac9-157b98ebb9cf.jsonl |
| **105618** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-06 00:01 | agent-ae66f6a6cea2f054b.jsonl |
| 102134 | main | - | 2026-07-29 19:37 | 6501f23d-dd00-483a-acc9-0a6ae23cbc31.jsonl |
| **96142** | **subagent** | f2612050-6cf0-445b-a146-0792f40d3cb0 | 2026-08-05 18:51 | agent-aacb14fe32d3d247a.jsonl |
| **93199** | **subagent** | be795ea7-64c2-4c72-aeb8-aabe354c2f64 | 2026-08-06 00:48 | agent-a5887f9b20d772674.jsonl |
| **89852** | **subagent** | f2612050-6cf0-445b-a146-0792f40d3cb0 | 2026-08-05 19:27 | agent-aabd2d90b6caefef0.jsonl |
| **88489** | **subagent** | e64a50f3-4d9e-4cfe-9333-e9760520e609 | 2026-08-05 15:16 | agent-a104332ecb5c865c1.jsonl |
| **86727** | **subagent** | be795ea7-64c2-4c72-aeb8-aabe354c2f64 | 2026-08-06 01:03 | agent-a1ec4900ae4ecfbc3.jsonl |
| **84597** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:29 | agent-a1cde03bc5c7b4771.jsonl |
| **75792** | **subagent** | be795ea7-64c2-4c72-aeb8-aabe354c2f64 | 2026-08-06 00:51 | agent-a90600014389fa20b.jsonl |
| **74571** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:19 | agent-a9522a3acc5854703.jsonl |
| **72159** | **subagent** | 7f7f9f78-1b1f-41ca-87e4-a8ee4cd56380 | 2026-07-23 12:34 | agent-a64843f06f2440e73.jsonl |
| **69105** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-06 00:17 | agent-a8ef13e3b505fdef3.jsonl |
| **67153** | **subagent** | 7f7f9f78-1b1f-41ca-87e4-a8ee4cd56380 | 2026-07-23 12:38 | agent-a326a953f3da62afc.jsonl |
| **66688** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:41 | agent-a3679a82c33b20715.jsonl |
| **66031** | **subagent** | 7f7f9f78-1b1f-41ca-87e4-a8ee4cd56380 | 2026-07-23 12:32 | agent-a54c058cb5405de3e.jsonl |
| **62905** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:31 | agent-a0e95769ad249f459.jsonl |
| **61763** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:45 | agent-a18abfbceb85198e8.jsonl |
| **59271** | **subagent** | f2612050-6cf0-445b-a146-0792f40d3cb0 | 2026-08-05 19:23 | agent-aa47586dd53862d31.jsonl |
| **57300** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:49 | agent-a3693675c2d3accac.jsonl |
| **56366** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:42 | agent-a0668a04178cd4bf0.jsonl |
| **53092** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:51 | agent-aa1d6cba3301b556b.jsonl |
| **51941** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-06 00:03 | agent-a5c0bda3eed7d1d51.jsonl |
| **51395** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-06 00:36 | agent-a0f5bddd04c527da9.jsonl |
| **49402** | **subagent** | 4ccca600-3493-4b6f-82c4-39a073d7e42a | 2026-08-05 23:47 | agent-ad968cdef90bac9e8.jsonl |
| 47750 | main | - | 2026-08-05 17:40 | 01f0a657-4dcf-480d-9838-f61c469d6412.jsonl |
| **46358** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 07:30 | agent-a0dccc0a9a4b9ac8c.jsonl |
| **36563** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 01:21 | agent-a0e68e55bcf578a52.jsonl |
| **36536** | **subagent** | e64a50f3-4d9e-4cfe-9333-e9760520e609 | 2026-08-05 15:15 | agent-a27589de5c3c8edb0.jsonl |
| **22822** | **subagent** | f398089a-a3b2-4c58-9ac9-157b98ebb9cf | 2026-08-06 07:30 | agent-a48a89d8f37eaab2e.jsonl |

(Raw TSV backing this table: `/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/f398089a-a3b2-4c58-9ac9-157b98ebb9cf/scratchpad/subagent_peaks.tsv`)

## Subagent population summary (n=30)

- Count: 30
- Max: 141,800 tokens
- Median: 66,920.5 tokens
- ≥120,000 (WARN threshold): **3** (141800, 133592, 133578)
- ≥150,000 (STOP threshold): **0**

No subagent transcript reached the 150K STOP threshold. Three exceeded the 120K WARN threshold, all within roughly 8–22K tokens of 150K, and all three belong to the two most recent parent sessions (`f398089a…`, `be795ea7…`) — i.e. the largest subagent contexts cluster in the most recent work, not evenly across history.

## Top 10 subagent peaks with task descriptions

(descriptions pulled from the sibling `.meta.json` `description` field, which is the short Task-tool label — equivalent to a truncated first-user-message summary)

| Rank | Peak tokens | Parent | agentType | model | Task description |
|---|---|---|---|---|---|
| 1 | 141,800 | f398089a… | general-purpose | sonnet | Implement Task 9 attach-session |
| 2 | 133,592 | f398089a… | general-purpose | fable | Final whole-branch review |
| 3 | 133,578 | be795ea7… | general-purpose | sonnet | Implement Task 8: docs + gate |
| 4 | 105,618 | 4ccca600… | general-purpose | sonnet | Implement Task 5 (opencode plugin) |
| 5 | 96,142 | f2612050… | general-purpose | (unset) | Research vendor hooks and launch capabilities |
| 6 | 93,199 | be795ea7… | general-purpose | sonnet | Implement Task 7: option inheritance |
| 7 | 89,852 | f2612050… | general-purpose | (unset) | Install and smoke-test Copilot CLI |
| 8 | 88,489 | e64a50f3… | Explore | (unset) | Summarize Matt Pocock skill library |
| 9 | 86,727 | be795ea7… | general-purpose | sonnet | Review Task 8 docs work |
| 10 | 84,597 | f398089a… | general-purpose | sonnet | Final-review fix wave |

## Caveats

- **`usage` presence**: every transcript sampled had at least one line with a `.message.usage` block (assistant turns), so no file was fully unmeasurable; peak = true max across the transcript, not an estimate.
- **Peak vs. reported "context size"**: `input_tokens + cache_read_input_tokens + cache_creation_input_tokens` approximates the model's total context at that turn (matches the `context-budget.sh` measurement convention referenced in this workspace's `docs/context-budget.md`), but it is a per-turn API-reported figure, not a direct read of a token counter — if Claude Code's actual budget hook uses a different formula (e.g. excluding cache-creation tokens) the classification against 120K/150K could shift slightly for borderline transcripts (only the 3 subagents at 133–142K are close enough to matter).
- **No compaction markers observed**: did not specifically scan for mid-transcript compaction/summarization events; if a subagent's context was compacted mid-run, the recorded "peak" still reflects the true max turn-level usage before/after compaction, so this shouldn't undercount, but the transcript's own peak may not equal the theoretical peak the model would have hit absent compaction.
- **Parent attribution**: parent session is inferred from the containing directory name (`<parent-uuid>/subagents/`), not from an explicit field inside the subagent transcript itself — reliable given the structural relationship, but noted since the task asked to verify rather than assume this.
- **Two agents' `model` field unset** (`Research vendor hooks…`, `Install and smoke-test Copilot CLI`, `Summarize Matt Pocock skill library`) in their `.meta.json` — likely predate a metadata field addition or used a runtime default; did not chase further since it doesn't affect the token math.
- **Main-session peaks included in the full table for context** but excluded from the "subagent population" stats per the task's request — 8 of 20 main sessions are themselves ≥120K (one at 215K), which is outside this task's scope but worth flagging since main-session context pressure is at least as prominent as subagent pressure in this project.
