class_name Chapter
extends Node
## Base class of every chapter controller. Director instantiates the concrete
## script, sets `level` and `start_beat`, and adds it to the World. `_play(beat)`
## is a coroutine that runs the chapter from `beat` (so checkpoint reloads resume
## mid-chapter). Helpers keep chapter scripts declarative and short.

var level: LevelRoot
var start_beat: StringName = &"start"
var player: Player
var pickles: Pickles
var npcs: Dictionary = {}
var busy_talk := false
var qa: Array[Dictionary] = []          ## QA bot hooks: {name, cond: Callable, act: Callable, done}
var _vision_cam: Camera3D
var _rep: Dictionary = {}               ## repeat-line rotation counters
var _skip_vision := false
var chapter_done := false


func _ready() -> void:
	name = "Chapter"
	add_to_group("chapter")
	await get_tree().process_frame
	if level == null:
		level = Director.level as LevelRoot
	Events.player_died.connect(_on_player_died)
	await _play(start_beat)


## Override: run the chapter starting at `beat`.
func _play(_beat: StringName) -> void:
	pass


func _on_player_died(_reason: StringName) -> void:
	Director.respawn_after_death("")


# ------------------------------------------------------------------ world access
func mk(marker_name: String) -> Transform3D:
	return level.marker(marker_name)


func mkp(marker_name: String) -> Vector3:
	return level.marker_pos(marker_name)


func prop(prop_name: String) -> Node3D:
	return level.prop(prop_name)


func pc(prop_name: String) -> PropComponent:
	return level.prop_comp(prop_name)


func rb(prop_name: String) -> RigidBody3D:
	return level.prop(prop_name) as RigidBody3D


# ------------------------------------------------------------------ spawning
func begin_player(marker: String, pickles_marker := "PicklesStart", with_pickles := true, fade_in := 0.9) -> void:
	player = Director.spawn_player(level.marker(marker)) as Player
	if with_pickles:
		pickles = Director.spawn_pickles(level.marker(pickles_marker)) as Pickles
	await get_tree().process_frame
	if fade_in > 0.0:
		Director.fade(false, fade_in)
	else:
		Director.fade_rect.color.a = 0.0


func npc(id: StringName, marker: String, opts := {}) -> Actor:
	var a := Actor.new()
	a.actor_id = id
	a.display_name = String(opts.get("name", DialogueManager.DISPLAY_NAMES.get(String(id), "")))
	a.talkable = bool(opts.get("talkable", false))
	a.idle_anim = String(opts.get("idle", "idle"))
	a.look_at_player = bool(opts.get("look", true))
	a.prompt = String(opts.get("prompt", "Talk to"))
	a.name = String(opts.get("node_name", String(id).capitalize()))
	Director.world.add_child(a)
	a.global_transform = level.marker(marker)
	npcs[id] = a
	if opts.has("emotion"):
		a.set_emotion(StringName(opts.emotion))
	return a


func actor(id: StringName) -> Actor:
	return npcs.get(id) as Actor


func remove_npc(id: StringName) -> void:
	var a: Actor = npcs.get(id) as Actor
	if a and is_instance_valid(a):
		a.queue_free()
	npcs.erase(id)


# ------------------------------------------------------------------ dialogue
func say(line: String, prio := 1) -> void:
	await DialogueManager.say(StringName(line), prio)


func seq(lines: Array, gap := 0.2, prio := 1) -> void:
	await DialogueManager.say_seq(lines, gap, prio)


func bark(line: String) -> void:
	DialogueManager.bark(StringName(line))


## Talk handler: runs `cb` when the player interacts with actor `a`, one conversation at a time.
func on_talk(a: Actor, cb: Callable) -> void:
	a.talkable = true
	a.interacted.connect(func(_p: Node) -> void: _run_talk(a, cb))


func _run_talk(a: Actor, cb: Callable) -> void:
	if busy_talk or DialogueManager.is_busy():
		return
	busy_talk = true
	a.face_point(Director.player.global_position)
	await cb.call()
	a.clear_face()
	busy_talk = false


## Returns a callable that plays prefix_01, prefix_02 ... in rotation (repeat chatter).
func rotate_lines(prefix: String, count: int) -> Callable:
	return func() -> void:
		var i: int = int(_rep.get(prefix, 0))
		_rep[prefix] = i + 1
		await DialogueManager.say(StringName("%s_%02d" % [prefix, 1 + (i % count)]), 1)


# ------------------------------------------------------------------ flow helpers
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Polls `cond` every frame. Returns true when it became true, false on timeout (timeout<=0 => forever).
func wait_until(cond: Callable, timeout := 0.0) -> bool:
	var t := 0.0
	while not bool(cond.call()):
		await get_tree().process_frame
		if not get_tree().paused:
			t += get_process_delta_time()
		if timeout > 0.0 and t >= timeout:
			return false
		if not is_inside_tree():
			return false
	return true


func wait_flag(f: String, timeout := 0.0) -> bool:
	return await wait_until(func() -> bool: return GameState.has_flag(StringName(f)), timeout)


func wait_speech() -> void:
	while DialogueManager.is_busy():
		await get_tree().process_frame


func objective(text: String) -> void:
	SequenceManager.set_objective(text)


func hint(text: String, seconds := 4.0) -> void:
	Events.hint_requested.emit(text, seconds)


func title_card(text: String, seconds := 2.4) -> void:
	Events.title_card_requested.emit(text, seconds)


func save(beat: StringName) -> void:
	GameState.beat = beat
	SaveManager.checkpoint(beat)


func flag(f: String, v: Variant = true) -> void:
	GameState.set_flag(StringName(f), v)


func has_flag(f: String) -> bool:
	return GameState.has_flag(StringName(f))


func music(track: String, fade := 1.5) -> void:
	AudioManager.play_music(StringName(track), fade)


func sting(name_: String, db := 0.0) -> void:
	AudioManager.stinger(StringName(name_), db)


func sfx(name_: String, at: Variant = null, db := 0.0) -> void:
	AudioManager.play_sfx(StringName(name_), at, db)


func cine(on: bool) -> void:
	Director.lock_input(on)
	if player:
		player.frozen = on
	Director.set_hud_visible(not on)


func pin_hud(on: bool) -> void:
	Director.set_hud_visible(on)


## Walk the player (input ignored) to a world point.
func walk_player_to(pos: Vector3, speed := 2.4, arrive := 0.4, timeout := 14.0) -> void:
	if player == null:
		return
	var t := 0.0
	while t < timeout:
		var d := pos - player.global_position
		d.y = 0.0
		if d.length() < arrive:
			break
		player.set_forced_walk(d.normalized() * speed)
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-d.x, -d.z), 0.12)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	player.set_forced_walk(Vector3.ZERO)


func face_player_to(point: Vector3, seconds := 0.6) -> void:
	if player:
		player.look_at_point(point, seconds)
		await wait(seconds)


func teleport_player(marker: String) -> void:
	if player == null:
		return
	var xf := level.marker(marker)
	player.global_position = xf.origin + Vector3(0, 0.05, 0)
	player.rotation.y = xf.basis.get_euler().y
	player.velocity = Vector3.ZERO


## Fade to black, hold, run `mid`, fade back.
func blackout(hold := 0.5, mid: Callable = Callable(), seconds := 0.5) -> void:
	await Director.fade(true, seconds)
	if mid.is_valid():
		await mid.call()
	await wait(hold)
	await Director.fade(false, seconds)


func end_to(next_chapter: int) -> void:
	chapter_done = true
	await Director.load_chapter(next_chapter, &"start")


func set_group(group: String, on: bool) -> void:
	level.set_deco(group, on)


# ------------------------------------------------------------------ prop helpers
func bind_use(prop_name: String, verb: String, cb: Callable) -> PropComponent:
	var c := pc(prop_name)
	if c == null:
		push_warning("Chapter: bind_use missing prop " + prop_name)
		return null
	c.use_verb = verb
	c.used.connect(func(_p: Node) -> void: cb.call())
	return c


func unbind_use(prop_name: String) -> void:
	var c := pc(prop_name)
	if c:
		c.use_verb = ""
		for cn in c.used.get_connections():
			c.used.disconnect(cn.callable)


func set_inspect(prop_name: String, line: String) -> void:
	var c := pc(prop_name)
	if c:
		c.inspect_line = StringName(line)


func set_hazard(prop_name: String, level_: int) -> void:
	var c := pc(prop_name)
	if c:
		c.hazard = level_
		if level_ > 0:
			c.add_to_group("hazards")
		else:
			c.remove_from_group("hazards")


func freeze_prop(prop_name: String, on := true) -> void:
	var r := rb(prop_name)
	if r:
		r.freeze = on
		r.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC


## Small trigger volume: emits once when the player enters.
func trigger(center: Vector3, size: Vector3, cb: Callable, once := true) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	a.add_child(cs)
	level.add_child(a)
	a.global_position = center
	a.body_entered.connect(func(b: Node) -> void:
		if b is Player:
			if once:
				a.set_deferred("monitoring", false)
			cb.call())
	return a


func trigger_marker(marker_name: String, size: Vector3, cb: Callable, once := true) -> Area3D:
	return trigger(mkp(marker_name) + Vector3(0, size.y * 0.5, 0), size, cb, once)


## Invisible interaction proxy (layer 6) so landmarks without colliders can be inspected (E near, RMB far).
func add_inspect(center: Vector3, size: Vector3, line: String, node_name := "", hazard_level := 0) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 32
	sb.collision_mask = 0
	sb.name = node_name if node_name != "" else "Inspect_" + line
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	var p := PropComponent.new()
	p.name = "Prop"
	p.inspect_line = StringName(line)
	p.hazard = hazard_level
	sb.add_child(p)
	level.add_child(sb)
	sb.global_position = center
	return sb


## Invisible "use" proxy (layer 6) with a prompt verb, for things that have no collider of their own.
func add_use(center: Vector3, size: Vector3, verb: String, cb: Callable, node_name := "") -> StaticBody3D:
	var sb := add_inspect(center, size, "", node_name if node_name != "" else "Use_" + verb)
	var c := sb.get_node("Prop") as PropComponent
	c.use_verb = verb
	c.used.connect(func(_p: Node) -> void: cb.call())
	return sb


## Spawn an extra prop scene at runtime.
func spawn_prop(scene: String, pos: Vector3, yaw_deg := 0.0, node_name := "") -> Node3D:
	var packed := load("res://scenes/props/%s.tscn" % scene) as PackedScene
	var n := packed.instantiate() as Node3D
	if node_name != "":
		n.name = node_name
	level.add_child(n)
	n.global_position = pos
	n.rotation_degrees.y = yaw_deg
	return n


## Wait for physics props to come to rest, then remember that as their "home" (chain blockers compare against it).
func settle_props(names: Array, seconds := 1.6) -> void:
	await wait(seconds)
	for n in names:
		var c := pc(String(n))
		if c and c.body:
			c.home_xform = c.body.global_transform


# ------------------------------------------------------------------ chains
func make_chain(id: String, steps: Array, opts := {}) -> AccidentChain:
	var c := AccidentChain.new()
	c.name = "Chain_" + id
	add_child(c)
	c.setup(level, StringName(id), steps, opts)
	return c


func make_lethal(node_name: String, center: Vector3, size: Vector3) -> LethalVolume:
	var v := LethalVolume.new()
	v.name = node_name
	v.size = size
	level.add_child(v)
	v.global_position = center
	return v


# ------------------------------------------------------------------ premonition
## Plays a premonition: the chain runs in vision mode (no deaths / state changes) while a temporary camera
## cuts between shots. shots: [{step, t, cam, look, fov, hold, line, sfx}]. Everything is rewound afterwards.
func vision(id: StringName, chain: AccidentChain, watch: Array, shots: Array, opts := {}) -> void:
	var seen: bool = GameState.seen_premonitions.has(String(id))
	var max_t: float = opts.get("max", 16.0)
	cine(true)
	Events.premonition_started.emit(id)
	AudioManager.play_music(&"mus_premonition", 0.5)
	AudioManager.set_muffled(0.6, 0.4)
	var fx := player.screen_fx
	var k: float = SettingsManager.get_value("comfort/premonition_distortion")
	fx.tween_fx(&"desat", 0.85, 0.25)
	fx.tween_fx(&"vignette", 0.65, 0.25)
	fx.tween_fx(&"aberration", 0.012 * k, 0.25)
	fx.tween_fx(&"wobble", 0.35 * k, 0.25)
	fx.tween_fx(&"film_grain", 0.12, 0.25)
	fx.set_fx(&"tint", Color(1.0, 0.72, 0.7))
	fx.tween_fx(&"tint_amount", 0.35, 0.25)
	Events.flash_requested.emit(Color.WHITE, 0.45)
	_vision_cam = Camera3D.new()
	_vision_cam.fov = 62.0
	Director.world.add_child(_vision_cam)
	_vision_cam.current = true
	var chain_ref := chain
	chain_ref.vision = true
	chain_ref.snapshot(watch)
	var cam_tween: Tween
	var apply := func(s: Dictionary) -> void:
		var from: Vector3 = _as_pos(s.get("cam", player.global_position + Vector3(0, 1.6, 0)))
		var look: Vector3 = _as_pos(s.get("look", from + Vector3(0, 0, -1)))
		_vision_cam.global_position = from
		_vision_cam.look_at(look, Vector3.UP)
		_vision_cam.fov = float(s.get("fov", 62.0))
		if s.has("cam_to"):
			if cam_tween and cam_tween.is_valid():
				cam_tween.kill()
			cam_tween = create_tween()
			cam_tween.tween_property(_vision_cam, "global_position", _as_pos(s.cam_to), float(s.get("hold", 2.0)))
		if s.has("line"):
			DialogueManager.say(StringName(s.line), 2)
		if s.has("sfx"):
			AudioManager.play_sfx(StringName(s.sfx), null, float(s.get("db", 0.0)))
		Events.flash_requested.emit(Color(1, 1, 1), 0.2)
	# time-based and step-based shots
	for s: Dictionary in shots:
		if s.has("t"):
			get_tree().create_timer(float(s.t), false).timeout.connect(func() -> void:
				if is_instance_valid(_vision_cam):
					apply.call(s))
	chain_ref.step_fired.connect(func(sid: StringName) -> void:
		for s: Dictionary in shots:
			if s.get("step", "") == String(sid) and is_instance_valid(_vision_cam):
				apply.call(s))
	if shots.size() > 0 and shots[0].has("t") == false and shots[0].get("step", "") == "":
		apply.call(shots[0])
	chain_ref.start()
	var t := 0.0
	_skip_vision = false
	while chain_ref.is_running() and t < max_t:
		await get_tree().process_frame
		t += get_process_delta_time()
		if seen and (Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"jump")):
			break
	chain_ref.stop()
	chain_ref.restore()
	chain_ref.vision = false
	Events.flash_requested.emit(Color.WHITE, 0.8)
	sting("sting_tragic_build")
	await wait(0.35)
	if is_instance_valid(_vision_cam):
		_vision_cam.queue_free()
	player.camera.current = true
	fx.reset_all()
	AudioManager.set_muffled(0.0, 0.6)
	GameState.seen_premonitions[String(id)] = true
	Events.premonition_ended.emit(id)
	# input stays locked: callers continue their cutscene and release it with cine(false)


## Short "flicker" premonition (no chain): distortion + stinger while `lines` play, then back to normal.
func flash_vision(lines: Array, keep_locked := false) -> void:
	cine(true)
	var fx := player.screen_fx
	var k: float = SettingsManager.get_value("comfort/premonition_distortion")
	sting("sting_tragic_build", -4.0)
	fx.tween_fx(&"desat", 0.85, 0.15)
	fx.tween_fx(&"vignette", 0.7, 0.15)
	fx.tween_fx(&"aberration", 0.012 * k, 0.15)
	fx.tween_fx(&"wobble", 0.3 * k, 0.15)
	fx.set_fx(&"tint", Color(1.0, 0.7, 0.7))
	fx.tween_fx(&"tint_amount", 0.35, 0.15)
	Events.flash_requested.emit(Color.WHITE, 0.3)
	await seq(lines, 0.1, 2)
	await wait(0.25)
	Events.flash_requested.emit(Color.WHITE, 0.4)
	fx.reset_all()
	if not keep_locked:
		cine(false)


func _as_pos(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	if v is Transform3D:
		return (v as Transform3D).origin
	var s := String(v)
	if level.has_marker(s):
		return level.marker_pos(s)
	var n := level.find_child(s, true, false) as Node3D
	if n:
		return n.global_position
	return Vector3.ZERO


# ------------------------------------------------------------------ QA bot support
func qa_add(hook_name: String, cond: Callable, act: Callable) -> void:
	qa.append({"name": hook_name, "cond": cond, "act": act, "done": false})


func qa_clear() -> void:
	qa.clear()
