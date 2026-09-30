extends Node
## Contact sheet of one glb playing many animations.
## builder.tscn -- animsheet out.png res://characters/pickles.glb anim1,anim2,... seek view

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var out: String = args[0]
	var path: String = args[1]
	var anims: Array = args[2].split(",")
	var seek: float = float(args[3]) if args.size() > 3 else 0.5
	var view: String = args[4] if args.size() > 4 else "side"
	var spacing: float = float(args[5]) if args.size() > 5 else 1.6
	var root := Node3D.new()
	get_tree().root.add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.33, 0.38)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, -60, 0); sun.light_energy = 1.4; root.add_child(sun)
	var floor_mi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(80, 80); floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.5, 0.5, 0.52); floor_mi.material_override = fm; root.add_child(floor_mi)
	var ps: PackedScene = load(path)
	var cols := 6
	var i := 0
	for a in anims:
		var inst: Node3D = ps.instantiate()
		BuildUtil.apply_materials(inst)
		root.add_child(inst)
		inst.position = Vector3(-(i / cols) * spacing * 1.25, 0, -(i % cols) * spacing)
		for n in inst.find_children("*", "AnimationPlayer", true, false):
			var ap := n as AnimationPlayer
			if ap.has_animation(a):
				ap.play(a)
				ap.seek(seek * ap.get_animation(a).length, true)
				ap.pause()
			else:
				print("MISSING anim ", a)
		i += 1
	var rows := int(ceil(float(i) / cols))
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true
	var cz: float = -(mini(i, cols) - 1) * spacing * 0.5
	var dist: float = mini(i, cols) * spacing * 0.95 + 2.0
	if view == "side":
		cam.position = Vector3(dist, 1.0 + rows * 0.4, cz)
		cam.look_at_from_position(cam.position, Vector3(-(rows - 1) * spacing * 0.6, 0.5, cz), Vector3.UP)
	else:
		cam.position = Vector3(dist * 0.6, 1.6, cz + dist * 0.5)
		cam.look_at_from_position(cam.position, Vector3(-(rows - 1) * spacing * 0.6, 0.5, cz), Vector3.UP)
	cam.fov = 32
	get_tree().root.size = Vector2i(1900, 1000)
	for _i in 8:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(out)
	print("ANIMSHEET saved ", out)
