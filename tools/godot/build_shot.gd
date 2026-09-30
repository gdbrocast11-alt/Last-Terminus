extends Node
## Screenshot from Eddie's eyes.  builder.tscn -- shot <level> <marker> <out.png> [yaw_deg] [pitch_deg] [frames] [pickles_marker]

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var level_name: String = args[0]
	var mk: String = args[1]
	var out: String = args[2]
	var yaw: float = float(args[3]) if args.size() > 3 else 0.0
	var pit: float = float(args[4]) if args.size() > 4 else 0.0
	var frames: int = int(args[5]) if args.size() > 5 else 10
	var pmk: String = args[6] if args.size() > 6 and not String(args[6]).contains("=") else ""
	var overrides: Dictionary = {}
	for a in args.slice(6):
		if String(a).contains("="):
			var kv := String(a).split("=")
			overrides[kv[0]] = float(kv[1])
	var packed: PackedScene = load("res://scenes/levels/%s.tscn" % level_name)
	var lv: Node3D = packed.instantiate()
	Director.world.add_child(lv)
	Director.level = lv
	SettingsManager.apply_to_scene()
	var wenv := lv.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if wenv:
		if overrides.has("sdfgi"):
			wenv.environment.sdfgi_enabled = overrides.sdfgi > 0.5
		if overrides.has("amb"):
			wenv.environment.ambient_light_energy = overrides.amb
		if overrides.has("exp"):
			wenv.environment.tonemap_exposure = overrides.exp
		if overrides.has("ssr"):
			wenv.environment.ssr_enabled = overrides.ssr > 0.5
		if overrides.has("glow"):
			wenv.environment.glow_enabled = overrides.glow > 0.5
	for l in lv.find_children("*", "DirectionalLight3D", true, false):
		if overrides.has("sun"):
			(l as DirectionalLight3D).light_energy = overrides.sun
	var xf: Transform3D = lv.marker(mk)
	var pl := Director.spawn_player(xf)
	pl.rotation.y = deg_to_rad(yaw)
	pl.pitch = deg_to_rad(pit)
	if pmk != "":
		Director.spawn_pickles(lv.marker(pmk))
	Director.set_hud_visible(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().root.size = Vector2i(1600, 900)
	for i in frames:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(out)
	print("SHOT saved ", out)
