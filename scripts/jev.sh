#!/usr/bin/env bash
# File: scripts/jev.sh
# Purpose: The one vendor surface for Jev (TypeSafe's typed-question model).
#          Reads a request {state, questions[, model]} as JSON on stdin, POSTs
#          it with a bearer key, prints one JSON line per answer
#          ({key, value, confidence}) on stdout. The only code in the
#          workspace that knows the endpoint or the key.
#          Key order: JEV_API_KEY (offline test / hosts with no keychain),
#          macOS `security`, Linux `secret-tool`. Endpoint: JEV_ENDPOINT
#          (stub in tests). Exit: 0 answered; 2 usage; 3 no key (one stderr
#          line, empty stdout); 4 non-200 (status + body head on stderr).
#          The key never appears on stdout, stderr, argv, or disk.
#          Spec: work/jev-integration/spec.md; test: scripts/tests/test-jev.sh.
set -u

JEV_MODEL_DEFAULT="jev-latest"
JEV_ENDPOINT_DEFAULT="https://api.typesafe.ai/v1/systemone"

usage() {
  cat <<'USAGE'
usage: scripts/jev.sh [--help] < request.json

Reads {state, questions[, model]} as JSON on stdin and prints one JSON line
per answer: {"key": <question key>, "value": <choice>, "confidence": <0..1>}.
A question is {type: "choice", instructions, criteria: {label: description}}.

  state      any JSON value (a string, or an array of records)
  questions  map of question key -> question
  model      optional; default jev-latest

Key: JEV_API_KEY, else the OS keychain entry `jev-api-key` (macOS security,
Linux secret-tool). Endpoint: JEV_ENDPOINT (default: the live URL).
Exit: 0 answered, 2 usage, 3 no key, 4 non-200 from the server.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

key="${JEV_API_KEY:-}"
if [ -z "$key" ] && command -v security >/dev/null 2>&1; then
  key="$(security find-generic-password -s jev-api-key -w 2>/dev/null)" || key=""
fi
if [ -z "$key" ] && command -v secret-tool >/dev/null 2>&1; then
  key="$(secret-tool lookup service jev-api-key 2>/dev/null)" || key=""
fi
if [ -z "$key" ]; then
  echo "jev: no API key — set JEV_API_KEY or add the keychain entry 'jev-api-key' (docs/service-access.md)" >&2
  exit 3
fi

# The request body stays on stdin; the script travels in a variable. The key
# reaches Python through the child's environment only, never argv.
PY=$(cat <<'PY'
import json, os, sys, urllib.request, urllib.error

def die(code, msg):
    print("jev: " + msg, file=sys.stderr); sys.exit(code)

try:
    body = json.load(sys.stdin)
except ValueError as e:
    die(2, "request body on stdin is not JSON: %s" % e)
if not isinstance(body, dict) or "state" not in body \
        or not isinstance(body.get("questions"), dict) or not body["questions"]:
    die(2, "request body must be an object with `state` and a non-empty `questions` map")
body.setdefault("model", os.environ["JEV_MODEL"])

req = urllib.request.Request(
    os.environ["JEV_ENDPOINT"], data=json.dumps(body).encode(),
    headers={"Authorization": "Bearer " + os.environ["JEV_API_KEY"],
             "Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        resp = json.loads(r.read())
except urllib.error.HTTPError as e:
    die(4, "HTTP %d: %s" % (e.code, e.read()[:300].decode(errors="replace")))
except urllib.error.URLError as e:
    die(4, "request failed: %s" % e.reason)

for k, a in resp.get("answers", {}).items():
    print(json.dumps({"key": k, "value": a.get("choice"), "confidence": a.get("confidence")}))
PY
)
JEV_API_KEY="$key" JEV_ENDPOINT="${JEV_ENDPOINT:-$JEV_ENDPOINT_DEFAULT}" JEV_MODEL="$JEV_MODEL_DEFAULT" \
  exec python3 -c "$PY"
