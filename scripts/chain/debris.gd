class_name Debris
extends RefCounted
## Cheap physics confetti for collapses and crashes. Bodies are capped, never
## collide with the player, and go to sleep / disappear after a while.

static var _mesh: BoxMesh
static var _mats: Array[Material] = []
static var _live: Array[RigidBody3D] = []
const MAX_LIVE := 70


static func spawn(tree: SceneTree, _kind: StringName, pos: Vector3, count: int, force: float, life: float, dir := Vector3.UP) -> void:
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = Vector3(1, 1, 1)
		for m in ["Concrete", "ConcreteRough", "SteelDark", "Brick", "CeilingTile", "WoodWarm"]:
			var mat := BuildUtilRuntime.material(m)
			if mat:
				_mats.append(mat)
	var ps: float = SettingsManager.preset_params(SettingsManager.get_value("graphics/preset")).particle_scale
	count = maxi(2, int(count * ps))
	var root: Node = Director.world
	for i in count:
		if _live.size() >= MAX_LIVE:
			var old: RigidBody3D = _live.pop_front()
			if is_instance_valid(old):
				old.queue_free()
		var rb := RigidBody3D.new()
		rb.collision_layer = 16
		rb.collision_mask = 1
		rb.mass = 2.0
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var sz := Vector3(randf_range(0.12, 0.55), randf_range(0.08, 0.3), randf_range(0.12, 0.5))
		bs.size = sz
		cs.shape = bs
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh
		mi.scale = sz
		if not _mats.is_empty():
			mi.material_override = _mats[randi() % _mats.size()]
		rb.add_child(mi)
		root.add_child(rb)
		rb.global_position = pos + Vector3(randf_range(-0.6, 0.6), randf_range(0.0, 0.8), randf_range(-0.6, 0.6))
		rb.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		rb.linear_velocity = (dir + Vector3(randf_range(-0.8, 0.8), randf_range(0.0, 0.5), randf_range(-0.8, 0.8))).normalized() * force * randf_range(0.5, 1.2)
		rb.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
		rb.linear_damp = 0.3
		rb.can_sleep = true
		rb.continuous_cd = true
		_live.append(rb)
		tree.create_timer(life + randf() * 3.0, false).timeout.connect(func() -> void:
			if is_instance_valid(rb):
				rb.queue_free())
