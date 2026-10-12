# IDE / app probes: steps for the user

These surfaces need a person: they run inside an editor, not a terminal the
agent can drive. Each test takes about 5 minutes. The results land in files
inside the probe clone, and the agent reads them from there.

## 0. One-time setup

In a terminal, from the workspace root:

```bash
work/runtime-session-identity/probes/make-ide-probe-clone.sh
code ~/Developer/experiments/ws-identity-probe
```

This makes a throwaway copy of the workspace at
`~/Developer/experiments/ws-identity-probe`. Every hook in the copy is
wrapped so it logs what it receives to `probe-out/`. When VS Code asks
whether to trust the folder, answer **Yes**: hooks don't run in an untrusted
folder.

## 1. Codex: VS Code extension (`openai.chatgpt`)

1. Open the Codex panel in the probe-clone window and start a **new** chat.
2. Send: `Run ./probe-env.sh codex vscode-A in the terminal and show me the output.`
3. Start a **second** new Codex chat in the same window, and send the same
   message with `vscode-B` in place of `vscode-A`.
4. Send one more short message in each chat (e.g. `ok`) so the turn hooks fire.

## 2. Copilot Chat: agent mode in VS Code

1. In the same window, open Copilot Chat and switch to **Agent** mode.
2. Send: `Run ./probe-env.sh copilot-vscode copilot-A in the terminal and show me the output.`
3. Open a second Copilot chat and repeat it with `copilot-B`.
4. Send `ok` in each chat.

## 3. Antigravity: the IDE and the app

Open the probe clone in the Antigravity IDE (and in the Antigravity app),
start two agent chats, and ask each one to run
`./probe-env.sh antigravity ag-ide-A` (then `ag-ide-B`, `ag-app-A`, and so on).
`register` will fail, because the runtime isn't supported yet. That's
expected: the env and process sections are what we need. Antigravity hooks
aren't wired yet, so `hook-*.log` stays empty for it.

## 4. Codex desktop app: optional

There's no Codex app in `/Applications`. If you use it, install it, open the
probe clone in it, and repeat step 1 with labels `app-A` and `app-B`.

## When done

Tell the agent "IDE probes done". It reads `probe-out/env.log` and
`probe-out/hook-*.log` in the clone and writes `codex-vscode.md` and
`copilot-vscode.md` (plus `gemini-ide.md` if you chose an IDE in step 3).
