class_name EnvBuilder
extends RefCounted
## Builds Environment / CameraAttributes for a level from its "env" dictionary.

static func make(e: Dictionary) -> Environment:
	var env := Environment.new()
	var kind: String = e.get("kind", "interior")
	var exterior := kind.begins_with("exterior")
	if exterior:
		var sky := Sky.new()
		var sm := ProceduralSkyMaterial.new()
		var top: Array = e.get("sky_top", [0.32, 0.5, 0.8])
		var hor: Array = e.get("sky_horizon", [0.75, 0.82, 0.9])
		sm.sky_top_color = Color(top[0], top[1], top[2])
		sm.sky_horizon_color = Color(hor[0], hor[1], hor[2])
		sm.ground_horizon_color = Color(hor[0] * 0.8, hor[1] * 0.8, hor[2] * 0.8)
		sm.ground_bottom_color = Color(0.2, 0.2, 0.22)
		sm.sun_angle_max = 30.0
		sm.sun_curve = 0.15
		sky.sky_material = sm
		env.sky = sky
		env.background_mode = Environment.BG_SKY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.ambient_light_energy = e.get("ambient_energy", 1.0)
	else:
		var bg: Array = e.get("bg", [0.02, 0.02, 0.03])
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(bg[0], bg[1], bg[2])
		var amb: Array = e.get("ambient", [0.3, 0.3, 0.35])
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(amb[0], amb[1], amb[2])
		env.ambient_light_energy = e.get("ambient_energy", 1.0)
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED if false else Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.tonemap_exposure = e.get("exposure", 1.0)
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.0
	env.ssao_detail = 0.6
	env.ssil_enabled = true
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.sdfgi_enabled = bool(e.get("sdfgi", false))
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = exterior
	env.sdfgi_bounce_feedback = 0.4
	env.sdfgi_energy = 1.0
	env.set_meta("sdfgi_allowed", bool(e.get("sdfgi", false)))
	var fog_d: float = e.get("fog", 0.0)
	var fog_c: Array = e.get("fog_color", [0.5, 0.55, 0.65])
	if bool(e.get("vfog", false)) and fog_d > 0.0:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = fog_d
		env.volumetric_fog_albedo = Color(fog_c[0], fog_c[1], fog_c[2])
		env.volumetric_fog_emission = Color(fog_c[0], fog_c[1], fog_c[2]) * 0.05
		env.volumetric_fog_anisotropy = 0.45
		env.volumetric_fog_length = 60.0
		env.volumetric_fog_gi_inject = 0.6
		env.set_meta("vfog_allowed", true)
	else:
		env.volumetric_fog_enabled = false
		env.set_meta("vfog_allowed", false)
	if fog_d > 0.0 and exterior:
		env.fog_enabled = true
		env.fog_density = fog_d * 0.35
		env.fog_light_color = Color(fog_c[0], fog_c[1], fog_c[2])
		env.fog_sky_affect = 0.4
	env.adjustment_enabled = true
	env.adjustment_brightness = e.get("brightness", 1.0)
	env.adjustment_contrast = e.get("contrast", 1.06)
	env.adjustment_saturation = e.get("saturation", 1.06)
	var grade: String = e.get("grade", "")
	if grade != "":
		env.adjustment_color_correction = _lut(grade)
	return env


static func make_camera_attrs(e: Dictionary) -> CameraAttributesPractical:
	var a := CameraAttributesPractical.new()
	a.auto_exposure_enabled = false
	a.dof_blur_far_enabled = false
	a.dof_blur_far_distance = 25.0
	a.dof_blur_far_transition = 20.0
	a.dof_blur_amount = 0.05
	a.set_meta("dof_allowed", bool(e.get("dof", false)))
	return a


## Tiny 1D LUTs for the colour grade of each mood.
static func _lut(grade: String) -> GradientTexture1D:
	var g := Gradient.new()
	match grade:
		"warm_night":
			g.set_color(0, Color(0.0, 0.0, 0.03)); g.set_color(1, Color(1.0, 0.96, 0.9))
		"cool_teal":
			g.set_color(0, Color(0.0, 0.02, 0.03)); g.set_color(1, Color(0.93, 1.0, 1.0))
		"sickly":
			g.set_color(0, Color(0.0, 0.02, 0.0)); g.set_color(1, Color(0.95, 1.0, 0.9))
		"sunset":
			g.set_color(0, Color(0.03, 0.0, 0.04)); g.set_color(1, Color(1.0, 0.93, 0.86))
		"bleak":
			g.set_color(0, Color(0.01, 0.01, 0.02)); g.set_color(1, Color(0.92, 0.95, 1.0))
		_:
			g.set_color(0, Color(0, 0, 0)); g.set_color(1, Color(1, 1, 1))
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 256
	return t
