class_name NavActor
extends CharacterBody3D
## Shared base for Pickles and human actors: navmesh walking, animation
## switching, gravity, stuck detection and a scripted-motion override.

signal arrived
signal stuck

@export var walk_speed := 1.6
@export var run_speed := 4.2
@export var turn_speed := 8.0
@export var gravity := 14.0
@export var char_id := "eddie"

var model: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var nav: NavigationAgent3D
var moving := false
var running := false
var scripted := false                   ## when true, physics movement is disabled (tweens drive us)
var face_target := Vector3.ZERO
var _has_face := false
var _current_anim := ""
var _stuck_timer := 0.0
var _last_pos := Vector3.ZERO
var _move_timeout := 0.0
var speed_mul := 1.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 16
	_build()


func _build() -> void:
	nav = NavigationAgent3D.new()
	nav.path_desired_distance = 0.35
	nav.target_desired_distance = 0.55
	nav.radius = 0.35
	nav.height = 1.7
	nav.path_max_distance = 2.0
	add_child(nav)
	_load_model()
	_last_pos = global_position


func _load_model() -> void:
	var path := "res://scenes/characters/%s.tscn" % char_id
	if not ResourceLoader.exists(path):
		push_error("NavActor: missing character scene " + path)
		return
	model = (load(path) as PackedScene).instantiate()
	model.name = "Model"
	add_child(model)
	skel = BoneUtil.find_skeleton(model)
	anim = BoneUtil.find_anim_player(model)
	if anim:
		anim.playback_default_blend_time = 0.25
	_on_model_ready()


func _on_model_ready() -> void:
	pass


func play_anim(anim_name: String, blend: float = 0.25, speed: float = 1.0) -> void:
	if anim == null or not anim.has_animation(anim_name):
		return
	if _current_anim == anim_name and anim.is_playing():
		anim.speed_scale = speed
		return
	_current_anim = anim_name
	var a := anim.get_animation(anim_name)
	if a:
		a.loop_mode = Animation.LOOP_LINEAR if _is_loop(anim_name) else Animation.LOOP_NONE
	anim.play(anim_name, blend, speed)


func _is_loop(_n: String) -> bool:
	return true


func current_anim() -> String:
	return _current_anim


func move_to(pos: Vector3, run := false, timeout := 40.0) -> void:
	moving = true
	running = run
	_move_timeout = timeout
	nav.target_position = pos
	_stuck_timer = 0.0


## Awaitable version.
func go_to(pos: Vector3, run := false, timeout := 40.0) -> void:
	move_to(pos, run, timeout)
	await arrived


func stop_moving() -> void:
	moving = false
	velocity.x = 0.0
	velocity.z = 0.0


func face_point(p: Vector3) -> void:
	face_target = p
	_has_face = true


func clear_face() -> void:
	_has_face = false


func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_last_pos = pos
	_stuck_timer = 0.0


func _physics_process(delta: float) -> void:
	if scripted:
		return
	var horiz := Vector3.ZERO
	if moving:
		_move_timeout -= delta
		var next := nav.get_next_path_position()
		var to_next := next - global_position
		to_next.y = 0.0
		var final := nav.target_position - global_position
		final.y = 0.0
		if final.length() < nav.target_desired_distance or nav.is_navigation_finished() and final.length() < 1.2 or _move_timeout <= 0.0:
			moving = false
			arrived.emit()
		else:
			if to_next.length() < 0.05 or nav.is_navigation_finished():
				to_next = final    # no navmesh path: head straight for the goal
			var spd := (run_speed if running else walk_speed) * speed_mul
			horiz = to_next.normalized() * spd
			_turn_toward(to_next, delta)
			# stuck detection
			if global_position.distance_to(_last_pos) < 0.02 * delta * 60.0 * 0.4:
				_stuck_timer += delta
			else:
				_stuck_timer = 0.0
			_last_pos = global_position
			if _stuck_timer > 1.4:
				_stuck_timer = 0.0
				stuck.emit()
	elif _has_face:
		var d := face_target - global_position
		d.y = 0.0
		if d.length() > 0.05:
			_turn_toward(d, delta)
	velocity.x = move_toward(velocity.x, horiz.x, 30.0 * delta) if horiz != Vector3.ZERO else move_toward(velocity.x, 0.0, 22.0 * delta)
	velocity.z = move_toward(velocity.z, horiz.z, 30.0 * delta) if horiz != Vector3.ZERO else move_toward(velocity.z, 0.0, 22.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	_update_anim(delta)


func _turn_toward(dir: Vector3, delta: float) -> void:
	# Models face -Z (Blender +Y). rotation.y such that -Z points along dir.
	var target := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target, clampf(turn_speed * delta, 0.0, 1.0))


func _update_anim(_delta: float) -> void:
	pass


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()
