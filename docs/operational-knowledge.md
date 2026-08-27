<!--
File: docs/operational-knowledge.md
Purpose: Distilled rules that prevent silent failures (shell, tooling, gotchas).
Fill in: accumulate hard-won operational knowledge as you encounter it.
See: docs/workspace-structure.md → "docs/ — Workspace Documentation"
-->

# Operational Knowledge

Gotchas and rules that prevent silent failures. Each entry: the symptom, the
cause, and the rule that avoids it. Add to this as you hit new ones.

## context-budget.sh — concurrent sessions clobber the registry (measure the wrong session)

**Symptom:** `record`/`check` report far fewer tokens than the in-band hook
(e.g. 47K OK vs 128K WARN), citing another session's artifact. **Cause:** the
registry is one file per *runtime* (`.context-budget/session-claude.json`);
any concurrent same-runtime session in this workspace (including a
`claude --bg` agent) overwrites it at register, and non-register commands
prefer the registry over re-discovery. **Rule:** if another session may have
registered since yours did, pass your own transcript explicitly
(`--transcript "$HOME/.claude/projects/<slug>/<session-id>.jsonl"`), or
re-run `register` (it always re-discovers and `CLAUDE_CODE_SESSION_ID` pins
your own artifact). Root fix (session-keyed state) is designed in
`work/automatic-session-rollover/relaunch-analysis.md`.

## Claude Code — /context under-reports by ~10K until the first real message

**Symptom:** `/context all` run as a fresh session's first action shows ~10K
fewer tokens (Messages ≈ 1K) than the same command after one "Hi" (Messages
≈ 11K), reading like a startup regression. **Cause:** the harness materializes
its listing attachments — deferred-tool roster, skill listing, MCP server
instructions, agent listing — *with the first real user message*, not at
session start; `/context` is a local command and doesn't trigger them.
**Rule:** treat post-first-message numbers as the session's true floor
(~44.7K on this machine, 2026-08-06); `scripts/context-budget.sh` measures
from the transcript artifact, which includes the materialized attachments,
so its numbers are the trustworthy ones — WARN/STOP sit ~10K closer than a
pre-message `/context` suggests.

## Claude Code — EnterWorktree re-keys the session transcript path mid-session

Claude Code stores the live transcript under `~/.claude/projects/<cwd-slug>/<session-id>.jsonl`,
keyed by the session's cwd. `EnterWorktree` changes the cwd, so the transcript
**moves** to `…-experiments-ai-workspace-template--claude-worktrees-<name>/`.
Consequences (observed 2026-08-05, session 7):

- A `context-budget.sh register` done before entering the worktree stores an
  artifact path that goes stale; resolve-self finds the file missing and falls
  back to discovery in the *old* project dir — which returns the **newest other
  session's** artifact (a predecessor's 148K WARN was misattributed to a fresh
  45K session).
- Mitigation: after `EnterWorktree`, re-run `register`, or pass `--transcript`
  with the worktree-keyed path explicitly. Before acting on any surprising
  WARN/STOP, confirm the artifact is yours: `grep` it for a string unique to
  the current conversation.
- **Recurred 2026-08-21.** The failure is silent, not loud: `record` from the
  worktree did **not** error — it printed a perfectly plausible
  `tokens=135245 status=WARN` for a *different* session's artifact, 4.5K above
  this session's true 130755. A number that looks right is the whole hazard.
  Always read the `artifact=` field in the output and check the slug matches
  your cwd before believing the token count.

## Claude Code — worktree-isolated Bash guard refuses compound commands

In a worktree-isolated session (background jobs after `EnterWorktree`), the
Bash permission guard rejects compound commands — `for`-loops, `;`-chains
with redirects, unquoted globs — even when they only run tests, with "too
complex to verify that it stays inside the worktree". Hit in sessions 18
and 19 (e.g. `for t in scripts/tests/test-*.sh; do …; done`). Mitigation:
one plain command per Bash call; iterate by issuing separate calls instead
of shell loops. Also refused (usage-scenarios sessions 4–5): `git -C
<other-checkout>` redirects, `cd "$PWD" && perl -pi`, and `;`-chains
ending in `>/dev/null` — prefer the Edit tool for file rewrites and drop
output redirects; merging to main from a worktree-isolated background
session requires `ExitWorktree(keep)` first (the guard blocks any git
aimed at the shared checkout).

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

## Diff Review Workflow

Open a commit (or commit range) for review as a directory diff with
`scripts/diff-review.sh`. It wraps `git difftool --dir-diff` with the flags
that keep symlinked files from rendering as "missing" in Beyond Compare:

```bash
scripts/diff-review.sh -r repos/<repo> <sha>             # one commit in Beyond Compare
scripts/diff-review.sh -r repos/<repo> <tip> <first>~1   # a multi-commit range
scripts/diff-review.sh -t vscode -r repos/<repo> <sha>   # VS Code per-file fallback
```

Two flags are load-bearing; the script always applies them:

- **`--no-symlinks`**: when a compared commit equals the working tree, git
  populates that side with symlinks; Beyond Compare doesn't follow them, so
  files render as missing / panes misalign. The flag forces real file copies.
- **Blocking launcher (macOS)**: `bcompare` returns immediately and git deletes
  its temp dirs before Beyond Compare reads them (empty panes); the blocking
  `bcomp` launcher avoids this. The script auto-detects the blocking binary.

Select the tool with `-t`: `bc` (Beyond Compare, default), `code` (VS Code +
Compare Folders extension tree), or `vscode` (VS Code built-in per-file diff).
The script fast-fails on a bad SHA before opening any GUI.

Beyond Compare binary/path facts (this Mac): the app is
`/Applications/Beyond Compare.app`; the real CLIs are
`…/Contents/MacOS/bcomp` (the blocking helper git wants) and
`…/Contents/MacOS/BCompare`. The `/usr/local/bin/bcomp`/`bcompare` symlinks
are **not** installed and `/usr/local/bin` needs root, so bare
`bcomp`/`bcompare` don't resolve in the shell (add via `sudo ln -sf …` or
BC → *Install Command Line Tools*). Git's global `difftool.bc.path`/
`mergetool.bc.path` point straight at the app-bundle `bcomp`, so
`git difftool -t bc` resolves the tool — but that fixes the path, **not** the
symlink/temp-dir races above; still prefer `diff-review.sh` for commit-range
review.

## Codex CLI on this machine — global config pins an unavailable model

`~/.codex/config.toml` pins `gpt-5.6-terra`, which the account can't use:
bare `codex exec "..."` fails at model resolution before any repo config or
hook runs. Override per invocation (`codex exec -m gpt-5.5 "..."`) or fix the
global file. Found 2026-08-06 during the codex hook smoke check — the repo's
`.codex/config.toml` hook wiring itself was accepted fine.

## opencode run — rewrites .opencode/opencode.json as a side effect

Any `opencode run` appends a `"$schema": "https://opencode.ai/config.json"`
line to `.opencode/opencode.json`. Harmless but dirties the working tree —
don't commit it accidentally, and don't be surprised when it reappears after
each run.

## claude-in-chrome — cannot open file:// URLs

The Chrome extension refuses `file://` navigation ("browser-internal or
unparseable URL"). To preview a local HTML file in a browser-automation
session, serve it first: `python3 -m http.server <port> --bind 127.0.0.1`
from the file's directory, then navigate to `http://127.0.0.1:<port>/…`.
Kill the server when done (it's a background task otherwise).

## Worktree-isolated sessions vs. the main checkout — runtime state diverges

> **Superseded by fix (2026-08-06, session 19, issue 05):** coordination
> scripts now anchor `WORKSPACE_ROOT` to the repository (`git rev-parse
> --git-common-dir`), so registry/locks/ledger written from a worktree land
> in the main checkout, and `launch-next-session.sh` invoked from a worktree
> syncs the main checkout and launches from it. See
> `docs/context-budget.md` → "Worktrees". The first bullet below still
> applies to *tracked* files (scripts, hooks): ship, then pull.

Background/worktree sessions push tracked work to `origin/main` while the
MAIN checkout stays behind and holds all machine-local runtime state
(`.context-budget/` registry, `work/*/.active-session` locks, ledger,
`.session-seq`, live `.claude/settings.json` references). Two consequences,
both hit twice (sessions 15 and 16):

- Anything the user's live session executes (statusline script, hooks) only
  updates after `git pull --ff-only` in the main checkout — ship, then have
  the user pull.
- Never auto-relaunch a rollover successor from inside a worktree: its
  registry/locks are worktree-local and die with it. Launch the successor
  from the main checkout after pulling. *(Retired by the fix above.)*

## Ledger headings break silently — verify the count, and check the archive after prep

Two separate ledger-integrity failures inside one session (2026-08-22), both of
which passed a "looks fine" glance:

1. **A patch script spliced a whole block into the file's own comment header.**
   The script asserted its *content* but anchored its *insertion point* on
   `text.index("# Session Handoff")` — which matched the copy of that string
   inside `handoff.md`'s PURPOSE comment (`TOP. Each "# Session Handoff" block
   records…`), not the first real heading. `check-ledger.py` still printed
   **"all ledgers well-formed"**; what exposed it was the count line reading
   *"17 blocks, newest is session 79"* when 18/80 was expected.
2. **`scripts/rollover-prep.sh` emitted a bare `# Session Handoff` line** at
   line 1 of `handoff-archive.md` when it rotated blocks out. That one the gate
   *did* catch: `handoff-archive.md:1 not a well-formed session block heading`,
   exit 1.

**Rules that follow:**

- **Read `check-ledger.py`'s count line, not its verdict.** The verdict cannot
  see a heading swallowed by a comment or a surrounding block; the count can.
  Run it with `> file 2>&1; echo $?` — piping through `tail` masks the exit code.
- **A patch script must assert its insertion point as strictly as its content.**
  Anchor on a line-anchored pattern (`^# Session Handoff — <n>`), never a bare
  substring that also appears in prose or comments.
- **`rollover-prep.sh` rotates the archive unattended — check the result.** The
  skill says so; this is the failure it is warning about. Verify the archive's
  first line is a real numbered heading before committing the rollover.

**Related:** `skills/session-rollover/SKILL.md` → Verification; the standing fix
suggestion is to have `check-ledger.py` assert the block numbers form an
unbroken descending run, which would have caught failure 1 immediately.

## Workspace scripts — `die` is `exit`, so `|| true` cannot catch it

Every script here defines `die() { echo "error: $*" >&2; exit 3; }`
(`scripts/context-budget.sh`, `scripts/launch-next-session.sh`). Calling a
helper that may `die` and guarding it with `|| true` **does not work** — `exit`
terminates the shell, and `||` only sees non-zero *returns*, never an exit.

```sh
resolve_session 2>/dev/null || true      # WRONG — a die() inside still exits 3
```

This matters for any helper whose failure should be tolerable. `resolve_session`
in `context-budget.sh` dies on an undetectable runtime or a missing artifact,
which is fatal for a caller that only wanted the session id as decoration.

Run it in a **subshell**, where the `exit` is contained:

```sh
ident="$( (resolve_session >/dev/null 2>&1 && printf '%s|%s' "$RUNTIME" "$SESSION_ID") 2>/dev/null )" || true
```

Caught 2026-08-25 while writing the session-numbering plan's provenance-sidecar
snippet: the guard would have failed the counter sync — the part that matters —
because identity lookup, the decoration, could not resolve a runtime.
