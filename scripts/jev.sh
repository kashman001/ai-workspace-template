#!/usr/bin/env bash
# File: scripts/jev.sh
# Purpose: The one vendor surface for Jev (TypeSafe's typed-question model).
#          Reads a request {state, questions[, model]} as JSON on stdin, POSTs
#          it with a bearer key, prints one JSON line per answer
#          ({key, value, confidence}) on stdout. Questions pass through as
#          given (Choice, Score, Noul); the value is the typed answer. The
#          only code in the workspace that knows the endpoint or the key.
#          Key order: JEV_API_KEY (offline test / hosts with no keychain),
#          macOS `security`, Linux `secret-tool`. Endpoint: JEV_ENDPOINT
#          (stub in tests). Exit: 0 answered; 2 usage or a published limit
#          broken (refused before any request); 3 no key (one stderr line,
#          empty stdout); 4 non-200 (status + body head on stderr).
#          The key never appears on stdout, stderr, argv, or disk.
#          Spec: work/jev-integration/spec.md; test: scripts/tests/test-jev.sh.
set -u

JEV_MODEL_DEFAULT="jev-latest"
JEV_ENDPOINT_DEFAULT="https://api.typesafe.ai/v1/systemone"

usage() {
  cat <<'USAGE'
usage: scripts/jev.sh [--help] [--check] < request.json

Asks Jev (TypeSafe's typed-question model) one or more questions about a
piece of state. Reads {state, questions[, model]} as JSON on stdin and prints
one JSON line per answer: {"key": <question key>, "value": <typed answer>,
"confidence": <0..1 or null>}. Questions are sent exactly as given.

  state      any JSON value (a string, or an array/object of records; refer
             to parts of it in instructions as `records[3]` or `ticket.text`)
  questions  map of your key -> {type, instructions, criteria}; the key is
             for your code, it is not sent to the model
  model      optional; default jev-latest

Three question types, one worked example each (each line is a full request):

  choice  pick one of a closed set; value is the chosen label
          criteria: {label: description}; add an "other" option when nothing
          may fit. Up to 255 options.
  {"state":"Login page throws 500 after password reset","questions":{"kind":{"type":"choice","instructions":"Classify the record","criteria":{"bug":"Something is broken","enhancement":"A request for new behaviour","other":"None of the above"}}}}
  -> {"key": "kind", "value": "bug", "confidence": 0.99}

  score   degree along an ordered scale; value is the probability-weighted
          level (0 = first criterion, 1 = second, ...); criteria: an ordered
          array of 2-10 level descriptions, low to high
  {"state":"The export button crashes the settings page in Safari. It works in Chrome.","questions":{"severity":{"type":"score","instructions":"How severe is this bug report?","criteria":["Cosmetic; no impact to functionality","Broken, but a workaround exists","Blocking; no workaround"]}}}
  -> {"key": "severity", "value": 1.43, "confidence": 0.35}

  noul    does a condition hold; value is the probability of yes, confidence
          is null (a value near 0.5 means undecided, not "medium");
          criteria is optional: {"true": what a yes means, "false": what a no means}
  {"state":"I already opened ticket 4411 about this. Can I speak to a person?","questions":{"wants_human":{"type":"noul","instructions":"Is the customer asking for a human agent?"}}}
  -> {"key": "wants_human", "value": 0.99, "confidence": null}

Ask independent questions about the same state in one request; they run in
parallel and cannot see each other. Confidence measures how concentrated the
answer distribution is, not whether the workflow is correct.

Flags:
  --check    Verify the key is present (does not send a request); prints one
             line on stdout and exits 0 if present, or exits 3 with one line
             on stderr if absent. Reads no stdin.
  --help     Show this message.

Key: JEV_API_KEY, else the OS keychain entry `jev-api-key` (macOS security,
Linux secret-tool). Endpoint: JEV_ENDPOINT (default: the live URL).
Limits (refused here, before any request): more than 255 options in one
Choice; state plus the longest question over an estimated 32k tokens.
Exit: 0 answered, 2 usage or limit refused, 3 no key, 4 non-200 from the
server (429 = rate limited; status and body head on stderr).
Detail (the `other` pattern, thresholds, cost): skills/jev/SKILL.md.
USAGE
}

check_mode=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --check) check_mode=1 ;;
    *) usage >&2; exit 2 ;;
  esac
done

key="${JEV_API_KEY:-}"
key_source=""

if [ -n "$key" ]; then
  key_source="env"
elif command -v security >/dev/null 2>&1; then
  key="$(security find-generic-password -s jev-api-key -w 2>/dev/null)" || key=""
  [ -n "$key" ] && key_source="keychain"
fi

if [ -z "$key" ] && command -v secret-tool >/dev/null 2>&1; then
  key="$(secret-tool lookup service jev-api-key 2>/dev/null)" || key=""
  [ -n "$key" ] && key_source="keychain"
fi

if [ "$check_mode" = 1 ]; then
  if [ -n "$key" ]; then
    echo "jev: key present ($key_source)"
    exit 0
  else
    echo "jev: no API key — set JEV_API_KEY or add the keychain entry 'jev-api-key' (docs/service-access.md)" >&2
    exit 3
  fi
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

# Jev's published limits, checked before anything is sent (S7). Tokens are
# estimated as characters / 4, the same estimate the rlm helper sizes with.
for k, q in body["questions"].items():
    if isinstance(q, dict) and q.get("type") == "choice" and isinstance(q.get("criteria"), dict) \
            and len(q["criteria"]) > 255:
        die(2, "question %r has %d options; a Choice allows at most 255" % (k, len(q["criteria"])))
est = (len(json.dumps(body["state"])) + max(len(json.dumps(q)) for q in body["questions"].values())) / 4
if est > 32000:
    die(2, "state plus the longest question is ~%dk tokens; the limit is 32k per request" % (est / 1000))

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

# The typed value: Choice -> choice, Score -> score, Noul -> noul (no confidence).
for k, a in resp.get("answers", {}).items():
    value = next((a[f] for f in ("choice", "score", "noul") if f in a), None) if isinstance(a, dict) else None
    print(json.dumps({"key": k, "value": value, "confidence": a.get("confidence") if isinstance(a, dict) else None}))
PY
)
JEV_API_KEY="$key" JEV_ENDPOINT="${JEV_ENDPOINT:-$JEV_ENDPOINT_DEFAULT}" JEV_MODEL="$JEV_MODEL_DEFAULT" \
  exec python3 -c "$PY"
