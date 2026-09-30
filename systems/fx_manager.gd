extends Node
## Pooled one-shot particle bursts and surface decals (blood/paint/water/scorch).
## All effects respect the graphics preset (particle scale) and the gore option.

const KINDS := {
	# name: count, lifetime, speed range, gravity, size range, colour, spread, texture, explosiveness
	&"spark": {"n": 28, "life": 0.55, "v": [3.0, 8.0], "g": 9.0, "s": [0.03, 0.07], "c": Color(1.0, 0.8, 0.35), "spread": 70.0, "tex": "fx_spark", "exp": 0.95, "emit": true},
	&"dust": {"n": 20, "life": 2.2, "v": [0.6, 2.4], "g": -0.2, "s": [0.5, 1.4], "c": Color(0.72, 0.68, 0.62, 0.55), "spread": 180.0, "tex": "fx_soft", "exp": 0.9, "emit": false},
	&"smoke": {"n": 22, "life": 3.0, "v": [0.4, 1.2], "g": -0.6, "s": [0.4, 1.1], "c": Color(0.15, 0.15, 0.16, 0.6), "spread": 25.0, "tex": "fx_soft", "exp": 0.3, "emit": false},
	&"splash": {"n": 40, "life": 0.9, "v": [1.5, 4.5], "g": 9.8, "s": [0.03, 0.08], "c": Color(0.75, 0.9, 1.0, 0.85), "spread": 55.0, "tex": "fx_soft", "exp": 0.95, "emit": false},
	&"smoothie": {"n": 36, "life": 1.0, "v": [1.0, 3.5], "g": 9.8, "s": [0.04, 0.1], "c": Color(0.7, 0.2, 0.65, 0.95), "spread": 60.0, "tex": "fx_soft", "exp": 0.95, "emit": false},
	&"paint": {"n": 60, "life": 1.1, "v": [2.0, 6.0], "g": 9.8, "s": [0.04, 0.12], "c": Color(0.8, 0.03, 0.05, 0.95), "spread": 80.0, "tex": "fx_soft", "exp": 0.98, "emit": false},
	&"blood": {"n": 34, "life": 0.8, "v": [1.5, 5.0], "g": 9.8, "s": [0.03, 0.08], "c": Color(0.5, 0.0, 0.02, 0.95), "spread": 70.0, "tex": "fx_soft", "exp": 0.98, "emit": false},
	&"stars": {"n": 12, "life": 0.9, "v": [1.0, 3.0], "g": 1.0, "s": [0.12, 0.22], "c": Color(1.0, 0.9, 0.3, 1.0), "spread": 90.0, "tex": "fx_star", "exp": 0.95, "emit": true},
	&"steam": {"n": 26, "life": 2.0, "v": [0.5, 1.4], "g": -0.5, "s": [0.4, 0.9], "c": Color(0.95, 0.95, 1.0, 0.35), "spread": 30.0, "tex": "fx_soft", "exp": 0.2, "emit": false},
	&"confetti": {"n": 60, "life": 2.5, "v": [2.0, 6.0], "g": 3.0, "s": [0.05, 0.1], "c": Color(1, 1, 1, 1), "spread": 60.0, "tex": "fx_soft", "exp": 0.98, "emit": true},
	&"fire": {"n": 18, "life": 0.7, "v": [0.5, 1.6], "g": -1.6, "s": [0.25, 0.5], "c": Color(1.0, 0.55, 0.12, 0.9), "spread": 20.0, "tex": "fx_soft", "exp": 0.2, "emit": true},
	&"debris": {"n": 26, "life": 1.4, "v": [3.0, 9.0], "g": 12.0, "s": [0.04, 0.12], "c": Color(0.45, 0.42, 0.4, 1.0), "spread": 75.0, "tex": "fx_soft", "exp": 0.98, "emit": false},
	&"pee": {"n": 44, "life": 0.7, "v": [1.3, 2.3], "g": 9.8, "s": [0.02, 0.045], "c": Color(1.0, 0.9, 0.15, 0.95), "spread": 12.0, "tex": "fx_soft", "exp": 0.0, "emit": true},
	&"leaves": {"n": 18, "life": 3.5, "v": [1.0, 3.0], "g": 1.2, "s": [0.06, 0.12], "c": Color(0.5, 0.65, 0.2, 1.0), "spread": 120.0, "tex": "fx_soft", "exp": 0.7, "emit": false},
}

const MAX_DECALS := 70

var _pool: Dictionary = {}
var _quad_mats: Dictionary = {}
var _decals: Array[Decal] = []
var _decal_tex: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _root() -> Node:
	return Director.world if Director and Director.world else get_tree().current_scene


func _mat(kind: StringName) -> StandardMaterial3D:
	if _quad_mats.has(kind):
		return _quad_mats[kind]
	var k: Dictionary = KINDS[kind]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if k.get("emit", false) and kind != &"confetti" else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = load("res://textures/%s.png" % k.tex)
	m.particles_anim_h_frames = 1
	m.particles_anim_v_frames = 1
	m.no_depth_test = false
	_quad_mats[kind] = m
	return m


func _make(kind: StringName) -> GPUParticles3D:
	var k: Dictionary = KINDS[kind]
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = k.spread
	pm.initial_velocity_min = k.v[0]
	pm.initial_velocity_max = k.v[1]
	pm.gravity = Vector3(0, -k.g, 0)
	pm.scale_min = k.s[0]
	pm.scale_max = k.s[1]
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	var grad := Gradient.new()
	var c: Color = k.c
	grad.colors = PackedColorArray([Color(c, c.a), Color(c, c.a), Color(c, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	if kind == &"confetti":
		pm.color = Color.WHITE
		pm.hue_variation_min = -1.0
		pm.hue_variation_max = 1.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(0.15, 1.0))
	sc.add_point(Vector2(1, 1.4 if kind in [&"dust", &"smoke", &"steam", &"fire"] else 0.8))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	quad.material = _mat(kind)
	p.draw_pass_1 = quad
	p.lifetime = k.life
	p.one_shot = true
	p.explosiveness = k.exp
	p.emitting = false
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


func _acquire(kind: StringName) -> GPUParticles3D:
	if not _pool.has(kind):
		_pool[kind] = []
	var live: Array = []
	var found: GPUParticles3D = null
	for e: Variant in _pool[kind]:
		if is_instance_valid(e):
			live.append(e)
			if found == null and not (e as GPUParticles3D).emitting:
				found = e as GPUParticles3D
	_pool[kind] = live
	if found:
		return found
	var np := _make(kind)
	_root().add_child(np)
	_pool[kind].append(np)
	return np


func burst(kind: StringName, pos: Vector3, scale := 1.0, dir := Vector3.UP) -> void:
	if not KINDS.has(kind):
		return
	if SettingsManager.reduced_gore() and kind == &"blood":
		kind = &"stars"
	var p := _acquire(kind)
	var ps: float = SettingsManager.preset_params(SettingsManager.get_value("graphics/preset")).particle_scale
	p.amount = maxi(4, int(KINDS[kind].n * scale * ps))
	p.global_position = pos
	if dir != Vector3.UP:
		p.look_at(pos + dir, Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT)
		p.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	else:
		p.global_rotation = Vector3.ZERO
	(p.process_material as ParticleProcessMaterial).scale_min = KINDS[kind].s[0] * scale
	(p.process_material as ParticleProcessMaterial).scale_max = KINDS[kind].s[1] * scale
	p.restart()
	p.emitting = true


## Continuous emitter attached to a node; caller frees it.
func emitter(kind: StringName, parent: Node3D, offset := Vector3.ZERO, scale := 1.0) -> GPUParticles3D:
	var p := _make(kind)
	p.one_shot = false
	p.explosiveness = 0.0
	var ps: float = SettingsManager.preset_params(SettingsManager.get_value("graphics/preset")).particle_scale
	p.amount = maxi(4, int(KINDS[kind].n * scale * ps))
	p.lifetime = KINDS[kind].life
	parent.add_child(p)
	p.position = offset
	p.emitting = true
	return p


func decal(kind: StringName, pos: Vector3, normal := Vector3.UP, size := 1.0, color := Color(0.5, 0, 0.02)) -> void:
	if SettingsManager.reduced_gore() and kind == &"blood":
		return
	var tex_name: String = {&"blood": "decal_splat_%d" % (1 + randi() % 3), &"paint": "decal_splat_%d" % (1 + randi() % 3), &"smoothie": "decal_splat_%d" % (1 + randi() % 3),
		&"puddle": "decal_puddle", &"scorch": "decal_scorch"}.get(kind, "decal_splat_1")
	if not _decal_tex.has(tex_name):
		_decal_tex[tex_name] = load("res://textures/%s.png" % tex_name)
	var d := Decal.new()
	d.size = Vector3(size, 1.2, size)
	d.texture_albedo = _decal_tex[tex_name]
	d.modulate = color
	d.upper_fade = 0.3
	d.lower_fade = 0.3
	d.cull_mask = 1
	_root().add_child(d)
	d.global_position = pos + normal * 0.05
	var up := normal.normalized()
	var fwd := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var right := up.cross(fwd).normalized()
	fwd = right.cross(up).normalized()
	d.global_basis = Basis(right, up, -fwd).rotated(up, randf() * TAU)
	_decals.append(d)
	if _decals.size() > MAX_DECALS:
		var old: Decal = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func blood(pos: Vector3, size := 1.0) -> void:
	burst(&"blood", pos + Vector3(0, 0.5, 0), size)
	decal(&"blood", Vector3(pos.x, pos.y, pos.z), Vector3.UP, 1.6 * size)


func puff(pos: Vector3, size := 1.0) -> void:
	burst(&"dust", pos, size)


func clear_decals() -> void:
	for d in _decals:
		if is_instance_valid(d):
			d.queue_free()
	_decals.clear()
