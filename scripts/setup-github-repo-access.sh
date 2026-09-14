#!/usr/bin/env bash
# File: scripts/setup-github-repo-access.sh
# Purpose: Machine-level, repo-scoped GitHub access for ONE repository.
#          Wires a fine-grained PAT held in the OS vault to git, so pushes/fetches to
#          that ONE repo resolve non-interactively (no account picker, no browser popup).
#          Every other GitHub repo keeps using whatever helper it uses today.
#          Use it when one machine holds two GitHub identities (work + personal) and
#          the generic github.com helper picks the wrong one, or prompts, on every push.
# Usage:   scripts/setup-github-repo-access.sh --owner OWNER --repo REPO [options]
#   --owner OWNER      GitHub owner (user or org) that owns the repository. Required.
#   --repo REPO        Repository name. Required.
#   --user USER        GitHub username for git/API basic-auth. Default: OWNER.
#   --email EMAIL      Commit email to pin on the clone named by --repo-path.
#                      Omit to leave that clone's identity alone.
#   --repo-path PATH   Local clone to normalize the origin URL of (and pin --email on).
#   --key-service NAME OS vault entry name. Default: github-OWNER-REPO-token.
#   --helper-path PATH Credential helper to install.
#                      Default: ~/.local/bin/git-credential-OWNER-REPO.
#   --verify-only      Check the existing setup; write nothing.
#   --rotate           Replace an existing key (expired, revoked, or mistyped).
#   -h, --help         This text.
# See:     docs/service-access.md → "GitHub — repo-scoped access (one repository)"
set -euo pipefail

log(){ printf '  %s\n' "$*"; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# ── Configuration: all of it comes in as arguments ───────────────────────────
GH_OWNER=""
GH_REPO=""
GH_USER=""
COMMIT_EMAIL=""     # empty means "leave the clone's identity alone"
KEY_SERVICE=""
HELPER_PATH=""
CLONE_PATH=""
VERIFY_ONLY=0
ROTATE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) GH_OWNER="$2"; shift 2 ;;
    --repo) GH_REPO="$2"; shift 2 ;;
    --user) GH_USER="$2"; shift 2 ;;
    --email) COMMIT_EMAIL="$2"; shift 2 ;;
    --repo-path) CLONE_PATH="$2"; shift 2 ;;
    --key-service) KEY_SERVICE="$2"; shift 2 ;;
    --helper-path) HELPER_PATH="$2"; shift 2 ;;
    --verify-only) VERIFY_ONLY=1; shift ;;
    --rotate) ROTATE=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[ -n "$GH_OWNER" ] || die "--owner is required. See --help."
[ -n "$GH_REPO" ] || die "--repo is required. See --help."
# Owner/repo land in a vault entry name, a filename, and a URL. Refuse anything
# that is not a GitHub-legal name rather than letting it through into a path.
for _v in "$GH_OWNER" "$GH_REPO"; do
  case "$_v" in
    *[!A-Za-z0-9._-]*|"") die "invalid owner/repo name '${_v}' — letters, digits, '.', '_' and '-' only." ;;
  esac
done

# Defaults derived from owner/repo. Both are overridable because a machine that
# already has an entry under another name should adopt this script without a
# rename: point --key-service/--helper-path at what is already there.
GH_USER="${GH_USER:-$GH_OWNER}"
KEY_SERVICE="${KEY_SERVICE:-github-${GH_OWNER}-${GH_REPO}-token}"
HELPER_PATH="${HELPER_PATH:-${HOME}/.local/bin/git-credential-${GH_OWNER}-${GH_REPO}}"
HELPER_NAME="$(basename "$HELPER_PATH")"

REPO_URL="https://github.com/${GH_OWNER}/${GH_REPO}.git"
API_URL="https://api.github.com/repos/${GH_OWNER}/${GH_REPO}"
TOKEN_URL="https://github.com/settings/personal-access-tokens/new"
# How to re-invoke this script for THIS repo, quoted into the messages below so
# a failure prints a command that can be pasted, not a template to fill in.
SELF_CMD="scripts/setup-github-repo-access.sh --owner ${GH_OWNER} --repo ${GH_REPO}"
[ "$GH_USER" = "$GH_OWNER" ] || SELF_CMD="${SELF_CMD} --user ${GH_USER}"

[ "$(uname -s)" = "Darwin" ] || die "macOS only (uses the login Keychain as the vault).
On Linux/WSL, store the token with secret-tool/pass and adapt the helper — see docs/service-access.md."

# The two credential.<url> sections this script owns. Both URL forms are
# registered because git matches by exact path, so a remote written without the
# .git suffix would otherwise miss.
CRED_URLS=(
  "https://github.com/${GH_OWNER}/${GH_REPO}"
  "https://github.com/${GH_OWNER}/${GH_REPO}.git"
)

# Rollback state. WIRED flips when this run writes git config; VERIFIED flips
# once the wiring is proven. Any exit in between must undo the wiring — a bad
# token that leaves git pointing at it is worse than no wiring at all, because
# every later push fails with an authentication error that looks like the
# account's fault.
WIRED=0
VERIFIED=0
unwire(){
  for u in "${CRED_URLS[@]}"; do
    git config --global --remove-section "credential.${u}" 2>/dev/null || true
  done
}
on_exit(){
  rc=$?
  if [ "$rc" -ne 0 ] && [ "$WIRED" = 1 ] && [ "$VERIFIED" = 0 ]; then
    unwire
    {
      printf '\n'
      printf 'ROLLED BACK: the git wiring this run added has been REMOVED.\n'
      printf '  Both credential sections for %s/%s are gone from ~/.gitconfig;\n' "$GH_OWNER" "$GH_REPO"
      printf '  git is back to whatever helper it used before this run.\n'
      printf '  Check with: git config --global --get-regexp %s\n' "'credential\\..*'"
      printf '\n'
      printf '  The vault entry was left ALONE on purpose — the token may be\n'
      printf '  fine and the wiring at fault. Re-run this script to try again, or\n'
      printf '  --rotate if the token itself is the suspect.\n'
    } >&2
  fi
  exit "$rc"
}
trap on_exit EXIT

# ── 1. The key itself: one canonical copy, in the login Keychain ─────────────
HAVE_KEY=0
if security find-generic-password -s "$KEY_SERVICE" -a "$GH_USER" -w >/dev/null 2>&1; then
  HAVE_KEY=1
fi

if [ "$HAVE_KEY" = 1 ] && [ "$ROTATE" = 0 ]; then
  log "vault entry '${KEY_SERVICE}' present (account ${GH_USER})"
elif [ "$VERIFY_ONLY" = 1 ]; then
  # --verify-only never writes, so --rotate has nothing to do here; say which
  # case this is rather than claiming the entry is missing when it is not.
  if [ "$HAVE_KEY" = 1 ]; then
    log "vault entry '${KEY_SERVICE}' present (account ${GH_USER}) — --verify-only, not rotating"
  else
    die "vault entry '${KEY_SERVICE}' missing — run without --verify-only to add it."
  fi
else
  if [ "$HAVE_KEY" = 1 ]; then
    # Reached only under --rotate: an entry EXISTS and is about to be replaced.
    # Saying "no entry yet" here is a lie that reads as data loss mid-rotation.
    cat <<MSG

  Replacing the existing '${KEY_SERVICE}' entry (account ${GH_USER}).
  The current value is discarded — have the replacement token ready.
MSG
  else
    cat <<MSG

  No '${KEY_SERVICE}' entry in the Keychain yet.
MSG
  fi
  cat <<MSG

  Create a FINE-GRAINED personal access token:
    ${TOKEN_URL}
      Resource owner ......... ${GH_OWNER}
      Repository access ...... Only select repositories → ${GH_OWNER}/${GH_REPO}
      Repository permissions . Contents: Read and write
                               Pull requests: Read and write
                               Metadata: Read-only (auto-selected)
      Expiration ............. 90 days

  Then paste it at the prompt below. It is read silently — it never lands in
  shell history, this terminal's scrollback, or any file on disk.

MSG
  [ -t 0 ] || die "not a TTY — run this from an interactive shell so the token can be typed, not passed as an argument."
  # Delete first, then add. `-U` locates the existing item by ALL supplied
  # attributes, so passing -l that differs from the stored label makes it miss
  # and fail with "already exists" rather than update.
  # Delete in a loop: a keychain can hold DUPLICATE items under one service, and
  # find-generic-password only ever returns the first — so a single delete can
  # leave a stale item that shadows the new key forever.
  _n=0
  while security find-generic-password -s "$KEY_SERVICE" -a "$GH_USER" >/dev/null 2>&1; do
    security delete-generic-password -s "$KEY_SERVICE" -a "$GH_USER" >/dev/null 2>&1 || break
    _n=$((_n+1)); [ "$_n" -ge 20 ] && break
  done
  [ "$_n" -gt 0 ] && log "removed ${_n} existing entr$([ "$_n" = 1 ] && echo y || echo ies)"
  security add-generic-password -s "$KEY_SERVICE" -a "$GH_USER" \
    -l "GitHub PAT — ${GH_OWNER}/${GH_REPO}" -w
  log "stored in Keychain as '${KEY_SERVICE}'"
fi

# ── 2. The credential helper (machine-level, shared by every workspace) ──────
# Installing the helper is idempotent and inert on its own: nothing consults it
# until section 4 names it in git config. Safe to do before the token is proven.
if [ "$VERIFY_ONLY" = 0 ]; then
  mkdir -p "$(dirname "$HELPER_PATH")"
  cat > "$HELPER_PATH" <<HELPER
#!/bin/sh
# git credential helper — ${GH_OWNER}/${GH_REPO} ONLY.
# Installed by scripts/setup-github-repo-access.sh; see docs/service-access.md.
# Answers only 'get'; 'store'/'erase' are no-ops so git never overwrites the
# canonical Keychain entry behind your back.
[ "\$1" = "get" ] || exit 0
token=\$(security find-generic-password -s "${KEY_SERVICE}" -a "${GH_USER}" -w 2>/dev/null) || {
  echo "${HELPER_NAME}: no '${KEY_SERVICE}' entry in the Keychain." >&2
  echo "  fix: ${SELF_CMD}" >&2
  exit 0
}
printf 'username=%s\n' "${GH_USER}"
printf 'password=%s\n' "\$token"
HELPER
  chmod 700 "$HELPER_PATH"
  log "installed helper → ${HELPER_PATH}"
fi
[ -x "$HELPER_PATH" ] || die "helper missing or not executable: ${HELPER_PATH}"

# ── 3. Verify the TOKEN — before any of it is wired to git ───────────────────
# A plain fetch proves nothing: against a public repo it succeeds with no key at
# all, and it never exercises push rights. Only an authenticated API call shows
# whether the key is live AND can write.
# This half of the verification needs no wiring at all: it is a bare API call.
# Running it here is what keeps a dead token from ever reaching ~/.gitconfig.
token="$(security find-generic-password -s "$KEY_SERVICE" -a "$GH_USER" -w 2>/dev/null || true)"
[ -n "$token" ] || die "could not read the token back out of the Keychain."
resp="$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${token}" \
         -H "Accept: application/vnd.github+json" "$API_URL" || echo 000)"
case "$resp" in
  200) : ;;
  401) die "HTTP 401 — the stored value is not a valid token (revoked, expired, or mistyped).
  A 401 means GitHub does not recognize the value at all; a 404 would mean it is
  live but not scoped to this repo.
  Create a fresh one at ${TOKEN_URL}, then replace the stored key:
      ${SELF_CMD} --rotate" ;;
  404) die "HTTP 404 — token is valid but not granted access to ${GH_OWNER}/${GH_REPO}. Check 'Only select repositories'." ;;
  *)   die "HTTP ${resp} from ${API_URL}" ;;
esac
push="$(curl -sS -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.github+json" "$API_URL" \
        | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get("permissions",{}).get("push"))')"
[ "$push" = "True" ] || die "token reaches the repo but has no push right — grant 'Contents: Read and write'."
log "token verified: ${GH_OWNER}/${GH_REPO} reachable, push=true"

# ── 4. Wire it to git — path-scoped, so ONLY this repo is affected ───────────
# Reached only once the token is known good. Undone by the EXIT trap if the
# resolution probe in section 6 does not pass.
if [ "$VERIFY_ONLY" = 0 ]; then
  WIRED=1
  for u in "${CRED_URLS[@]}"; do
    git config --global "credential.${u}.useHttpPath" true
    # Reset the inherited helper list for this URL, then append ours, so the
    # generic github.com helper (Git Credential Manager) does not also run.
    git config --global --unset-all "credential.${u}.helper" 2>/dev/null || true
    git config --global --add "credential.${u}.helper" ""
    git config --global --add "credential.${u}.helper" "$HELPER_PATH"
  done
  log "git configured for ${REPO_URL} (path-scoped)"
fi

# ── 5. Per-clone identity: canonical remote URL + the repo's commit email ────
if [ -n "$CLONE_PATH" ]; then
  [ -d "${CLONE_PATH}/.git" ] || die "not a git clone: ${CLONE_PATH}"
  cur="$(git -C "$CLONE_PATH" remote get-url origin 2>/dev/null || echo '')"
  case "$cur" in
    *"${GH_OWNER}/${GH_REPO}"*) ;;
    *) die "origin of ${CLONE_PATH} is '${cur}', not ${GH_OWNER}/${GH_REPO}" ;;
  esac
  if [ "$cur" != "$REPO_URL" ] && [ "$VERIFY_ONLY" = 0 ]; then
    git -C "$CLONE_PATH" remote set-url origin "$REPO_URL"
    log "normalized origin: ${cur} → ${REPO_URL}"
  fi
  if [ "$VERIFY_ONLY" = 0 ] && [ -n "$COMMIT_EMAIL" ]; then
    # No --email means "leave the clone's identity alone" — writing it anyway
    # would pin user.email to the empty string and break commits there.
    git -C "$CLONE_PATH" config user.email "$COMMIT_EMAIL"
    log "commit identity pinned: $(git -C "$CLONE_PATH" config user.email)"
  else
    log "clone ${CLONE_PATH}: origin=${cur} user.email=$(git -C "$CLONE_PATH" config user.email 2>/dev/null || echo unset)"
  fi
fi

# ── 6. Verify GIT resolves it — the half that needs the wiring to exist ──────
# The API call above proves the token; this proves the plumbing. It can only run
# after section 4, which is why the wiring is rolled back on failure rather than
# gated on this probe.
probe="$(printf 'protocol=https\nhost=github.com\npath=%s/%s.git\n\n' "$GH_OWNER" "$GH_REPO" \
         | GIT_TERMINAL_PROMPT=0 git credential fill 2>/dev/null | sed -n 's/^password=.*/password=<redacted>/p;s/^username=/username=/p')"
case "$probe" in
  *"username=${GH_USER}"*"password=<redacted>"*) log "git credential fill → username=${GH_USER}, password supplied from Keychain (no prompt)" ;;
  *) die "git did not resolve the credential from the Keychain. Check the [credential] sections in ~/.gitconfig." ;;
esac

VERIFIED=1
echo "OK — ${GH_OWNER}/${GH_REPO} access is wired to the Keychain, scoped to that repo only."
