class_name AccidentChain
extends Node
## Data-driven Rube Goldberg machine.
##
## The chain is a deterministic timeline of *steps*. Physics is presentation
## only: props are driven by tweens along authored markers (and released to
## physics afterwards to settle), so a rolling wheel can never miss its target
## or soft-lock the level. Each step may carry *blockers* (player/Pickles/Gus
## interventions). A blocked step aborts its motion, runs `on_block` and lets
## *reroute* steps (`after_blocked`) start -- "I stopped it! ...oh no."
##
## Step dictionary (see Ch.step):
##   id, after[] (all done), any[] (any done), after_blocked[] (any blocked),
##   delay, dur, do[] (actions), on_block[], on_done[], blockers[], live (bool)

signal step_fired(step_id: StringName)
signal step_blocked(step_id: StringName, reason: String)
signal step_done(step_id: StringName)
signal finished(result: Dictionary)

enum S { IDLE, RUNNING, DONE, BLOCKED }

static var trace := false                ## QA: print blocks / fires

var chain_id: StringName = &"chain"
var level: LevelRoot
var steps: Dictionary = {}
var order: Array[StringName] = []
var status: Dictionary = {}
var _trigger_time: Dictionary = {}
var _end_time: Dictionary = {}
var _tweens: Dictionary = {}
var _loops: Dictionary = {}
var running := false
var t := 0.0
var max_time := 240.0
var result := {"deaths": [], "near_misses": [], "blocked": [], "rerouted": 0, "saved": []}
var layers_on_fire := 0
var music_stems: Array = []
var music_group: StringName = &""
var dialogue_on_reroute := true
var _cache: Dictionary = {}
var _finished_emitted := false
var vision := false                      ## premonition playback: no deaths, no persistent state changes
var speed := 1.0                         ## time scale for steps and tweens (vision playback runs faster)
var _snap: Dictionary = {}               ## node path -> Transform3D captured by snapshot()
var _snap_vis: Dictionary = {}


func setup(lv: LevelRoot, id: StringName, step_list: Array, opts := {}) -> void:
	level = lv
	chain_id = id
	max_time = opts.get("max_time", 240.0)
	dialogue_on_reroute = opts.get("reroute_dialogue", true)
	vision = opts.get("vision", false)
	speed = opts.get("speed", 1.0)
	for s: Dictionary in step_list:
		var sid := StringName(s.id)
		steps[sid] = s
		order.append(sid)
		status[sid] = S.IDLE
	add_to_group("accident_chains")


func start() -> void:
	if running:
		return
	running = true
	t = 0.0
	Events.chain_started.emit(chain_id)
	for sid in order:
		if _is_entry(steps[sid]):
			_trigger_time[sid] = 0.0


func stop(kill_motion := true) -> void:
	running = false
	if kill_motion:
		for sid in _tweens.keys():
			_kill_tweens(sid)
		for k in _loops.keys():
			_stop_loop(k)


func is_running() -> bool:
	return running


func step_status(sid: StringName) -> int:
	return status.get(sid, S.IDLE)


func is_done(sid: StringName) -> bool:
	return status.get(sid, S.IDLE) == S.DONE


func was_blocked(sid: StringName) -> bool:
	return status.get(sid, S.IDLE) == S.BLOCKED


func _is_entry(s: Dictionary) -> bool:
	return s.get("after", []).is_empty() and s.get("any", []).is_empty() and s.get("after_blocked", []).is_empty()


func _process(delta: float) -> void:
	if not running or get_tree().paused:
		return
	t += delta * speed
	var any_active := false
	for sid in order:
		var st: int = status[sid]
		var s: Dictionary = steps[sid]
		match st:
			S.IDLE:
				if not _trigger_time.has(sid):
					_evaluate_trigger(sid, s)
				if _trigger_time.has(sid):
					any_active = true
					if t >= _trigger_time[sid] + float(s.get("delay", 0.0)):
						_fire(sid, s)
			S.RUNNING:
				any_active = true
				if s.get("live", true) and not s.get("blockers", []).is_empty():
					var why := _check_blockers(s, true)
					if why != "":
						_block(sid, s, why, true)
						continue
				if t >= _end_time[sid]:
					_complete(sid, s)
	if not any_active:
		_finish()
	elif t > max_time:
		_finish()


func _evaluate_trigger(sid: StringName, s: Dictionary) -> void:
	var after: Array = s.get("after", [])
	var any: Array = s.get("any", [])
	var ab: Array = s.get("after_blocked", [])
	var ok := true
	if not after.is_empty():
		for a in after:
			if status.get(StringName(a), S.IDLE) != S.DONE:
				ok = false
				break
	if ok and not any.is_empty():
		ok = false
		for a in any:
			if status.get(StringName(a), S.IDLE) == S.DONE:
				ok = true
				break
	if ok and not ab.is_empty():
		ok = false
		for a in ab:
			if status.get(StringName(a), S.IDLE) == S.BLOCKED:
				ok = true
				break
	if ok and (not after.is_empty() or not any.is_empty() or not ab.is_empty()):
		_trigger_time[sid] = t


func _fire(sid: StringName, s: Dictionary) -> void:
	var why := _check_blockers(s)
	if why != "":
		_block(sid, s, why, false)
		return
	status[sid] = S.RUNNING
	if trace:
		print("CHAIN ", chain_id, " fire ", sid, " t=", snappedf(t, 0.1))
	_end_time[sid] = t + float(s.get("dur", 0.5))
	step_fired.emit(sid)
	Events.chain_step_fired.emit(chain_id, sid)
	_run_actions(sid, s.get("do", []), true)
	if s.has("say"):
		DialogueManager.say(StringName(s.say), 1)
	# music intensity follows the number of steps fired
	layers_on_fire += 1
	if music_group != &"" and s.get("music", true):
		AudioManager.set_layers(clampi(1 + layers_on_fire / 3, 1, music_stems.size()))


func _complete(sid: StringName, s: Dictionary) -> void:
	status[sid] = S.DONE
	_run_actions(sid, s.get("on_done", []))
	step_done.emit(sid)


func _block(sid: StringName, s: Dictionary, reason: String, mid_motion: bool) -> void:
	if mid_motion:
		_kill_tweens(sid)
	status[sid] = S.BLOCKED
	if trace:
		print("CHAIN ", chain_id, " BLOCK ", sid, " reason=", reason, " t=", snappedf(t, 0.1))
	result.blocked.append(String(sid))
	step_blocked.emit(sid, reason)
	Events.chain_step_blocked.emit(chain_id, sid)
	_run_actions(sid, s.get("on_block", []))
	# who caused it decides the commentary
	var by: String = s.get("by", "player")
	var has_alt := false
	for other in order:
		if steps[other].get("after_blocked", []).has(String(sid)):
			has_alt = true
	if by == "player" and dialogue_on_reroute and s.get("comment", true):
		Events.intervention.emit(&"blocked", sid, {"reason": reason})
		if has_alt:
			result.rerouted += 1
			GameState.bump(&"reroutes")
			AchievementManager.unlock(&"not_like_that")
			AudioManager.stinger(&"sting_oh_no")
			DialogueManager.say_seq([&"gen_reroute_01", &"gen_reroute_02"], 0.5, 1)
			Events.chain_rerouted.emit(chain_id, sid, sid)
		else:
			AudioManager.stinger(&"sting_saved", -4.0)
			if s.has("saved_line"):
				DialogueManager.say(StringName(s.saved_line), 1)
			else:
				DialogueManager.say(DialogueManager.pick("gen_save", 3), 1)


func _finish() -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	running = false
	for k in _loops.keys():
		_stop_loop(k)
	result["saved_all"] = result.deaths.is_empty()
	finished.emit(result)
	Events.chain_finished.emit(chain_id, result)


## Fast-forward: complete everything still pending in final state. Used by
## recovery paths (e.g. the player skips a cutscene) so nothing is left half-done.
func force_finish() -> void:
	for sid in order:
		if status[sid] == S.RUNNING:
			_kill_tweens(sid)
			_complete(sid, steps[sid])
	stop(false)
	_finish()


# ------------------------------------------------------------------ blockers
func _check_blockers(s: Dictionary, live_only := false) -> String:
	if vision:
		return ""       # a premonition always shows the whole disaster
	for b: Dictionary in s.get("blockers", []):
		# displacement checks are only meaningful before the step itself starts moving things
		if live_only and b.k in ["moved", "far", "gone", "actor_away"]:
			continue
		var r := _blocker_hit(b)
		if r != "":
			return r
	return ""


func _blocker_hit(b: Dictionary) -> String:
	match b.k:
		"held":
			var pc := _pc(b.p)
			if pc and pc.is_held():
				return "held:" + String(b.p)
		"moved":
			var pc2 := _pc(b.p)
			if pc2 and pc2.moved_distance() > float(b.get("min", 0.6)):
				return "moved:" + String(b.p)
		"flag":
			if GameState.has_flag(StringName(b.f)):
				return "flag:" + String(b.f)
		"noflag":
			if not GameState.has_flag(StringName(b.f)):
				return "noflag:" + String(b.f)
		"state":
			var n := _node(b.p)
			if n and String(n.get_meta("state", "")) == String(b.s):
				return "state:%s=%s" % [b.p, b.s]
		"pickles_has":
			var pk := Director.pickles as Pickles
			var pc3 := _pc(b.p)
			if pk and pc3 and pk.carrying == pc3:
				return "pickles_has:" + String(b.p)
		"gone":
			var n2 := _node(b.p)
			if n2 == null or not n2.visible or not n2.is_inside_tree():
				return "gone:" + String(b.p)
		"far":
			var na := _node3d(b.a)
			var nb := _node3d(b.b)
			if na and nb and na.global_position.distance_to(nb.global_position) > float(b.get("min", 1.0)):
				return "far:%s-%s" % [b.a, b.b]
		"near_player":
			var n3 := _node3d(b.p)
			if n3 and Director.player and n3.global_position.distance_to(Director.player.global_position) < float(b.get("max", 1.5)):
				return "near_player:" + String(b.p)
		"actor_away":
			var ac := _actor(b.n)
			var vol := _node(b.vol) as LethalVolume
			if ac and vol and not vol.contains(ac):
				return "actor_away:" + String(b.n)
		"fn":
			if bool((b.f as Callable).call()):
				return "fn"
	return ""


# ------------------------------------------------------------------ lookup
func _node(n: Variant) -> Node:
	if n is Node:
		return n
	var key := String(n)
	if _cache.has(key) and is_instance_valid(_cache[key]):
		return _cache[key]
	var out: Node = null
	if key == "@player":
		out = Director.player
	elif key == "@pickles":
		out = Director.pickles
	else:
		out = level.get_node_or_null("Markers/" + key)
		if out == null:
			out = level.find_child(key, true, false)
		if out == null:
			out = _actor(StringName(key))
	if out == null:
		push_warning("AccidentChain[%s]: cannot find node '%s'" % [chain_id, key])
	_cache[key] = out
	return out


func _node3d(n: Variant) -> Node3D:
	return _node(n) as Node3D


func _pc(n: Variant) -> PropComponent:
	var nd := _node(n)
	if nd == null:
		return null
	return nd.get_node_or_null("Prop") as PropComponent


func _actor(id: Variant) -> Actor:
	for a in get_tree().get_nodes_in_group("actors"):
		if (a as Actor).actor_id == StringName(id):
			return a as Actor
	return null


func _xf(to: Variant) -> Transform3D:
	if to is Transform3D:
		return to
	if to is Vector3:
		return Transform3D(Basis.IDENTITY, to)
	var s := String(to)
	if level.has_marker(s):
		return level.marker(s)
	var n := _node3d(to)
	return n.global_transform if n else Transform3D.IDENTITY


# ------------------------------------------------------------------ actions
func _kill_tweens(sid: StringName) -> void:
	for tw in _tweens.get(sid, []):
		if (tw as Tween).is_valid():
			(tw as Tween).kill()
	_tweens[sid] = []


func _add_tween(sid: StringName) -> Tween:
	var tw := create_tween()
	tw.set_speed_scale(speed)
	if not _tweens.has(sid):
		_tweens[sid] = []
	_tweens[sid].append(tw)
	return tw


func _run_actions(sid: StringName, acts: Array, guard := false) -> void:
	for a: Dictionary in acts:
		if a.has("at_t"):
			var cb := _do_guarded.bind(sid, a, guard)
			get_tree().create_timer(float(a.at_t) / maxf(speed, 0.01), false).timeout.connect(cb)
		else:
			_do(sid, a)


func _do_guarded(sid: StringName, a: Dictionary, guard: bool) -> void:
	if guard and status.get(sid, S.IDLE) == S.BLOCKED:
		return          # the step was blocked before this delayed action came due
	if not running and not _finished_emitted:
		return
	_do(sid, a)


func _do(sid: StringName, a: Dictionary) -> void:
	if not is_inside_tree():
		return
	if vision and a.a in ["lethal", "kill", "flag", "say", "seq", "swap", "free", "npc", "title", "pickles", "slowmo", "music", "debris"]:
		if a.a == "kill":
			Events.flash_requested.emit(Color(1, 1, 1), 0.35)
		return
	match a.a:
		"move": _act_move(sid, a)
		"tip": _act_tip(sid, a)
		"impulse": _act_impulse(a)
		"anim": _act_anim(a)
		"sfx": _act_sfx(a)
		"loop": _act_loop(sid, a)
		"stoploop": _stop_loop(String(a.id))
		"fx": _act_fx(a)
		"light": _act_light(a)
		"cam": _act_cam(a)
		"say": DialogueManager.say(StringName(a.line), int(a.get("prio", 1)))
		"seq": DialogueManager.say_seq(a.lines, 0.2, int(a.get("prio", 1)))
		"npc": _act_npc(a)
		"lethal": _act_lethal(a)
		"kill": _act_kill(a)
		"flag": GameState.set_flag(StringName(a.f), a.get("v", true))
		"swap": _act_swap(a)
		"show": _set_visible(a.t, true, a)
		"hide": _set_visible(a.t, false, a)
		"free": _act_free(a)
		"music": _act_music(a)
		"stinger": AudioManager.stinger(StringName(a.name), float(a.get("db", 0.0)))
		"fn": (a.f as Callable).call()
		"state": _node(a.t).set_meta("state", String(a.s))
		"scripted": _act_scripted(a)
		"debris": _act_debris(a)
		"title": Events.title_card_requested.emit(String(a.text), float(a.get("d", 2.0)))
		"pickles": _act_pickles(a)
		"slowmo": _act_slowmo(a)


func _act_scripted(a: Dictionary) -> void:
	var pc := _pc(a.t)
	if pc:
		pc.set_scripted(bool(a.on))


func _act_move(sid: StringName, a: Dictionary) -> void:
	var n := _node3d(a.t)
	if n == null:
		return
	var pc := n.get_node_or_null("Prop") as PropComponent
	if n is NavActor:
		(n as NavActor).stop_moving()
		(n as NavActor).scripted = true
	if pc:
		if pc.is_held() and a.get("steal", true):
			if Director.player and Director.player.interact.held == n:
				Director.player.interact.drop()
		pc.set_scripted(true)
	elif n is RigidBody3D:
		(n as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		(n as RigidBody3D).freeze = true
	var from := n.global_transform
	var to := _xf(a.to)
	var d := float(a.get("d", 1.0))
	var spin_axis: Vector3 = a.get("spin", Vector3.ZERO)
	var turns: float = a.get("turns", 0.0)
	var arc: float = a.get("arc", 0.0)
	var keep_rot: bool = a.get("keep_rot", false)
	var ease_kind: String = a.get("ease", "linear")
	var tw := _add_tween(sid)
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(n):
			return
		var e := _ease(k, ease_kind)
		var pos := from.origin.lerp(to.origin, e)
		pos.y += sin(e * PI) * arc
		var basis_: Basis = from.basis if keep_rot else from.basis.slerp(to.basis, e)
		if spin_axis != Vector3.ZERO:
			basis_ = basis_ * Basis(spin_axis.normalized(), turns * TAU * e)
		n.global_transform = Transform3D(basis_, pos), 0.0, 1.0, d)
	if a.get("release", true):
		tw.tween_callback(func() -> void:
			if is_instance_valid(n):
				if n is NavActor:
					(n as NavActor).scripted = false
				var pc2 := n.get_node_or_null("Prop") as PropComponent
				if pc2:
					pc2.set_scripted(false)
				elif n is RigidBody3D:
					(n as RigidBody3D).freeze = false)


func _act_tip(sid: StringName, a: Dictionary) -> void:
	# rotate a node about a pivot (ladders falling, doors swinging, fans wobbling)
	var n := _node3d(a.t)
	if n == null:
		return
	var pc := n.get_node_or_null("Prop") as PropComponent
	if pc:
		pc.set_scripted(true)
	var pivot_xf := _xf(a.pivot)
	var axis: Vector3 = a.axis
	var deg: float = a.deg
	var d := float(a.get("d", 1.0))
	var from := n.global_transform
	var ease_kind: String = a.get("ease", "in")
	var bounce: float = a.get("bounce", 0.0)
	var tw := _add_tween(sid)
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(n):
			return
		var e := _ease(k, ease_kind)
		if bounce > 0.0 and k > 0.85:
			e = 1.0 - bounce * sin((k - 0.85) / 0.15 * PI) * 0.06
		var rot := Basis(axis.normalized(), deg_to_rad(deg) * e)
		var local := pivot_xf.affine_inverse() * from
		n.global_transform = pivot_xf * Transform3D(rot, Vector3.ZERO) * local, 0.0, 1.0, d)
	if a.get("release", false):
		tw.tween_callback(func() -> void:
			if pc:
				pc.set_scripted(false))


func _ease(k: float, kind: String) -> float:
	match kind:
		"in": return k * k
		"out": return 1.0 - (1.0 - k) * (1.0 - k)
		"in_out": return k * k * (3.0 - 2.0 * k)
		"in_cubic": return k * k * k
		"snap": return 1.0 - pow(1.0 - k, 4.0)
	return k


func _act_impulse(a: Dictionary) -> void:
	var n := _node3d(a.t)
	if not (n is RigidBody3D):
		return
	var rb := n as RigidBody3D
	var pc := rb.get_node_or_null("Prop") as PropComponent
	if pc:
		pc.set_scripted(false)
	rb.freeze = false
	rb.sleeping = false
	var dir: Vector3 = a.get("dir", Vector3.ZERO)
	if a.has("toward"):
		dir = (_node3d(a.toward).global_position - rb.global_position).normalized()
	rb.apply_central_impulse(dir * float(a.get("s", 5.0)) * rb.mass)
	if a.has("spin"):
		rb.angular_velocity = a.spin


func _act_anim(a: Dictionary) -> void:
	var n := _node(a.t)
	if n == null:
		return
	var ap := n as AnimationPlayer
	if ap == null:
		ap = BoneUtil.find_anim_player(n)
	if ap and ap.has_animation(String(a.name)):
		ap.play(String(a.name), 0.1, float(a.get("speed", 1.0)))


func _pos_of(a: Dictionary) -> Variant:
	if a.has("at"):
		var n := _node3d(a.at)
		return n.global_position if n else null
	if a.has("pos"):
		return a.pos
	return null


func _act_sfx(a: Dictionary) -> void:
	var pos: Variant = _pos_of(a)
	AudioManager.play_sfx(StringName(a.name), pos, float(a.get("db", 0.0)), float(a.get("pitch", 1.0)))


func _act_loop(sid: StringName, a: Dictionary) -> void:
	var n := _node3d(a.at)
	if n == null:
		return
	var key := String(a.get("id", a.name))
	_stop_loop(key)
	var p := AudioManager.attach_loop(StringName(a.name), n, float(a.get("db", 0.0)), float(a.get("dist", 30.0)))
	if p:
		_loops[key] = p
	if a.has("stop_after"):
		get_tree().create_timer(float(a.stop_after), false).timeout.connect(_stop_loop.bind(key))


func _stop_loop(key: String) -> void:
	if _loops.has(key):
		if is_instance_valid(_loops[key]):
			(_loops[key] as Node).queue_free()
		_loops.erase(key)


func _act_fx(a: Dictionary) -> void:
	var p: Variant = _pos_of(a)
	if p == null:
		return
	var pos: Vector3 = p
	var kind := StringName(a.kind)
	if vision and (kind == &"decal" or kind == &"blood"):
		return
	if kind == &"decal":
		FX.decal(StringName(a.get("what", "puddle")), pos, a.get("normal", Vector3.UP), float(a.get("size", 1.5)), a.get("color", Color(0.3, 0.5, 0.7, 0.7)))
	elif kind == &"blood":
		FX.blood(pos, float(a.get("scale", 1.0)))
	elif a.get("dur", 0.0) > 0.0:
		var n := _node3d(a.at) if a.has("at") else null
		if n:
			var em := FX.emitter(kind, n, a.get("offset", Vector3.ZERO), float(a.get("scale", 1.0)))
			var tm := Timer.new()
			tm.one_shot = true
			tm.wait_time = float(a.dur)
			em.add_child(tm)
			tm.timeout.connect(func() -> void:
				em.emitting = false
				var tm2 := Timer.new()
				tm2.one_shot = true
				tm2.wait_time = 3.0
				em.add_child(tm2)
				tm2.timeout.connect(em.queue_free)
				tm2.start())
			tm.start()
			return
	FX.burst(kind, pos + a.get("offset", Vector3.ZERO), float(a.get("scale", 1.0)), a.get("dir", Vector3.UP))


func _act_light(a: Dictionary) -> void:
	var l := level.light(String(a.name))
	if l == null:
		l = _node(a.name) as Light3D
	if l == null:
		return
	match String(a.mode):
		"off":
			l.visible = false
		"on":
			l.visible = true
		"flicker":
			var tw := _add_tween(&"__lights")
			for i in int(a.get("n", 6)):
				tw.tween_callback(func() -> void: l.visible = not l.visible)
				tw.tween_interval(randf_range(0.03, 0.12))
			tw.tween_callback(func() -> void: l.visible = bool(a.get("end_on", false)))
		"color":
			l.light_color = a.color
		"energy":
			var tw2 := _add_tween(&"__lights")
			tw2.tween_property(l, "light_energy", float(a.energy), float(a.get("d", 0.3)))


func _act_cam(a: Dictionary) -> void:
	if a.has("shake"):
		Events.camera_shake_requested.emit(float(a.shake), 0.5)
	if a.has("rumble"):
		Events.rumble_requested.emit(float(a.rumble) * 0.6, float(a.rumble), float(a.get("rumble_d", 0.4)))
	if a.has("flash"):
		Events.flash_requested.emit(a.get("flash_color", Color.WHITE), float(a.flash))
	if a.has("muffle"):
		AudioManager.set_muffled(float(a.muffle), 0.1)
		if a.has("muffle_end"):
			get_tree().create_timer(float(a.muffle_end), false).timeout.connect(AudioManager.set_muffled.bind(0.0, 1.0))


func _act_slowmo(a: Dictionary) -> void:
	var scale_to := float(a.get("scale", 0.3))
	var d := float(a.get("d", 0.8))
	Engine.time_scale = scale_to
	get_tree().create_timer(d * scale_to, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


func _act_npc(a: Dictionary) -> void:
	var ac := _actor(a.n)
	if ac == null or not ac.alive:
		return
	match String(a.cmd):
		"walk":
			ac.move_to(_xf(a.to).origin, false)
		"run":
			ac.move_to(_xf(a.to).origin, true)
		"flee":
			ac.run_away_to(_xf(a.to).origin)
		"panic":
			ac.set_panic(true)
		"calm":
			ac.set_panic(false)
		"anim":
			ac.mode = Actor.Mode.SCRIPTED
			ac.play_anim(String(a.name), 0.15)
		"idle":
			ac.mode = Actor.Mode.IDLE
		"face":
			ac.face_point(_xf(a.to).origin)
		"emote":
			ac.set_emotion(StringName(a.name))
		"tele":
			ac.teleport(_xf(a.to).origin)
		"protect":
			ac.protected = bool(a.get("on", true))
		"hide":
			ac.visible = false
			ac.collision_layer = 0
		"show":
			ac.visible = true
		"stop":
			ac.stop_moving()


func _act_lethal(a: Dictionary) -> void:
	var v := _node(a.vol) as LethalVolume
	if v:
		v.arm(float(a.get("d", 1.0)), StringName(a.get("cause", "accident")), String(a.get("style", "back")))


func _act_kill(a: Dictionary) -> void:
	var v := _node(a.vol) as LethalVolume
	var cause := StringName(a.get("cause", "accident"))
	var style: String = a.get("style", "back")
	var targets: Array = a.get("n", [])
	if targets is Array and targets.is_empty() and a.get("everyone", false):
		targets = []
		for ac in get_tree().get_nodes_in_group("actors"):
			targets.append(String((ac as Actor).actor_id))
	if a.get("n") is String or a.get("n") is StringName:
		targets = [String(a.n)]
	for id in targets:
		if String(id) == "player":
			if Director.player and v and v.contains(Director.player) and not Director.player.dead:
				Director.player.die(cause)
			continue
		var ac := _actor(id)
		if ac == null or not ac.alive:
			continue
		if v and v.contains(ac) and not ac.protected:
			result.deaths.append(String(id))
			ac.die(cause, style)
			FX.blood(ac.global_position, 1.0)
			AudioManager.play_sfx(&"thump", ac.global_position, 2.0)
			Events.rumble_requested.emit(0.4, 0.7, 0.3)
		else:
			result.near_misses.append(String(id))
			if ac.actor_id in GameState.SURVIVOR_IDS:
				result.saved.append(String(id))
				Events.npc_saved.emit(ac.actor_id)


func _act_swap(a: Dictionary) -> void:
	var n := _node3d(a.t)
	if n == null:
		return
	var path := "res://scenes/props/%s.tscn" % a.scene
	if not ResourceLoader.exists(path):
		return
	var xf := n.global_transform
	var parent := n.get_parent()
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	parent.add_child(inst)
	inst.global_transform = xf
	inst.name = String(a.get("name", n.name))
	n.queue_free()
	_cache.erase(String(a.t))


func _set_visible(t_: Variant, on: bool, a: Dictionary) -> void:
	var n := _node3d(t_)
	if n == null:
		return
	n.visible = on
	for c in n.find_children("*", "CollisionObject3D", true, false) + ([n] if n is CollisionObject3D else []):
		(c as CollisionObject3D).collision_layer = 0 if not on else ((c as CollisionObject3D).collision_layer if (c as CollisionObject3D).collision_layer != 0 else 16)


func _act_free(a: Dictionary) -> void:
	var n := _node(a.t)
	if n:
		n.queue_free()
		_cache.erase(String(a.t))


func _act_music(a: Dictionary) -> void:
	if a.has("track"):
		AudioManager.play_music(StringName(a.track), float(a.get("fade", 1.0)))
	if a.has("layers"):
		AudioManager.set_layers(int(a.layers))


func _act_debris(a: Dictionary) -> void:
	var p: Variant = _pos_of(a)
	if p == null:
		return
	Debris.spawn(get_tree(), StringName(a.get("scene", "debris_chunk")), p, int(a.get("n", 8)), float(a.get("force", 5.0)), float(a.get("life", 6.0)), a.get("dir", Vector3.UP))


func _act_pickles(a: Dictionary) -> void:
	var pk := Director.pickles as Pickles
	if pk == null:
		return
	match String(a.cmd):
		"bark":
			pk.bark()
		"anim":
			pk.play_oneshot(String(a.name), float(a.get("d", 1.5)))
		"goto":
			pk.command(&"goto", _xf(a.to).origin)
		"scripted":
			pk.begin_scripted()
		"free":
			pk.end_scripted()
		"tele":
			pk.teleport(_xf(a.to).origin)


## Remember where the given props are so a premonition can be rewound afterwards.
func snapshot(names: Array) -> void:
	_snap.clear()
	_snap_vis.clear()
	for n in names:
		var nd := _node3d(n)
		if nd:
			_snap[String(n)] = nd.global_transform
			_snap_vis[String(n)] = nd.visible


func restore() -> void:
	for k in _snap.keys():
		var nd := _node3d(k)
		if nd == null:
			continue
		nd.global_transform = _snap[k]
		nd.visible = _snap_vis.get(k, true)
		var pc := nd.get_node_or_null("Prop") as PropComponent
		if pc:
			pc.set_scripted(false)
			pc.reset_home()
		if nd is RigidBody3D:
			(nd as RigidBody3D).linear_velocity = Vector3.ZERO
			(nd as RigidBody3D).angular_velocity = Vector3.ZERO
			(nd as RigidBody3D).sleeping = true


func debug_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for sid in order:
		var st: String = ["idle", "RUN", "done", "BLOCKED"][status[sid]]
		out.append("%s: %s" % [sid, st])
	return out
