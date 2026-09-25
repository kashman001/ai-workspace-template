import json, os, subprocess, time, urllib.request, urllib.error
KEY = subprocess.check_output(["security","find-generic-password","-s","jev-api-key","-w"]).decode().strip()
URL = "https://api.typesafe.ai/v1/systemone"
def call(body):
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    t = time.time()
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read()), time.time()-t
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:600], time.time()-t
crit = {"bug":"Something is broken or wrong","enhancement":"A request for new or changed behaviour","question":"Asking how something works","other":"None of the above"}
records = ["Login page throws 500 after password reset", "Please add dark mode to the dashboard", "How do I export my data as CSV?", "The quarterly newsletter is out, read it here", "Search returns stale results after an edit"]
# 1. rlm-shaped batch: state = record array, one Choice per record
qs = {f"r{i}": {"type":"choice","instructions":f"Classify `records[{i}]`","criteria":crit} for i in range(len(records))}
s, r, dt = call({"state": records, "model": "jev-latest", "questions": qs})
print("1) batch-of-5 Choice:", s, f"{dt:.2f}s")
if s == 200:
    print("   usage:", r.get("usage"), "model:", r.get("model"))
    for k in sorted(r["answers"]): a = r["answers"][k]; print(f"   {k}: {a.get('choice'):<12} conf={a.get('confidence')} probs={ {o: round(p,3) for o,p in a.get('probabilities',{}).items()} }")
else: print("   ", r)
# 2. single record baseline latency
s, r, dt = call({"state": records[0], "model": "jev-latest", "questions": {"q": {"type":"choice","instructions":"Classify","criteria":crit}}})
print("2) single Choice:", s, f"{dt:.2f}s", (r["answers"]["q"]["choice"], r["answers"]["q"]["confidence"]) if s==200 else r)
# 3. O21 probe: 256 options (docs cap 255)
big = {f"opt{i}": f"option {i}" for i in range(256)}
s, r, dt = call({"state": "x", "model": "jev-latest", "questions": {"q": {"type":"choice","instructions":"pick","criteria":big}}})
print("3) 256 options:", s, f"{dt:.2f}s", (r if s!=200 else "accepted"))
# 4. O21 probe: instructions omitted (docs: required; spec: optional)
s, r, dt = call({"state": records[1], "model": "jev-latest", "questions": {"q": {"type":"choice","criteria":crit}}})
print("4) no instructions:", s, f"{dt:.2f}s", (r["answers"]["q"]["choice"], r["answers"]["q"]["confidence"]) if s==200 else r)
