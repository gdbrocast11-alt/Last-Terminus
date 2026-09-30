extends Node
## Scene statistics (draw calls, primitives, lights, bodies) for a few viewpoints.
## builder.tscn -- perf <level> marker[:yaw:pitch] ...

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var lv: Node3D = (load("res://scenes/levels/%s.tscn" % args[0]) as PackedScene).instantiate()
	Director.world.add_child(lv)
	SettingsManager.apply_to_scene()
	var meshes := lv.find_children("*", "MeshInstance3D", true, false).size()
	var lights := lv.find_children("*", "Light3D", true, false).size()
	var bodies := lv.find_children("*", "CollisionObject3D", true, false).size()
	var rbs := lv.find_children("*", "RigidBody3D", true, false).size()
	print("PERF %s static: meshes=%d lights=%d collision_objects=%d rigid=%d" % [args[0], meshes, lights, bodies, rbs])
	for spec in args.slice(1):
		var p := String(spec).split(":")
		var xf: Transform3D = lv.marker(p[0])
		var pl := Director.spawn_player(xf)
		pl.rotation.y = deg_to_rad(float(p[1])) if p.size() > 1 else pl.rotation.y
		pl.pitch = deg_to_rad(float(p[2])) if p.size() > 2 else 0.0
		for i in 40:
			await get_tree().process_frame
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var objs := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		print("PERF %s @%s: draws=%d prims=%dk objects=%d" % [args[0], p[0], draws, prims / 1000, objs])
