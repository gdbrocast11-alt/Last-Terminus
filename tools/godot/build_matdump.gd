extends Node
## Dump the materials used by each mesh of a level shell. builder.tscn -- matdump <level>
func run(args: Array) -> void:
	await get_tree().process_frame
	var lv: Node3D = (load("res://scenes/levels/%s.tscn" % args[0]) as PackedScene).instantiate()
	add_child(lv)
	for mi in lv.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.get_path().get_concatenated_names().contains("Shell"):
			continue
		var names: Array = []
		for s in m.mesh.get_surface_count():
			var mat := m.get_active_material(s)
			names.append("%s:%s" % [mat.resource_name if mat else "NULL", (mat as StandardMaterial3D).albedo_color.to_html(false) if mat is StandardMaterial3D else "?"])
		print("MESH ", m.name, " aabb=", m.get_aabb().size.snapped(Vector3.ONE * 0.1), " -> ", ", ".join(names))
