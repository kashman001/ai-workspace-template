#!/usr/bin/env bash
# File: scripts/tests/test-jev.sh
# Purpose: Contract of scripts/jev.sh at its one seam, the command line, with
#          no live key and no network: a stub HTTP server (fixtures under
#          scripts/tests/fixtures/jev/) records what the CLI sends and replies
#          with a recorded response; a fake `security`/`secret-tool` on PATH
#          stands in for a keychain with no entry. Asserts stdout, stderr,
#          exit code, and the bytes the stub received — never the real
#          keychain. Spec: work/jev-integration/spec.md S3, S4, S6, S8, S19.
#          Self-contained: throwaway workspace in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$SRC_ROOT/scripts/tests/fixtures/jev"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"
JEV="$SRC_ROOT/scripts/jev.sh"
KEY="test-key-3f9a1c-never-printed"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_absent()   { case "$2" in *"$3"*) bad "$1 (found [$3])" ;; *) ok "$1" ;; esac; }

# Stub server: binds a free port, writes it to $TMP/port, appends one JSON
# line per request ({headers, body}) to $TMP/requests.jsonl, replies 200
# with the fixture named in argv.
cat > "$TMP/stub.py" <<'PY'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
fixture, out, portfile = sys.argv[1:4]
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try: body = json.loads(raw)
        except ValueError: body = raw.decode(errors="replace")
        with open(out, "a") as f:
            f.write(json.dumps({"path": self.path, "headers": dict(self.headers), "body": body}) + "\n")
        data = open(fixture, "rb").read()
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
srv = HTTPServer(("127.0.0.1", 0), H)
open(portfile, "w").write(str(srv.server_address[1]))
srv.serve_forever()
PY
python3 "$TMP/stub.py" "$FIX/choice-batch.json" "$TMP/requests.jsonl" "$TMP/port" &
STUB_PID=$!; disown
trap 'kill "$STUB_PID" 2>/dev/null; rm -rf "$TMP"' EXIT
for _ in $(seq 1 50); do [ -s "$TMP/port" ] && break; sleep 0.1; done
[ -s "$TMP/port" ] || { echo "stub server did not start" >&2; exit 1; }
ENDPOINT="http://127.0.0.1:$(cat "$TMP/port")"
requests() { [ -f "$TMP/requests.jsonl" ] && wc -l < "$TMP/requests.jsonl" | tr -d ' ' || echo 0; }

# A keychain with no entry: fake `security` (macOS) and `secret-tool` (Linux)
# first on PATH, both failing the way the real tools do without an item.
FAKE="$TMP/fake-bin"; mkdir -p "$FAKE"
printf '#!/bin/sh\necho "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." >&2\nexit 44\n' > "$FAKE/security"
printf '#!/bin/sh\nexit 1\n' > "$FAKE/secret-tool"
chmod +x "$FAKE/security" "$FAKE/secret-tool"

# The rlm-shaped request the spike sent: state = record array, one Choice per record.
REQ='{"state":["Login page throws 500 after password reset","Please add dark mode to the dashboard","How do I export my data as CSV?","The quarterly newsletter is out, read it here","Search returns stale results after an edit"],
"questions":{"r0":{"type":"choice","instructions":"Classify `records[0]`","criteria":{"bug":"Something is broken or wrong","enhancement":"A request for new or changed behaviour","question":"Asking how something works","other":"None of the above"}},
"r1":{"type":"choice","instructions":"Classify `records[1]`","criteria":{"bug":"Something is broken or wrong","enhancement":"A request for new or changed behaviour","question":"Asking how something works","other":"None of the above"}}}}'

echo "T1: with a key — the documented request reaches the endpoint, typed answers come back as JSON lines"
out="$(printf '%s' "$REQ" | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t1.err")"; rc=$?
err="$(cat "$TMP/t1.err")"
assert_eq "T1a: exit 0" "$rc" "0"
assert_eq "T1b: one request sent" "$(requests)" "1"
got="$(tail -1 "$TMP/requests.jsonl")"
assert_eq "T1c: bearer header carries the key" "$(printf '%s' "$got" | jq -r '.headers.Authorization')" "Bearer $KEY"
assert_eq "T1d: JSON content type" "$(printf '%s' "$got" | jq -r '.headers["Content-Type"]')" "application/json"
assert_eq "T1e: body shape {state, model, questions}" "$(printf '%s' "$got" | jq -c '.body | keys')" '["model","questions","state"]'
assert_eq "T1f: state passed through" "$(printf '%s' "$got" | jq -r '.body.state[3]')" "The quarterly newsletter is out, read it here"
assert_eq "T1g: model defaults to jev-latest" "$(printf '%s' "$got" | jq -r '.body.model')" "jev-latest"
assert_eq "T1h: questions passed through as given" "$(printf '%s' "$got" | jq -c '.body.questions.r1 | [.type, .instructions, .criteria.other]')" \
  '["choice","Classify `records[1]`","None of the above"]'
assert_eq "T1i: one JSON line per answer, key + typed value + confidence" "$(printf '%s' "$out" | jq -c .)" \
  "$(printf '%s\n' '{"key":"r0","value":"bug","confidence":1.0}' '{"key":"r1","value":"enhancement","confidence":1.0}' '{"key":"r2","value":"question","confidence":0.98}' '{"key":"r3","value":"other","confidence":0.89}' '{"key":"r4","value":"bug","confidence":0.99}' | jq -c .)"
assert_eq "T1j: nothing on stderr" "$err" ""
assert_absent "T1k: the key is not on stdout" "$out" "$KEY"
assert_absent "T1l: the key is not on stderr" "$err" "$KEY"

echo "T2: a body-carried model wins over the default"
printf '%s' "$REQ" | jq -c '. + {model: "jev-1.13.0"}' | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" >/dev/null 2>&1; rc=$?
assert_eq "T2a: exit 0" "$rc" "0"
assert_eq "T2b: model as given" "$(tail -1 "$TMP/requests.jsonl" | jq -r '.body.model')" "jev-1.13.0"

echo "T3: no key — exit 3, one stderr line naming the keychain entry, empty stdout, no request"
before="$(requests)"
out="$(printf '%s' "$REQ" | env -u JEV_API_KEY JEV_ENDPOINT="$ENDPOINT" PATH="$FAKE:$PATH" "$JEV" 2>"$TMP/t3.err")"; rc=$?
err="$(cat "$TMP/t3.err")"
assert_eq "T3a: exit 3" "$rc" "3"
assert_eq "T3b: empty stdout" "$out" ""
assert_eq "T3c: one stderr line" "$(wc -l < "$TMP/t3.err" | tr -d ' ')" "1"
assert_contains "T3d: names the keychain entry" "$err" "jev-api-key"
assert_eq "T3e: no request sent" "$(requests)" "$before"
assert_absent "T3f: the key string is nowhere on stdout" "$out" "$KEY"
assert_absent "T3g: the key string is nowhere on stderr" "$err" "$KEY"

echo "T4: the keychain is consulted when the override is unset — a fake security that has the entry"
printf '#!/bin/sh\n[ "$1" = find-generic-password ] && [ "$3" = jev-api-key ] && { echo "%s"; exit 0; }\nexit 44\n' "$KEY" > "$FAKE/security"
out="$(printf '%s' "$REQ" | env -u JEV_API_KEY JEV_ENDPOINT="$ENDPOINT" PATH="$FAKE:$PATH" "$JEV" 2>"$TMP/t4.err")"; rc=$?
assert_eq "T4a: exit 0" "$rc" "0"
assert_eq "T4b: bearer header carries the keychain key" "$(tail -1 "$TMP/requests.jsonl" | jq -r '.headers.Authorization')" "Bearer $KEY"
assert_absent "T4c: the key is not on stdout" "$out" "$KEY"
assert_absent "T4d: the key is not on stderr" "$(cat "$TMP/t4.err")" "$KEY"
assert_eq "T4e: the override wins over the keychain" \
  "$(printf '%s' "$REQ" | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="env-key" PATH="$FAKE:$PATH" "$JEV" >/dev/null 2>&1; tail -1 "$TMP/requests.jsonl" | jq -r '.headers.Authorization')" "Bearer env-key"

echo "T5: usage — a bad body or an unknown flag exits 2 before any request"
before="$(requests)"
out="$(printf 'not json' | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t5.err")"; rc=$?
assert_eq "T5a: non-JSON body exits 2" "$rc" "2"
assert_eq "T5b: empty stdout" "$out" ""
assert_contains "T5c: says why" "$(cat "$TMP/t5.err")" "JSON"
printf '{"state":"x"}' | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" >/dev/null 2>&1; assert_eq "T5d: missing questions exits 2" "$?" "2"
printf '%s' "$REQ" | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" --bogus >/dev/null 2>&1; assert_eq "T5e: unknown flag exits 2" "$?" "2"
assert_eq "T5f: no request sent" "$(requests)" "$before"
"$JEV" --help >/dev/null 2>&1; assert_eq "T5g: --help exits 0" "$?" "0"
assert_absent "T5h: the key is not in any usage text" "$("$JEV" --help 2>&1)" "$KEY"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
