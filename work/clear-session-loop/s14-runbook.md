# S14 runbook — does a cleared session start on its own? (human steps)

Spec: `spec.md` S14/S15. Two runs are needed. Each run is one real rollover
that **you** started (not `session-loop.sh`), because the launcher refuses
`--clear` under a supervisor (`supervised_stage_only`).

## 0. Leave the supervised session (once)

1. In the current session type `/exit`.
2. If `session-loop.sh` then pauses ("press Enter…"), press **Ctrl-C** to end
   the chain. Do not start the next session through it.

## 1. Start session #5 yourself

```sh
cd ~/Developer/experiments/ai-workspace-template
claude
```

Paste:

> Work item clear-session-loop - rollover session #5. Read `work/clear-session-loop/next-session.md` and continue from **First actions**.

The session does a small amount of bookkeeping, then runs
`scripts/launch-next-session.sh clear-session-loop --clear` and tells you to
press `/clear`.

## 2. Probe run 1 — the part only you can do

1. When the launcher prints `NOW PRESS /clear`, type `/clear` and press Enter.
2. **Type nothing.** Note the time and watch for 60 seconds.
3. Write down:
   - **PASS** — the assistant starts working by itself (its first action
     reads `work/clear-session-loop/next-session.md`).
   - **FAIL** — nothing happens for 60 s. Then type `go` and press Enter.
4. If it was FAIL, tell the new session so in your first message
   (e.g. `go — probe run 1: FAIL, idle for 60 s`). If PASS, say nothing; it
   will record the result from its own context.

The cleared session (#6) records run 1 in `probes.md` and continues.

## 3. Probe run 2

At session #6's rollover it runs `--clear` again. Repeat step 2 exactly.
Session #7 records run 2, applies the matching S15 doc change (PASS: a
"verified" note; FAIL: "press `/clear`, then type `go`"), and closes the item.

## If something goes wrong

- Launcher refuses `--clear` with `supervised_stage_only`: the session was
  started under `session-loop.sh`. Exit and restart it with plain `claude`.
- Launcher refuses `runtime_path_unsupported`: no `claude` process found; the
  session falls back to a normal (fresh-process) rollover. Record the run as
  not done and retry next time.
- You forget and type something right after `/clear`: that run doesn't count;
  repeat at the next rollover.
