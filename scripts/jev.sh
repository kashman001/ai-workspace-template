#!/usr/bin/env bash
# File: scripts/jev.sh
# Purpose: The one vendor surface for Jev (TypeSafe's typed-question model).
#          Reads a request {state, questions[, model]} as JSON on stdin, POSTs
#          it with a bearer key, prints one JSON line per answer
#          ({key, value, confidence}) on stdout. Questions pass through as
#          given (Choice, Score, Noul); the value is the typed answer. The
#          only code in the workspace that knows the endpoint or the key.
#          Key order: JEV_API_KEY (offline test / hosts with no keychain),
#          macOS `security`, Linux `secret-tool`; JEV_DISABLED=1 skips all
#          of it and takes the no-key branch. Endpoint: JEV_ENDPOINT
#          (stub in tests). Exit: 0 answered; 2 usage or a published limit
#          broken (refused before any request); 3 no key (one stderr line,
#          empty stdout); 4 non-200 (status + body head on stderr).
#          The key never appears on stdout, stderr, argv, or disk.
#          Spec: work/jev-integration/spec.md; test: scripts/tests/test-jev.sh.
set -u

JEV_MODEL_DEFAULT="jev-latest"
JEV_ENDPOINT_DEFAULT="https://api.typesafe.ai/v1/systemone"

usage() {
  cat <<'JEV_HELP'
jev.sh - ask Jev (TypeSafe's typed-question model) typed questions about a
         piece of state: pick a label, place on a scale, or judge yes/no

USAGE
  scripts/jev.sh < request.json   send one request; print one JSON line
                                  per answer
  scripts/jev.sh --check          is a key available? sends nothing, reads
                                  no stdin; exit 0 = yes, exit 3 = no
  scripts/jev.sh --help           show this text

  First time here: run --check. Exit 3 means no key; do the task without
  Jev (nothing to set up on the command line; see KEY below).

REQUEST  one JSON object on stdin
  state        any JSON value: a string, or an array/object of records.
               Refer to parts of it in instructions as `records[3]` or
               `ticket.text`.
  questions    object: question key -> {type, instructions, criteria}.
               The question key is for your code; it is not sent to the
               model. Questions are sent exactly as given.
  model        optional; default jev-latest

  Put every independent question about the same state in one request:
  they run in parallel and cannot see each other's answers.

ANSWER  one JSON line per question
  {"key": <question key>, "value": <typed answer>, "confidence": <0..1|null>}

  Confidence measures how concentrated the answer distribution is, not
  whether the workflow is correct.

QUESTION TYPES
  choice   pick one of a closed set.  value: the chosen label.
           criteria: {label: description}, up to 255 options; add an
           "other" option when nothing may fit.
  score    degree along an ordered scale.  value: the probability-weighted
           level (0 = first criterion, 1 = second, ...).
           criteria: ordered array of 2-10 level descriptions, low to high.
  noul     does a condition hold.  value: the probability of yes;
           confidence is null. A value near 0.5 means undecided, not
           "medium".  criteria: optional {"true": what a yes means,
           "false": what a no means}.

EXAMPLES  one runnable command per type, then the line it prints
          (stdin accepts multi-line JSON as shown)

  printf '%s' '{
    "state":
  "Login page throws 500 after password reset",
    "questions": {"kind": {
      "type": "choice", "instructions": "Classify the record",
      "criteria": {"bug": "Something is broken",
                   "enhancement": "A request for new behaviour",
                   "other": "None of the above"}}}
  }' | scripts/jev.sh
  {"key": "kind", "value": "bug", "confidence": 0.99}

  printf '%s' '{
    "state":
  "The export button crashes the settings page in Safari. It works in Chrome.",
    "questions": {"severity": {
      "type": "score", "instructions": "How severe is this bug report?",
      "criteria": ["Cosmetic; no impact to functionality",
                   "Broken, but a workaround exists",
                   "Blocking; no workaround"]}}
  }' | scripts/jev.sh
  {"key": "severity", "value": 1.43, "confidence": 0.35}

  printf '%s' '{
    "state":
  "I already opened ticket 4411 about this. Can I speak to a person?",
    "questions": {"wants_human": {
      "type": "noul",
      "instructions": "Is the customer asking for a human agent?"}}
  }' | scripts/jev.sh
  {"key": "wants_human", "value": 0.99, "confidence": null}

KEY
  JEV_API_KEY if set, else the OS keychain entry `jev-api-key` (macOS
  `security`, Linux `secret-tool`). The script never writes the key to
  stdout, stderr, argv, or a file. Setup: docs/service-access.md ->
  "Jev (TypeSafe)".

ENVIRONMENT
  JEV_API_KEY    the key; takes precedence over the keychain
  JEV_ENDPOINT   override the endpoint (tests); default: the live URL
  JEV_DISABLED   set to 1 to behave as if no key were present (exit 3,
                 keychain not read); keeps a corpus local on a keyed machine

LIMITS  checked here; a request that breaks one is refused, nothing is sent
  more than 255 options in one choice
  state plus the longest question over an estimated 32k tokens

EXIT STATUS
  0   answered
  2   usage error, or a limit above broken; nothing was sent
  3   no key; one line on stderr, nothing on stdout
  4   non-200 from the server; status and body head on stderr
      (429 = rate limited)

SEE ALSO
  skills/jev/SKILL.md   when Jev fits, the "other" pattern, thresholds,
                        batching, rate limits, cost
JEV_HELP
}

check_mode=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --check) check_mode=1 ;;
    *) usage >&2; exit 2 ;;
  esac
done

# The off switch: a keyed machine that must keep this corpus local. Exactly
# the no-key branch, decided before any key is looked up.
if [ "${JEV_DISABLED:-0}" != 0 ]; then
  echo "jev: disabled by JEV_DISABLED — unset it to use the key (docs/service-access.md)" >&2
  exit 3
fi

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
