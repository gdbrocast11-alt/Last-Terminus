extends Node
## Screenshot a glb (character / prop) with optional animation.
## builder.tscn -- viewer out.png res://characters/eddie.glb [anim] [seek] [view: front|side|three|face|back|high] [more glbs offset in x...]

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var out: String = args[0]
	var paths: Array = args[1].split(",")
	var anim: String = args[2] if args.size() > 2 else ""
	var seek: float = float(args[3]) if args.size() > 3 else 0.0
	var view: String = args[4] if args.size() > 4 else "three"
	var root := Node3D.new()
	get_tree().root.add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.33, 0.38)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.9)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, -30, 0); sun.light_energy = 1.5; sun.shadow_enabled = true; root.add_child(sun)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-20, 150, 0); fill.light_energy = 0.5; root.add_child(fill)
	var floor_mi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 60); floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.45, 0.45, 0.48); floor_mi.material_override = fm; root.add_child(floor_mi)
	var i := 0
	var spacing := 1.0
	var focus := Vector3.ZERO
	for p in paths:
		var ps: PackedScene = load(p)
		var inst: Node3D = ps.instantiate()
		BuildUtil.apply_materials(inst)
		root.add_child(inst)
		inst.position = Vector3(i * 1.6, 0, 0)
		var ap: AnimationPlayer = null
		for n in inst.find_children("*", "AnimationPlayer", true, false):
			ap = n
		if ap and anim != "" and ap.has_animation(anim):
			ap.play(anim)
			ap.seek(seek, true)
			ap.pause()
		elif ap and i == 0:
			print("ANIMS: ", ap.get_animation_list())
		i += 1
	var n := float(i)
	focus = Vector3((n - 1) * 0.8, 0.9, 0)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true
	var d := 4.2 + n * 0.9
	match view:
		"front": cam.position = focus + Vector3(0, 0.1, -d)      # characters face +Z? check
		"back": cam.position = focus + Vector3(0, 0.1, d)
		"side": cam.position = focus + Vector3(d, 0.1, 0)
		"face": focus = Vector3(0, 1.62, 0); cam.position = focus + Vector3(0.35, 0.05, -0.85)
		"high": cam.position = focus + Vector3(2, 3, -3)
		"dog": focus = Vector3(0, 0.35, 0); cam.position = focus + Vector3(-1.1, 0.25, -1.5)
		"dogside": focus = Vector3(0, 0.35, 0); cam.position = focus + Vector3(-2.0, 0.2, 0.0)
		_: cam.position = focus + Vector3(-d * 0.55, 0.4, -d * 0.85)
	cam.look_at_from_position(cam.position, focus, Vector3.UP)
	cam.fov = 32 if view != "face" else 30
	get_tree().root.size = Vector2i(1400, 900)
	for _i in 8:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(out)
	print("VIEWER saved ", out)
