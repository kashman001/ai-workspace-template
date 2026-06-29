---
description: Recursive Language Model loop — answer a query over a context too big to read into chat
argument-hint: "context=<path> query=<question>   (optional: sub_model= max_workers= max_depth=)"
---

RLM request: **$ARGUMENTS**

Execute the **rlm** skill defined in `skills/rlm/SKILL.md` — follow its loop in order
(init → probe → decompose + sub-query → aggregate + answer), using the context path and
query above. If `context=` or `query=` is missing, ask for them before running.

Hard rules from the skill: never read the whole context into the conversation (no Read tool
on the context file, no `print(content)`); let the sub-LM do semantics and Python do
counting/aggregation; batch sub-calls; return the answer via `FINAL`/`FINAL_VAR`, then echo
it to the user in the requested format.
