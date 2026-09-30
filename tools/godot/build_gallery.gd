extends Node
## Renders a contact-sheet screenshot of prop scenes for visual QA.
## godot --path . res://tools/godot/builder.tscn -- gallery out.png cols name1 name2 ...   (or "all" / "cat:transit" / "mat:Name")

var cam: Camera3D
var out_path := "/tmp/gallery.png"
var frames := 0

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	out_path = args[0] if args.size() > 0 else out_path
	var cols := int(args[1]) if args.size() > 1 else 8
	var names: Array = []
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://props/props_def.json"))
	for a in args.slice(2):
		if a == "all":
			names.append_array(defs.keys())
		elif a.begins_with("cat:"):
			for k in defs.keys():
				if defs[k].cat == a.substr(4):
					names.append(k)
		elif a.begins_with("mat:"):
			for k in defs.keys():
				if defs[k].mats.has(a.substr(4)):
					names.append(k)
		else:
			names.append(a)
	var root := Node3D.new()
	get_tree().root.add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.36, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.light_energy = 1.4; sun.shadow_enabled = true; root.add_child(sun)
	var floor_mi := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(400, 400); floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.5, 0.5, 0.52); floor_mi.material_override = fm; root.add_child(floor_mi)
	var spacing := 4.5
	var i := 0
	for n in names:
		var p := "res://scenes/props/%s.tscn" % n
		if not ResourceLoader.exists(p):
			continue
		var inst: Node3D = (load(p) as PackedScene).instantiate()
		root.add_child(inst)
		inst.position = Vector3((i % cols) * spacing, 0, -(i / cols) * spacing)
		if inst is RigidBody3D:
			inst.freeze = true
		i += 1
	var rows := int(ceil(float(i) / cols))
	cam = Camera3D.new(); root.add_child(cam); cam.current = true
	var cx := (cols - 1) * spacing * 0.5
	var width := cols * spacing
	cam.position = Vector3(cx, width * 0.28 + 3, -(rows - 1) * spacing * 0.5 + width * 0.62)
	cam.look_at(Vector3(cx, 0.6, -(rows - 1) * spacing * 0.5), Vector3.UP)
	cam.fov = 40
	get_tree().root.size = Vector2i(1900, 1000)
	for _i in 8:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png(out_path)
	print("GALLERY saved ", out_path)

