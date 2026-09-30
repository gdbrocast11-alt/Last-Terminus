extends Node
## Loads every game script inside the full project (autoloads available) so parse
## errors surface with file:line. builder.tscn -- lint

func run(_args: Array) -> void:
	var bad := 0
	var total := 0
	for dir in ["res://systems", "res://scripts"]:
		for path in _scripts(dir):
			total += 1
			var s := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_REPLACE) as GDScript
			if s == null or not s.can_instantiate():
				bad += 1
				print("LINT FAIL ", path)
	print("LINT done: ", total, " scripts, ", bad, " failed")


func _scripts(dir: String) -> Array:
	var out: Array = []
	var da := DirAccess.open(dir)
	if da == null:
		return out
	for f in da.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in da.get_directories():
		out.append_array(_scripts(dir + "/" + d))
	return out
