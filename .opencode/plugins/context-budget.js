// .opencode/plugins/context-budget.js
// Context-budget WARN/STOP push (ADR-0003/0004): on each user message, ask
// scripts/hooks/context-budget-opencode-hook.sh for an escalation message and
// inject it as an in-band text Part. Part MUST carry id/sessionID/messageID —
// a bare {type,text} part fails schema validation and kills the turn.
export const ContextBudget = async ({ $, directory }) => {
  const hook = `${directory}/scripts/hooks/context-budget-opencode-hook.sh`;
  return {
    "chat.message": async (input, output) => {
      try {
        const r = await $`${hook} ${input.sessionID}`.quiet().nothrow();
        const text = r.stdout.toString().trim();
        if (!text) return;
        output.parts.push({
          id: "prt_budget" + Date.now().toString(36),
          sessionID: input.sessionID,
          messageID: output.message.id,
          type: "text",
          text,
        });
      } catch {
        // fail-open: budget push must never break a turn
      }
    },
    // Session-loop supervisor exit (plan 2, Task 8). session.idle fires exactly
    // once per turn, after the assistant message completes, and the plugin lives
    // in the terminal-owning opencode process — so process.pid is the right
    // target here, the way $PPID is inside a spawned hook. Inert unless the
    // shell hook says otherwise, which needs TF_SESSION_LOOP=1.
    //
    // Proven end to end on 1.18.15 against `opencode --prompt` (the TUI form
    // launch-next-session.sh actually uses; one-shot `opencode run` cannot test
    // this, since it exits at the turn boundary anyway). The plugin's
    // process.pid was measured equal to the TUI's own pid. opencode handles the
    // SIGTERM gracefully, so the supervisor sees rc=0, not 143 — which is
    // immaterial: session-loop.sh logs rc and gates on the sentinel + counter.
    event: async ({ event }) => {
      if (event?.type !== "session.idle") return;
      try {
        // Payload shape pinned by a live probe on 1.18.15 (2026-08-27, session
        // 14): session.idle carries {id, type, properties:{sessionID}}, and that
        // sessionID is the same value chat.message gets as input.sessionID. The
        // four-spelling fallback this replaced was a guess; one spelling is now
        // a fact. See probe-results.md, "2026-08-27 — probe 1".
        const sid = event.properties?.sessionID;
        if (!sid) return;
        const r = await $`${hook} --exit-check ${sid}`.quiet().nothrow();
        if (r.stdout.toString().trim() !== "exit") return;
        process.kill(process.pid, "SIGTERM");
      } catch {
        // fail-open: a failed exit check must never break a turn
      }
    },
  };
};
