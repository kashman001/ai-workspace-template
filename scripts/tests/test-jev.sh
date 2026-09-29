#!/usr/bin/env bash
# File: scripts/tests/test-jev.sh
# Purpose: Contract of scripts/jev.sh at its one seam, the command line, with
#          no live key and no network: a stub HTTP server (fixtures under
#          scripts/tests/fixtures/jev/) records what the CLI sends and replies
#          with a recorded response; a fake `security`/`secret-tool` on PATH
#          stands in for a keychain with no entry. Asserts stdout, stderr,
#          exit code, and the bytes the stub received — never the real
#          keychain. T8+ drive the `rlm` REPL's classify() helper through the
#          real REPL (skills/rlm/scripts/rlm_repl.py exec) against the same
#          stub, with a fake `claude` on PATH standing in for the leaf.
#          T15+ widen the CLI to Score and Noul, the S7 refusals, and --help.
#          T20 proves the JEV_DISABLED off switch (ticket 07).
#          T21+ drive the score() and check() helpers (ticket 09).
#          Spec: work/jev-integration/spec.md S2-S13, S19.
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
# with the fixture named in argv -- or, when the fixture is `echo`, with an
# answer per question: its first criterion label at confidence 1.0 -- or, when
# it is `status:<code>`, with that non-200 status and a small error body.
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
        if fixture.startswith("status:"):
            data = json.dumps({"error": {"type": "vendor_error", "message": "stub refused this request"}}).encode()
            self.send_response(int(fixture[7:])); self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data); return
        if fixture == "echo":
            qs = body["questions"] if isinstance(body, dict) else {}
            data = json.dumps({"answers": {k: {"choice": next(iter(q["criteria"])), "confidence": 1.0}
                                           for k, q in qs.items()}}).encode()
        else:
            data = open(fixture, "rb").read()
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
srv = HTTPServer(("127.0.0.1", 0), H)
open(portfile, "w").write(str(srv.server_address[1]))
srv.serve_forever()
PY
STUB_PIDS=""
trap 'kill $STUB_PIDS 2>/dev/null; rm -rf "$TMP"' EXIT
# start_stub <fixture> <name>: serves <fixture>, logs to $TMP/<name>.jsonl, prints the endpoint URL.
start_stub() {
  python3 "$TMP/stub.py" "$1" "$TMP/$2.jsonl" "$TMP/$2.port" >/dev/null 2>&1 & STUB_PIDS="$STUB_PIDS $!"; disown
  for _ in $(seq 1 50); do [ -s "$TMP/$2.port" ] && break; sleep 0.1; done
  [ -s "$TMP/$2.port" ] || { echo "stub server $2 did not start" >&2; exit 1; }
  echo "http://127.0.0.1:$(cat "$TMP/$2.port")"
}
ENDPOINT="$(start_stub "$FIX/choice-batch.json" requests)"
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
  "$(printf '%s\n' '{"key":"r0","value":"bug","confidence":1.0}' '{"key":"r1","value":"enhancement","confidence":1.0}' '{"key":"r2","value":"question","confidence":0.98}' '{"key":"r3","value":"other","confidence":0.41}' '{"key":"r4","value":"bug","confidence":0.99}' | jq -c .)"
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

echo "T6: --check with a key present (env override) — exit 0, report source"
out="$(JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" --check 2>"$TMP/t6.err")"; rc=$?
assert_eq "T6a: exit 0" "$rc" "0"
assert_contains "T6b: reports env source" "$out" "env"
assert_eq "T6c: stderr is empty" "$(cat "$TMP/t6.err")" ""
assert_absent "T6d: the key is not on stdout" "$out" "$KEY"

echo "T7: --check with a key absent — exit 3, one stderr line, empty stdout"
printf '#!/bin/sh\nexit 1\n' > "$FAKE/security"  # reset to the failing version
before="$(requests)"
out="$(env -u JEV_API_KEY JEV_ENDPOINT="$ENDPOINT" PATH="$FAKE:$PATH" "$JEV" --check 2>"$TMP/t7.err")"; rc=$?
assert_eq "T7a: exit 3" "$rc" "3"
assert_eq "T7b: empty stdout" "$out" ""
assert_eq "T7c: one stderr line" "$(wc -l < "$TMP/t7.err" | tr -d ' ')" "1"
assert_contains "T7d: names the keychain entry" "$(cat "$TMP/t7.err")" "jev-api-key"
assert_eq "T7e: no request sent" "$(requests)" "$before"
assert_absent "T7f: the key string is nowhere on stdout" "$out" "$KEY"
assert_absent "T7g: the key string is nowhere on stderr" "$(cat "$TMP/t7.err")" "$KEY"

# ---------------------------------------------------------------------------
# T8+: the rlm classify() helper, driven through the real REPL. The leaf is a
# fake `claude` on PATH that logs argv + prompt and answers `N: <label>` for
# every numbered record line; the label comes from $TMP/leaf-label.
RLM="$SRC_ROOT/skills/rlm/scripts/rlm_repl.py"
echo bug > "$TMP/leaf-label"
cat > "$FAKE/claude" <<EOF
#!/bin/sh
echo "\$*" >> "$TMP/claude.argv"
prompt=\$(cat)
printf '%s\n=====\n' "\$prompt" >> "$TMP/claude.prompts"
printf '%s\n' "\$prompt" | awk -v l="\$(cat "$TMP/leaf-label")" '/^[0-9]+: /{sub(/:.*/,""); print \$0 ": " l}'
EOF
chmod +x "$FAKE/claude"
printf 'ctx\n' > "$TMP/ctx.txt"
(cd "$TMP" && python3 "$RLM" --state "$TMP/state.pkl" init "$TMP/ctx.txt" --no-audit >/dev/null) || { echo "rlm init failed" >&2; exit 1; }
# rlm_exec: code on stdin; env for the run in RLM_ENV (a string of VAR=value words).
rlm_exec() { (cd "$TMP" && env -u JEV_API_KEY PATH="$FAKE:$PATH" $RLM_ENV python3 "$RLM" --state "$TMP/state.pkl" exec --no-audit); }
leaf_calls() { [ -f "$TMP/claude.argv" ] && wc -l < "$TMP/claude.argv" | tr -d ' ' || echo 0; }
reset_leaf() { rm -f "$TMP/claude.argv" "$TMP/claude.prompts"; }
RECORDS='["Login page throws 500 after password reset","Please add dark mode to the dashboard","How do I export my data as CSV?","The quarterly newsletter is out, read it here","Search returns stale results after an edit"]'
CATS='{"bug":"Something is broken or wrong","enhancement":"A request for new or changed behaviour","question":"Asking how something works"}'
# The prompt the skill's `N: label` pattern builds for these records (with `other` in the list).
EXPECTED_LEAF_PROMPT="$(printf '%s\n' \
  'Which category best describes each record?' \
  'Use exactly one of these categories: bug, enhancement, question, other.' \
  "Output exactly one line per record as 'N: <category>'. No extra text." \
  '' \
  '0: Login page throws 500 after password reset' \
  '1: Please add dark mode to the dashboard' \
  '2: How do I export my data as CSV?' \
  '3: The quarterly newsletter is out, read it here' \
  '4: Search returns stale results after an edit')"

echo "T8: with a key — one Jev request per batch, other appended, low-confidence record re-asked through the leaf"
reset_leaf; before="$(requests)"
out="$(RLM_ENV="JEV_ENDPOINT=$ENDPOINT JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t8.err" <<PY
import json
r = classify($RECORDS, $CATS)
print(json.dumps(r))
PY
)"; rc=$?
assert_eq "T8a: exec exits 0" "$rc" "0"
assert_eq "T8b: one Jev request for five records" "$(( $(requests) - before ))" "1"
got="$(tail -1 "$TMP/requests.jsonl")"
assert_eq "T8c: state is the record array" "$(printf '%s' "$got" | jq -c '.body.state')" "$RECORDS"
assert_eq "T8d: one Choice per record, keyed r0..r4" "$(printf '%s' "$got" | jq -c '.body.questions | keys')" '["r0","r1","r2","r3","r4"]'
assert_eq "T8e: each question references its record" "$(printf '%s' "$got" | jq -r '.body.questions | to_entries | map(. as $e | select($e.value.instructions | contains("records[" + ($e.key|ltrimstr("r")) + "]"))) | length')" "5"
assert_eq "T8f: type choice, other appended with a fixed description" "$(printf '%s' "$got" | jq -c '.body.questions.r2 | [.type, (.criteria|keys), .criteria.other]')" \
  '["choice",["bug","enhancement","other","question"],"None of the above"]'
assert_eq "T8g: the caller's descriptions are the criteria" "$(printf '%s' "$got" | jq -r '.body.questions.r0.criteria.bug')" "Something is broken or wrong"
assert_eq "T8h: model id sent" "$(printf '%s' "$got" | jq -r '.body.model')" "jev-latest"
assert_eq "T8i: labels aligned with records; r3 (0.41) fell below the default threshold (0.5) to the leaf" \
  "$(printf '%s' "$out" | head -1 | jq -c 'map([.label, .source])')" \
  '[["bug","jev"],["enhancement","jev"],["question","jev"],["bug","leaf"],["bug","jev"]]'
assert_eq "T8j: jev confidences carried, leaf has none" "$(printf '%s' "$out" | head -1 | jq -c 'map(.confidence)')" '[1.0,1.0,0.98,null,0.99]'
assert_eq "T8k: exactly one leaf call, for the one low-confidence record" "$(leaf_calls)" "1"
assert_contains "T8l: the leaf prompt numbers the record by its original index" "$(cat "$TMP/claude.prompts")" "3: The quarterly newsletter is out, read it here"
assert_absent "T8m: the leaf prompt carries no other record" "$(cat "$TMP/claude.prompts")" "dark mode"
assert_eq "T8n: nothing on stderr" "$(cat "$TMP/t8.err")" ""
assert_absent "T8o: the key is not on stdout" "$out" "$KEY"

echo "T9: the threshold — a call argument, else RLM_JEV_THRESHOLD, else the module default"
reset_leaf
out="$(RLM_ENV="JEV_ENDPOINT=$ENDPOINT JEV_API_KEY=$KEY" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["source"] for x in classify($RECORDS, $CATS, threshold=0.4)]))
PY
)"
assert_eq "T9a: threshold=0.4 (below the 0.5 default) keeps every record on jev" "$(printf '%s' "$out" | head -1)" '["jev", "jev", "jev", "jev", "jev"]'
assert_eq "T9b: no leaf call" "$(leaf_calls)" "0"
out="$(RLM_ENV="JEV_ENDPOINT=$ENDPOINT JEV_API_KEY=$KEY RLM_JEV_THRESHOLD=0.99" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["source"] for x in classify($RECORDS, $CATS)]))
PY
)"
assert_eq "T9c: RLM_JEV_THRESHOLD=0.99 sends r2 (0.98) and r3 (0.41) to the leaf" "$(printf '%s' "$out" | head -1)" '["jev", "jev", "leaf", "leaf", "jev"]'
assert_eq "T9d: the two re-asks share one leaf call" "$(leaf_calls)" "1"
out="$(RLM_ENV="JEV_ENDPOINT=$ENDPOINT JEV_API_KEY=$KEY RLM_JEV_MODEL=jev-1.13.0" rlm_exec 2>/dev/null <<PY
classify($RECORDS[:1], $CATS, threshold=0)
PY
)"
assert_eq "T9e: RLM_JEV_MODEL pins the model id" "$(tail -1 "$TMP/requests.jsonl" | jq -r '.body.model')" "jev-1.13.0"

echo "T10: no key — the current path: the skill's N: label prompt through the leaf, no request, nothing about Jev"
reset_leaf; before="$(requests)"
printf '#!/bin/sh\nexit 44\n' > "$FAKE/security"
out="$(RLM_ENV="JEV_ENDPOINT=$ENDPOINT" rlm_exec 2>"$TMP/t10.err" <<PY
import json
print(json.dumps(classify($RECORDS, $CATS)))
PY
)"; rc=$?
assert_eq "T10a: exec exits 0" "$rc" "0"
assert_eq "T10b: no request sent" "$(requests)" "$before"
assert_eq "T10c: one leaf call for the whole batch" "$(leaf_calls)" "1"
assert_eq "T10d: the leaf prompt is the skill's N: label prompt, byte for byte" "$(sed '/^=====$/,$d' "$TMP/claude.prompts")" "$EXPECTED_LEAF_PROMPT"
assert_eq "T10e: the leaf is invoked as llm_query invokes it" "$(cut -d' ' -f1-5 "$TMP/claude.argv")" "-p --model haiku --allowedTools "
assert_eq "T10f: every label from the leaf, source leaf, no confidence" "$(printf '%s' "$out" | head -1 | jq -c 'map([.label, .confidence, .source]) | unique')" '[["bug",null,"leaf"]]'
assert_eq "T10g: nothing on stderr" "$(cat "$TMP/t10.err")" ""
assert_absent "T10h: stdout never mentions Jev" "$(printf '%s' "$out" | tr 'A-Z' 'a-z')" "jev"

echo "T11: the CLI fails (exit 4) — the batch falls back to the leaf with one warning line"
reset_leaf
out="$(RLM_ENV="JEV_ENDPOINT=http://127.0.0.1:1 JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t11.err" <<PY
import json
print(json.dumps([x["source"] for x in classify($RECORDS, $CATS)]))
PY
)"; rc=$?
assert_eq "T11a: exec exits 0" "$rc" "0"
assert_eq "T11b: every record labelled by the leaf" "$(printf '%s' "$out" | head -1)" '["leaf", "leaf", "leaf", "leaf", "leaf"]'
assert_eq "T11c: one leaf call" "$(leaf_calls)" "1"
assert_eq "T11d: one warning line" "$(wc -l < "$TMP/t11.err" | tr -d ' ')" "1"
assert_contains "T11e: the warning names the fallback" "$(cat "$TMP/t11.err")" "leaf"
assert_absent "T11f: the key is not in the warning" "$(cat "$TMP/t11.err")" "$KEY"

echo "T12: malformed answers — the batch falls back to the leaf with one warning line"
reset_leaf
BAD_ENDPOINT="$(start_stub "$FIX/choice-batch-malformed.json" malformed)"
out="$(RLM_ENV="JEV_ENDPOINT=$BAD_ENDPOINT JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t12.err" <<PY
import json
print(json.dumps([x["source"] for x in classify($RECORDS, $CATS)]))
PY
)"
assert_eq "T12a: the request was made" "$(wc -l < "$TMP/malformed.jsonl" | tr -d ' ')" "1"
assert_eq "T12b: every record labelled by the leaf" "$(printf '%s' "$out" | head -1)" '["leaf", "leaf", "leaf", "leaf", "leaf"]'
assert_eq "T12c: one warning line" "$(wc -l < "$TMP/t12.err" | tr -d ' ')" "1"

echo "T13: batching — 50 records per request, split further when state + longest question nears 32k tokens"
reset_leaf
ECHO_ENDPOINT="$(start_stub echo echo)"
out="$(RLM_ENV="JEV_ENDPOINT=$ECHO_ENDPOINT JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t13.err" <<PY
import json
r = classify(["record %d" % i for i in range(120)], ["a", "b"])
print(json.dumps([len(r), sorted(set(x["label"] for x in r)), sorted(set(x["source"] for x in r))]))
PY
)"
assert_eq "T13a: 120 short records -> 3 requests" "$(wc -l < "$TMP/echo.jsonl" | tr -d ' ')" "3"
assert_eq "T13b: batch sizes 50, 50, 20" "$(jq -r '.body.state | length' "$TMP/echo.jsonl" | paste -sd, -)" "50,50,20"
assert_eq "T13c: keys restart at r0 per batch and reference the batch index" "$(sed -n 3p "$TMP/echo.jsonl" | jq -c '.body.questions | [(keys_unsorted|first), (keys_unsorted|last), .r19.instructions]')" '["r0","r19","Which category best describes each record? Classify `records[19]`."]'
assert_eq "T13d: 120 labels back, all jev, first criterion" "$(printf '%s' "$out" | head -1)" '[120, ["a"], ["jev"]]'
assert_eq "T13e: a list of categories becomes criteria described by their labels" "$(sed -n 1p "$TMP/echo.jsonl" | jq -c '.body.questions.r0.criteria')" '{"a":"a","b":"b","other":"None of the above"}'
assert_eq "T13f: no leaf call, nothing on stderr" "$(leaf_calls)/$(cat "$TMP/t13.err")" "0/"
out="$(RLM_ENV="JEV_ENDPOINT=$ECHO_ENDPOINT JEV_API_KEY=$KEY" rlm_exec 2>/dev/null <<PY
r = classify(["x" * 4000] * 100, ["a", "b"])   # ~1k tokens each: a 50-record batch would be ~50k, over the limit
print(len(r))
PY
)"
assert_eq "T13g: 100 long records -> more than the two requests plain 50-batching would send" "$(tail -n +4 "$TMP/echo.jsonl" | wc -l | tr -d ' ' | awk '{print ($1>2)?"yes":"no"}')" "yes"
assert_eq "T13h: every request's state plus one question stays under 32k estimated tokens" \
  "$(tail -n +4 "$TMP/echo.jsonl" | jq -r '.body | ((.state|tostring|length) + (.questions.r0|tostring|length)) / 4 < 32000' | sort -u)" "true"
assert_eq "T13i: 100 labels back" "$(printf '%s' "$out" | head -1)" "100"

echo "T14: llm_query is byte-for-byte unchanged (golden: fixtures/jev/llm_query.golden.py)"
python3 - "$SRC_ROOT" > "$TMP/llm_query.now.py" <<'PY'
import sys, inspect
sys.path.insert(0, sys.argv[1] + "/skills/rlm/scripts")
import rlm_repl
sys.stdout.write(inspect.getsource(rlm_repl.llm_query))
PY
if diff -u "$FIX/llm_query.golden.py" "$TMP/llm_query.now.py" > "$TMP/llm_query.diff"; then ok "T14a: no diff"; else bad "T14a: llm_query differs from the golden"; cat "$TMP/llm_query.diff" >&2; fi
rm -rf "$SRC_ROOT/skills/rlm/scripts/__pycache__"

# ---------------------------------------------------------------------------
# T15+: the CLI widened to the three question types (S5), the client-side
# limit refusals and the non-200 exit (S7).
echo "T15: a Score question passes through; the answer line carries the score and its confidence"
SCORE_ENDPOINT="$(start_stub "$FIX/score.json" score)"
SCORE_REQ='{"state":"The export button crashes the settings page in Safari. It works in Chrome.","questions":{"severity":{"type":"score","instructions":"How severe is this bug report?","criteria":["Cosmetic; no impact to functionality","Broken or degraded feature, but workaround exists","Blocking issue; no workaround exists"]}}}'
out="$(printf '%s' "$SCORE_REQ" | JEV_ENDPOINT="$SCORE_ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t15.err")"; rc=$?
assert_eq "T15a: exit 0" "$rc" "0"
assert_eq "T15b: the question reached the endpoint as given" "$(tail -1 "$TMP/score.jsonl" | jq -c '.body.questions.severity | [.type, (.criteria|length)]')" '["score",3]'
assert_eq "T15c: one line: key, score as value, confidence" "$(printf '%s' "$out" | jq -c .)" '{"key":"severity","value":1.43,"confidence":0.35}'
assert_eq "T15d: nothing on stderr" "$(cat "$TMP/t15.err")" ""

echo "T16: Noul questions pass through; the answer line carries the probability and no confidence"
NOUL_ENDPOINT="$(start_stub "$FIX/noul.json" noul)"
NOUL_REQ='{"state":"I already opened ticket 4411 about this last week. Can I speak to a person?","questions":{"is_human_escalation":{"type":"noul","instructions":"Is the customer asking for a human agent?"},"is_repeat_contact":{"type":"noul","instructions":"Has the customer contacted support about this before?","criteria":{"true":"Mentions a prior attempt, ticket, or that they have asked before","false":"No sign of any previous contact"}}}}'
out="$(printf '%s' "$NOUL_REQ" | JEV_ENDPOINT="$NOUL_ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t16.err")"; rc=$?
assert_eq "T16a: exit 0" "$rc" "0"
assert_eq "T16b: both questions reached the endpoint, criteria kept" "$(tail -1 "$TMP/noul.jsonl" | jq -c '.body.questions | [keys, .is_repeat_contact.criteria.true]')" \
  '[["is_human_escalation","is_repeat_contact"],"Mentions a prior attempt, ticket, or that they have asked before"]'
assert_eq "T16c: one line per answer: probability as value, confidence null" "$(printf '%s' "$out" | jq -c .)" \
  "$(printf '%s\n' '{"key":"is_human_escalation","value":0.99,"confidence":null}' '{"key":"is_repeat_contact","value":0.93,"confidence":null}' | jq -c .)"
assert_eq "T16d: nothing on stderr" "$(cat "$TMP/t16.err")" ""

echo "T17: the published limits are refused client-side — exit 2, one stderr line, before any request"
before="$(requests)"
out="$(jq -nc '{state:"s",questions:{q:{type:"choice",instructions:"pick",criteria:([range(256)]|map({key:("o\(.)"),value:"d"})|from_entries)}}}' \
  | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t17a.err")"; rc=$?
assert_eq "T17a: 256 Choice options exit 2" "$rc" "2"
assert_eq "T17b: empty stdout" "$out" ""
assert_contains "T17c: the reason names the 255 limit" "$(cat "$TMP/t17a.err")" "255"
out="$(jq -nc '{state:"s",questions:{q:{type:"choice",instructions:"pick",criteria:([range(255)]|map({key:("o\(.)"),value:"d"})|from_entries)}}}' \
  | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>/dev/null)"; rc=$?
assert_eq "T17d: 255 options is allowed (sent, exit 0)" "$rc/$(( $(requests) - before ))" "0/1"
before="$(requests)"
out="$(python3 -c 'import json; print(json.dumps({"state": "x" * 130000, "questions": {"q": {"type": "noul", "instructions": "Is it long?"}}}))' \
  | JEV_ENDPOINT="$ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t17e.err")"; rc=$?
assert_eq "T17e: state + longest question estimated over 32k tokens exits 2" "$rc" "2"
assert_eq "T17f: empty stdout" "$out" ""
assert_contains "T17g: the reason names the token limit" "$(cat "$TMP/t17e.err")" "32"
assert_eq "T17h: one stderr line each" "$(cat "$TMP/t17a.err" "$TMP/t17e.err" | wc -l | tr -d ' ')" "2"
assert_eq "T17i: no request sent for the refusals" "$(requests)" "$before"

echo "T18: a non-200 from the server — exit 4 with the status and the body head on stderr, empty stdout"
DENY_ENDPOINT="$(start_stub status:429 deny)"
out="$(printf '%s' "$REQ" | JEV_ENDPOINT="$DENY_ENDPOINT" JEV_API_KEY="$KEY" "$JEV" 2>"$TMP/t18.err")"; rc=$?
assert_eq "T18a: exit 4" "$rc" "4"
assert_eq "T18b: empty stdout" "$out" ""
assert_contains "T18c: stderr carries the status" "$(cat "$TMP/t18.err")" "429"
assert_contains "T18d: stderr carries the body head" "$(cat "$TMP/t18.err")" "stub refused this request"
assert_eq "T18e: one stderr line" "$(wc -l < "$TMP/t18.err" | tr -d ' ')" "1"
assert_absent "T18f: the key is not on stderr" "$(cat "$TMP/t18.err")" "$KEY"
AUTH_ENDPOINT="$(start_stub status:401 unauth)"
printf '%s' "$REQ" | JEV_ENDPOINT="$AUTH_ENDPOINT" JEV_API_KEY="$KEY" "$JEV" >/dev/null 2>"$TMP/t18g.err"; rc=$?
assert_eq "T18g: 401 is also exit 4, status on stderr" "$rc/$(grep -c 401 "$TMP/t18g.err")" "4/1"

echo "T19: --help teaches the three types with a worked example each, the exit codes, the key order, and the limits"
help="$("$JEV" --help 2>&1)"
assert_eq "T19a: an example request per type" "$(printf '%s' "$help" | grep -cE '"type": ?"(choice|score|noul)"')" "3"
# Each example is a multi-line block: printf '%s' '{ ... }' | scripts/jev.sh
t19_blocks="$(printf '%s\n' "$help" | awk '/^ *printf .%s. .\{$/{b="{"; f=1; next} f && /^ *\}. \| scripts\/jev\.sh$/{print b "}"; b=""; f=0; next} f{b=b $0}')"
assert_eq "T19b: three example blocks, each valid JSON with state and questions" "$(printf '%s\n' "$t19_blocks" | while IFS= read -r l; do [ -n "$l" ] || continue; printf '%s' "$l" | jq -e '.state and .questions' >/dev/null 2>&1 && echo ok || echo bad; done | sort | uniq -c | tr -s ' ' | sed 's/^ //')" "3 ok"
for w in "exit" " 0 " " 2 " " 3 " " 4 " "JEV_API_KEY" "jev-api-key" "255" "32" "--check"; do
  assert_contains "T19c: mentions [$w]" "$help" "$w"
done

echo "T20: JEV_DISABLED — the no-key branch on a keyed machine: exit 3, one stderr line, nothing sent, keychain untouched"
# A fake security that HAS the entry and records every call, so "untouched" is observable.
printf '#!/bin/sh\ntouch "%s"\n[ "$1" = find-generic-password ] && [ "$3" = jev-api-key ] && { echo "%s"; exit 0; }\nexit 44\n' "$TMP/keychain-touched" "$KEY" > "$FAKE/security"
before="$(requests)"
out="$(printf '%s' "$REQ" | env -u JEV_API_KEY JEV_DISABLED=1 JEV_ENDPOINT="$ENDPOINT" PATH="$FAKE:$PATH" "$JEV" 2>"$TMP/t20.err")"; rc=$?
assert_eq "T20a: exit 3" "$rc" "3"
assert_eq "T20b: empty stdout" "$out" ""
assert_eq "T20c: one stderr line" "$(wc -l < "$TMP/t20.err" | tr -d ' ')" "1"
assert_contains "T20d: names the switch" "$(cat "$TMP/t20.err")" "JEV_DISABLED"
assert_eq "T20e: no request sent" "$(requests)" "$before"
assert_eq "T20f: the keychain was not read" "$([ -e "$TMP/keychain-touched" ] && echo touched || echo untouched)" "untouched"
out="$(printf '%s' "$REQ" | JEV_DISABLED=1 JEV_API_KEY="$KEY" JEV_ENDPOINT="$ENDPOINT" "$JEV" 2>"$TMP/t20g.err")"; rc=$?
assert_eq "T20g: the switch beats the env override too" "$rc/$(requests)" "3/$before"
assert_absent "T20h: the key is not on stderr" "$(cat "$TMP/t20g.err")" "$KEY"
out="$(env -u JEV_API_KEY JEV_DISABLED=1 JEV_ENDPOINT="$ENDPOINT" PATH="$FAKE:$PATH" "$JEV" --check 2>"$TMP/t20i.err")"; rc=$?
assert_eq "T20i: --check exits 3, empty stdout" "$rc/$out" "3/"
printf '%s' "$REQ" | JEV_DISABLED=0 JEV_API_KEY="$KEY" JEV_ENDPOINT="$ENDPOINT" "$JEV" >/dev/null 2>&1; rc=$?
assert_eq "T20j: JEV_DISABLED=0 is not disabled (sent, exit 0)" "$rc/$(( $(requests) - before ))" "0/1"
"$JEV" --help >/dev/null 2>&1; assert_eq "T20k: --help exits 0 regardless" "$?" "0"
assert_contains "T20l: --help documents the switch" "$("$JEV" --help 2>&1)" "JEV_DISABLED"

# ---------------------------------------------------------------------------
# T21+: the rlm score() and check() helpers (ticket 09), same harness as T8+.
printf '#!/bin/sh\nexit 44\n' > "$FAKE/security"   # T20 left a keychain with an entry; the no-key tests need none
SREC='["The whole site is down for everyone","Button label has a typo","Export fails for large files"]'
SLEVELS='["Cosmetic; no impact","Degraded, workaround exists","Blocking; no workaround"]'
CREC='["Refund me now","Thanks, all good","I want my money back","Where is my order","Cancel my plan","Nice product"]'
CCOND='The customer asks for a refund.'
SCORE_EP="$(start_stub "$FIX/score-batch.json" scorebatch)"
NOUL_EP="$(start_stub "$FIX/noul-batch.json" noulbatch)"
sreq() { [ -f "$TMP/scorebatch.jsonl" ] && wc -l < "$TMP/scorebatch.jsonl" | tr -d ' ' || echo 0; }
nreq() { [ -f "$TMP/noulbatch.jsonl" ] && wc -l < "$TMP/noulbatch.jsonl" | tr -d ' ' || echo 0; }

echo "T21: score() with a key — one Score request, criteria = the ordered levels, low-confidence record re-asked through the leaf"
reset_leaf; echo 2 > "$TMP/leaf-label"
out="$(RLM_ENV="JEV_ENDPOINT=$SCORE_EP JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t21.err" <<PY
import json
print(json.dumps(score($SREC, $SLEVELS)))
PY
)"; rc=$?
got="$(tail -1 "$TMP/scorebatch.jsonl")"
assert_eq "T21a: exec exits 0" "$rc" "0"
assert_eq "T21b: one request for three records" "$(sreq)" "1"
assert_eq "T21c: state is the record array" "$(printf '%s' "$got" | jq -c '.body.state')" "$SREC"
assert_eq "T21d: one Score per record, keyed r0..r2" "$(printf '%s' "$got" | jq -c '.body.questions | [keys, (map(.type)|unique)]')" '[["r0","r1","r2"],["score"]]'
assert_eq "T21e: criteria is the ordered level array" "$(printf '%s' "$got" | jq -c '.body.questions.r1.criteria')" "$SLEVELS"
assert_eq "T21f: each question references its record" "$(printf '%s' "$got" | jq -r '.body.questions.r2.instructions | contains("records[2]")')" "true"
assert_eq "T21g: levels/source: r1 (0.35) fell below 0.5 to the leaf, the others carry jev's value and confidence" "$(printf '%s' "$out" | head -1)" \
  '[{"level": 1.95, "confidence": 0.9, "source": "jev"}, {"level": 2, "confidence": null, "source": "leaf"}, {"level": 0.2, "confidence": 0.8, "source": "jev"}]'
assert_eq "T21h: one leaf call" "$(leaf_calls)" "1"
assert_contains "T21i: the leaf prompt numbers the record by its original index" "$(cat "$TMP/claude.prompts")" "1: Button label has a typo"
assert_absent "T21j: the leaf prompt carries no other record" "$(cat "$TMP/claude.prompts")" "site is down"
assert_eq "T21k: nothing on stderr" "$(cat "$TMP/t21.err")" ""

echo "T22: score() without a key — the N: level leaf prompt, no request, nothing about Jev"
reset_leaf; before="$(sreq)"; echo 2 > "$TMP/leaf-label"
EXPECTED_SCORE_PROMPT="$(printf '%s\n' \
  'On the scale below, where does each record fall?' \
  'Levels (0 is lowest):' \
  'Level 0: Cosmetic; no impact' \
  'Level 1: Degraded, workaround exists' \
  'Level 2: Blocking; no workaround' \
  "Output exactly one line per record as 'N: <level number>'. No extra text." \
  '' \
  '0: The whole site is down for everyone' \
  '1: Button label has a typo' \
  '2: Export fails for large files')"
out="$(RLM_ENV="JEV_ENDPOINT=$SCORE_EP" rlm_exec 2>"$TMP/t22.err" <<PY
import json
print(json.dumps(score($SREC, $SLEVELS)))
PY
)"; rc=$?
assert_eq "T22a: exec exits 0" "$rc" "0"
assert_eq "T22b: no request sent" "$(sreq)" "$before"
assert_eq "T22c: one leaf call for the whole batch" "$(leaf_calls)" "1"
assert_eq "T22d: the leaf prompt is the N: level prompt, byte for byte" "$(sed '/^=====$/,$d' "$TMP/claude.prompts")" "$EXPECTED_SCORE_PROMPT"
assert_eq "T22e: level index from the leaf, source leaf, no confidence" "$(printf '%s' "$out" | head -1 | jq -c 'map([.level, .confidence, .source]) | unique')" '[[2,null,"leaf"]]'
assert_eq "T22f: nothing on stderr" "$(cat "$TMP/t22.err")" ""
assert_absent "T22g: stdout never mentions Jev" "$(printf '%s' "$out" | tr 'A-Z' 'a-z')" "jev"
echo "Blocking; no workaround" > "$TMP/leaf-label"
out="$(RLM_ENV="JEV_ENDPOINT=$SCORE_EP" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["level"] for x in score($SREC, $SLEVELS)]))
PY
)"
assert_eq "T22h: a leaf answering with the level text parses to its index" "$(printf '%s' "$out" | head -1)" "[2, 2, 2]"
echo 7 > "$TMP/leaf-label"
out="$(RLM_ENV="JEV_ENDPOINT=$SCORE_EP" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["level"] for x in score($SREC, $SLEVELS)]))
PY
)"
assert_eq "T22i: an out-of-range or garbled leaf answer is None" "$(printf '%s' "$out" | head -1)" "[null, null, null]"

echo "T23: check() with a key — one Noul request, {value, probability, source}, fallback when |p - 0.5| < 0.25"
reset_leaf; echo yes > "$TMP/leaf-label"
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP JEV_API_KEY=$KEY" rlm_exec 2>"$TMP/t23.err" <<PY
import json
print(json.dumps(check($CREC, "$CCOND")))
PY
)"; rc=$?
got="$(tail -1 "$TMP/noulbatch.jsonl")"
assert_eq "T23a: exec exits 0" "$rc" "0"
assert_eq "T23b: one request for six records" "$(nreq)" "1"
assert_eq "T23c: one Noul per record, keyed r0..r5" "$(printf '%s' "$got" | jq -c '.body.questions | [(keys|length), (map(.type)|unique)]')" '[6,["noul"]]'
assert_eq "T23d: the condition and the record reference are in each question" "$(printf '%s' "$got" | jq -r '.body.questions.r4.instructions | contains("refund") and contains("records[4]")')" "true"
assert_eq "T23e: p=0.75 and p=0.25 sit on the margin and stay jev; 0.74, 0.26, 0.6 go to the leaf" "$(printf '%s' "$out" | head -1 | jq -c 'map(.source)')" '["jev","jev","jev","leaf","leaf","leaf"]'
assert_eq "T23f: jev answers carry value (p>=0.5) and probability" "$(printf '%s' "$out" | head -1 | jq -c '.[0:3] | map([.value, .probability])')" '[[true,0.99],[true,0.75],[false,0.25]]'
assert_eq "T23g: leaf answers carry a bool and no probability" "$(printf '%s' "$out" | head -1 | jq -c '.[3:] | map([.value, .probability]) | unique')" '[[true,null]]'
assert_eq "T23h: one leaf call for the three fallbacks" "$(leaf_calls)" "1"
assert_contains "T23i: the leaf prompt numbers them by original index" "$(cat "$TMP/claude.prompts")" "3: Where is my order"
assert_absent "T23j: the leaf prompt carries none of the jev-answered records" "$(cat "$TMP/claude.prompts")" "Refund me now"
assert_eq "T23k: nothing on stderr" "$(cat "$TMP/t23.err")" ""

echo "T24: the margin — RLM_JEV_NOUL_MARGIN, else the margin argument, else 0.25"
reset_leaf
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP JEV_API_KEY=$KEY RLM_JEV_NOUL_MARGIN=0.3" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["source"] for x in check($CREC, "$CCOND")]))
PY
)"
assert_eq "T24a: RLM_JEV_NOUL_MARGIN=0.3 moves 0.75 and 0.25 to the leaf" "$(printf '%s' "$out" | head -1)" '["jev", "leaf", "leaf", "leaf", "leaf", "leaf"]'
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP JEV_API_KEY=$KEY RLM_JEV_NOUL_MARGIN=0.05" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["source"] for x in check($CREC, "$CCOND")]))
PY
)"
assert_eq "T24b: RLM_JEV_NOUL_MARGIN=0.05 keeps every record on jev" "$(printf '%s' "$out" | head -1)" '["jev", "jev", "jev", "jev", "jev", "jev"]'
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP JEV_API_KEY=$KEY RLM_JEV_NOUL_MARGIN=0.3" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["source"] for x in check($CREC, "$CCOND", margin=0.05)]))
PY
)"
assert_eq "T24c: the margin argument beats the env" "$(printf '%s' "$out" | head -1)" '["jev", "jev", "jev", "jev", "jev", "jev"]'

echo "T25: check() without a key — the N: yes|no leaf prompt, no request, nothing about Jev"
reset_leaf; before="$(nreq)"; echo no > "$TMP/leaf-label"
EXPECTED_CHECK_PROMPT="$(printf '%s\n' \
  "Answer yes or no for each record. $CCOND" \
  "Output exactly one line per record as 'N: yes' or 'N: no'. No extra text." \
  '' \
  '0: Refund me now' \
  '1: Thanks, all good' \
  '2: I want my money back' \
  '3: Where is my order' \
  '4: Cancel my plan' \
  '5: Nice product')"
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP" rlm_exec 2>"$TMP/t25.err" <<PY
import json
print(json.dumps(check($CREC, "$CCOND")))
PY
)"; rc=$?
assert_eq "T25a: exec exits 0" "$rc" "0"
assert_eq "T25b: no request sent" "$(nreq)" "$before"
assert_eq "T25c: one leaf call" "$(leaf_calls)" "1"
assert_eq "T25d: the leaf prompt is the N: yes|no prompt, byte for byte" "$(sed '/^=====$/,$d' "$TMP/claude.prompts")" "$EXPECTED_CHECK_PROMPT"
assert_eq "T25e: value false, no probability, source leaf" "$(printf '%s' "$out" | head -1 | jq -c 'map([.value, .probability, .source]) | unique')" '[[false,null,"leaf"]]'
assert_eq "T25f: nothing on stderr" "$(cat "$TMP/t25.err")" ""
assert_absent "T25g: stdout never mentions Jev" "$(printf '%s' "$out" | tr 'A-Z' 'a-z')" "jev"
echo maybe > "$TMP/leaf-label"
out="$(RLM_ENV="JEV_ENDPOINT=$NOUL_EP" rlm_exec 2>/dev/null <<PY
import json
print(json.dumps([x["value"] for x in check($CREC[:2], "$CCOND")]))
PY
)"
assert_eq "T25h: an unparseable leaf answer is None" "$(printf '%s' "$out" | head -1)" "[null, null]"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
