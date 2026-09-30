extends Node
## Builds StandardMaterial3D resources from materials/materials.json + textures/.
## Usage: godot --headless --path . res://tools/godot/builder.tscn -- materials

func run(_args: Array) -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://materials/materials.json"))
	var made := 0
	for mat_name in defs.keys():
		var d: Dictionary = defs[mat_name]
		var m := StandardMaterial3D.new()
		m.resource_name = mat_name
		var c: Array = d.color
		m.albedo_color = Color(c[0], c[1], c[2], d.alpha)
		var tex: Variant = d.tex
		if tex != null:
			var a := "res://textures/%s_albedo.png" % tex
			var n := "res://textures/%s_normal.png" % tex
			var o := "res://textures/%s_orm.png" % tex
			if ResourceLoader.exists(a):
				m.albedo_texture = load(a)
				m.normal_enabled = true
				m.normal_texture = load(n)
				m.normal_scale = d.normal
				var orm: Texture2D = load(o)
				m.ao_enabled = true
				m.ao_texture = orm
				m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
				m.roughness_texture = orm
				m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
				m.roughness = clampf(d.rough / 0.7, 0.35, 1.4)
				m.metallic_texture = orm
				m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
				m.metallic = d.metal
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		else:
			m.roughness = d.rough
			m.metallic = d.metal
		m.metallic_specular = 0.5
		if d.alpha < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.metallic_specular = 0.9
		if d.cull == "none":
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if d.emit != null:
			var e: Array = d.emit[0]
			m.emission_enabled = true
			m.emission = Color(e[0], e[1], e[2])
			m.emission_energy_multiplier = d.emit[1]
		if d.vcol:
			m.vertex_color_use_as_albedo = true
		if d.sss > 0.0:
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = d.sss * 0.35
		var err := ResourceSaver.save(m, "res://materials/%s.tres" % mat_name)
		if err == OK:
			made += 1
		else:
			push_error("failed saving material %s" % mat_name)
	print("BUILD materials: ", made, "/", defs.size())
