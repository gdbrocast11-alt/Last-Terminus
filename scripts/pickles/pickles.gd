class_name Pickles
extends NavActor
## Eddie's scruffy mutt. Generally obedient, delightfully distractible, and
## unkillable. Behaviour is a small authored state machine (no generic AI) so
## critical sequences can never be derailed by random behaviour; chapter
## scripts take him over with begin_scripted() / end_scripted().

signal barked
signal fetched(item: Node)
signal command_received(cmd: StringName)

enum State { FOLLOW, STAY, GOTO, FETCH_GO, FETCH_BACK, SCRIPTED }

const IDLE_POOL := ["idle", "sit", "sniff_stand", "scratch", "tilt", "idle", "yawn", "look_back", "lie", "stretch"]

var state: int = State.FOLLOW
var player: Node3D
var carrying: PropComponent
var fetch_target: PropComponent
var stay_pose := "sit"
var idle_pose := "idle"
var idle_timer := 3.0
var follow_slot := randf_range(-0.7, 0.7)
var leash_enabled := false
var leash_length := 4.2
var mouth_anchor: Node3D
var _goto_pos := Vector3.ZERO
var _player_still_time := 0.0
var _blink_t := 2.0
var _blink_phase := 0.0
var _jingle_t := 0.0
var _hidden_timer := 0.0
var _bark_cooldown := 0.0
var _pending_anim := ""
var _oneshot_time := 0.0
var _wrong_cooldown := 25.0
var immortal := true
var wander_ok := true


func _ready() -> void:
	char_id = "pickles"
	walk_speed = 1.5
	run_speed = 4.6
	turn_speed = 9.0
	super._ready()
	collision_layer = 4
	collision_mask = 1 | 16
	add_to_group("pickles")
	add_to_group("immortal")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2
	cap.height = 0.62
	cs.shape = cap
	cs.rotation_degrees.x = 90
	cs.position = Vector3(0, 0.3, 0)
	add_child(cs)
	nav.radius = 0.25
	nav.height = 0.7
	DialogueManager.register_speaker(&"pickles", self)
	play_anim("idle")


func _on_model_ready() -> void:
	if skel == null:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "Head"
	skel.add_child(ba)
	mouth_anchor = Marker3D.new()
	mouth_anchor.name = "Mouth"
	ba.add_child(mouth_anchor)
	mouth_anchor.position = Vector3(0, 0.05, -0.02)
	# Eye bones aren't animated, so we can blink them from script.


func _is_loop(n: String) -> bool:
	return not (n in ["bark", "shake", "tilt", "look_back", "stretch", "jump", "dodge", "roll", "yawn"])


# ------------------------------------------------------------------ public API
func get_prompt() -> String:
	return "Pet Pickles"


func interact(_pl: Node) -> void:
	pet()


func pet() -> void:
	if state == State.SCRIPTED:
		return
	play_oneshot("happy", 1.6)
	AudioManager.play_sfx(&"pk_pant", global_position, -4.0)
	var n := GameState.bump(&"pets")
	AchievementManager.progress(&"belly_rub", 10)
	if n % 4 == 1:
		DialogueManager.bark(DialogueManager.pick("gen_pet", 5))


func command(cmd: StringName, target: Variant = null) -> void:
	command_received.emit(cmd)
	Events.pickles_command.emit(cmd)
	if state == State.SCRIPTED:
		return
	match cmd:
		&"come":
			release_item(true)
			state = State.FOLLOW
			wander_ok = true
			play_oneshot("happy", 0.7)
			DialogueManager.bark(DialogueManager.pick("gen_come", 4))
		&"stay":
			state = State.STAY
			stop_moving()
			stay_pose = "sit"
			DialogueManager.bark(DialogueManager.pick("gen_stay", 3))
		&"goto":
			var p: Vector3 = target if target is Vector3 else (target as Node3D).global_position
			_goto_pos = p
			state = State.GOTO
			move_to(p, global_position.distance_to(p) > 8.0)
			DialogueManager.bark(DialogueManager.pick("gen_goto", 2))
		&"fetch":
			var pc := _prop_of(target)
			if pc == null:
				return
			fetch_target = pc
			state = State.FETCH_GO
			move_to(pc.body.global_position, true)
			DialogueManager.bark(DialogueManager.pick("gen_fetch", 3))
		&"drop":
			release_item(false)
			DialogueManager.bark(DialogueManager.pick("gen_drop", 3))
		&"bark":
			bark()
			_notify_distractables()
			DialogueManager.bark(DialogueManager.pick("gen_bark", 2))


func _prop_of(t: Variant) -> PropComponent:
	if t is PropComponent:
		return t
	if t is Node:
		var n := (t as Node).get_node_or_null("Prop")
		return n as PropComponent
	return null


func bark() -> void:
	if _bark_cooldown > 0.0 and state != State.SCRIPTED:
		return
	_bark_cooldown = 0.6
	play_oneshot("bark", 0.75)
	AudioManager.play_sfx(&"pk_bark", global_position, 2.0)
	barked.emit()
	Events.rumble_requested.emit(0.1, 0.1, 0.1)


func _notify_distractables() -> void:
	for n in get_tree().get_nodes_in_group("distractable"):
		if n.has_method("on_pickles_bark") and (n as Node3D).global_position.distance_to(global_position) < 14.0:
			n.on_pickles_bark(self)


func play_oneshot(anim_name: String, seconds: float) -> void:
	_pending_anim = anim_name
	_oneshot_time = seconds
	play_anim(anim_name, 0.15)


func release_item(silent: bool) -> void:
	if carrying == null:
		return
	var body := carrying.body
	carrying.pickles_holding = false
	if body is RigidBody3D:
		body.freeze = false
		body.linear_velocity = -global_transform.basis.z * 1.0 + Vector3(0, 1.0, 0)
	var c := carrying
	carrying = null
	if not silent:
		Events.intervention.emit(&"pickles_drop", c.prop_id, {})


func grab_item(pc: PropComponent) -> void:
	if pc == null or pc.body == null:
		return
	carrying = pc
	pc.pickles_holding = true
	if pc.body is RigidBody3D:
		pc.body.freeze = true
	Events.intervention.emit(&"pickles_grab", pc.prop_id, {})
	fetched.emit(pc.body)


## Chapter scripts take full control (tweens, authored gags).
func begin_scripted() -> void:
	state = State.SCRIPTED
	scripted = false
	stop_moving()


func end_scripted(to_state: int = State.FOLLOW) -> void:
	state = to_state
	scripted = false
	clear_face()


func teleport_near(pos: Vector3) -> void:
	var off := Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
	var p := pos + off
	var map := get_world_3d().navigation_map
	p = NavigationServer3D.map_get_closest_point(map, p)
	teleport(p)


## Failsafe when the world tries to hurt him: dodge into a funny safe pose.
func survive(event: StringName) -> void:
	Events.pickles_survived.emit(event)
	GameState.bump(&"pickles_survived")


# ------------------------------------------------------------------ per-frame
func _process(delta: float) -> void:
	_bark_cooldown = maxf(0.0, _bark_cooldown - delta)
	# blink by squashing the eye bones
	if skel:
		_blink_t -= delta
		if _blink_t <= 0.0 and _blink_phase <= 0.0:
			_blink_phase = 1.0
			_blink_t = randf_range(2.0, 6.0)
		if _blink_phase > 0.0:
			_blink_phase -= delta * 8.0
		var sq := 1.0 - 0.92 * clampf(sin(clampf(_blink_phase, 0, 1) * PI), 0, 1)
		for n in ["Eye.L", "Eye.R"]:
			var i := skel.find_bone(n)
			if i >= 0:
				skel.set_bone_pose_scale(i, Vector3(1.0, 1.0, sq))
	# carried item follows the mouth
	if carrying and is_instance_valid(carrying.body) and mouth_anchor:
		carrying.body.global_position = mouth_anchor.global_position
		carrying.body.global_rotation = global_rotation
	# collar jingle
	if horizontal_speed() > 0.8:
		_jingle_t -= delta * horizontal_speed()
		if _jingle_t <= 0.0:
			_jingle_t = 1.6
			AudioManager.play_sfx(&"pk_jingle", global_position, -12.0)
	if _oneshot_time > 0.0:
		_oneshot_time -= delta


func _physics_process(delta: float) -> void:
	player = Director.player
	if player == null:
		super._physics_process(delta)
		return
	_hidden_timer = _hidden_timer + delta if not _visible_to_player() else 0.0
	match state:
		State.FOLLOW:
			_follow(delta)
		State.STAY:
			pass
		State.GOTO:
			if not moving:
				state = State.STAY
				stay_pose = "sit"
		State.FETCH_GO:
			if fetch_target == null or not is_instance_valid(fetch_target.body):
				state = State.FOLLOW
			else:
				nav.target_position = fetch_target.body.global_position
				if global_position.distance_to(fetch_target.body.global_position) < 0.9 or not moving:
					grab_item(fetch_target)
					state = State.FETCH_BACK
					move_to(player.global_position, true)
		State.FETCH_BACK:
			nav.target_position = player.global_position
			if global_position.distance_to(player.global_position) < 1.5:
				stop_moving()
				var c := carrying
				release_item(true)
				state = State.FOLLOW
				play_oneshot("happy", 1.2)
				if c:
					Events.intervention.emit(&"fetch_delivered", c.prop_id, {})
	# out-of-bounds failsafe
	if global_position.y < -12.0 or global_position.distance_to(player.global_position) > 60.0:
		teleport_near(player.global_position)
	super._physics_process(delta)


func _follow(delta: float) -> void:
	var to_p := player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	var pspeed := 0.0
	if player is CharacterBody3D:
		pspeed = Vector2(player.velocity.x, player.velocity.z).length()
	_player_still_time = _player_still_time + delta if pspeed < 0.3 else 0.0
	var max_d := leash_length if leash_enabled else 3.6
	if dist > max_d or (moving and dist > 2.2):
		if not moving or fmod(Time.get_ticks_msec() / 1000.0, 0.7) < delta:
			var back := -player.global_transform.basis.z.rotated(Vector3.UP, PI + follow_slot)
			var tgt := player.global_position + back * 1.6
			move_to(tgt, dist > 7.5 or pspeed > 5.0)
	elif moving and dist < 2.2:
		stop_moving()
	if not moving and dist < 3.6:
		face_point(player.global_position)
	# idle personality
	if not moving:
		idle_timer -= delta
		if idle_timer <= 0.0:
			idle_timer = randf_range(4.0, 9.0)
			if _player_still_time > 2.5 and wander_ok:
				var pick: String = IDLE_POOL[randi() % IDLE_POOL.size()]
				idle_pose = pick
				if pick in ["yawn", "tilt", "look_back", "stretch"]:
					play_oneshot(pick, 2.0)
					idle_pose = "idle"
			else:
				idle_pose = "idle_alert"
	# stuck / hidden recovery
	if _hidden_timer > 3.0 and dist > 14.0:
		teleport_near(player.global_position - player.global_transform.basis.z * 2.5)
		_hidden_timer = 0.0


func _visible_to_player() -> bool:
	if player == null:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return true
	var to_me := global_position - cam.global_position
	return cam.is_position_in_frustum(global_position + Vector3(0, 0.3, 0)) and to_me.length() < 40.0


func _update_anim(_delta: float) -> void:
	if state == State.SCRIPTED:
		return
	if _oneshot_time > 0.0 and horizontal_speed() < 0.5:
		return
	var spd := horizontal_speed()
	if spd > 3.0:
		play_anim("run", 0.15, clampf(spd / 4.4, 0.8, 1.3))
	elif spd > 1.9:
		play_anim("carry" if carrying else "trot", 0.2, clampf(spd / 2.6, 0.8, 1.3))
	elif spd > 0.25:
		play_anim("carry" if carrying else "walk", 0.2, clampf(spd / 1.5, 0.8, 1.3))
	else:
		match state:
			State.STAY:
				play_anim(stay_pose, 0.3)
			State.GOTO, State.FETCH_GO, State.FETCH_BACK:
				play_anim("sit_alert", 0.3)
			_:
				play_anim(idle_pose, 0.35)
