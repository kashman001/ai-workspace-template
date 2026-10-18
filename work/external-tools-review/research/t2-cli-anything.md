# T2 — CLI-Anything (`HKUDS/CLI-Anything`)

Researched 2026-10-18 against a shallow clone of `main` at `34f5195`
(github.com/HKUDS/CLI-Anything). Repo contents were read as data, none executed.
Paths below such as `cli-anything-plugin/HARNESS.md` are paths in that repo.

## What it is

- **A method plus a plugin that turns a program's source tree into a Python
  CLI.** You run `/cli-anything <local-path-or-GitHub-URL>`. The command reads
  the source and goes through a scripted pipeline: Phase 0 get the source, then
  1 codebase analysis, 2 CLI design, 3 implementation, 4–6 test plan, tests and
  results, 6.5 SKILL.md generation, 7 packaging (`cli-anything-plugin/commands/cli-anything.md`).
  Software names alone are refused. The command needs source code.
- **The method lives in one prompt file**, `cli-anything-plugin/HARNESS.md`
  (747 lines, "a standard operating procedure (SOP) ... for coding agents"). It
  sets non-negotiable rules. The CLI must call the real application to render
  ("Do NOT reimplement rendering", "Do NOT gracefully degrade"). Every command
  takes `--json`. "Fail loudly and clearly". The CLI should be idempotent where
  possible and expose `info`/`list`/`status` introspection. E2E tests must run
  the real software and check the output (magic bytes, structure). "It ran
  without errors" is not sufficient (HARNESS.md "Principles & Rules").
- **Output shape:** a Click CLI with a default REPL (it must use the bundled
  `repl_skin.py`), JSON session state with undo/redo, and a pip-installable
  package `cli-anything-<sw>` under the PEP 420 namespace `cli_anything.*`.
  The generated SKILL.md comes from `skill_generator.py`, which reads the Click
  decorators, setup.py and README and fills a Jinja2 template
  (`cli-anything-plugin/templates/SKILL.md.template`, HARNESS.md Phase 6.5).
  The SKILL.md frontmatter is just `name` and `description`.
- **MCP → CLI bridge:** `cli-anything-plugin/guides/mcp-backend.md` shows how to
  wrap an MCP server's tools as sync Python functions behind a CLI, using the
  `mcp` stdio client. This turns an MCP capability into a CLI.
- **Second product, CLI-Hub:** `pip install cli-anything-hub` gives a package
  manager (`cli-hub list/search/install/launch`) plus a "meta-skill"
  (`cli-hub-meta-skill/SKILL.md`). The registry has 79 first-party harnesses
  (`registry.json`, e.g. GIMP, Blender, LibreOffice, Zotero, Obsidian, n8n) and
  24 third-party CLIs (`public_registry.json`).
- **Runtimes:** first-class as a Claude Code plugin marketplace
  (`.claude-plugin/marketplace.json`). Ported to Cursor, Codex
  (`codex-skill/`, marked "Experimental / Community"), OpenCode
  (`opencode-commands/`), Copilot CLI (`copilot plugin install ./cli-anything-plugin`),
  plus Pi, OpenClaw, Hermes, Reasonix and Qoder (README "Pick Your Agent
  Platform"). **No Gemini CLI port** is listed. The README's roadmap still
  lists "Integration with additional agent frameworks beyond Claude Code".
- **Self-declared limits** (README "Limitations"): it needs frontier models,
  works badly when there is only a binary and no source, and often needs
  repeated `/refine` passes.
- **Signals (gh API, 2026-10-18):** Apache-2.0 (root `LICENSE` and
  `cli-anything-plugin/LICENSE`). 54.5k stars, 4.9k forks. Created 2026-03-08,
  release v0.4.0 on 2026-06-25, last push 2026-09-22. The last 8 commits are
  README edits. The last code merges are a batch on 2026-08-21. 116 open PRs,
  about 80 open issues. Top contributor `yuh-yang` has 290 commits, the next
  has 43. So it is very popular, but review throughput looks bursty and depends
  on one maintainer **(inference from commit list)**.

## What the template already has

- **The CLI-first rule:** `CONTEXT.md` "Tool & Context Loading", `docs/mcp-setup.md`
  §"Core vs. fragments" ("CLI-first: capabilities ride CLIs wherever one
  exists"), and `mcp-fragments/README.md` ("Prefer a CLI on `PATH` first"). The
  rule is stated, but **nothing says how to build a CLI when none exists.**
- **A hand-built CLI contract example:** `scripts/jev.sh` plus
  `skills/jev/SKILL.md`. It has a usage block, JSON on stdin, one JSON line per
  answer, documented exit codes, and a `--check` preflight with exit 3. This is
  the template's de facto standard for agent-facing CLIs, but it is not
  written down as a general standard.
- **The reverse direction:** `scripts/mcp/youtube_transcript_mcp.py` (launched
  by `scripts/mcp/youtube-transcript.sh`) wraps the `yt-dlp` CLI as a stdio
  **MCP server**. It has no CLI entrypoint. `docs/mcp-setup.md` calls it
  "`scripts/mcp/`'s `yt-dlp` wrapper" under CLI-first, which reads oddly
  against the code.
- **Where a new capability goes:** `docs/workspace-structure.md` "Authoring a
  Team Capability" says deterministic → `scripts/`, workflow →
  `skills/<name>/SKILL.md`, isolation → `.claude/agents/`.
- **Skill authoring:** `skills/writing-for-agents/` (style and mechanics for
  SKILL.md). `skills/create-verification-skill/` is the closest analogue: a
  vendored generator that writes a project-local `skills/verify-<app>/` skill
  driving the real app. CLI-Anything's "use the real software, verify the
  output" rule matches its spirit.
- **Vendoring with provenance:** `skills/vendored-skills.md` (MIT upstreams,
  pinned commit per SKILL.md, `scripts/sync-vendored-skills.sh`).
- **Install guidance:** `docs/recommended-tooling.md` (required and optional
  toolchain, per-runtime install).

## Gaps it would fill

1. **No written standard for an agent-facing CLI.** jev.sh shows one by
   example. HARNESS.md "Principles & Rules" gives a short, portable checklist
   the template lacks: `--json` on every command, loud errors, idempotence,
   introspection commands, and checking real output rather than the exit code.
2. **No recipe for "the capability exists only as MCP or an API, so make it a
   CLI".** `guides/mcp-backend.md` is that pattern. It would let the template
   act on its own CLI-first rule instead of adding fragments.
3. **No convention for a CLI to ship its own skill file.** CLI-Anything pairs
   every CLI with a SKILL.md so agents can find it. A template script could
   carry a sibling `skills/<name>/SKILL.md` in the same way (jev already does
   this by hand).

## Cost / risk of adopting

- **Agent-agnosticism — mixed.** The method is plain Markdown and works on any
  runtime. But the shipped generator is a Claude Code plugin first. The Codex
  port is "Experimental / Community", and there is no Gemini port. Vendoring
  the plugin would add a large Claude-shaped surface, which runs against
  `integrations-must-be-agent-agnostic`.
- **Scope mismatch.** It targets heavy GUI/desktop apps (GIMP, Blender) and
  produces a whole Python package with REPL, session/undo and PyPI layout. The
  template's needs are small bash/Python wrappers. Taking the full pipeline
  would break "simplicity first".
- **Licence:** Apache-2.0. Compatible, but it differs from the MIT texts in
  `vendored-skills.md`. Vendoring would require shipping the LICENSE and any
  NOTICE file and stating changes (Apache §4). Paraphrasing ideas needs none
  of that.
- **Maintenance:** very popular, with a large PR backlog and one dominant
  maintainer. Recent activity is mostly README edits. Pinning a vendored copy
  would need a refresh process.
- **Security (main concern):**
  - Generated code is model-written Python that calls subprocesses on real
    apps. `SECURITY.md` names prompt-injected agents passing crafted arguments
    as the threat. Its mitigations are per-harness (allowlists, escaping), so
    each generated CLI needs human review.
  - `cli-hub` fetches its registry live from
    `https://hkuds.github.io/CLI-Anything/registry.json`
    (`cli-hub/cli_hub/registry.py`). It runs each entry's `install_cmd` with
    `shell=True` whenever the string contains shell metacharacters, "so that
    ... `curl … | bash` works" (`cli-hub/cli_hub/installer.py` `_run_command`).
    At least one public entry is `curl -s https://jimeng.jianying.com/cli | bash`
    (`public_registry.json`). Using cli-hub therefore means trusting a remote
    registry with arbitrary shell.
  - `cli-hub` sends **on-by-default** PostHog analytics. It sniffs agent env
    vars and parent-process names (Claude Code, Codex, Copilot, Gemini…), and
    the opt-out is `CLI_HUB_NO_ANALYTICS=1` (`cli-hub/cli_hub/analytics.py`).
    The opt-out is disclosed only in `cli-hub/README.md` "Analytics", not in
    the root README.

## Verdict: **learn-from**

The useful part is the method, not the machinery. The HARNESS.md rules for
agent-facing CLIs (JSON everywhere, fail loudly, introspection, verify real
output) and the MCP-to-CLI wrapping pattern are portable. They fill a real gap
next to the template's CLI-first rule, and they cost a few paragraphs. The
generator itself is not worth taking. It is Claude-plugin-first and has no
Gemini path. It builds a heavyweight Python package aimed at GUI desktop apps.
Its generated code needs review anyway. Vendoring would bring Apache-2.0
obligations and refresh work. CLI-Hub should be actively avoided as a
recommendation for downloaders: it runs registry-supplied shell commands and
sends default-on telemetry. Adopters who want CLI-Anything can install it
themselves. The template should not ship or endorse it.

## Candidate recommendations

1. Add a short "Agent-facing CLI contract" section to `docs/workspace-structure.md`
   "Authoring a Team Capability": `--json`, documented exit codes, a `--check`
   preflight, loud errors, introspection, and verifying real output. Cite
   jev.sh as the example and HARNESS.md as prior art.
2. Add one line to `docs/mcp-setup.md` CLI-first: "no CLI exists → wrap the
   MCP server or API in a small script under `scripts/` before adding a
   fragment". Point to the MCP-to-CLI pattern.
3. Fix or clarify the `docs/mcp-setup.md` wording that calls the yt-dlp MCP
   server a CLI-first "wrapper". Alternatively, give `youtube_transcript_mcp.py`
   a plain CLI mode so it actually is one.
4. State the convention that a `scripts/` CLI meant for agents ships a sibling
   `skills/<name>/SKILL.md` (as jev does). Check it with `writing-for-agents`.
5. Add a backlog note: do not recommend `cli-hub` in `docs/recommended-tooling.md`,
   because of remote-registry `shell=True` installs and default-on telemetry.
   If it is ever mentioned, require `CLI_HUB_NO_ANALYTICS=1`.
