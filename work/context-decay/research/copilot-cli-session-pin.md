# GitHub Copilot CLI — session-state discovery & session-id pin research

Date: 2026-07-23
Scope: the standalone `copilot` CLI (npm `@github/copilot`, tracked at
`github/copilot-cli`) — **not** the deprecated `gh copilot` (`gh-copilot`)
extension, and not VS Code's Copilot Chat terminal integration.

## 0. Local machine confirmation (no install performed)

```
$ command -v copilot        # (nothing — not installed)
$ gh extension list          # (empty — no gh-copilot extension either)
$ ls -la ~/.copilot
drwx------@   3 kashif  staff    96 Apr 26 23:04 .
drwx------@   3 kashif  staff    96 Jul  2 10:59 ide
$ find ~/.copilot -maxdepth 3
/Users/kashif/.copilot
/Users/kashif/.copilot/ide
/Users/kashif/.copilot/ide/43c83f3b-f62c-4da5-91d9-32541145fa6c.lock
```

`~/.copilot/ide/` only — this is VS Code Copilot Chat's IDE-bridge lock file,
unrelated to the standalone CLI. No `session-state/`, `history-session-state/`,
`sessions/`, `session-store.db`, or `settings.json` exist, because the
standalone CLI has never run here. **All findings below are from public
documentation/changelog/issues, not from local inspection of a live session —
see §4 for what still needs a real install to confirm.**

`github/copilot-cli` on GitHub is issue-tracker-only (confirmed via
`gh api repos/github/copilot-cli/contents/` → just `.github/`, `LICENSE.md`,
`README.md`, `changelog.md`, `install.sh`; `language: Shell`, `size: 362`).
The actual CLI is closed-source; the changelog is the best first-party
source and is unusually detailed (per-release, dated, itemized).

Current release at research time: **v1.0.74-4** (pre-release, 2026-07-23);
latest stable line **v1.0.73** (2026-07-20) per `changelog.md` head.

## 1. On-disk session-state layout

### Current format (since v0.0.342, 2025-10-15)

Straight from `github/copilot-cli`'s own `changelog.md` (line 2672-2675,
entry `## 0.0.342 - 2025-10-15`):

> - Overhauled our session logging format:
>     - Introduced a new session logging format that decouples how we store
>       sessions from how we display them in the timeline. ...
>     - **New sessions are stored in `~/.copilot/session-state`**
>     - **Legacy sessions are stored in `~/.copilot/history-session-state`** --
>       these will be migrated to the new format & location as you resume
>       them from `copilot --resume`

This is corroborated by GitHub's own docs page ("About/Using GitHub Copilot
CLI session data", aka `.../concepts/agents/copilot-cli/chronicle` and its
how-tos mirror) and by a detailed third-party write-up:

- Docs: "Data for a session is written to disk in a session-specific
  subdirectory of `~/.copilot/session-state/`, which happens periodically
  during a session and also when the session ends." Also: "there's a
  `session-store.db` file that serves as a database" with an FTS5 full-text
  index and auto-generated summaries.
  https://docs.github.com/en/copilot/concepts/agents/copilot-cli/chronicle
- Jon Magic's blog (inspected an actual `~/.copilot` tree):
  ```
  ~/.copilot/
  ├── config.json
  ├── session-state/
  │   └── <uuid>/
  │       ├── events.jsonl
  │       ├── workspace.yaml
  │       └── checkpoints/
  ├── session-store.db
  └── mcp-config.json
  ```
  Session ids are UUIDs; `copilot --resume=<uuid>` resumes a specific one.
  https://jonmagic.com/posts/github-copilot-session-search-and-resume-cli/
- `github/copilot-cli` issue #3551 (feature request, filed 2026-05-28),
  quoting the CLI's own behavior: **"~/.copilot/session-state/{id}/events.jsonl"**
  is written "for every session." https://github.com/github/copilot-cli/issues/3551

**Important discrepancy vs. the script:** `copilot_cli_discover()` currently
checks `history-session-state/` (correct — legacy) and `sessions/`
(**not attested anywhere** — no changelog entry, doc, blog post, or issue
across ~15 sources ever mentions a `~/.copilot/sessions/` path; one AI-generated
DeepWiki page asserted it but DeepWiki is not a primary source and is
internally inconsistent — a sibling DeepWiki page instead correctly names
`session-state/`). **The function never checks `session-state/` — the
actual current/primary directory since Oct 2025 — at all.** This looks like
a plain bug, not just an incompleteness: on a modern install, the newest
session data (`session-state/<uuid>/events.jsonl`) would never be found;
only pre-Oct-2025-created, not-yet-resumed legacy sessions under
`history-session-state/` would be seen, and even those still get migrated
away once resumed.

### Token/usage fields

- `github/copilot-cli` changelog v1.0.28 (2026-04-16 batch, entry text):
  "Session usage metrics (requests, tokens, code changes) are now persisted
  to `events.jsonl` **after each session ends**."
- Jon Magic's post shows a concrete example line shape:
  `"modelMetrics":{"gpt-5.4":{"usage":{"inputTokens":192048}}}`
- The changelog independently confirms the field-name family used elsewhere
  in the product: `"gen_ai.usage.input_tokens"` / `"gen_ai.usage.cache_read.input_tokens"`
  in emitted OTel spans (v1.0.6x era), and the interactive `/context`,
  `/usage` slash commands surface the same token accounting live in the TUI.
  The script's `copilot_cli_measure()` regex
  `'"\(promptTokens\|input_tokens\|inputTokens\)":[0-9]*'` **does match**
  `"inputTokens":192048` (grep -o is nesting-agnostic), so *if* discovery
  pointed at the right `events.jsonl`, the field-name guesswork already in
  the script is reasonable — no changes needed there.

**Open question (needs live install, see §4):** the "persisted after each
session ends" wording is ambiguous about whether `events.jsonl` gets
per-turn `inputTokens` entries live (as the changelog's own `/context`/
status-line line-item, "Status line context window percentage ... using the
last call's input and output tokens instead of cumulative totals," v1.0.6x-era,
implies something is updated live) vs. only a single end-of-session rollup
(which would make `events.jsonl` useless for *mid-session* context-budget
checks — the whole point of this script). Docs say writes happen
"periodically during a session and also when the session ends," which
suggests live updates exist, but no source gives the exact write cadence or
confirms `tail -1`-style "most recent `inputTokens` occurrence = current
context size" is a valid read while a session is still running.

## 2. Session-identifying environment variables — confirmed, with a name

This is the best finding of this research: **there IS a documented,
session-identifying env var exported to shell/tool subprocesses**, found in
the official changelog (not merely inferred):

> `## 1.0.29 - 2026-04-16`
> - **Shell commands and MCP servers now receive `COPILOT_AGENT_SESSION_ID`
>   as an environment variable**

Adjacent/related env-var changelog entries (same repo, for corroboration and
to rule out decoys):

- `## 0.0.421 - 2026-03-03` — "Git hooks can detect Copilot CLI subprocesses
  via the `COPILOT_CLI=1` environment variable to skip interactive prompts."
  (presence flag, not a session id — useful as a cheap "are we inside a
  copilot-cli-spawned shell at all" pre-check, but not for pinning *which*
  session.)
- `COPILOT_HOME` — overrides the `~/.copilot` config/state root (so a
  session's state dir isn't always literally `~/.copilot`; a fully correct
  discoverer should respect `$COPILOT_HOME` if set, falling back to
  `~/.copilot`). Documented in GitHub's own CLI reference:
  https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-programmatic-reference
- `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS`, `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS`,
  `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` — unrelated opt-in gates for
  `-p` prompt mode, not session ids.
- Status-line/hook payloads separately expose `session_id` and `session_name`
  fields (JSON payload keys for hooks and the statusline script, e.g. v1.0.6x
  "Status line payload includes `session_name` field alongside `session_id`")
  — these are payload fields passed to hook *scripts*, a different channel
  than the shell-command env var, but corroborate that the CLI has a
  first-class internal session-id concept it's willing to expose externally.

I could not find any source stating the exact **relationship** between the
`COPILOT_AGENT_SESSION_ID` value and the `session-state/<uuid>/` directory
name (e.g., "they are byte-for-byte identical"), but given (a) sessions are
UUID-identified end-to-end (resume flag takes the same id,
`/session delete SESSION-ID` takes the same id, hook payloads carry the same
`session_id`), and (b) there is exactly one session-id concept threaded
through the whole product, it would be a surprising design for the exported
shell-env value to be a *different* id than the directory name. This is the
one load-bearing assumption in the recommendation below that public sources
don't nail down with a byte-level guarantee.

No env var was found for the deprecated `gh-copilot` extension (moot here —
`gh extension list` on this machine is empty and that surface is deprecated
anyway) and no *additional* CLI-specific analog of VS Code's
`VSCODE_TARGET_SESSION_LOG` was found for the standalone CLI beyond
`COPILOT_AGENT_SESSION_ID` itself.

## 3. Resume/list feature and id format

- `copilot --resume=<uuid>` / interactive `/resume` slash command; ids are
  UUIDs (v4-style, matching the `session-state/<uuid>/` directory names).
  https://docs.github.com/en/copilot/how-tos/copilot-sdk/features/session-persistence
- `/session delete SESSION-ID` also takes the same id shape.
- `session-store.db` (SQLite) has a `sessions` table with id, auto-generated
  summary, repo, branch, timestamps — a second place the id format is
  reinforced but not contradicted.

## 4. Recommendation

**Pin strategy, in priority order:**

1. If `$COPILOT_AGENT_SESSION_ID` is set in the shell the script runs in,
   use it directly: state dir = `${COPILOT_HOME:-$HOME/.copilot}/session-state/$COPILOT_AGENT_SESSION_ID/`,
   artifact = `.../events.jsonl` inside it. This is the same pattern already
   used for Claude Code (`$CLAUDE_CODE_SESSION_ID`) and Copilot-in-VS-Code
   (`$VSCODE_TARGET_SESSION_LOG` basename) — exact id, no mtime race.
2. Else, fall back to newest-mtime scanning, but **fix the scanned paths**:
   scan `${COPILOT_HOME:-$HOME/.copilot}/session-state/*/events.jsonl` (current
   format — currently missing from the script entirely) in addition to
   `history-session-state/` (legacy, pre-resume-migration only), and drop the
   unattested `sessions/` path. Document the same newest-mtime race that
   exists for the other runtimes' fallback paths.
3. Respect `$COPILOT_HOME` as an override root before defaulting to
   `~/.copilot`, since it's a documented, honored env var for relocating all
   state.

**Is this improvable from public information alone, or does it need a live
install?**

- The **directory rename/bug fix** (§1: add `session-state/`, drop
  `sessions/`, keep `history-session-state/` as legacy fallback) is backed
  by the CLI's own changelog stating the exact path strings — this can be
  fixed now, without a live install, at reasonably high confidence.
- The **env var pin** (`COPILOT_AGENT_SESSION_ID`) is backed by an explicit,
  dated first-party changelog line — also fixable now at reasonably high
  confidence for *existence* and *name*.
- What genuinely **cannot** be verified from public sources and needs a live
  `copilot` install + running session to confirm before fully trusting the
  adapter:
  1. That `$COPILOT_AGENT_SESSION_ID`'s value is exactly the `<uuid>`
     component of `session-state/<uuid>/` (assumed, not proven).
  2. Whether `events.jsonl` receives live/incremental `inputTokens` writes
     during an in-progress session (needed for mid-session WARN/STOP
     thresholds) versus only a single end-of-session summary line (which
     would make this measurement approach silently stale until the session
     ends — a much worse failure mode than the current best-effort estimate).
  3. Whether `$COPILOT_AGENT_SESSION_ID` is actually present in the specific
     execution context this script runs in — i.e., shell commands the
     *agent* issues (matches the changelog wording "shell commands ... now
     receive" the var) — as opposed to only being visible to the top-level
     CLI process itself. The changelog wording is reassuring but not a
     substitute for `env | grep COPILOT` inside an actual agent-issued shell
     call.

**Bottom line:** land the directory-path fix and the env-var pin now (both
have solid documentary backing and are a strict improvement over the current
unverified/buggy state), but keep `copilot_cli` flagged as
best-effort/unverified in the script's comments — specifically flag point
(2) above (live-write cadence of `events.jsonl`) as the one item that could
make the measurement silently wrong even after the path/pin fixes, and that
only a real install can settle.

## Sources

- `github/copilot-cli` `changelog.md` (fetched via `gh api
  repos/github/copilot-cli/contents/changelog.md`, 2827 lines, current head
  `## 1.0.73 - 2026-07-20`) — primary source for §1 (session-state rename,
  `## 0.0.342 - 2025-10-15`), §1 token persistence (`## 1.0.28`-era entry),
  §2 (`COPILOT_AGENT_SESSION_ID`, `## 1.0.29 - 2026-04-16`; `COPILOT_CLI=1`,
  `## 0.0.421 - 2026-03-03`).
- `gh api repos/github/copilot-cli` / `.../contents/` — confirms repo is
  issue-tracker-only (Shell, size 362; files: `.github/`, `LICENSE.md`,
  `README.md`, `changelog.md`, `install.sh`).
- https://docs.github.com/en/copilot/concepts/agents/copilot-cli/chronicle —
  "About GitHub Copilot CLI session data" (official docs; session-state dir,
  session-store.db, periodic writes).
- https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle
  — sibling how-to page (less detail than the concepts page).
- https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-programmatic-reference
  — `COPILOT_HOME`, `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`/`GITHUB_TOKEN`
  precedence.
- https://docs.github.com/en/copilot/how-tos/copilot-sdk/features/session-persistence
  — `--resume`/`/resume`, UUID session ids.
- https://jonmagic.com/posts/github-copilot-session-search-and-resume-cli/ —
  third-party but detailed, shows an actual inspected `~/.copilot` tree and
  an `events.jsonl` line sample with `modelMetrics.<model>.usage.inputTokens`.
- https://github.com/github/copilot-cli/issues/3551 — feature request
  quoting `~/.copilot/session-state/{id}/events.jsonl` as the per-session
  event-log path GitHub already writes.
- https://deepwiki.com/github/copilot-cli/6.2-session-state-and-lifecycle-management,
  6.4-session-state-management, 3.3-session-management-and-history,
  5.2-environment-variables — AI-generated wiki over the repo's *docs/issues*
  (not source, since there is none public); used only as a cross-check —
  **internally inconsistent** (one page says `~/.copilot/sessions/`, another
  says `session-state/`; the latter matches every other source and the
  former appears nowhere else, so treated as a DeepWiki hallucination).
- https://github.com/microsoft/vscode/issues/265446 (closed as duplicate) —
  ruled out as a *different* product surface (VS Code Copilot Chat terminal,
  not standalone CLI); confirms no `COPILOT_TERMINAL`-style var was ever
  shipped there, so no risk of confusing it with `COPILOT_AGENT_SESSION_ID`.
- Local commands run 2026-07-23 on this machine: `command -v copilot` (not
  found), `gh extension list` (empty), `ls -la ~/.copilot`, `find ~/.copilot
  -maxdepth 3` (only `ide/<lock>`, from VS Code's IDE bridge, unrelated).
