class_name BuildUtilRuntime
extends RefCounted
## Runtime access to the material library (no editor tooling).

static var _cache: Dictionary = {}

static func material(mat_name: String) -> Material:
	if _cache.has(mat_name):
		return _cache[mat_name]
	var p := "res://materials/%s.tres" % mat_name
	var m: Material = load(p) if ResourceLoader.exists(p) else null
	_cache[mat_name] = m
	return m
