# 08 — Do per-role WARN/STOP thresholds earn their keep?

Type: grilling (HITL — needs the user live)
Status: resolved
Blocked by: none
Map: ../map.md

## Question

Research §2 kept one threshold pair (120K/150K in `context-budget.env`)
for all roles, flagging per-role overrides (e.g. reviewer children vs
implementer children vs primary) as "possible later but YAGNI now". The
empirical data (§1, `subagent-rollover-stats.md`) shows real children
reaching ~141.8K — inside WARN territory under the shared pair.

Decide with the user:

- What evidence would justify per-role thresholds (e.g. systematic
  role-correlated degradation before 120K, or chronic false-positive WARNs
  for short-lived roles)? Does current data meet it?
- If yes: config shape — noting the per-work-item
  `work/<proj>/context-budget.env` override already exists, so the
  question is specifically *role* keying, not per-context tuning.
- If no: record the YAGNI ruling with its revisit trigger, so the question
  stops recurring in handoffs.

## Answer

**YAGNI — per-role thresholds do not earn their keep. Thresholds stay one
shared pair, keyed to nothing but the model's dumb zone.** (Resolved with
the user live, session 27, 2026-08-06.)

**The reasoning (grilled, all four points user-confirmed):**

1. **No taxonomy to key on.** The registry's "role" schema
   (primary/auxiliary/child/superseded) is a *coordination* role; the
   ticket's motivating "roles" (reviewer vs implementer children) are
   *task* roles, which nothing in the system records — the stats had to
   pull `agentType` from claude-only `.meta.json` sidecars. Per-role
   thresholds would first require inventing and plumbing a role taxonomy.
   Decided: don't. The 120K/150K pair encodes where *the model* degrades —
   a property of the model, not of who's running it. Roles already differ
   where they should: in the *response* to crossing (primary →
   rollover-ask; child → roll-don't-resume), not in where the line sits.
2. **Evidence bar set:** only role-correlated *outcomes* justify moving
   the line — chronic mid-task `ROLLOVER_NEEDED` dispatch closures
   clustering in one role class, demonstrated quality degradation below
   120K attributable to a role, or chronic false-positive WARNs for a
   role. Size distribution alone is what the shared pair is *for*.
3. **Current data does not meet it** (`subagent-rollover-stats.md`,
   n=30): max 141.8K, median ~66.9K, 3 ≥ WARN, 0 ≥ STOP. The three WARN
   crossings were genuinely deep in the dumb zone (one closed
   `ROLLOVER_NEEDED` and the roll worked as designed) — true positives,
   not noise. Dominant pressure is *main* sessions (8/20 ≥ 120K, one at
   215K), which per-role child thresholds wouldn't touch.
4. **Revisit trigger (recorded in `docs/context-budget.md` → Thresholds):**
   reopen only if (a) dispatch records show ~3+ mid-task `ROLLOVER_NEEDED`
   closures clustering in one role class, or (b) pre-120K degradation
   attributable to a role is observed.

**Premise correction found while resolving:** the ticket text assumed the
per-work-item `work/<proj>/context-budget.env` override "already exists"
for thresholds — it exists for *relaunch knobs only*
(`launch-next-session.sh` sources it; `context-budget.sh` reads thresholds
from the global env alone). Per-item threshold plumbing remains unbuilt,
deliberately.

**Rejected alternatives:** keying by coordination role (exists but is the
wrong concept — coordination roles differ in response, not degradation
point); keying by task role (no recording surface, claude-only metadata,
new plumbing for no demonstrated outcome).
