# implement-spec vs. our plan system

## In plain words

Both take a set of tickets with "this one must wait for that one" links and
work through them in dependency order. **implement-spec** (Matt Pocock's,
vendored) is a one-shot build recipe: in a single session it fans tickets out to
parallel helper agents, each on its own git branch and worktree, merges them
into one integration branch, runs a code review, and closes the tickets. **Our
plans** (`/plan` + `scripts/plan.sh`) are a durable, on-disk progress board
for work that spans many sessions: a script records every status change,
work is grouped into waves with a checkpoint ("reconcile") at the end of each,
nodes can run a shell check before they count as done, and people get explicit
"needs a human" steps. Short version: implement-spec is *how to build fast in
one go*; plans are *how to keep a long effort on track across sessions*.

## Side by side

| Dimension | implement-spec | Our plans |
|---|---|---|
| Input / source of truth | A spec + its tickets in the issue tracker (`implement-spec/SKILL.md:14-16`); the tracker stays the truth | Node files under `work/<item>/plans/NN-<slug>/nodes/` are the truth; `plan.md` is prose + a rendered board (`docs/plans.md:3-9`). Created *from* tickets or a spec (`plans/SKILL.md:34-68`) |
| Graph & "frontier" | Tickets form a task graph; frontier = tickets whose blockers are done (`:20`; `to-tickets/SKILL.md:78`). No waves | Same edges, plus **waves** run strictly in order; frontier = ready todo nodes *in the lowest unfinished wave only* (`docs/plans.md:85,108-115`). A ready node in a later wave is not offered |
| Parallelism & isolation | Max concurrency: background implementer subagents, each in its own worktree + branch off an integration branch; a merger subagent merges each back (`:24,32-41`) | Nodes in one wave may run in parallel (`CONTEXT.md` glossary "Wave"); `parallel: n` and `isolated: yes` fields exist (`docs/plans.md:59,63`) but deliberately never name worktrees (`work/plans/spec.md:84-86`). I found no code that creates worktrees or branches from `isolated` — it appears to be a recorded intent only |
| State storage & writer | Ticket state lives in the tracker; branch state in git. No separate status file | Every status change goes through a `plan.sh` verb; status is never hand-edited (`plans/SKILL.md:17-26`). Subagents may only append Log lines and tick boxes (`plans/SKILL.md:167-188`) |
| Verification | Each implementer uses `tdd` (`:36`); the integration branch gets one `code-review` at the end (`:43`) | Per-node `check:` shell command; `done` refuses until it passes, `loop: N` failures → `blocked` (`docs/plans.md:90,61`). Reconcile node re-verifies every claim on disk (`plans/SKILL.md:91-97`). `plan.sh check` lints the plan itself (`docs/plans.md:133-157`) |
| Human-in-the-loop | Only upstream: `to-tickets` quizzes the user on the breakdown (`to-tickets/SKILL.md:55-69`). Implementation runs hands-off | First-class `kind: hitl` nodes; a ticket needing a person/key/spend gets one in front of it so an unattended chain stops at the question (`plans/SKILL.md:50-53`). Replans above the plan's authority become hitl nodes (`:139-145`) |
| Session / context budget | Not addressed — assumes one orchestrating session; context kept lean via "context pointers" and an optional exploration subagent writing notes outside the repo (`:22,30`) | Built for it: nodes sized to one session (`docs/plans.md:38-43`), `sync` writes a Position block into the launcher for the next session (`:96`), plans bind to `session-loop.sh` chains (`plans/SKILL.md:74-76`) |
| Review step | Mandatory `code-review` on the integration branch; one implementer fixes all findings (`:43`) | No code-review step in the plan procedures (grep of `skills/plans`, `docs/plans.md` finds none). The reconcile node's review is "is the claimed work really on disk", not code quality |
| Completion / closing | Mark draft PR ready, or close each ticket the tracker's way; report the branch; delete worktrees (`:45-47`) | Final reconcile `done` + `sync`, then hand-edit `status: closed` in `plan.md` (`plans/SKILL.md:24-26`); reconcile flips linked ticket `Status:` to resolved (`:101-102`). No branch/PR step |
| Runtime portability | Leans on Claude Code: "call the Skill tool", background subagents, worktrees (`:24,36`). `disable-model-invocation` (`:4`) | Bash 3.2 + jq script and plain-markdown skill; per-runtime table for Claude/Codex/Gemini/OpenCode/Copilot (`docs/plans.md:228-250`), model tiers mapped per runtime (`:159-184`) |

## What each does that the other doesn't

**Only implement-spec:**
- Real git isolation: one worktree + branch per ticket, a dedicated merger
  agent, an integration branch, optional draft PR (`:32-39`).
- A whole-result code review before calling it done (`:43`).
- Explicit cleanup of worktrees (`:47`).
- A shared exploration-notes folder so implementers skip re-exploring (`:30`).

**Only plans:**
- Durable, script-owned state that survives session ends and context
  compaction; `status`/`frontier`/`graph` derived on demand (`docs/plans.md:80-96`).
- Per-node executable done-checks with retry limits (`:61,90`).
- Wave checkpoints that distrust subagent claims and re-verify on disk
  (`plans/SKILL.md:84-116`).
- Human-only steps, replan authority levels (local/structural/goal), and a
  `## Replans` audit trail (`docs/plans.md:204-215`).
- Model tiers per node, mapped to each runtime's model flag (`:159-184`).

## Ideas worth borrowing

Into our plans:
1. **A review node before the last reconcile.** When `/plan create` builds a
   plan for code work, add a final-wave `work` node "Run `code-review` on the
   work since <base>; fix findings" ahead of the closing reconcile. Touches
   `skills/plans/SKILL.md` ("Create a plan", step 3). Small, no script change.
2. **Give `isolated: yes` a documented meaning.** Say in one paragraph what an
   orchestrator does with it (e.g. dispatch the child in a worktree, and the
   wave's reconcile node merges it back — implement-spec steps 4-5 and 9 as the
   recipe), keeping the plan file itself free of the word "worktree". Touches
   `skills/plans/SKILL.md` ("Subagent prompt template") and the `isolated` row
   in `docs/plans.md:63`.
3. **Shared exploration notes.** Let the subagent prompt template point at a
   per-plan notes file (e.g. `plans/NN-<slug>/notes/`) so parallel children
   don't each re-explore. Touches `skills/plans/SKILL.md` (prompt template).

Into implement-spec (as a local note, not an edit — the vendored file must
stay a clean re-copy, `implement-spec/SKILL.md:7-12`):
4. **Distrust the implementer's "done".** The merger step could re-run the
   ticket's acceptance criteria before merging, as our reconcile node does.
   Best place: a line in `skills/vendored-skills.md` next to implement-spec,
   or an upstream issue (like `upstream-issue-code-review.md`).
5. **Point users at `/plan` for multi-session work.** A routing line in
   `skills/vendored-skills.md` (or `skills/ask-matt`'s routing, if it stays
   adapted) saying implement-spec assumes one session.

## Routing rule

Use **implement-spec** when the tickets are all agent-doable code changes that
fit in one sitting and you want them built in parallel on branches. Use
**plans** when the effort spans several sessions, includes steps only a person
can do, or needs per-step checks and a durable record of where things stand —
and for code-heavy waves, a plan node may itself run implement-spec's
branch-per-ticket approach.
