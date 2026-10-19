#!/usr/bin/env python3
"""Blinded judge: python3 judge.py <skill> <task>. One headless call scores the 3 arm outputs
(shuffled, labelled X/Y/Z) against the design.md rubric. Writes runs/judge-<skill>-<task>.{json,key}."""
import json, os, random, subprocess, sys, tempfile
skill, task = sys.argv[1:3]
here = os.path.dirname(os.path.abspath(__file__))
R = {
"unslop": ["no opener cliche ('in today's', 'I'm delighted', 'this PR introduces')",
 "none of: leverage, seamless(ly), robust, comprehensive, game-changer, paradigm shift, delve, landscape",
 "no closing filler ('don't hesitate', 'in conclusion', 'moving forward', 'let's dive in')",
 "every fact from the input survives (t2: base 2, 30s cap, 5s old, 20% jitter, tests; t3: 14 of 15, billing-sync, certificate, Thursday; t1: judge lists the input's facts)",
 "shorter than the input"],
"code-simplification": ["behaviour preserved on edge cases (t1: None user, empty/whitespace email, case-fold dedupe, order kept; t2: 10%/5% tiers at boundaries, member +5%, cap 15%; t3: stable tie order, n larger than size). Reason carefully about the code.",
 "no '== True', '.keys()' or manual index loops left",
 "fewer lines than the input",
 "no new features or renamed public names",
 "a note of one sentence or less that matches the change"],
"technical-writing": ["every supplied fact present, none invented (list the facts first)",
 "steps numbered and each starts with an imperative verb",
 "warnings/consequences sit next to the step they affect (t2: delete-before-deploy gives 401s; t3: flush cache; t1: exit code 2)",
 "no filler or marketing words",
 "uses only supplied facts (no invented flags, versions or URLs)"]}[skill]
task_text = open(f"{here}/tasks/{skill}/{task}.md").read()
arms = ["none", "dummy", "skill"]; random.shuffle(arms)
labels = dict(zip("XYZ", arms))
outs = "\n\n".join(f"=== OUTPUT {l} ===\n{open(f'{here}/runs/{skill}-{task}-{a}.txt').read()}\n=== END {l} ===" for l, a in labels.items())
crit = "\n".join(f"{i+1}. {c}" for i, c in enumerate(R))
prompt = f"""You are a strict grader. Below is a task and three candidate outputs (X, Y, Z). Score each output pass/fail on each criterion; judge only from the text.

TASK GIVEN TO THE CANDIDATES:
{task_text}

CRITERIA:
{crit}

{outs}

Reply with ONLY a JSON object: {{"X":{{"c1":true,"c2":false,...,"c5":true,"evidence":"one line"}},"Y":{{...}},"Z":{{...}}}}"""
d = tempfile.mkdtemp()
p = subprocess.run(["claude","-p","--model","claude-sonnet-5-5","--output-format","json","--tools","","--no-session-persistence",
  "--disable-slash-commands","--setting-sources","","--max-budget-usd","0.50"], input=prompt, capture_output=True, text=True, cwd=d)
res = json.loads(p.stdout)
open(f"{here}/runs/judge-{skill}-{task}.json","w").write(p.stdout)
json.dump(labels, open(f"{here}/runs/judge-{skill}-{task}.key","w"))
print(skill, task, "cost", res.get("total_cost_usd"))
