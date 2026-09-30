extends Node
## Assembles environments/<name>.json (+ shell glb) into scenes/levels/<name>.tscn:
## shell mesh, box colliders per surface, props, lights, markers, reverb zones,
## reflection probes, occluders, environment and a baked navigation mesh.
## builder.tscn -- levels [name ...]

const LevelRootScript := preload("res://scripts/levels/level_root.gd")


func run(args: Array) -> void:
	var names: Array = args
	if names.is_empty():
		var da := DirAccess.open("res://environments")
		for f in da.get_files():
			if f.ends_with(".json"):
				names.append(f.get_basename())
	for n in names:
		await _build(n)


func _build(level_name: String) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://environments/%s.json" % level_name))
	var root := Node3D.new()
	root.set_script(LevelRootScript)
	root.name = level_name.capitalize().replace(" ", "")
	get_tree().root.add_child(root)
	# ---- shell
	var shell_scene: PackedScene = load(d.shell)
	var shell: Node3D = shell_scene.instantiate()
	shell.name = "Shell"
	BuildUtil.apply_materials(shell)
	root.add_child(shell)
	for mi in shell.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		m.visibility_range_end = 0.0
	# ---- colliders (grouped by surface)
	var bodies: Dictionary = {}
	for c in d.cols:
		var surf: String = c.surface
		if not bodies.has(surf):
			var sb := StaticBody3D.new()
			sb.name = "Col_" + surf
			sb.collision_layer = 1
			sb.collision_mask = 0
			sb.set_meta("surface", surf)
			sb.add_to_group("nav_source")
			root.add_child(sb)
			bodies[surf] = sb
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(c.s[0], c.s[1], c.s[2])
		cs.shape = bs
		cs.position = Vector3(c.c[0], c.c[1], c.c[2])
		cs.rotation_degrees = Vector3(c.r[0], c.r[1], c.r[2])
		bodies[surf].add_child(cs)
	# ---- props
	var props_root := Node3D.new()
	props_root.name = "Props"
	root.add_child(props_root)
	for p in d.props:
		var path := "res://scenes/props/%s.tscn" % p.scene
		if not ResourceLoader.exists(path):
			push_warning("missing prop scene " + path)
			continue
		var inst: Node3D = (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		inst.name = p.name
		props_root.add_child(inst)
		inst.position = Vector3(p.p[0], p.p[1], p.p[2])
		inst.rotation_degrees = Vector3(p.r[0], p.r[1], p.r[2])
		if p.has("scale"):
			inst.scale = Vector3(p.scale[0], p.scale[1], p.scale[2])
		if p.has("group"):
			inst.add_to_group("deco_" + p.group, true)
		var comp := inst.get_node_or_null("Prop")
		var nocol := false
		if comp:
			var o: Dictionary = p.opts
			for k in o.keys():
				if k == "inspect":
					comp.set("inspect_line", StringName(o[k]))
				elif k == "tags":
					comp.set("tags", PackedStringArray(o[k]))
				elif k == "grab":
					comp.set("grab_class", String(o[k]))
				elif k == "nocol":
					if o[k]:
						for cs3 in inst.find_children("*", "CollisionShape3D", true, false):
							cs3.get_parent().remove_child(cs3)
							cs3.free()
						nocol = true
				else:
					comp.set(k, o[k])
		if inst is RigidBody3D:
			(inst as RigidBody3D).sleeping = true
			if nocol:
				(inst as RigidBody3D).freeze = true
		# small props fade out with distance (cheap "LOD" for big halls)
		for pmi in inst.find_children("*", "MeshInstance3D", true, false):
			var pm := pmi as MeshInstance3D
			if pm.get_aabb().size.length() < 1.6:
				pm.visibility_range_end = 38.0
				pm.visibility_range_end_margin = 4.0
				pm.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if inst is StaticBody3D and not nocol and not (comp and "door" in (comp.get("tags") as PackedStringArray)):
			inst.add_to_group("nav_source", true)
	# ---- lights
	var lights_root := Node3D.new()
	lights_root.name = "Lights"
	root.add_child(lights_root)
	var li := 0
	for l in d.lights:
		var node: Light3D
		match l.kind:
			"spot":
				var s := SpotLight3D.new()
				s.spot_range = l.range
				s.spot_angle = l.angle
				s.spot_attenuation = 0.8
				node = s
			"dir":
				var dl := DirectionalLight3D.new()
				dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				dl.directional_shadow_max_distance = 80.0
				dl.add_to_group("graphics_directional", true)
				node = dl
			_:
				var o := OmniLight3D.new()
				o.omni_range = l.range
				o.omni_attenuation = 1.3
				node = o
		node.name = l.name if l.name != "" else "Light%d" % li
		li += 1
		node.light_color = Color(l.color[0], l.color[1], l.color[2])
		node.light_energy = l.energy
		node.shadow_enabled = l.shadow
		node.set_meta("wants_shadow", bool(l.shadow))
		if l.kind != "dir":
			node.add_to_group("level_lights", true)
		node.light_volumetric_fog_energy = l.fog
		node.shadow_bias = 0.04
		node.shadow_normal_bias = 1.2
		lights_root.add_child(node)
		node.position = Vector3(l.p[0], l.p[1], l.p[2])
		node.rotation_degrees = Vector3(l.rot[0], l.rot[1], l.rot[2])
	# ---- markers
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	for mk in d.markers.keys():
		var m := Marker3D.new()
		m.name = mk
		markers.add_child(m)
		var v: Array = d.markers[mk]
		m.position = Vector3(v[0], v[1], v[2])
		m.rotation_degrees.y = v[3]
	# ---- reverb zones
	var zones := Node3D.new()
	zones.name = "Zones"
	root.add_child(zones)
	for z in d.zones:
		var a := Area3D.new()
		a.name = z.name
		a.collision_layer = 0
		a.collision_mask = 0
		a.reverb_bus_enabled = true
		a.reverb_bus_name = z.reverb
		a.reverb_bus_amount = z.amount
		a.reverb_bus_uniformity = 0.6
		var cs2 := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(z.mx[0] - z.mn[0], z.mx[1] - z.mn[1], z.mx[2] - z.mn[2])
		cs2.shape = bx
		zones.add_child(a)
		a.add_child(cs2)
		a.position = Vector3((z.mx[0] + z.mn[0]) / 2, (z.mx[1] + z.mn[1]) / 2, (z.mx[2] + z.mn[2]) / 2)
	# ---- reflection probes + occluders
	for pr in d.probes:
		var rp := ReflectionProbe.new()
		rp.size = Vector3(pr.mx[0] - pr.mn[0], pr.mx[1] - pr.mn[1], pr.mx[2] - pr.mn[2])
		rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.box_projection = true
		rp.interior = bool(pr.get("interior", true))
		rp.intensity = 0.9 if rp.interior else 1.0
		root.add_child(rp)
		rp.position = Vector3((pr.mx[0] + pr.mn[0]) / 2, (pr.mx[1] + pr.mn[1]) / 2, (pr.mx[2] + pr.mn[2]) / 2)
	for oc in d.occluders:
		var oi := OccluderInstance3D.new()
		var bo := BoxOccluder3D.new()
		bo.size = Vector3(oc.mx[0] - oc.mn[0], oc.mx[1] - oc.mn[1], oc.mx[2] - oc.mn[2])
		oi.occluder = bo
		root.add_child(oi)
		oi.position = Vector3((oc.mx[0] + oc.mn[0]) / 2, (oc.mx[1] + oc.mn[1]) / 2, (oc.mx[2] + oc.mn[2]) / 2)
	# ---- environment
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = EnvBuilder.make(d.env)
	we.camera_attributes = EnvBuilder.make_camera_attrs(d.env)
	we.add_to_group("world_environment", true)
	root.add_child(we)
	# ---- navigation
	var region := NavigationRegion3D.new()
	region.name = "Navigation"
	root.add_child(region)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.35
	nm.agent_height = 1.7
	nm.agent_max_climb = 0.3
	nm.agent_max_slope = 40.0
	nm.cell_size = 0.2
	nm.cell_height = 0.12
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = "nav_source"
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, root)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	region.navigation_mesh = nm
	print("LEVEL ", level_name, " navmesh polys: ", nm.get_polygon_count())
	# ---- save
	get_tree().root.remove_child(root)
	BuildUtil.save_scene(root, "res://scenes/levels/%s.tscn" % level_name)
	root.free()
