---
id: 04-linux-render-check
title: render-check.sh finds Chrome/Chromium on Linux, clear error if missing; run once on Linux
status: todo
kind: work
wave: 1
blocked_by: []
check: grep -qi 'chromium' prototype/render-check.sh
sessions: []
---

## Goal

render-check.sh finds Chrome on macOS and Linux (google-chrome, google-chrome-stable, chromium, chromium-browser; CHROME env override) and exits with a clear install message when none is found.

## Acceptance

Still works on this Mac (re-shoot one figure). Linux: run once in a Linux container if docker/podman is available; otherwise record 'Linux run pending' in RESULTS — not a pass.

## Log
