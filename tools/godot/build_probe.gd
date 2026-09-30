extends Node
## Ground-height probe. builder.tscn -- probe <level> [x,z ...]
## With no points: checks that every marker sits on (or slightly above) walkable ground and prints the offenders.

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var packed: PackedScene = load("res://scenes/levels/%s.tscn" % args[0])
	var lv: Node3D = packed.instantiate()
	Director.world.add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := (lv as Node3D).get_world_3d().direct_space_state
	if args.size() > 1:
		for a in args.slice(1):
			var xz := String(a).split(",")
			var x := float(xz[0])
			var z := float(xz[1])
			var top := float(xz[2]) if xz.size() > 2 else 40.0
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -60.0, z), 1)
			var r := space.intersect_ray(q)
			print("PROBE ", x, ",", z, " -> ", r.position.y if not r.is_empty() else "none", " ", (r.collider as Node).get_path() if not r.is_empty() else "")
		return
	var bad := 0
	for m in lv.get_node("Markers").get_children():
		var p: Vector3 = (m as Marker3D).global_position
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p - Vector3(0, 6.0, 0), 1)
		var r := space.intersect_ray(q)
		if r.is_empty():
			print("MARKER no ground: ", m.name, " ", p)
			bad += 1
			continue
		var dy: float = p.y - r.position.y
		if p.y < 40.0 and (dy < -0.25 or dy > 0.6) and not String(m.name).begins_with("Cup") and p.y < 2.0:
			print("MARKER height mismatch: ", m.name, " marker.y=", p.y, " ground=", r.position.y)
			bad += 1
	print("PROBE markers checked, problems: ", bad)
