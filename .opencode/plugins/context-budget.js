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
  };
};
