extends Node
## Physically walks the real player controller between markers to catch blocked doorways, bad stairs,
## navmesh gaps, etc.   builder.tscn -- walktest <level> from:to [from:to ...]    (markers, or "@x,y,z")
## Also reports NPC navmesh connectivity for each leg.

func _pos(lv: Node3D, s: String) -> Vector3:
	if s.begins_with("@"):
		var p := s.substr(1).split(",")
		return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return lv.marker_pos(s)


func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var lv: Node3D = (load("res://scenes/levels/%s.tscn" % args[0]) as PackedScene).instantiate()
	Director.world.add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var fails := 0
	var pl: Player = null
	for leg in args.slice(1):
		var pr := String(leg).split(":")
		var a := _pos(lv, pr[0])
		var b := _pos(lv, pr[1])
		if pl and is_instance_valid(pl):
			pl.free()
		pl = Director.spawn_player(Transform3D(Basis.IDENTITY, a + Vector3(0, 0.1, 0))) as Player
		await get_tree().physics_frame
		# navmesh path for NPCs
		var map := lv.get_world_3d().navigation_map
		var path := NavigationServer3D.map_get_path(map, a, b, true)
		var nav_ok := path.size() > 1 and path[path.size() - 1].distance_to(b) < 1.5
		Input.action_press(&"move_forward", 1.0)
		var t := 0.0
		var best := 1e9
		var stuck_t := 0.0
		var last := pl.global_position
		while t < 60.0:
			var d := b - pl.global_position
			d.y = 0.0
			if d.length() < 0.9:
				break
			pl.rotation.y = atan2(-d.x, -d.z)
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			if pl.global_position.distance_to(last) < 0.004:
				stuck_t += get_physics_process_delta_time()
				if stuck_t > 0.4 and pl.is_on_floor():
					Input.action_press(&"jump", 1.0)      # try to mantle / hop
				if stuck_t > 4.0:
					break
			else:
				stuck_t = 0.0
				Input.action_release(&"jump")
			last = pl.global_position
			best = minf(best, (b - pl.global_position).length())
		Input.action_release(&"move_forward")
		Input.action_release(&"jump")
		var final := (b - pl.global_position)
		final.y = 0
		var ok := final.length() < 1.2
		if not ok:
			fails += 1
		var blocker := ""
		if not ok:
			for i in pl.get_slide_collision_count():
				blocker += " " + str((pl.get_slide_collision(i).get_collider() as Node).get_path()).get_file()
			blocker += " at " + str(pl.global_position.snapped(Vector3.ONE * 0.1))
		print("WALK %s %s -> %s  %s  t=%.1fs  dist=%.1f  navmesh=%s  y=%.2f%s" % [args[0], pr[0], pr[1], "OK" if ok else "FAIL", t, final.length(), "ok" if nav_ok else "NOPATH", pl.global_position.y, blocker])
	print("WALKTEST ", args[0], " failures: ", fails)
