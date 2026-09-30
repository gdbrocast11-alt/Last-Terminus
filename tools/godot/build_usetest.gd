extends Node
## Stands in front of props with the real player and presses the real Interact input.
## builder.tscn -- usetest <chapter> <beat> <prop> [prop ...]   (prop names as in the level; "@Name" = proxy node under the level)

func run(args: Array) -> void:
	await get_tree().process_frame
	GameState.reset()
	GameState.in_game = true
	await Director.load_chapter(int(args[0]), StringName(args[1]))
	for i in 180:
		await get_tree().physics_frame
	var lv: LevelRoot = Director.level as LevelRoot
	var fails := 0
	var floor_y: float = Director.player.global_position.y
	for n in args.slice(2):
		var node: Node3D = lv.prop(n) if not String(n).begins_with("@") else lv.find_child(String(n).substr(1), true, false) as Node3D
		if node == null:
			print("USE ", n, " MISSING")
			fails += 1
			continue
		var pc := node.get_node_or_null("Prop") as PropComponent
		var used := [0]
		if pc:
			pc.used.connect(func(_p: Node) -> void: used[0] += 1)
			pc.inspected.connect(func(_p: Node) -> void: used[0] += 1)
		var pl := Director.player
		var target_pos := node.global_position
		var cs := _first_shape(node)
		if cs != null:
			target_pos = cs.global_position
		# approach from several sides until the ray finds it
		var ok := false
		var seen := ""
		var tries: Array = []
		for rad in [1.4, 0.9, 1.9]:
			for ang in [0.0, 90.0, 180.0, 270.0, 45.0, 135.0, 225.0, 315.0]:
				tries.append([rad, ang])
		for tr in tries:
			var off := Vector3(0, 0, float(tr[0])).rotated(Vector3.UP, deg_to_rad(float(tr[1])))
			pl.global_position = Vector3(target_pos.x, floor_y, target_pos.z) + off
			pl.velocity = Vector3.ZERO
			var d: Vector3 = target_pos - pl.camera.global_position
			pl.rotation.y = atan2(-d.x, -d.z)
			pl.pitch = atan2(d.y, Vector2(d.x, d.z).length())
			pl.frozen = false
			Director.input_locked = false
			for i in 8:
				await get_tree().physics_frame
			var t: Node = pl.interact.target
			if t != null:
				seen = str(t.get_path()).get_file() + "/" + str(pl.interact.prompts)
			if pc and pl.interact.target == pc:
				ok = true
				break
			if pl.interact.target == node or (pl.interact.target != null and node.is_ancestor_of(pl.interact.target)):
				ok = true
				break
		var verb_before := pc.use_verb if pc else ""
		if ok:
			Input.action_press(&"interact")
			for i in 4:
				await get_tree().physics_frame
			Input.action_release(&"interact")
			for i in 30:
				await get_tree().physics_frame
		var verb_after := pc.use_verb if pc else ""
		var blame := ""
		if not ok:
			var space := pl.get_world_3d().direct_space_state
			var q := PhysicsRayQueryParameters3D.create(pl.camera.global_position, target_pos, 1 | 4 | 8 | 16 | 32)
			q.collide_with_areas = true
			q.exclude = [pl.get_rid()]
			var hh := space.intersect_ray(q)
			blame = " ray->" + (str((hh.collider as Node).get_path()) if not hh.is_empty() else "nothing") + " tgt=" + str(target_pos) + " pl=" + str(pl.global_position) + " layer=" + str(node.get("collision_layer"))
		print("USE %-16s targeted=%s pressed_effect=%d verb:%s->%s %s%s" % [n, ok, used[0], verb_before, verb_after, seen, blame])
		if not ok:
			fails += 1
	print("USETEST failures: ", fails)


func _first_shape(n: Node) -> Node3D:
	for c in n.get_children():
		if not c.is_inside_tree():
			continue
		if c is CollisionShape3D:
			return c as Node3D
		var r := _first_shape(c)
		if r != null:
			return r
	return null
