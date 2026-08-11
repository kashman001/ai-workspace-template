<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-11 (rollover #2: §6 sweep + ledger analysis + template port)

## Summary

Claude Code session (a62b36d8). Completed the findings-§6 record-correction
sweep, ran the standing **ledger analysis** follow-up, integrated its
recommendations, and ported the whole arc to `repos/ai-workspace-template`.
All work committed AND pushed on both repos (user directive).

## What happened

- **§6 sweep closed.** `docs/context-budget.md` correction was already written
  by the VS Code agent (uncommitted) — committed as `fadcfe8` together with
  dropping the no-op `chat.hookFilesLocations` entry from
  `.vscode/settings.json`. The VS Code agent's repo memory
  (`…/memory-tool/memories/repo/index.md`) verified correct on disk — HOOK A
  CONFIRMED bullet in place, live-verified from its session 0006a9b3.
- **Ledger analysis done** (`ledger-analysis.md`, committed `f67ba3c`):
  181 records / 67 sessions. Headlines: 63% of STOP sessions never saw WARN
  (work units 50–130K vs a 30K WARN band); STOP overshoot median +17K;
  rollover procedure ~20K median; estimate-accuracy unanswerable (needs
  gemini). R1/R2 applied to `skills/session-rollover/SKILL.md` (WARN = one
  small closing unit only; pre-flight headroom check before major units).
- **Block-marker hazard** port from template 3ffcf5a committed (`4d0462e`).
- **Template port pushed** (`kashman001/ai-workspace-template` `6a6f1fa` +
  backlog row `fb07fdf`): hook fix, Guard C, docs/CONTEXT.md corrections,
  `chat.useHooks`, SKILL R1/R2 (cross-deployment numbers), our analysis
  imported as `ledger-analysis-heavy-deployment-2026-08-11.md` (their own
  `ledger-analysis.md` left untouched — different deployment, different
  numbers), backlog change-log row + Last-updated bump.

## Decisions Made

- Template port kept per-repo divergences (their Copilot CLI row wording,
  `check-dependencies.sh` naming) — ported only this arc's hunks.
- R11-workstream files (`docs/operational-knowledge.md`,
  `skills/policy-rego-authoring/design-patterns.md`, `work/R11PolicyDev/*`)
  left uncommitted for that workstream's own session.

## Open Questions / follow-ups (also in README)

- Copilot CLI record discrepancy: `docs/context-budget.md` cites
  `work/automatic-session-rollover/smoke-test-copilot.md` — that dir exists
  only in the template repo (where the 2026-08-05 verification happened),
  dangling here. Fix the pointer or re-verify locally.
- Gemini telemetry (estimate-accuracy question blocked on it).
- Future ledger re-pass: do flat-token copilot-vscode sessions disappear
  post-hook-fix?
- Minor: end-of-session `record` returned "no session artifact found" once at
  STOP — not investigated (single occurrence, prior record landed fine).

## Key Files

- `ledger-analysis.md` — the deliverable
- `skills/session-rollover/SKILL.md` — tightened trigger policy
- Template: commits `6a6f1fa`, `fb07fdf` on github main

# Session Handoff — 2026-08-07 (session #4: trims declined, Warp attribution settled, inspector fixed)

**Ran as a background job (worktree `context-decay-s4`), user live mid-session.**

**Trim candidates (mission steps 1–2):** measured live (turn-1 = 43,855 exact).
skill_listing ~4,026 tok is only ~307 tok workspace-controlled (built-ins
~1,511 / user-global skills ~954 / plugins ~872); CLAUDE.md moderate pass
~600–800, aggressive ~1,000–1,300, all with real downsides (non-Claude
runtimes, downloaders, always-on behavioral rules). Full table:
`trim-estimates.md`. **User declined all trims** — bar was "unused AND no
negative implications"; decision note in `decisions.md` (2026-08-07). Don't
re-propose.

**Warp attribution (mission step 3): settled.** hook_success stdout/stderr
never enter model context; only the `content` field does (context-budget
SessionStart hook: content≈stdout and visibly in context; Warp PostToolUse/
Stop: content=0; superpowers SessionStart arrives as separate
hook_additional_context). Residual analysis over two Warp-heavy transcripts:
whole-JSON attribution → median residual −43/−14 with 57–73% turns negative;
content-only → uniform small-positive (median ≈ +155). Fixed both jq measure
sites in `scripts/context-inspect.sh` (hook_success now content-length);
verified: 136 Warp records drop to 0 tok, residuals all small-positive.
Backlog L31 (archive), scorecard 49.

**Learnings (parked):**
- Every session on this machine carries Warp plugin hooks — there is no
  non-Warp control session; residual-delta comparison within a session is
  the usable method.
- Backlog archive has pre-existing duplicate IDs (two L19s, two L20s from
  parallel passes; L-series otherwise runs to L30 — new cards start L31).

---

# Session Handoff — 2026-08-07 (session #3: audit done, snapshot tool + rollover capture shipped)

**Ran as a background job in auto permission mode; rolled at WARN 128.5K.**
Work on branch `worktree-context-decay-snapshot-tool` (worktree), NOT main —
merge required before the successor sees these files.

**Audit (mission step 1–2):** turn-1 = 43,857 exact. Composition:
harness-fixed ~31.6K; skill_listing ~4.0K (largest workspace lever); project
CLAUDE.md ~3.1K; global CLAUDE.md ~1.7K; superpowers SessionStart injection
~1.9K (user-global); agent_listing ~0.8K; memory ~0.1K. Post-turn-1 pulls
~2.5K (deferred MCP tools, mcp_instructions). The user never pasted /context
outputs — superseded by building the tool instead (their call, mid-session).

**Built (user-accepted, plan in `plan-snapshot-tool.md`):**
- `context-inspect.sh --phases` — per-turn diff table: exact delta vs
  attributed est (att/msg/asst) + residual; turns grouped by requestId
  (one turn = several assistant jsonl lines sharing one usage envelope).
  Verified on a 36-turn transcript: residuals small-positive (thinking +
  est error).
- `scripts/context-experiment.sh [--workload <file>]` — headless two-run
  driver (baseline "hi" + workload), prints S1/S2/S3 summary. Live-verified:
  S2=34,063, S3=36,049 (headless baseline is ~10K lighter than interactive —
  fewer connectors/skills).
- `scripts/capture-rollover-options.sh <project>` — mechanical capture of
  the session's permissionMode → `.rollover-options` (user ask: successors
  inherit e.g. auto mode). Live-verified end-to-end: dry-run successor cmd
  carries `--permission-mode auto`. Model deliberately not captured
  (decisions.md 2026-08-07). Wired into session-rollover step 6 + docs.

**Learnings (parked):**
- Worktree sessions write transcripts under the WORKTREE-path slug, and the
  harness *moves* the live transcript file on EnterWorktree — both inspect
  and capture scripts now try `$PWD` slug before workspace-root slug.
- Transcript records `permissionMode` per line ("last wins" is correct;
  stale sibling transcripts can disagree — always pin the live session).
- Backlog: L19 + L20 added and resolved (archive); scorecard 48.

---


**Trigger:** user request during a template-maintenance background session:
a tool an agent can run to analyze context *composition* (baseline vs what
the first message pulls in), feeding future optimization work items.

**What shipped:** `scripts/context-inspect.sh` — resolves the session
transcript ($CLAUDE_CODE_SESSION_ID, else newest for the workspace slug),
prints exact per-turn context totals from the usage envelope, a harness
attachment breakdown split turn-1 vs later (skill_listing, deferred_tools,
mcp_instructions, agent_listing, hook context…), the disk-side
CLAUDE.md/memory stack (harness-injected, absent from transcripts), and the
harness-fixed remainder. Verified on two real transcripts (45.7K/43.9K
turn-1 exact; turn-1 attachments ~10K est — the L29 /context under-report,
now itemized). Doc pointer: context-budget.md → Quickstart — agent.
Claude-runtime transcripts only.

**Learnings (parked):**
- CLAUDE.md / auto-memory / userEmail never appear in the transcript jsonl —
  harness-injected; only attachments + usage are recorded. Any per-component
  audit must combine transcript + disk.
- Workspace-root resolution self-heals post-merge: the script keys on
  `scripts/context-inspect.sh` existing at the git-common root, so worktree
  runs before the merge fall back to the worktree root (memory-slug path
  misses); harmless afterward.

---

# Session Handoff — 2026-07-23 (session 4b: post-rollover continuation — convention migration + ledger analysis pass 2)

Session 4 continued past its rollover (user-driven) and hit **STOP at
153.5K** — the live instance of ledger-analysis finding #5. Work done in
the continuation, all committed & pushed through `fe5072a`:

- `2ed1eec` — pulled `bd40023` (launcher/ledger work-directory convention +
  `create-work-item` skill) and migrated `work/context-decay/` to it
  (README added, purpose headers, this ledger rebuilt newest-on-top).
- `fe5072a` — **ledger analysis pass 2** (`ledger-analysis.md`): pass-1
  numbers confirmed; new findings — subagent fan-out kept a ~208K unit to
  +40K orchestrator growth; post-rollover continuation is the leak. Next
  pass at ~40 entries or first estimate/non-claude rows.

State: `main` clean, pushed. Next: dormant — gates in `next-session.md`.

# Session Handoff — 2026-07-23 (session 4: L13 + L11 remainder)

Backlog is 0 open / 27 resolved; the project is dormant.

## What got done (all committed & pushed, through `a138c6e`)

- `4ac6f49` — **Fix L13**: developer-quickstart session-lifecycle note in
  `docs/context-budget.md` + `SessionStart` registration hook in
  `.claude/settings.json.example` (reads `transcript_path` from the hook
  stdin payload; fails open). Also copied into the user's live gitignored
  `.claude/settings.json` — future Claude sessions here register
  mechanically.
- `7c29476` (pulled from origin, authored downstream) — copilot-vscode
  discovery maps `$VSCODE_TARGET_SESSION_LOG` (a `debug-logs/<id>` dir on
  current builds) to `chatSessions/<id>.jsonl`. `df12f76` reconciled the
  backlog (M10 follow-up row) since the delivering session skipped it.
- `83dcb0a` — **Fix L11 remainder** (subagent-driven: 2 sonnet research
  agents + 1 opus implementer): `codex_discover()` pins
  `rollout-*-$CODEX_THREAD_ID.jsonl` — var live-probed via a real
  `codex exec` session on this machine and confirmed in openai/codex source;
  `copilot_cli_discover()` pins
  `${COPILOT_HOME:-~/.copilot}/session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl`
  (CLI ≥1.0.29 changelog) and drops the nonexistent `sessions/` path.
  Research with citations: `work/context-decay/research/*.md`.

## Decisions (commit trailers + backlog cards)

- Pin runtime-exported ids, mtime only as fallback — settled M10/M11
  reasoning extended to the last two adapters.
- Copilot CLI adapter stays **unverified**: its pin is changelog-sourced,
  not live-probed (CLI not installed here).

## Gotchas worth remembering

- `SessionStart` hook stdout is injected into session context — keep it terse.
- `codex exec` probing works for "what env does runtime X export to its
  shells" questions — it cleared a gate previously assumed machine-blocked.
- Copilot CLI's real state dir is `session-state/` (since 0.0.342), not
  `history-session-state/` (legacy) or `sessions/` (never existed).

## State at rollover / next step

Branch `main` clean, pushed. Registered 41.6K → WARN at 120.7K → rollover at
~125K. Ledger 18 entries (analysis gate ~20 is close). Next: dormant; check
gates in `next-session.md`.

# Session Handoff — 2026-07-23 (session 3: session-pinning fixes)

Session 2's handoff is in git history at `f18b830^..f18b830`.

## What got done (all committed & pushed)

- `03c19d3` — **Fix M10+M11**: session discovery pinned to runtime-exported
  ids over newest-mtime. M10 (reported live from a downstream copilot-vscode
  session: false STOP from a stale sibling log) — `copilot_vscode_discover`
  prefers `$VSCODE_TARGET_SESSION_LOG`. M11 — `claude_discover` pins
  `$CLAUDE_CODE_SESSION_ID.jsonl`; differential-verified (stale transcript
  touched newest in the same shell call: unpinned register binds it, pinned
  binds the live session).
- `f1eb1b1` — **Fix M12+L12, L11 part**: `register --runtime gemini`
  truncates the shared workspace telemetry log after binding it (fixture
  lifecycle-verified: stale 140K WARN → 0 after register → appended response
  reads exact); `gemini_measure` reports `0 estimate` when no logs exist;
  codex any-project fallback removed (fails rather than bind another
  project's rollout); single-session-per-runtime limitation documented.
- Backlog: M10, M11, M12, L12 resolved; L11 open (machine-gated remainder);
  **L13 opened at rollover** — registration lifecycle is agent-documented
  only; fix queued as the next session's first task.

## Decisions (captured in commit trailers + backlog cards)

- Authoritative session-id pin where the runtime exports one; mtime only as
  fallback (rejected: mtime-only — lazy flushes / concurrent sessions lie).
- Gemini: truncate-at-register over OTLP session-id filtering (CLI exports
  no session id to match against).

## Gotchas worth remembering

- Claude transcripts re-flush every turn: mtime differential tests must
  touch-and-measure in a single shell call or the live session instantly
  regains newest mtime.
- `check` reads the registry pin (M9 fix); only `register` re-discovers —
  test discovery changes via `register`, not `check`.

## State at rollover / next step

Registered at 41.6K, WARN hook fired at ~126K mid-turn (live demo of layer
1), rollover started at 133K. Ledger 13 entries, all claude/exact. Next:
land L13.
