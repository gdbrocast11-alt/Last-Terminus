#!/usr/bin/env python3
"""Verify every prop scene referenced by environments/*.json exists in props/props_def.json."""
import json, glob, sys
defs = json.load(open("props/props_def.json"))
bad = 0
for f in sorted(glob.glob("environments/*.json")):
    d = json.load(open(f))
    names = set()
    for p in d["props"]:
        names.add(p["name"])
        if p["scene"] not in defs:
            print(f"{f}: unknown prop scene '{p['scene']}' ({p['name']})")
            bad += 1
    if len(names) != len(d["props"]):
        print(f"{f}: duplicate prop names")
        bad += 1
print("check_levels:", "OK" if not bad else f"{bad} problems")
sys.exit(1 if bad else 0)
