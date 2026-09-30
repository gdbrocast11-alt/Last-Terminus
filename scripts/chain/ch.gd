class_name Ch
extends RefCounted
## Tiny DSL for authoring accident chains. Every helper returns a plain
## Dictionary understood by AccidentChain.

static func step(id: String, after: Array, delay: float, dur: float, acts: Array, opts := {}) -> Dictionary:
	var d := {"id": id, "after": after, "delay": delay, "dur": dur, "do": acts}
	d.merge(opts, true)
	return d


static func alt(id: String, blocked: String, delay: float, dur: float, acts: Array, opts := {}) -> Dictionary:
	var d := {"id": id, "after_blocked": [blocked], "delay": delay, "dur": dur, "do": acts}
	d.merge(opts, true)
	return d


# ---- motion
static func move(t: String, to: Variant, d: float, opts := {}) -> Dictionary:
	var a := {"a": "move", "t": t, "to": to, "d": d}
	a.merge(opts, true)
	return a


static func roll(t: String, to: Variant, d: float, axis := Vector3.RIGHT, turns := 3.0, opts := {}) -> Dictionary:
	var a := {"a": "move", "t": t, "to": to, "d": d, "spin": axis, "turns": turns, "keep_rot": true, "ease": "in_out"}
	a.merge(opts, true)
	return a


static func tip(t: String, pivot: Variant, axis: Vector3, deg: float, d: float, opts := {}) -> Dictionary:
	var a := {"a": "tip", "t": t, "pivot": pivot, "axis": axis, "deg": deg, "d": d}
	a.merge(opts, true)
	return a


static func impulse(t: String, dir: Vector3, s: float, opts := {}) -> Dictionary:
	var a := {"a": "impulse", "t": t, "dir": dir, "s": s}
	a.merge(opts, true)
	return a


# ---- presentation
static func sfx(name: String, at: Variant = null, opts := {}) -> Dictionary:
	var a := {"a": "sfx", "name": name}
	if at is Vector3:
		a["pos"] = at
	elif at != null:
		a["at"] = at
	a.merge(opts, true)
	return a


static func loop(name: String, at: String, stop_after := 0.0, opts := {}) -> Dictionary:
	var a := {"a": "loop", "name": name, "at": at}
	if stop_after > 0.0:
		a["stop_after"] = stop_after
	a.merge(opts, true)
	return a


static func fx(kind: String, at: Variant, opts := {}) -> Dictionary:
	var a := {"a": "fx", "kind": kind}
	if at is Vector3:
		a["pos"] = at
	else:
		a["at"] = at
	a.merge(opts, true)
	return a


static func light(name: String, mode: String, opts := {}) -> Dictionary:
	var a := {"a": "light", "name": name, "mode": mode}
	a.merge(opts, true)
	return a


static func cam(opts: Dictionary) -> Dictionary:
	var a := {"a": "cam"}
	a.merge(opts, true)
	return a


static func say(line: String, prio := 1, delay := 0.0) -> Dictionary:
	var a := {"a": "say", "line": line, "prio": prio}
	if delay > 0.0:
		a["at_t"] = delay
	return a


static func seq(lines: Array, prio := 1) -> Dictionary:
	return {"a": "seq", "lines": lines, "prio": prio}


static func anim(t: String, name: String, opts := {}) -> Dictionary:
	var a := {"a": "anim", "t": t, "name": name}
	a.merge(opts, true)
	return a


static func npc(n: String, cmd: String, opts := {}) -> Dictionary:
	var a := {"a": "npc", "n": n, "cmd": cmd}
	a.merge(opts, true)
	return a


static func lethal(vol: String, d: float, cause: String, style := "back") -> Dictionary:
	return {"a": "lethal", "vol": vol, "d": d, "cause": cause, "style": style}


static func kill(vol: String, who: Variant, cause: String, style := "back", opts := {}) -> Dictionary:
	var a := {"a": "kill", "vol": vol, "n": who, "cause": cause, "style": style}
	a.merge(opts, true)
	return a


static func flag(f: String, v: Variant = true) -> Dictionary:
	return {"a": "flag", "f": f, "v": v}


static func swap(t: String, scene: String, name := "") -> Dictionary:
	var a := {"a": "swap", "t": t, "scene": scene}
	if name != "":
		a["name"] = name
	return a


static func show(t: String) -> Dictionary:
	return {"a": "show", "t": t}


static func hide(t: String) -> Dictionary:
	return {"a": "hide", "t": t}


static func free_(t: String) -> Dictionary:
	return {"a": "free", "t": t}


static func fn(f: Callable) -> Dictionary:
	return {"a": "fn", "f": f}


static func state(t: String, s: String) -> Dictionary:
	return {"a": "state", "t": t, "s": s}


static func debris(at: Variant, n := 10, force := 5.0, opts := {}) -> Dictionary:
	var a := {"a": "debris", "n": n, "force": force}
	if at is Vector3:
		a["pos"] = at
	else:
		a["at"] = at
	a.merge(opts, true)
	return a


static func stinger(name: String, db := 0.0) -> Dictionary:
	return {"a": "stinger", "name": name, "db": db}


static func pickles(cmd: String, opts := {}) -> Dictionary:
	var a := {"a": "pickles", "cmd": cmd}
	a.merge(opts, true)
	return a


static func slowmo(scale := 0.3, d := 0.8) -> Dictionary:
	return {"a": "slowmo", "scale": scale, "d": d}


static func title(text: String, d := 2.0) -> Dictionary:
	return {"a": "title", "text": text, "d": d}


static func music(opts: Dictionary) -> Dictionary:
	var a := {"a": "music"}
	a.merge(opts, true)
	return a


# ---- blockers
static func held(p: String, by := "player") -> Dictionary:
	return {"k": "held", "p": p}


static func moved(p: String, min_dist := 0.6) -> Dictionary:
	return {"k": "moved", "p": p, "min": min_dist}


static func flagged(f: String) -> Dictionary:
	return {"k": "flag", "f": f}


static func is_state(p: String, s: String) -> Dictionary:
	return {"k": "state", "p": p, "s": s}


static func pickles_has(p: String) -> Dictionary:
	return {"k": "pickles_has", "p": p}


static func gone(p: String) -> Dictionary:
	return {"k": "gone", "p": p}


static func far(a: String, b: String, min_dist: float) -> Dictionary:
	return {"k": "far", "a": a, "b": b, "min": min_dist}


static func actor_away(n: String, vol: String) -> Dictionary:
	return {"k": "actor_away", "n": n, "vol": vol}


static func blocker_fn(f: Callable) -> Dictionary:
	return {"k": "fn", "f": f}
