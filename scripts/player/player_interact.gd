class_name PlayerInteract
extends Node
## Everything Eddie does with his hands: highlight + prompt, pick up / carry /
## throw / rotate, use, hit, inspect, danger intuition (Q) and the contextual
## Pickles command (F).

signal target_changed(target: Node)
signal focused
signal thrown(body: Node)

const REACH := 2.9
const HOLD_SPEED := 14.0
const MASK := 1 | 4 | 8 | 16 | 32

var player: Player
var target: Node = null
var target_prop: PropComponent = null
var prompts: Array = []               ## [{action, text}] for the HUD
var held: RigidBody3D = null
var held_prop: PropComponent = null
var held_class := ""
var rotating_held := false
var inspecting := false
var focus_active := false
var focus_cooldown := 0.0
var pickles_context := ""
var last_thrown: RigidBody3D = null
var far_prop: PropComponent = null    ## long-range inspect target (RMB) -- big landmarks and hazards

var _hold_basis := Basis.IDENTITY
var _hold_offset := Vector3.ZERO
var _saved_damp := 0.0
var _heavy_anchor := Vector3.ZERO
var _held_ext := 0.3
var _f_down_time := 0.0
var _f_active := false
var _focus_timer := 0.0
var _highlighted: Array = []
var _hazard_mat: ShaderMaterial
var _hazard_labels: Array = []


func _ready() -> void:
	_hazard_mat = ShaderMaterial.new()
	_hazard_mat.shader = load("res://shaders/hazard_overlay.gdshader")


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	var locked := player.frozen or Director.input_locked or get_tree().paused
	focus_cooldown = maxf(0.0, focus_cooldown - delta)
	_update_target()
	_update_held(delta)
	_update_prompts()
	if locked:
		if rotating_held:
			rotating_held = false
		return
	if Input.is_action_just_pressed(&"interact"):
		_on_interact()
	if Input.is_action_just_pressed(&"use_item"):
		_on_use()
	if Input.is_action_just_pressed(&"drop_item"):
		if held:
			drop()
	rotating_held = held != null and Input.is_action_pressed(&"secondary")
	if Input.is_action_just_pressed(&"secondary") and held == null:
		_inspect()
	inspecting = held == null and Input.is_action_pressed(&"secondary")
	if Input.is_action_just_pressed(&"focus"):
		_start_focus()
	_update_focus(delta)
	_handle_pickles_input(delta)
	# arm pose
	var reach := 0.0
	if held:
		reach = 0.85
	elif target_prop != null and target_prop.can_interact():
		reach = 0.25
	player.body.reach = lerpf(player.body.reach, reach, clampf(delta * 8.0, 0.0, 1.0))


# ------------------------------------------------------------------ targeting
func _update_target() -> void:
	var cam := player.camera
	var space := player.get_world_3d().direct_space_state
	var from := cam.global_position
	var fwd := -cam.global_transform.basis.z
	var best: Node = null
	var best_score := -1.0
	var offsets := [Vector2.ZERO, Vector2(0.05, 0), Vector2(-0.05, 0), Vector2(0, 0.05), Vector2(0, -0.05), Vector2(0.1, 0.06), Vector2(-0.1, 0.06), Vector2(0.1, -0.06), Vector2(-0.1, -0.06)]
	var right := cam.global_transform.basis.x
	var up := cam.global_transform.basis.y
	for off in offsets:
		var dir: Vector3 = (fwd + right * off.x + up * off.y).normalized()
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * REACH, MASK)
		q.collide_with_areas = true
		q.exclude = [player.get_rid()]
		if held:
			q.exclude.append(held.get_rid())
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var t := _resolve(hit.collider)
		if t == null:
			continue
		var hit_pos: Vector3 = hit.position
		var score: float = 1.0 - off.length() * 4.0 - (hit_pos - from).length() * 0.05
		if score > best_score:
			best_score = score
			best = t
	if best != target:
		target = best
		target_prop = best as PropComponent
		target_changed.emit(target)
	far_prop = null
	if target == null and held == null:
		var q2 := PhysicsRayQueryParameters3D.create(from, from + fwd * 24.0, 1 | 16 | 32)
		q2.exclude = [player.get_rid()]
		var hit2 := space.intersect_ray(q2)
		if not hit2.is_empty():
			var pn := (hit2.collider as Node).get_node_or_null("Prop") as PropComponent
			if pn != null and pn.inspect_line != &"" and pn.can_use:
				far_prop = pn


func _resolve(collider: Object) -> Node:
	if collider == null or not (collider is Node):
		return null
	var n := collider as Node
	if n is Pickles:
		return n
	if n is Actor:
		return n if (n as Actor).talkable and (n as Actor).alive else null
	var pc := n.get_node_or_null("Prop")
	if pc is PropComponent:
		return pc if (pc as PropComponent).can_interact() else null
	if n.has_method("interact") and n.has_method("get_prompt"):
		return n if String(n.call("get_prompt")) != "" else null
	var par := n.get_parent()
	if par and par.has_method("interact") and par.has_method("get_prompt"):
		return par if String(par.call("get_prompt")) != "" else null
	return null


func _update_prompts() -> void:
	prompts.clear()
	if held:
		prompts.append({"action": "use_item", "text": "Throw"})
		prompts.append({"action": "drop_item", "text": "Drop"})
		prompts.append({"action": "secondary", "text": "Rotate"})
	elif target != null:
		var text := ""
		if target is PropComponent:
			text = (target as PropComponent).prompt_text()
			var pc := target as PropComponent
			if pc.hit_verb != "":
				prompts.append({"action": "use_item", "text": pc.hit_verb})
		else:
			text = String(target.call("get_prompt"))
		if text != "":
			prompts.insert(0, {"action": "interact", "text": text})
	if far_prop != null and target == null and held == null:
		prompts.append({"action": "secondary", "text": "Inspect"})
	pickles_context = _pickles_command_text()
	if pickles_context != "" and Director.pickles:
		prompts.append({"action": "pickles_command", "text": pickles_context})


# ------------------------------------------------------------------ interact
func _on_interact() -> void:
	if held:
		# hand the item to something, otherwise set it down
		if target != null and not (target is PropComponent and (target as PropComponent).is_grabbable() and (target as PropComponent).use_verb == ""):
			_dispatch(target)
		else:
			drop()
		return
	if target == null:
		return
	_dispatch(target)


func _dispatch(t: Node) -> void:
	if t is PropComponent:
		var pc := t as PropComponent
		if pc.use_verb != "":
			pc.do_use(player)
			player.body.reach = 1.0
			AudioManager.play_sfx(&"click_soft", pc.body.global_position, -6.0)
			Events.intervention.emit(&"use", pc.prop_id, {})
			return
		if pc.is_grabbable():
			grab(pc)
			return
		if pc.inspect_line != &"":
			pc.do_inspect(player)
			return
	elif t.has_method("interact"):
		t.call("interact", player)


func _on_use() -> void:
	if held:
		throw_held()
		return
	if target_prop != null and target_prop.hit_verb != "":
		target_prop.do_hit(player)
		player.body.reach = 1.0
		Events.intervention.emit(&"hit", target_prop.prop_id, {})
		return
	# shove nearby loose things
	if target_prop != null and target_prop.body is RigidBody3D and not target_prop.is_held():
		var rb := target_prop.body as RigidBody3D
		if rb.freeze:
			return
		rb.apply_central_impulse(player.look_dir().slide(Vector3.UP).normalized() * clampf(rb.mass, 1.0, 40.0) * 2.2 + Vector3(0, rb.mass * 0.2, 0))
		AudioManager.play_sfx(&"shove", rb.global_position, -4.0)
		Events.intervention.emit(&"shove", target_prop.prop_id, {})


func _inspect() -> void:
	if target_prop != null and target_prop.inspect_line != &"":
		target_prop.do_inspect(player)
	elif far_prop != null:
		far_prop.do_inspect(player)
	elif target != null and not (target is PropComponent) and target.has_method("inspect"):
		target.call("inspect", player)
	else:
		# generic hazard shrug when looking at a hazard
		pass


# ------------------------------------------------------------------ holding
func grab(pc: PropComponent) -> void:
	var rb := pc.body as RigidBody3D
	if rb == null or rb.freeze or pc.is_held():
		return
	held = rb
	held_prop = pc
	held_class = pc.grab_class
	rb.sleeping = false
	_saved_damp = rb.linear_damp
	player.add_collision_exception_with(rb)
	rb.add_collision_exception_with(player)
	pc.held_by = player
	_hold_basis = player.global_transform.basis.inverse() * rb.global_transform.basis
	_heavy_anchor = player.global_transform.affine_inverse() * rb.global_position
	_held_ext = 0.3
	for c in rb.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape:
			var sh := (c as CollisionShape3D).shape
			if sh is BoxShape3D:
				_held_ext = clampf((sh as BoxShape3D).size.z, 0.1, 1.0)
			elif sh is SphereShape3D:
				_held_ext = clampf((sh as SphereShape3D).radius * 2.0, 0.1, 1.0)
			elif sh is CylinderShape3D:
				_held_ext = clampf((sh as CylinderShape3D).radius * 2.0, 0.1, 1.0)
	pc.grabbed.emit(player)
	AudioManager.play_sfx(&"pickup", rb.global_position, -4.0)
	Events.intervention.emit(&"grab", pc.prop_id, {})
	Events.rumble_requested.emit(0.1, 0.15, 0.08)


func drop() -> void:
	if held == null:
		return
	var rb := held
	var pc := held_prop
	player.remove_collision_exception_with(rb)
	rb.remove_collision_exception_with(player)
	rb.linear_damp = _saved_damp
	rb.linear_velocity *= 0.3
	pc.held_by = null
	pc.released.emit(player)
	held = null
	held_prop = null
	held_class = ""
	AudioManager.play_sfx(&"drop", rb.global_position, -6.0)
	Events.intervention.emit(&"drop", pc.prop_id, {"distance": pc.moved_distance()})


func throw_held() -> void:
	if held == null or held_class == "heavy":
		return
	var rb := held
	var pc := held_prop
	var dir := player.look_dir()
	drop()
	var strength := pc.throw_strength * (1.0 if pc.grab_class == "light" else 0.55)
	rb.linear_velocity = dir * strength + Vector3(0, 1.2, 0)
	rb.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
	last_thrown = rb
	AudioManager.play_sfx(&"throw", rb.global_position, -3.0)
	player.body.reach = 1.0
	thrown.emit(rb)
	Events.intervention.emit(&"throw", pc.prop_id, {})


func rotate_held(rel: Vector2) -> void:
	if held == null:
		return
	var yaw := Basis(Vector3.UP, -rel.x * 0.012)
	var pit := Basis(player.camera.global_transform.basis.x, -rel.y * 0.012)
	_hold_basis = player.global_transform.basis.inverse() * (pit * yaw * (player.global_transform.basis * _hold_basis))


func _update_held(delta: float) -> void:
	if held == null:
		return
	if not is_instance_valid(held):
		held = null
		return
	if held.freeze:
		drop()
		return
	var target_pos: Vector3
	if held_class == "heavy":
		target_pos = player.global_transform * _heavy_anchor
		target_pos.y = held.global_position.y
	else:
		target_pos = player.hold_point.global_position
		var ext := _held_extent()
		target_pos += player.look_dir() * ext * 0.5
	var diff := target_pos - held.global_position
	if diff.length() > 3.4:
		drop()
		return
	var cap := 12.0 if held_class != "heavy" else 3.0
	var vel := diff * HOLD_SPEED
	if vel.length() > cap:
		vel = vel.normalized() * cap
	if held_class == "heavy":
		vel.y = 0.0
	held.linear_velocity = vel
	# orientation
	var want := player.global_transform.basis * _hold_basis
	var cur := held.global_transform.basis
	var q := (want * cur.inverse()).get_rotation_quaternion()
	var axis := q.get_axis() if q.get_angle() > 0.001 else Vector3.UP
	var ang := q.get_angle()
	if ang > PI:
		ang -= TAU
	held.angular_velocity = axis * ang * 10.0 if held_class != "heavy" else Vector3.ZERO


func _held_extent() -> float:
	return _held_ext


# ------------------------------------------------------------------ danger intuition
func _start_focus() -> void:
	if focus_active or focus_cooldown > 0.0:
		return
	focus_active = true
	_focus_timer = 2.8
	focus_cooldown = 5.0
	AudioManager.play_sfx(&"focus_on", null, -6.0)
	Events.rumble_requested.emit(0.05, 0.3, 0.3)
	AchievementManager.progress(&"paranoia_focus", 20)
	var hazards := get_tree().get_nodes_in_group("hazards")
	var n := 0
	for h in hazards:
		var pc := h as PropComponent
		if pc == null or pc.body == null or not is_instance_valid(pc.body):
			continue
		if pc.body.global_position.distance_to(player.global_position) > 28.0:
			continue
		n += 1
		for mi in pc.body.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = _hazard_mat
			_highlighted.append(mi)
		var lab := Label3D.new()
		lab.text = "!" if pc.hazard == 1 else "!!"
		lab.font_size = 96
		lab.pixel_size = 0.004
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.modulate = Color(1.0, 0.85, 0.2)
		lab.outline_size = 16
		lab.outline_modulate = Color(0.1, 0.05, 0.0)
		pc.body.add_child(lab)
		lab.position = Vector3(0, 1.0, 0)
		_hazard_labels.append(lab)
	player.screen_fx.tween_fx(&"desat", 0.45, 0.25)
	player.screen_fx.tween_fx(&"vignette", 0.35, 0.25)
	focused.emit()
	Events.intervention.emit(&"focus", &"", {"count": n})


func _update_focus(delta: float) -> void:
	if not focus_active:
		return
	_focus_timer -= delta
	if _focus_timer <= 0.0:
		focus_active = false
		for mi in _highlighted:
			if is_instance_valid(mi):
				(mi as MeshInstance3D).material_overlay = null
		_highlighted.clear()
		for l in _hazard_labels:
			if is_instance_valid(l):
				l.queue_free()
		_hazard_labels.clear()
		player.screen_fx.tween_fx(&"desat", 0.0, 0.4)
		player.screen_fx.tween_fx(&"vignette", 0.0, 0.4)


# ------------------------------------------------------------------ pickles commands
func _pickles_command_text() -> String:
	var pk := Director.pickles as Pickles
	if pk == null or pk.state == Pickles.State.SCRIPTED:
		return ""
	if _fetch_target() != null:
		return "Fetch"
	if _go_marker() != null:
		return "Go there"
	if _distractable_in_view():
		return "Bark"
	if pk.carrying != null:
		return "Drop it"
	if pk.state == Pickles.State.STAY:
		return "Come"
	return "Stay"


func _fetch_target() -> PropComponent:
	if target_prop != null and target_prop.fetchable:
		return target_prop
	return null


func _go_marker() -> Node3D:
	if target != null and target is Node3D and (target as Node3D).is_in_group("pickles_go"):
		return target as Node3D
	# look for a GO marker under the crosshair on the floor
	var cam := player.camera
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_transform.basis.z * 14.0, 32, [player.get_rid()])
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := space.intersect_ray(q)
	if not hit.is_empty() and hit.collider is Node and (hit.collider as Node).is_in_group("pickles_go"):
		return hit.collider as Node3D
	return null


func _distractable_in_view() -> bool:
	for n in get_tree().get_nodes_in_group("distractable"):
		var d := n as Node3D
		if d and player.camera.is_position_in_frustum(d.global_position) and d.global_position.distance_to(player.global_position) < 14.0:
			return true
	return false


func _handle_pickles_input(delta: float) -> void:
	var pk := Director.pickles as Pickles
	if pk == null:
		return
	if Input.is_action_just_pressed(&"pickles_command"):
		_f_down_time = 0.0
		_f_active = true
	if _f_active and Input.is_action_pressed(&"pickles_command"):
		_f_down_time += delta
		if _f_down_time > 0.45:
			_f_active = false
			pk.command(&"come")
	if _f_active and Input.is_action_just_released(&"pickles_command"):
		_f_active = false
		if pk.state == Pickles.State.SCRIPTED:
			return
		var ft := _fetch_target()
		var gm := _go_marker()
		if ft != null:
			pk.command(&"fetch", ft)
		elif gm != null:
			pk.command(&"goto", gm)
		elif _distractable_in_view():
			pk.command(&"bark")
		elif pk.carrying != null:
			pk.command(&"drop")
		elif pk.state == Pickles.State.STAY:
			pk.command(&"come")
		else:
			pk.command(&"stay")
