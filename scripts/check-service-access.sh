#!/usr/bin/env bash
# File: scripts/check-service-access.sh
# Purpose: Preflight that required service credentials are reachable; (re)generate
#          .service-access.local.json. Verify + INSTRUCT only — it never logs you in
#          or stores secrets. When something's missing it prints exact fix commands;
#          an AI agent or human then follows docs/runbooks/authentication.md.
#          Required services missing → exit 1 (same hard-fail distinction as
#          check-dependencies.sh). Optional services missing → warn only, exit 0.
# See: docs/workspace-structure.md → "Service Access Pattern"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
  Darwin) OS=macOS ;; Linux) OS=Linux ;; MINGW*|MSYS*|CYGWIN*) OS=Windows ;; *) OS=unknown ;;
esac
echo "Service access preflight (OS: $OS)"
status="ok"
missing_required=0

# Required services hard-fail (missing_required=1 → exit 1); optional services
# would only set status="degraded". Today GitHub is the sole — and required —
# service; add optional ones below the required block as the registry grows.

# --- GitHub (required): gh CLI present + authenticated ---
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "  ✓ gh authenticated"
  else
    echo "  ✗ gh not authenticated" >&2
    echo "    fix: gh auth login" >&2
    status="degraded"; missing_required=1
  fi
else
  echo "  ✗ gh CLI not found" >&2
  case "$OS" in
    macOS)   echo "    fix: brew install gh && gh auth login" >&2 ;;
    Linux)   echo "    fix: see https://github.com/cli/cli#installation, then gh auth login" >&2 ;;
    Windows) echo "    fix: winget install GitHub.cli  (then gh auth login)" >&2 ;;
    *)       echo "    fix: install gh, then gh auth login" >&2 ;;
  esac
  status="degraded"; missing_required=1
fi

# --- GitHub, repo-scoped (optional): one fine-grained PAT per repository ------
# Says nothing about GitHub access in general — that is the `gh` login above.
# Only about repositories wired by scripts/setup-github-repo-access.sh, each of
# which has its own credential path (a dedicated vault key + a path-scoped git
# helper). Optional by construction: a workspace that never ran that script has
# nothing wired, and this block stays silent.
#
# Nothing declares the list — it is DISCOVERED from git config, so there is no
# per-workspace configuration to edit and drift. A wired repo is one with a
# path-scoped credential.<url> section whose helper is a git-credential-* under
# ~/.local/bin; that is exactly the shape the setup script installs.
repo_scoped=$(git config --global --get-regexp '^credential\.https://github\.com/.+\.helper$' 2>/dev/null \
  | while read -r _key _val; do
      # The reset entry ("helper =", empty value) shares the key; skip it.
      [ -n "${_val:-}" ] || continue
      [ "${_val#"$HOME"/.local/bin/git-credential-}" != "$_val" ] || continue
      [ -x "$_val" ] || continue
      _slug=${_key#credential.https://github.com/}
      _slug=${_slug%.helper}
      _slug=${_slug%.git}          # both URL forms are registered; one entry each
      printf '%s\t%s\n' "$_slug" "$_val"
    done | sort -u)

repo_scoped_json=""
if [ -n "$repo_scoped" ]; then
  while IFS=$'\t' read -r slug helper; do
    [ -n "$slug" ] || continue
    owner=${slug%%/*}; name=${slug#*/}
    # Resolve the credential the way git itself would, rather than reading the
    # vault directly: this proves the whole chain (git config → helper → vault)
    # and stays correct whatever the helper does internally.
    cred=$(printf 'protocol=https\nhost=github.com\npath=%s.git\n\n' "$slug" \
             | GIT_TERMINAL_PROMPT=0 git credential fill 2>/dev/null)
    user=$(printf '%s\n' "$cred" | sed -n 's/^username=//p' | head -1)
    tok=$(printf '%s\n' "$cred" | sed -n 's/^password=//p' | head -1)
    # Rebuild the exact invocation for THIS repo, including any non-default key
    # service or helper path, so the fix line can be pasted rather than adapted.
    # The key service is recoverable from the helper the setup script wrote.
    key_service=$(sed -n 's/.*find-generic-password -s "\([^"]*\)".*/\1/p' "$helper" 2>/dev/null | head -1)
    cmd="scripts/setup-github-repo-access.sh --owner ${owner} --repo ${name}"
    [ -n "$user" ] && [ "$user" != "$owner" ] && cmd="${cmd} --user ${user}"
    [ -n "$key_service" ] && [ "$key_service" != "github-${owner}-${name}-token" ] \
      && cmd="${cmd} --key-service ${key_service}"
    [ "$helper" != "${HOME}/.local/bin/git-credential-${owner}-${name}" ] \
      && cmd="${cmd} --helper-path ${helper}"

    if [ -z "$tok" ]; then
      echo "  ✗ github:${slug} — git resolved no credential (helper or vault entry missing)" >&2
      echo "    fix: ${cmd}" >&2
      status="degraded"
    else
      # The repo may be PUBLIC, so an unauthenticated fetch succeeds with no key
      # at all — read access proves nothing. Assert push rights from the API.
      body=$(curl -s -w $'\n%{http_code}' -H "Authorization: Bearer ${tok}" \
               -H "Accept: application/vnd.github+json" \
               "https://api.github.com/repos/${slug}" 2>/dev/null || printf '\n000')
      code=$(printf '%s' "$body" | tail -1)
      case "$code" in
        200)
          push=$(printf '%s' "$body" | sed '$d' | python3 -c \
            'import json,sys; print(json.load(sys.stdin).get("permissions",{}).get("push"))' 2>/dev/null || echo "?")
          if [ "$push" = "True" ]; then
            echo "  ✓ github:${slug} token valid, push=true (repo-scoped)"
          else
            echo "  ✗ github:${slug} token reaches the repo but push=${push}" >&2
            echo "    fix: grant Contents: Read and write, then ${cmd} --rotate" >&2
            status="degraded"
          fi
          ;;
        401) echo "  ✗ github:${slug} HTTP 401 — token expired or revoked (fine-grained PATs expire)" >&2
             echo "    fix: ${cmd} --rotate" >&2
             status="degraded" ;;
        404) echo "  ✗ github:${slug} HTTP 404 — token not granted access to this repo" >&2
             echo "    fix: re-mint with 'Only select repositories' → ${name}, then ${cmd} --rotate" >&2
             status="degraded" ;;
        *)   echo "  ✗ github:${slug} HTTP ${code} from the GitHub API" >&2
             echo "    fix: retry; if it persists, ${cmd} --verify-only" >&2
             status="degraded" ;;
      esac
    fi
    repo_scoped_json="${repo_scoped_json}${repo_scoped_json:+,}
    {
      \"repo\": \"${slug}\",
      \"_scope\": \"${slug} ONLY — every other GitHub repo uses the gh login above\",
      \"tokenSource\": \"OS vault entry '${key_service:-unknown}' (account ${user:-unknown}), read via ${helper}\",
      \"verify\": \"${cmd} --verify-only\",
      \"setup\": \"${cmd} (--rotate to replace an expired key)\"
    }"
    unset cred tok
  done <<EOF
$repo_scoped
EOF
  repo_scoped_json=",
  \"github-repo-scoped\": [${repo_scoped_json}
  ]"
fi

# --- cache (gitignored) so agents don't re-discover the commands ---
cat > .service-access.local.json <<JSON
{
  "_comment": "Generated by scripts/check-service-access.sh — gitignored. Resolved retrieve/verify commands per service.",
  "github": {
    "tokenSource": "gh keychain (managed by gh auth login)",
    "verify": "gh auth status"
  }${repo_scoped_json}
}
JSON
echo "  wrote .service-access.local.json"

echo "Status: $status"
[ "$status" = "ok" ] || echo "Some services need setup — follow docs/runbooks/authentication.md" >&2
[ "$missing_required" = 0 ] || exit 1
exit 0
