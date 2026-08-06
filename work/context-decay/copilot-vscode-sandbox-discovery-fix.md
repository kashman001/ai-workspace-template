# Fix: `copilot_vscode_discover()` fails under sandboxed terminal

## Problem

In `scripts/context-budget.sh`, the `copilot_vscode_discover()` function fails
with `no session artifact found for runtime=copilot-vscode` when run from a
VS Code integrated terminal that's running under the sandboxed terminal tool
(`sandbox-runtime`).

**Root cause:** the function's fallback path (used whenever
`VSCODE_TARGET_SESSION_LOG` points at a debug-logs *directory* rather than
the `.jsonl` file directly — true on Copilot 0.58+/VS Code 1.130) globs every
entry under `~/Library/Application Support/Code/User/workspaceStorage/*/` and
greps each `workspace.json` for a cwd match:

```sh
for d in "$ws"/*/; do
  [ -f "$d/workspace.json" ] || continue
  if grep -qF "$(pwd)" "$d/workspace.json" 2>/dev/null; then
    ...
```

The sandboxed terminal blocks `readdir` on the parent `workspaceStorage/`
directory itself (`ls` on it returns `Operation not permitted`), even though
a specific known subdirectory remains readable once referenced directly. So
the glob silently expands to nothing, and discovery fails — even though the
exact file we need (`workspaceStorage/<hash>/chatSessions/<sid>.jsonl`)
exists on disk and is fully derivable without ever listing the directory.

## Fix

`VSCODE_TARGET_SESSION_LOG` already encodes the workspace-storage hash in its
own path — `.../workspaceStorage/<hash>/GitHub.copilot-chat/debug-logs/<sid>`.
Update `copilot_vscode_discover()` to derive `<hash>` directly from
`$VSCODE_TARGET_SESSION_LOG` via parameter expansion (no `readdir` needed)
and probe `workspaceStorage/<hash>/chatSessions/<sid>.jsonl` directly,
*before* falling back to the existing glob-and-grep scan (keep that as a
fallback for older builds where `VSCODE_TARGET_SESSION_LOG` isn't set or
points straight at the `.jsonl`). Sketch:

```sh
copilot_vscode_discover() {
  local t="${VSCODE_TARGET_SESSION_LOG:-}" sid="" hash=""
  if [ -n "$t" ]; then
    [ -f "$t" ] && { echo "$t"; return 0; }
    sid="$(basename "$t")"; sid="${sid%.jsonl}"
    # Fast path: hash is embedded in .../workspaceStorage/<hash>/GitHub.copilot-chat/debug-logs/<sid>
    case "$t" in
      */workspaceStorage/*/GitHub.copilot-chat/debug-logs/*)
        hash="${t#*/workspaceStorage/}"; hash="${hash%%/*}"
        ;;
    esac
    if [ -n "$hash" ]; then
      for root in "Code" "Code - Insiders" "VSCodium"; do
        local f="$HOME/Library/Application Support/$root/User/workspaceStorage/$hash/chatSessions/$sid.jsonl"
        [ -f "$f" ] && { echo "$f"; return 0; }
      done
    fi
  fi
  # ...existing glob-and-grep fallback unchanged...
}
```

## Verify

From the workspace root, in a *sandboxed* terminal (no
`requestUnsandboxedExecution`), run:

```sh
export VSCODE_TARGET_SESSION_LOG="<value from session context>"
scripts/context-budget.sh register --runtime copilot-vscode
scripts/context-budget.sh check --runtime copilot-vscode
```

It should now succeed (`method=exact`, artifact basename matching the
session id) without needing the sandbox to grant filesystem access beyond
the workspace — confirming discovery no longer depends on listing
`workspaceStorage/`. Also re-run the existing `scripts/tests/test-*` suite
for `context-budget.sh` to make sure the fallback path for older VS Code
builds (where `VSCODE_TARGET_SESSION_LOG` is the `.jsonl` file itself, or
unset) still passes.
