#!/usr/bin/env python3
"""Check dialogue coverage.

* every "chN_..." style line id referenced from a .gd script exists in dialogue/lines.json
* every line in lines.json has a rendered audio file
* reports lines that no script references (informational; some are looked up by prefix)
"""
import glob, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
lines = json.load(open(os.path.join(ROOT, "dialogue", "lines.json"), encoding="utf-8"))

ID_RE = re.compile(r'"((?:ch\d|gen)_[a-z0-9_]+)"')
# chain ids / engine-meta keys that share the ch<N>_ prefix but are not dialogue
NOT_LINES = {"ch1_disaster", "ch1_station", "ch3_store", "ch4_pop_up", "ch4_treadmill", "ch4_wellness", "ch6_run_deaths", "ch7_mayhem"}
refs = {}
for path in glob.glob(os.path.join(ROOT, "**", "*.gd"), recursive=True):
    rel = os.path.relpath(path, ROOT)
    if rel.startswith(("addons/", ".godot/", "builds/")):
        continue
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        for m in ID_RE.finditer(raw):
            refs.setdefault(m.group(1), []).append(f"{rel}:{n}")

missing = []
for rid, where in sorted(refs.items()):
    if rid in lines or rid in NOT_LINES:
        continue
    # ids that are prefixes of a family (e.g. "ch6_res_beam" + "_01") are looked up dynamically
    if any(k.startswith(rid) for k in lines):
        continue
    missing.append((rid, where[0]))

no_audio = []
for lid, meta in lines.items():
    spk = meta.get("s") or meta.get("speaker") or ""
    p = os.path.join(ROOT, "audio", "voice", spk, lid + ".ogg")
    if not os.path.exists(p):
        no_audio.append(lid)

unused = [k for k in lines if k not in refs and not any(r.startswith(k.rsplit("_", 1)[0]) for r in refs)]

for rid, w in missing:
    print(f"MISSING LINE  {rid}   ({w})")
for lid in no_audio:
    print(f"NO AUDIO      {lid}")
print(f"lint_lines: {len(lines)} lines, {len(refs)} referenced ids, {len(missing)} missing, {len(no_audio)} without audio, {len(unused)} unreferenced")
sys.exit(1 if missing or no_audio else 0)
