extends Node
## Bakes characters/*.glb into scenes/characters/*.tscn with library materials applied.
## builder.tscn -- characters

func run(_args: Array) -> void:
	var da := DirAccess.open("res://characters")
	var n := 0
	for f in da.get_files():
		if not f.ends_with(".glb"):
			continue
		var id := f.get_basename()
		var packed: PackedScene = load("res://characters/" + f)
		var inst: Node3D = packed.instantiate()
		inst.name = id.capitalize().replace(" ", "")
		BuildUtil.apply_materials(inst)
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			(mi as MeshInstance3D).extra_cull_margin = 0.6
		var err := BuildUtil.save_scene(inst, "res://scenes/characters/%s.tscn" % id)
		if err == OK:
			n += 1
		inst.free()
	print("BUILD characters: ", n)
