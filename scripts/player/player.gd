class_name Player
extends CharacterBody3D
## Eddie Mercer, first person. Smooth look, walk/sprint/crouch/jump, contextual
## mantle, forgiving step-up, head bob, trauma-based camera shake, knock-downs
## that never take control away for long, and a forced-walk mode for escorts.

signal landed(speed: float)
signal mantled

const WALK_SPEED := 3.5
const SPRINT_SPEED := 5.9
const CROUCH_SPEED := 1.7
const ACCEL := 14.0
const AIR_ACCEL := 3.0
const JUMP_VELOCITY := 4.5
const GRAVITY := 13.0
const EYE_STAND := 1.62
const EYE_CROUCH := 1.05
const HEIGHT_STAND := 1.76
const HEIGHT_CROUCH := 1.1
const MOUSE_SCALE := 0.0022
const PAD_LOOK_RATE := 3.0
const STEP_HEIGHT := 0.36

var head: Node3D
var camera: Camera3D
var hold_point: Marker3D
var body: FPBody
var interact: PlayerInteract
var screen_fx: ScreenFX
var shape: CollisionShape3D
var capsule: CapsuleShape3D

var pitch := 0.0
var crouched := false
var sprinting := false
var frozen := false                 ## cutscene: no movement, look still works unless look_locked
var look_locked := false
var dead := false
var forced_velocity := Vector3.ZERO ## escorts: walk this way regardless of input
var forced_active := false
var stun := 0.0
var fov_kick := 0.0
var extra_roll := 0.0
var mantling := false
var trauma := 0.0
var last_surface := "concrete"

var _eye := EYE_STAND
var _bob_t := 0.0
var _step_t := 0.0
var _was_on_floor := true
var _fall_speed := 0.0
var _crouch_held := false
var _sprint_toggled := false
var _noise := FastNoiseLite.new()
var _noise_t := 0.0
var _look_smooth := Vector2.ZERO
var _cam_offset_extra := Vector3.ZERO
var _lean_roll := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8 | 16
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50.0)
	floor_stop_on_slope = true
	safe_margin = 0.002
	add_to_group("player")
	_build()
	_noise.frequency = 1.6
	_noise.seed = 4
	Events.camera_shake_requested.connect(add_trauma_time)
	Events.settings_changed.connect(_on_settings)
	_on_settings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build() -> void:
	shape = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = HEIGHT_STAND
	shape.shape = capsule
	shape.position.y = HEIGHT_STAND * 0.5
	add_child(shape)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = EYE_STAND
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.04
	camera.far = 400.0
	camera.current = true
	camera.cull_mask = 0xFFFFF
	var attrs := CameraAttributesPractical.new()
	attrs.auto_exposure_enabled = false
	attrs.dof_blur_far_enabled = false
	attrs.set_meta("dof_allowed", true)
	camera.attributes = attrs
	head.add_child(camera)
	hold_point = Marker3D.new()
	hold_point.name = "HoldPoint"
	hold_point.position = Vector3(0.12, -0.18, -1.0)
	camera.add_child(hold_point)
	body = FPBody.new()
	body.name = "FPBody"
	add_child(body)
	body.setup()
	body.position = Vector3(0, 0, 0.16)   # body sits slightly behind the eyes so the chest never clips the lens
	interact = PlayerInteract.new()
	interact.name = "Interact"
	interact.player = self
	add_child(interact)
	screen_fx = ScreenFX.new()
	screen_fx.name = "ScreenFX"
	add_child(screen_fx)


func _on_settings() -> void:
	if camera:
		camera.fov = SettingsManager.get_value("graphics/fov")


# --------------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if dead or get_tree().paused or Director.input_locked or look_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = SettingsManager.get_value("input/mouse_sensitivity") * MOUSE_SCALE
		var inv: float = -1.0 if SettingsManager.get_value("input/invert_y") else 1.0
		if interact and interact.rotating_held:
			interact.rotate_held(event.relative)
			return
		rotation.y -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens * inv, deg_to_rad(-88.0), deg_to_rad(88.0))


func add_trauma_time(amount: float, seconds: float) -> void:
	# Shake requests are scaled by the comfort option and capped for safety.
	var k: float = SettingsManager.get_value("comfort/camera_shake")
	trauma = minf(1.0, trauma + amount * k)


func knock(direction: Vector3, strength: float, seconds := 0.9) -> void:
	direction.y = 0.0
	velocity += direction.normalized() * strength + Vector3(0, strength * 0.25, 0)
	stun = seconds
	extra_roll = deg_to_rad(randf_range(8.0, 14.0)) * (1.0 if randf() > 0.5 else -1.0) * SettingsManager.get_value("comfort/camera_shake")
	Events.rumble_requested.emit(0.5, 0.8, 0.3)
	trauma = minf(1.0, trauma + 0.5)
	AudioManager.play_sfx(&"thump", global_position, 0.0)


func die(reason: StringName = &"generic") -> void:
	if dead:
		return
	dead = true
	frozen = true
	Events.player_died.emit(reason)
	Events.flash_requested.emit(Color(0.7, 0.0, 0.0), 0.5)
	AudioManager.play_sfx(&"death_sting")
	var tw := create_tween()
	tw.tween_property(head, "position:y", 0.35, 0.5).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "extra_roll", deg_to_rad(70.0), 0.5)
	Events.rumble_requested.emit(0.8, 1.0, 0.6)


func set_forced_walk(vel: Vector3) -> void:
	forced_velocity = vel
	forced_active = vel != Vector3.ZERO


# --------------------------------------------------------------------- physics
func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	var locked := frozen or Director.input_locked or get_tree().paused
	stun = maxf(0.0, stun - delta)
	_update_look(delta, locked)
	if mantling:
		return
	# crouch (toggle or hold per settings)
	if not locked:
		if SettingsManager.get_value("input/crouch_toggle"):
			if Input.is_action_just_pressed(&"crouch"):
				_set_crouch(not crouched)
		else:
			_set_crouch(Input.is_action_pressed(&"crouch"))
		if SettingsManager.get_value("input/sprint_toggle"):
			if Input.is_action_just_pressed(&"sprint"):
				_sprint_toggled = not _sprint_toggled
		else:
			_sprint_toggled = Input.is_action_pressed(&"sprint")
	var input_dir := Vector2.ZERO
	if not locked and not forced_active:
		input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var dir := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	var holding_heavy: bool = interact != null and interact.held_class == "heavy"
	var target_speed := CROUCH_SPEED if crouched else WALK_SPEED
	sprinting = false
	if _sprint_toggled and not crouched and input_dir.y <= 0.2 and input_dir.length() > 0.1 and not holding_heavy:
		target_speed = SPRINT_SPEED
		sprinting = true
	if holding_heavy:
		target_speed *= 0.65
	elif interact != null and interact.held_class == "medium":
		target_speed *= 0.85
	if input_dir.length() < 0.1 and _sprint_toggled and SettingsManager.get_value("input/sprint_toggle"):
		_sprint_toggled = false
	var control := 1.0 if stun <= 0.0 else 0.25
	var wish := dir * target_speed
	if forced_active:
		wish = forced_velocity
		control = 1.0
	var accel := ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, wish.x, accel * delta * target_speed * control * 0.6 + accel * delta)
	velocity.z = move_toward(velocity.z, wish.z, accel * delta * target_speed * control * 0.6 + accel * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	# jump / mantle
	if not locked and Input.is_action_just_pressed(&"jump") and stun <= 0.0:
		if not _try_mantle() and is_on_floor() and not crouched:
			velocity.y = JUMP_VELOCITY
	elif not locked and Input.is_action_pressed(&"jump") and not is_on_floor() and velocity.y < 1.0:
		_try_mantle()
	_fall_speed = minf(_fall_speed, velocity.y)
	var horiz := Vector3(velocity.x, 0, velocity.z)
	if horiz.length() > 0.5:
		_step_up(horiz.normalized() * 0.3)
	move_and_slide()
	# push rigid bodies gently
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var rb := c.get_collider() as RigidBody3D
		if rb and not (interact and interact.held == rb):
			rb.apply_central_impulse(-c.get_normal() * 1.2 * minf(1.0, 60.0 / maxf(rb.mass, 1.0)))
	if is_on_floor() and not _was_on_floor:
		landed.emit(_fall_speed)
		if _fall_speed < -5.0:
			AudioManager.play_sfx(&"thump", global_position, -6.0)
			trauma = minf(1.0, trauma + 0.25)
			Events.rumble_requested.emit(0.3, 0.4, 0.15)
		_fall_speed = 0.0
	_was_on_floor = is_on_floor()
	# body / animation
	var spd := Vector2(velocity.x, velocity.z).length()
	body.drive(spd, crouched, not is_on_floor(), sprinting)
	body.look_pitch = rad_to_deg(pitch)
	body.rotation = Vector3.ZERO
	_footsteps(delta, spd)


func _update_look(delta: float, locked: bool) -> void:
	if locked and not Director.input_locked and not frozen:
		return
	if look_locked or get_tree().paused or dead:
		return
	if PadLook.enabled():
		var v := PadLook.stick()
		var sens: float = SettingsManager.get_value("input/pad_sensitivity")
		var inv: float = -1.0 if SettingsManager.get_value("input/invert_y") else 1.0
		if interact and interact.rotating_held:
			interact.rotate_held(v * 6.0 * delta * 60.0 * 0.5)
		elif not Director.input_locked:
			rotation.y -= v.x * PAD_LOOK_RATE * sens * delta
			pitch = clampf(pitch - v.y * PAD_LOOK_RATE * 0.75 * sens * delta * inv, deg_to_rad(-88.0), deg_to_rad(88.0))


func _set_crouch(v: bool) -> void:
	if v == crouched:
		return
	if not v and _ceiling_blocked():
		return
	crouched = v
	var h := HEIGHT_CROUCH if crouched else HEIGHT_STAND
	capsule.height = h
	shape.position.y = h * 0.5


func _ceiling_blocked() -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.9, 0), global_position + Vector3(0, HEIGHT_STAND + 0.05, 0), 1)
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()


func _step_up(motion: Vector3) -> void:
	if not is_on_floor() or velocity.y > 0.5:
		return
	var xf := global_transform
	if test_move(xf, motion):
		if not test_move(xf, Vector3(0, STEP_HEIGHT, 0)):
			var up := xf.translated(Vector3(0, STEP_HEIGHT, 0))
			if not test_move(up, motion):
				global_position.y += STEP_HEIGHT * 0.999
				velocity.y = 0.0


func _try_mantle() -> bool:
	if mantling or stun > 0.0:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var space := get_world_3d().direct_space_state
	var base := global_position
	# wall in front at knee height?
	var q1 := PhysicsRayQueryParameters3D.create(base + Vector3(0, 0.45, 0), base + Vector3(0, 0.45, 0) + fwd * 0.85, 1)
	q1.exclude = [get_rid()]
	var wall := space.intersect_ray(q1)
	if wall.is_empty():
		return false
	# find the ledge top above it
	var probe: Vector3 = wall.position + fwd * 0.28
	var q2 := PhysicsRayQueryParameters3D.create(probe + Vector3(0, 1.75, 0), probe + Vector3(0, 0.1, 0), 1)
	q2.exclude = [get_rid()]
	var top := space.intersect_ray(q2)
	if top.is_empty():
		return false
	var height: float = top.position.y - base.y
	if height < 0.5 or height > 1.5 or top.normal.y < 0.7:
		return false
	# clearance at the destination
	var dest: Vector3 = top.position + Vector3(0, 0.03, 0)
	var sp := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.2
	sp.shape = cap
	sp.transform = Transform3D(Basis.IDENTITY, dest + Vector3(0, 0.75, 0))
	sp.collision_mask = 1
	if not space.intersect_shape(sp, 1).is_empty():
		return false
	_do_mantle(dest, height)
	return true


func _do_mantle(dest: Vector3, height: float) -> void:
	mantling = true
	velocity = Vector3.ZERO
	mantled.emit()
	AudioManager.play_sfx(&"mantle", global_position, -3.0)
	var start := global_position
	var mid := Vector3(start.x, dest.y + 0.02, start.z) + (dest - start).normalized() * 0.05
	var t := clampf(0.35 + height * 0.18, 0.4, 0.62)
	var tw := create_tween()
	tw.tween_property(self, "global_position", Vector3(start.x, dest.y, start.z), t * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", dest, t * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: mantling = false)
	create_tween().tween_property(self, "fov_kick", 4.0, t * 0.5).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(self, "fov_kick", 0.0, t * 0.5).set_delay(t * 0.5)


# --------------------------------------------------------------------- camera + audio
func _process(delta: float) -> void:
	if head == null:
		return
	var target_eye := EYE_CROUCH if crouched else EYE_STAND
	_eye = lerpf(_eye, target_eye, clampf(delta * 10.0, 0.0, 1.0))
	if not dead:
		head.position.y = _eye
	var bob_amt: float = SettingsManager.get_value("comfort/head_bob")
	var spd := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and spd > 0.4 and not frozen
	var bob := Vector3.ZERO
	if moving:
		_bob_t += delta * spd * (1.55 if not sprinting else 1.35)
		bob.y = sin(_bob_t * TAU * 0.5) * 0.028 * bob_amt * (1.4 if sprinting else 1.0)
		bob.x = cos(_bob_t * TAU * 0.25) * 0.016 * bob_amt
	else:
		_bob_t = lerpf(_bob_t, roundf(_bob_t), clampf(delta * 6.0, 0.0, 1.0))
	# strafe lean
	var side := 0.0
	if not frozen and not Director.input_locked:
		side = Input.get_axis(&"move_left", &"move_right")
	_lean_roll = lerpf(_lean_roll, -side * deg_to_rad(1.2) * bob_amt, clampf(delta * 8.0, 0.0, 1.0))
	# trauma shake
	trauma = maxf(0.0, trauma - delta * 1.1)
	var shake := Vector3.ZERO
	var shake_roll := 0.0
	if trauma > 0.001:
		_noise_t += delta * 60.0
		var t2 := trauma * trauma
		shake = Vector3(_noise.get_noise_2d(_noise_t, 0.0), _noise.get_noise_2d(_noise_t, 100.0), 0.0) * 0.06 * t2
		shake_roll = _noise.get_noise_2d(_noise_t, 200.0) * deg_to_rad(4.0) * t2
	extra_roll = lerpf(extra_roll, 0.0, clampf(delta * 3.0, 0.0, 1.0)) if not dead else extra_roll
	camera.position = bob + shake
	camera.rotation = Vector3(pitch, 0, extra_roll + _lean_roll + shake_roll)
	var base_fov: float = SettingsManager.get_value("graphics/fov")
	var target_fov := base_fov + (5.0 if sprinting and spd > 5.0 else 0.0) + fov_kick
	if interact and interact.inspecting:
		target_fov = base_fov - 22.0
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 8.0, 0.0, 1.0))
	# motion blur only when sprinting / knocked, scaled by setting
	var mb: float = SettingsManager.get_value("comfort/motion_blur")
	var blur_target := 0.0
	if sprinting and spd > 5.0:
		blur_target = 0.25
	blur_target = maxf(blur_target, minf(1.0, absf(extra_roll) * 4.0))
	blur_target *= mb
	var cur: Variant = screen_fx.mat.get_shader_parameter("blur")
	screen_fx.set_fx(&"blur", lerpf(float(cur if cur != null else 0.0), blur_target, clampf(delta * 6.0, 0.0, 1.0)))


func _footsteps(delta: float, spd: float) -> void:
	if not is_on_floor() or spd < 0.6:
		_step_t = 0.0
		return
	_step_t -= delta * spd
	if _step_t <= 0.0:
		_step_t = 1.35 if not crouched else 1.0
		last_surface = _surface_below()
		var vol := -10.0 if crouched else (-3.0 if sprinting else -7.0)
		AudioManager.play_sfx(StringName("step_" + last_surface), global_position, vol)


func _surface_below() -> String:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.2, 0), global_position + Vector3(0, -0.6, 0), 1 | 16)
	q.exclude = [get_rid()]
	var r := space.intersect_ray(q)
	if r.is_empty():
		return last_surface
	var col: Object = r.collider
	if col and col.has_meta("surface"):
		return String(col.get_meta("surface"))
	return "concrete"


func eye_position() -> Vector3:
	return camera.global_position


func look_dir() -> Vector3:
	return -camera.global_transform.basis.z


## Smoothly turn the view toward a world point (used in cutscenes; short and skippable).
func look_at_point(p: Vector3, seconds := 0.6) -> void:
	var to := p - camera.global_position
	var yaw := atan2(-to.x, -to.z)
	var pit := atan2(to.y, Vector2(to.x, to.z).length())
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation:y", lerp_angle(rotation.y, yaw, 1.0), seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "pitch", clampf(pit, deg_to_rad(-80), deg_to_rad(80)), seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
