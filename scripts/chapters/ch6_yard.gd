extends Chapter
## CHAPTER 6 -- HALLORAN YARD (the Pickles chapter). Six lethal setups, eighteen ways for the universe to
## refuse. Eddie gives up, sits down, and the whole yard goes off at once. Then he has to RUN.

const STATIONS := {
	"beam": {"lever": "LeverBeam", "mark": "A_Mark", "verb": "Release the beam", "arm": "ch6_arm_beam_01", "res": ["ch6_res_beam_01", "ch6_res_beam_02", "ch6_res_beam_03"]},
	"truck": {"lever": "LeverTruck", "mark": "B_Mark", "verb": "Release the brake", "arm": "ch6_arm_truck_01", "res": ["ch6_res_truck_01", "ch6_res_truck_02", "ch6_res_truck_03"]},
	"drop": {"lever": "LeverDrop", "mark": "C_Mark", "verb": "Open the trapdoor", "arm": "ch6_arm_drop_01", "res": ["ch6_res_drop_01", "ch6_res_drop_02", "ch6_res_drop_03"]},
	"barrels": {"lever": "FuseBox", "mark": "D_Mark", "verb": "Light the fuse", "arm": "ch6_arm_barrels_01", "res": ["ch6_res_barrels_01", "ch6_res_barrels_02", "ch6_res_barrels_03"]},
	"vend": {"lever": "LeverVend", "mark": "E_Mark", "verb": "Pull the lever", "arm": "ch6_arm_vend_01", "res": ["ch6_res_vend_01", "ch6_res_vend_02", "ch6_res_vend_03"]},
	"ball": {"lever": "LeverBall", "mark": "F_Mark", "verb": "Release the ball", "arm": "ch6_arm_ball_01", "res": ["ch6_res_ball_01", "ch6_res_ball_02", "ch6_res_ball_03"]},
}
const ESC_AT := [3, 5, 8, 10, 13, 16, 20]
const RESET_PROPS := ["Beam", "WrapperA", "YardTruck", "DropCrate", "Mattress", "PlankC", "Barrel1", "Barrel2", "Barrel3", "Barrel4", "Barrel5", "PropaneD1", "PropaneD2",
		"VendA", "VendB", "VendSpare", "WreckingBall", "JerseyB1", "HayA", "HayB", "HayF", "TiresA"]

var busy := false
var attempts_by: Dictionary = {}
var sit_enabled := false
var sat := false
var run_started := false
var run_done := false
var graves: Actor
var _home: Dictionary = {}
var _marks: Dictionary = {}
var _last_res := -1
var _hint_t := 0.0
var _speed_k := 1.0
var _run_nodes: Array[Node] = []
var _knockers: Array = []            ## [{node, radius}] barrels/machines that shove the runner
var _armed_hz := {}


func _play(beat: StringName) -> void:
	_setup_world()
	AudioManager.play_ambience(&"amb_yard", -5.0)
	music("mus_yard", 2.0)
	if beat == &"run":
		await _resume_run()
	else:
		await _intro()


# ============================================================================ setup
func _setup_world() -> void:
	for n in RESET_PROPS:
		var p := prop(n)
		if p:
			_home[n] = p.global_transform
	for n in ["Beam", "YardTruck", "WrapperA", "DropCrate", "Mattress", "PlankC", "Barrel1", "Barrel2", "Barrel3", "Barrel4", "Barrel5", "PropaneD1", "PropaneD2", "VendA", "VendB", "VendSpare"]:
		freeze_prop(n)
	for pair in [["Stump", "ch6_insp_stump"], ["WrapperA", "ch6_insp_wrapper"], ["Mattress", "ch6_insp_mattress"], ["Airbag", "ch6_insp_airbag"], ["HayA", "ch6_insp_hay"],
			["GantryCrane", "ch6_insp_crane"], ["YardTruck", "ch6_insp_truck"], ["Barrel1", "ch6_insp_barrels"], ["VendA", "ch6_insp_vend"], ["WreckingBall", "ch6_insp_ball"],
			["GateBench", "ch6_insp_bench"], ["RailA", "ch6_insp_rail"], ["ScaffoldDrop", "ch6_insp_scaffold"], ["WreckerGantry", "ch6_insp_ball"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(Vector3(0, 0.5, -46.0), Vector3(30, 1.0, 0.6), "ch6_insp_quarry", "InspectQuarry")
	prop("AirbagInflated").visible = false
	for id in STATIONS.keys():
		var s: Dictionary = STATIONS[id]
		var node_name: String = s.lever
		bind_use(node_name, s.verb, func() -> void: _attempt(id))
		_make_go_mark(id, mkp(s.mark))
	pc("Stump").use_verb = ""
	_qa_hooks()


func _make_go_mark(id: String, pos: Vector3) -> void:
	var a := Area3D.new()
	a.name = "GoMark_" + id
	a.collision_layer = 32
	a.collision_mask = 0
	a.monitorable = true
	a.add_to_group("pickles_go")
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.1
	sh.height = 0.5
	cs.shape = sh
	a.add_child(cs)
	level.add_child(a)
	a.global_position = pos + Vector3(0, 0.25, 0)
	# the painted X
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.05)
	mat.emission_energy_multiplier = 0.7
	for ang in [45.0, -45.0]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.5, 0.02, 0.18)
		mi.mesh = bm
		mi.material_override = mat
		mi.rotation_degrees.y = ang
		mi.position = Vector3(0, -0.22, 0)
		a.add_child(mi)
	_marks[id] = a


# ============================================================================ intro + apology
func _intro() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	title_card("HALLORAN YARD", 3.0)
	sting("sting_title_card", -6.0)
	objective("Go to the middle of the yard")
	save(&"start")
	await seq(["ch6_arrive_01", "ch6_arrive_02"], 0.4)
	await wait_until(func() -> bool: return player.global_position.z < 40.0)
	await seq(["ch6_arrive_03", "ch6_arrive_04"], 0.5)
	await wait_until(func() -> bool: return player.global_position.distance_to(mkp("Plaza")) < 5.0)
	await _apology()


func _apology() -> void:
	cine(true)
	pickles.command(&"come")
	await wait(1.0)
	pickles.teleport_near(player.global_position + player.global_transform.basis * Vector3(0.8, 0, -1.4))
	pickles.face_point(player.global_position)
	player.look_at_point(pickles.global_position + Vector3(0, 0.3, 0), 0.6)
	music("mus_graves", 1.5)
	await seq(["ch6_apology_01", "ch6_apology_02", "ch6_apology_03", "ch6_apology_04", "ch6_apology_05"], 0.6)
	pickles.play_oneshot("happy", 2.0)
	await seq(["ch6_apology_06", "ch6_apology_07"], 0.5)
	music("mus_yard", 2.0)
	cine(false)
	flag("apology_done")
	objective("Send Pickles to an X (look at it, press %s). Then pull the lever." % InputGlyphs.prompt(&"pickles_command"))
	hint("Look at a yellow X and press %s to send Pickles there. Then go pull that station's lever." % InputGlyphs.prompt(&"pickles_command"), 9.0)
	save(&"apology")
	_idle_loop()


# ============================================================================ attempts
func _attempt(id: String) -> void:
	if busy or run_started or sat:
		return
	var s: Dictionary = STATIONS[id]
	var mark := mkp(s.mark)
	var pk := pickles
	if pk.global_position.distance_to(mark) > 2.6 or pk.state == Pickles.State.FOLLOW or pk.state == Pickles.State.FETCH_GO or pk.state == Pickles.State.FETCH_BACK:
		if attempts_by.is_empty():
			bark("ch6_hint_lever")
		hint("Pickles has to be on the X first. Look at the X and press %s." % InputGlyphs.prompt(&"pickles_command"), 5.0)
		return
	busy = true
	cine(true)
	var n_here: int = int(attempts_by.get(id, 0))
	var total: int = GameState.count(&"yard_attempts")
	if n_here == 0:
		await say(s.arm)
	# the attempt monologue ("Okay. This time.")
	if total == 0:
		await seq(["ch6_att_01", "ch6_att_02", "ch6_att_03", "ch6_att_04"], 0.3)
	else:
		await say("ch6_att_0%d" % (5 + (total % 4)))
	player.look_at_point(mark + Vector3(0, 1.0, 0), 0.5)
	pickles.begin_scripted()
	pickles.stop_moving()
	pickles.scripted = true
	pickles.face_point(player.global_position)
	pickles.play_anim("sit", 0.2)
	await wait(0.8)
	var v: int = n_here % 3
	music("mus_chase", 0.4)
	AudioManager.set_layers(1)
	match id:
		"beam": await _v_beam(v)
		"truck": await _v_truck(v)
		"drop": await _v_drop(v)
		"barrels": await _v_barrels(v)
		"vend": await _v_vend(v)
		"ball": await _v_ball(v)
	# aftermath
	attempts_by[id] = n_here + 1
	total = GameState.bump(&"yard_attempts")
	AchievementManager.progress(&"bad_owner", 5)
	AchievementManager.progress(&"seriously", 10)
	AchievementManager.progress(&"not_going_to_die", 16)
	Events.pickles_survived.emit(StringName(id))
	AudioManager.stinger(StringName("sting_stupid_resolve_0%d" % (1 + randi() % 3)))
	music("mus_yard", 1.5)
	await wait(0.9)
	if n_here == 0:
		await seq(s.res, 0.3)
	else:
		var g := _pick_generic()
		await say("ch6_res_gen_0%d" % g)
	if total in ESC_AT:
		await say("ch6_esc_%02d" % total)
	pickles.play_oneshot("happy", 1.5)
	await _reset_station()
	pickles.scripted = false
	pickles.end_scripted(Pickles.State.FOLLOW)
	pickles.command(&"come")
	cine(false)
	busy = false
	_hint_t = 0.0
	save(&"attempts")
	if total >= 4 and not sit_enabled:
		_enable_sit()
	if total >= 20 and not sat:
		await _sit_scene()


func _pick_generic() -> int:
	var g := 1 + randi() % 4
	if g == _last_res:
		g = 1 + (g % 4)
	_last_res = g
	return g


func _reset_station() -> void:
	await Director.fade(true, 0.35)
	for n in _home.keys():
		var p := prop(n)
		if p:
			p.global_transform = _home[n]
			if p is RigidBody3D:
				(p as RigidBody3D).linear_velocity = Vector3.ZERO
				(p as RigidBody3D).angular_velocity = Vector3.ZERO
	prop("AirbagInflated").visible = false
	prop("Airbag").visible = true
	# Pickles goes back to his mark after a reset only if the next attempt needs him -- he walks over to Eddie instead
	pickles.teleport_near(player.global_position + player.global_transform.basis * Vector3(0, 0, -1.6))
	await wait(0.15)
	await Director.fade(false, 0.35)


func _idle_loop() -> void:
	while not run_started and not sat and is_inside_tree():
		await wait(1.0)
		if busy or Director.input_locked or DialogueManager.is_busy():
			_hint_t = 0.0
			continue
		_hint_t += 1.0
		if _hint_t > 55.0:
			_hint_t = 0.0
			if sit_enabled:
				bark("ch6_sit_hint")
			else:
				bark("ch6_hint_lever")


func _enable_sit() -> void:
	sit_enabled = true
	var c := pc("Stump")
	c.use_verb = "Sit down"
	c.used.connect(func(_p: Node) -> void: _sit_scene())
	await wait(1.5)
	bark("ch6_sit_hint")
	objective("You could sit down.")


# ============================================================================ helpers for the gags
func _tw(node: Node3D, to: Vector3, secs: float, delay := 0.0, ease_ := Tween.EASE_IN, trans := Tween.TRANS_QUAD) -> Tween:
	var t := create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_property(node, "global_position", to, secs).set_ease(ease_).set_trans(trans)
	return t


func _rot(node: Node3D, deg: Vector3, secs: float, delay := 0.0, ease_ := Tween.EASE_IN) -> Tween:
	var t := create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_property(node, "rotation_degrees", deg, secs).set_ease(ease_).set_trans(Tween.TRANS_QUAD)
	return t


func _after(secs: float, cb: Callable) -> void:
	get_tree().create_timer(secs, false).timeout.connect(cb)


func _pk_move(to: Vector3, secs: float, anim: String, delay := 0.0, end_anim := "") -> void:
	_after(delay, func() -> void:
		var p := pickles
		p.play_anim(anim, 0.1)
		p.face_point(to)
		var d := to - p.global_position
		d.y = 0
		if d.length() > 0.1:
			p.rotation.y = atan2(-d.x, -d.z)
		var t := create_tween()
		t.tween_property(p, "global_position", to, secs)
		if end_anim != "":
			t.tween_callback(func() -> void: p.play_anim(end_anim, 0.15)))


func _impact(pos: Vector3, big := 1.0) -> void:
	AudioManager.play_sfx(&"metal_crash", pos, 3.0 * big)
	FX.burst(&"dust", pos + Vector3(0, 0.2, 0), 2.2 * big)
	FX.burst(&"debris", pos + Vector3(0, 0.3, 0), 1.2 * big)
	Events.camera_shake_requested.emit(0.25 * big, 0.4)
	Events.rumble_requested.emit(0.3, 0.6 * big, 0.3)


# ============================================================================ Station A -- the beam
func _v_beam(v: int) -> void:
	var beam := prop("Beam")
	var mark := mkp("A_Mark")
	AudioManager.play_sfx(&"switch_click", mkp("A_Lever"))
	AudioManager.play_sfx(&"creak", mark + Vector3(0, 4, 0), 3.0)
	await wait(0.6)
	match v:
		0:  # sandwich wrapper: he looks back, chases it, the beam lands on the empty spot
			var w := prop("WrapperA")
			_tw(w, mark + Vector3(-2.8, 0.05, 3.0), 0.9, 0.0, Tween.EASE_OUT)
			_rot(w, Vector3(0, 380, 0), 0.9)
			_pk_move(mark + Vector3(-2.6, 0, 3.0), 0.8, "run", 0.25, "sniff")
			_tw(beam, Vector3(-30, 0.25, -8), 0.5, 1.2, Tween.EASE_IN, Tween.TRANS_CUBIC)
			await wait(1.7)
			_impact(mark, 1.4)
		1:  # hay bales: he wanders off, the beam lands on the hay with a "whump"
			_pk_move(mark + Vector3(1.6, 0, -2.6), 1.2, "trot", 0.2, "sniff")
			_tw(beam, Vector3(-30, 0.62, -10.9), 0.55, 1.4, Tween.EASE_IN, Tween.TRANS_CUBIC)
			await wait(1.95)
			_impact(mkp("A_Mark") + Vector3(0, 0, -3), 0.7)
			AudioManager.play_sfx(&"mattress_bounce", mark + Vector3(0, 0.5, -2.9))
		2:  # a bird: startled leap sideways, the beam bounces and rolls off
			FX.burst(&"leaves", mark + Vector3(0.5, 3.0, 0.0), 1.5)
			AudioManager.play_sfx(&"whoosh", mark + Vector3(0, 3, 0), -4.0)
			_pk_move(mark + Vector3(2.2, 0, 1.6), 0.6, "jump", 0.7, "shake")
			_tw(beam, Vector3(-30, 0.25, -8), 0.5, 1.0, Tween.EASE_IN, Tween.TRANS_CUBIC)
			_tw(beam, Vector3(-30, 0.25, -5.2), 0.9, 1.6, Tween.EASE_OUT)
			await wait(1.55)
			_impact(mark, 1.2)
			await wait(1.0)
	await wait(0.6)


# ============================================================================ Station B -- the truck
func _truck_pose(truck: Node3D, pos: Vector3, dir: Vector3) -> void:
	truck.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), pos)


func _v_truck(v: int) -> void:
	var truck := prop("YardTruck")
	var mark := mkp("B_Mark")
	AudioManager.play_sfx(&"click_soft", mkp("B_Lever"))
	AudioManager.play_sfx(&"creak", truck.global_position, 3.0)
	await wait(0.7)
	var pts := [Vector3(30, 3.2, -26.5), Vector3(30, 3.2, -24.0), Vector3(30, 0.0, -6.0), Vector3(30, 0.0, 0.0)]
	AudioManager.play_sfx(&"engine_rev", truck.global_position, 2.0)
	var loop := AudioManager.attach_loop(&"roll_loop", truck, 0.0, 40.0)
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		var pos: Vector3
		var dir := Vector3(0, -0.18, 1)
		if k < 0.12:
			pos = pts[0].lerp(pts[1], k / 0.12)
			dir = Vector3(0, 0, 1)
		elif k < 0.72:
			pos = pts[1].lerp(pts[2], (k - 0.12) / 0.6)
		else:
			pos = pts[2].lerp(pts[3], (k - 0.72) / 0.28)
			dir = Vector3(0, 0, 1)
		_truck_pose(truck, pos, dir), 0.0, 1.0, 3.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(2.6, false).timeout
	match v:
		0:  # scoop: he hops on the hood and rides it into the hay
			await get_tree().create_timer(0.9, false).timeout
			pickles.play_anim("ride", 0.1)
			var hood := truck.global_position + Vector3(0, 1.45, 1.1)
			pickles.global_position = hood
			var t2 := create_tween()
			t2.tween_method(func(k: float) -> void:
				pickles.global_position = truck.global_position + Vector3(0, 1.5, 1.05), 0.0, 1.0, 1.4)
			_tw(truck, Vector3(30, 0, 4.4), 1.2, 0.0, Tween.EASE_OUT)
			await wait(1.3)
			_impact(Vector3(30, 0.4, 5.0), 0.8)
			AudioManager.play_sfx(&"comic_boing", pickles.global_position)
			var t3 := create_tween()
			t3.tween_property(pickles, "global_position", Vector3(30.8, 0.0, 6.4), 0.5).set_ease(Tween.EASE_OUT)
			pickles.play_anim("happy", 0.1)
		1:  # the brakes catch by themselves
			AudioManager.play_sfx(&"squeak", truck.global_position, 4.0)
			AudioManager.play_sfx(&"comic_slide_down", truck.global_position)
			_tw(truck, Vector3(30, 0, -1.6), 0.9, 0.0, Tween.EASE_OUT)
			await wait(1.0)
			pickles.bark()
			_rot(truck, truck.rotation_degrees + Vector3(-6, 0, 0), 0.25, 0.0, Tween.EASE_OUT)
		2:  # swerve: the truck veers into the jersey barrier
			var t4 := create_tween()
			t4.tween_property(truck, "global_position", Vector3(25.2, 0, 3.6), 1.0).set_ease(Tween.EASE_IN)
			t4.parallel().tween_property(truck, "rotation_degrees:y", 235.0, 1.0)
			await wait(1.0)
			_impact(Vector3(26, 0.6, 4), 1.2)
			_tw(prop("JerseyB1"), Vector3(23.6, 0.3, 6.5), 0.5, 0.0, Tween.EASE_OUT)
			pickles.play_oneshot("tilt", 1.4)
	if is_instance_valid(loop):
		loop.queue_free()
	await wait(1.0)


# ============================================================================ Station C -- the drop
func _v_drop(v: int) -> void:
	var crate := prop("DropCrate")
	var mark := mkp("C_Mark")
	AudioManager.play_sfx(&"switch_click", mkp("C_Lever"))
	AudioManager.play_sfx(&"creak", crate.global_position, 3.0)
	await wait(0.7)
	match v:
		0:  # the mattress slides in and carries him away
			var m := prop("Mattress")
			_tw(m, mark + Vector3(0.0, 0.16, 0.2), 1.0, 0.0, Tween.EASE_OUT)
			AudioManager.play_sfx(&"cloth_rustle", m.global_position, 2.0)
			_after(1.05, func() -> void:
				pickles.play_anim("ride", 0.1)
				var t := create_tween()
				t.tween_property(m, "global_position", mark + Vector3(2.6, 0.16, -0.6), 0.9).set_ease(Tween.EASE_IN_OUT)
				t.parallel().tween_property(pickles, "global_position", mark + Vector3(2.6, 0.3, -0.6), 0.9).set_ease(Tween.EASE_IN_OUT))
			_tw(crate, mark + Vector3(0, 0.3, 0), 0.6, 1.5, Tween.EASE_IN, Tween.TRANS_CUBIC)
			await wait(2.2)
			_impact(mark, 1.0)
			pickles.play_anim("happy", 0.1)
		1:  # the crate hits a plank and skids away
			var pl := prop("PlankC")
			pl.global_position = mark + Vector3(0.9, 0.9, 0.0)
			pl.rotation_degrees = Vector3(0, 0, -32)
			_tw(crate, mark + Vector3(0.5, 1.5, 0), 0.5, 0.0, Tween.EASE_IN, Tween.TRANS_CUBIC)
			_tw(crate, mark + Vector3(4.0, 0.3, 0), 0.7, 0.55, Tween.EASE_IN)
			_rot(crate, Vector3(0, 0, -110), 0.9, 0.5)
			await wait(1.3)
			_impact(mark + Vector3(4.0, 0, 0), 0.9)
			pickles.play_oneshot("tilt", 1.4)
		2:  # he trots off to sniff the gravel; the crate explodes into confetti
			_pk_move(mark + Vector3(-2.4, 0, 1.6), 1.0, "trot", 0.2, "sniff")
			_tw(crate, mark + Vector3(0, 0.3, 0), 0.55, 1.4, Tween.EASE_IN, Tween.TRANS_CUBIC)
			await wait(2.0)
			FX.burst(&"confetti", mark + Vector3(0, 0.6, 0), 2.5)
			FX.burst(&"stars", mark + Vector3(0, 0.6, 0), 1.6)
			AudioManager.play_sfx(&"thump", mark, 2.0)
			AudioManager.play_sfx(&"comic_boing", mark)
			Events.camera_shake_requested.emit(0.2, 0.3)
	await wait(0.8)


# ============================================================================ Station D -- the barrels
func _v_barrels(v: int) -> void:
	var mark := mkp("D_Mark")
	var fuse := prop("FuseBox").global_position
	AudioManager.play_sfx(&"sizzle", fuse, 3.0)
	# a spark runs along the ground from the fuse box to the barrels
	var spark_from := fuse + Vector3(0.2, 0.15, 0)
	var spark_to := mark + Vector3(1.4, 0.1, 0)
	for k in 16:
		var kk := k
		_after(0.15 * kk, func() -> void: FX.burst(&"spark", spark_from.lerp(spark_to, float(kk) / 15.0), 0.4))
	await wait(2.6)
	match v:
		0:  # BOOM: he is launched, the airbag inflates just in time
			FX.burst(&"fire", mark + Vector3(0, 0.5, 0), 3.5)
			AudioManager.play_sfx(&"explosion", mark, 6.0)
			Events.camera_shake_requested.emit(0.7, 0.6)
			FX.burst(&"debris", mark + Vector3(0, 0.5, 0), 3.0)
			for n in ["Barrel1", "Barrel2", "Barrel3", "Barrel4", "Barrel5"]:
				var b := prop(n)
				_tw(b, b.global_position + Vector3(randf_range(-3, 3), randf_range(2, 5), randf_range(-3, 3)), 0.7, 0.0, Tween.EASE_OUT)
			var land := mkp("D_Land")
			pickles.play_anim("roll", 0.05)
			var arc := create_tween()
			arc.tween_method(func(k: float) -> void:
				var p := mark.lerp(land, k)
				p.y += sin(k * PI) * 7.5
				pickles.global_position = p
				pickles.rotation.z = k * TAU * 2.0, 0.0, 1.0, 1.7)
			_after(0.7, func() -> void:
				prop("Airbag").visible = false
				prop("AirbagInflated").visible = true
				AudioManager.play_sfx(&"airbag_hiss", mkp("D_Land"), 4.0))
			await arc.finished
			pickles.rotation.z = 0.0
			AudioManager.play_sfx(&"mattress_bounce", land, 4.0)
			pickles.play_anim("happy", 0.1)
			_tw(pickles, land + Vector3(0, 1.1, 0), 0.35, 0.0, Tween.EASE_OUT)
			await wait(0.4)
			_tw(pickles, land + Vector3(0, 0.2, 0), 0.4, 0.0, Tween.EASE_IN)
			await wait(0.6)
		1:  # dud: the fuse fizzles, one barrel lid pops
			AudioManager.play_sfx(&"sizzle", mark, 2.0)
			FX.burst(&"smoke", mark + Vector3(0, 0.9, 0), 1.2)
			AudioManager.play_sfx(&"comic_boing", mark)
			FX.burst(&"confetti", mark + Vector3(0, 1.0, 0), 1.6)
			pickles.play_oneshot("bark", 0.8)
			await wait(1.6)
		2:  # the barrels rocket over him and crash into the potty
			FX.burst(&"fire", mark + Vector3(0, 0.5, 0), 2.5)
			AudioManager.play_sfx(&"explosion", mark, 5.0)
			Events.camera_shake_requested.emit(0.6, 0.5)
			for n in ["Barrel1", "Barrel2", "Barrel3", "Barrel4", "Barrel5"]:
				var b2 := prop(n)
				var tgt := mkp("D_Mark") + Vector3(randf_range(6, 12), 0.4, randf_range(8, 14))
				var t2 := create_tween()
				t2.tween_method(func(k: float) -> void:
					b2.global_position = Vector3(lerpf(mark.x, tgt.x, k), lerpf(0.6, tgt.y, k) + sin(k * PI) * 6.0, lerpf(mark.z, tgt.z, k)), 0.0, 1.0, 1.5)
			pickles.play_oneshot("shake", 1.2)
			await wait(2.0)
			_impact(mkp("D_Mark") + Vector3(9, 0, 11), 1.2)
	await wait(0.6)


# ============================================================================ Station E -- the vending machines
func _v_vend(v: int) -> void:
	var a := prop("VendA")
	var b := prop("VendB")
	var mark := mkp("E_Mark")
	AudioManager.play_sfx(&"click_soft", mkp("E_Lever"))
	AudioManager.play_sfx(&"creak", a.global_position, 3.0)
	await wait(0.8)
	var a_home: Transform3D = _home["VendA"]
	var b_home: Transform3D = _home["VendB"]
	match v:
		0:  # they fall inward and lock into a perfect shape over him
			var ta := create_tween()
			ta.tween_method(func(k: float) -> void: _tip_about(a, a_home, Vector3(20, 0, 22.4), Vector3(1, 0, 0), 33.0 * k), 0.0, 1.0, 0.9).set_ease(Tween.EASE_IN)
			var tb := create_tween()
			tb.tween_method(func(k: float) -> void: _tip_about(b, b_home, Vector3(20, 0, 24.6), Vector3(1, 0, 0), -33.0 * k), 0.0, 1.0, 0.9).set_ease(Tween.EASE_IN)
			await wait(1.0)
			_impact(mark + Vector3(0, 1.0, 0), 1.0)
			pickles.play_anim("sit_alert", 0.1)
			await wait(0.5)
			AudioManager.play_sfx(&"clink", mark)
			pickles.play_anim("eat", 0.1)
			AudioManager.play_sfx(&"pk_eat", mark)
		1:  # a third machine slides in and holds one up
			var spare := prop("VendSpare")
			_tw(spare, Vector3(20, 0, 26.7), 1.0, 0.0, Tween.EASE_IN_OUT)
			_rot(spare, Vector3(0, 180, 0), 1.0)
			var ta2 := create_tween()
			ta2.tween_method(func(k: float) -> void: _tip_about(a, a_home, Vector3(20, 0, 22.4), Vector3(1, 0, 0), 62.0 * k), 0.0, 1.0, 1.0).set_ease(Tween.EASE_IN)
			var tb2 := create_tween()
			tb2.tween_interval(0.5)
			tb2.tween_method(func(k: float) -> void: _tip_about(b, b_home, Vector3(20, 0, 24.6), Vector3(1, 0, 0), -14.0 * k), 0.0, 1.0, 0.5)
			await wait(1.7)
			_impact(mark + Vector3(0, 0.8, 0), 1.1)
			pickles.play_oneshot("tilt", 1.4)
		2:  # they topple outward; a snack rolls to his paws
			var ta3 := create_tween()
			ta3.tween_method(func(k: float) -> void: _tip_about(a, a_home, Vector3(20, 0, 21.6), Vector3(1, 0, 0), -80.0 * k), 0.0, 1.0, 1.1).set_ease(Tween.EASE_IN)
			var tb3 := create_tween()
			tb3.tween_method(func(k: float) -> void: _tip_about(b, b_home, Vector3(20, 0, 25.4), Vector3(1, 0, 0), 80.0 * k), 0.0, 1.0, 1.1).set_ease(Tween.EASE_IN)
			await wait(1.2)
			_impact(mkp("E_Mark") + Vector3(0, 0.4, -3.2), 1.2)
			_impact(mkp("E_Mark") + Vector3(0, 0.4, 3.2), 1.0)
			AudioManager.play_sfx(&"clink", mark)
			pickles.play_anim("eat", 0.1)
			AudioManager.play_sfx(&"pk_eat", mark)
	await wait(1.4)


func _tip_about(node: Node3D, home: Transform3D, pivot: Vector3, axis: Vector3, deg: float) -> void:
	var rot := Transform3D(Basis(axis.normalized(), deg_to_rad(deg)), Vector3.ZERO)
	var local := Transform3D(home.basis, home.origin - pivot)
	var out := rot * local
	node.global_transform = Transform3D(out.basis, out.origin + pivot)


# ============================================================================ Station F -- the wrecking ball
func _swing(ball: Node3D, from_deg: float, to_deg: float, secs: float, ease_ := Tween.EASE_IN) -> Tween:
	var t := create_tween()
	t.tween_method(func(a: float) -> void: ball.rotation_degrees.x = a, from_deg, to_deg, secs).set_trans(Tween.TRANS_SINE).set_ease(ease_)
	return t


func _v_ball(v: int) -> void:
	var ball := prop("WreckingBall")
	var mark := mkp("F_Mark")
	AudioManager.play_sfx(&"click_soft", mkp("F_Lever"))
	# winch pulls the ball back
	AudioManager.play_sfx(&"creak", ball.global_position, 3.0)
	var back := _swing(ball, 0.0, -48.0, 1.6, Tween.EASE_OUT)
	await back.finished
	await wait(0.5)
	AudioManager.play_sfx(&"snap", ball.global_position, 3.0)
	match v:
		0:  # the rope pulls the WRONG way: it swings backwards into the gantry, then rolls off
			AudioManager.play_sfx(&"whoosh", ball.global_position, 3.0)
			var sw := _swing(ball, -48.0, -70.0, 0.7, Tween.EASE_OUT)
			await sw.finished
			_impact(ball.global_position, 1.5)
			var sw2 := _swing(ball, -70.0, -20.0, 1.3, Tween.EASE_IN_OUT)
			await sw2.finished
			pickles.play_oneshot("tilt", 1.4)
		1:  # a perfect swing -- he rolls under it at the last second
			var sw3 := _swing(ball, -48.0, 0.0, 1.05, Tween.EASE_IN)
			_after(0.55, func() -> void:
				pickles.play_anim("dodge", 0.05)
				_tw(pickles, mark + Vector3(1.6, 0, 0.0), 0.5, 0.0, Tween.EASE_OUT))
			AudioManager.play_sfx(&"whoosh", ball.global_position, 4.0)
			await sw3.finished
			AudioManager.play_sfx(&"whoosh", mark, 6.0)
			Events.camera_shake_requested.emit(0.3, 0.3)
			var sw4 := _swing(ball, 0.0, 44.0, 1.0, Tween.EASE_OUT)
			await sw4.finished
			pickles.play_anim("shake", 0.1)
		2:  # the leash catches the rope and he rides it out over the hay
			var sw5 := _swing(ball, -48.0, 0.0, 1.05, Tween.EASE_IN)
			AudioManager.play_sfx(&"whoosh", ball.global_position, 4.0)
			await sw5.finished
			pickles.play_anim("ride", 0.05)
			var sw6 := _swing(ball, 0.0, 50.0, 1.25, Tween.EASE_OUT)
			var land := mkp("F_Land")
			var arc := create_tween()
			arc.tween_method(func(k: float) -> void:
				var p := mark.lerp(land, k)
				p.y = 0.3 + sin(k * PI) * 4.2
				pickles.global_position = p, 0.0, 1.0, 1.25)
			await sw6.finished
			AudioManager.play_sfx(&"mattress_bounce", land, 3.0)
			pickles.play_anim("happy", 0.1)
			await wait(0.4)
	await wait(0.8)


# ============================================================================ sit down
func _sit_scene() -> void:
	if sat or busy or run_started:
		return
	sat = true
	busy = true
	unbind_use("LeverBeam")
	cine(true)
	objective("")
	pickles.begin_scripted()
	pickles.scripted = false
	await walk_player_to(mkp("SitSpot") + Vector3(0.8, 0, 0.9), 2.2, 0.5, 8.0)
	player.look_at_point(mkp("SitSpot") + Vector3(0, 0.4, 0), 0.5)
	pickles.end_scripted(Pickles.State.FOLLOW)
	pickles.command(&"come")
	await wait(0.8)
	var tw := create_tween()
	tw.tween_property(player.head, "position:y", player.head.position.y - 0.55, 0.9).set_trans(Tween.TRANS_SINE)
	music("mus_graves", 1.5)
	await seq(["ch6_sit_01", "ch6_sit_02", "ch6_sit_03"], 0.7)
	pickles.teleport_near(player.global_position + Vector3(0, 0, 0.8))
	pickles.play_oneshot("happy", 2.0)
	await seq(["ch6_sit_04", "ch6_sit_05", "ch6_sit_06"], 0.7)
	await wait(1.4)
	# CLANG
	AudioManager.stop_music(0.05)
	AudioManager.play_sfx(&"clang", mkp("Plaza") + Vector3(0, 3, -6), 8.0)
	Events.camera_shake_requested.emit(0.6, 0.6)
	Events.flash_requested.emit(Color(1, 1, 1), 0.2)
	await wait(1.1)
	AudioManager.play_sfx(&"clang", mkp("Plaza") + Vector3(6, 2, 4), 8.0, 0.8)
	AudioManager.play_sfx(&"metal_crash", mkp("Plaza") + Vector3(-8, 2, 5), 5.0)
	await seq(["ch6_clang_01"], 0.2)
	tw = create_tween()
	tw.tween_property(player.head, "position:y", player.head.position.y + 0.55, 0.3)
	await _start_run(true)


# ============================================================================ THE RUN
func _resume_run() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	teleport_player("RunStart")
	pickles.teleport_near(player.global_position)
	sat = true
	await _start_run(false)


func _start_run(first: bool) -> void:
	run_started = true
	busy = false
	_speed_k = maxf(0.65, 1.0 - 0.12 * float(int(Engine.get_meta("ch6_run_deaths", 0))))
	music("mus_chase", 0.3)
	AudioManager.play_layered(&"chain_a", ["perc", "bass", "mar", "str", "brass"], 2)
	if first:
		await say("ch6_clang_02")
	cine(false)
	pickles.end_scripted(Pickles.State.FOLLOW)
	pickles.command(&"come")
	pickles.speed_mul = 1.6
	objective("RUN! Get to the gate!")
	save(&"run")
	Events.player_died.connect(func(_r: StringName) -> void: Engine.set_meta("ch6_run_deaths", int(Engine.get_meta("ch6_run_deaths", 0)) + 1), CONNECT_ONE_SHOT)
	_yard_rumbles()
	# triggers along the route
	trigger_marker("RunA", Vector3(14, 3, 3), _hz_truck, true)
	trigger_marker("RunB", Vector3(14, 3, 3), _hz_barrels, true)
	trigger_marker("RunC", Vector3(14, 3, 3), _hz_vend, true)
	trigger_marker("RunD", Vector3(14, 3, 3), _hz_ball, true)
	trigger_marker("RunE", Vector3(14, 3, 3), _hz_gate, true)
	trigger_marker("ExitRun", Vector3(14, 4, 3), _run_finished, true)
	_run_lines()


func _yard_rumbles() -> void:
	# ambient chaos while you run: beams and drums crashing all over the yard
	var spots := [Vector3(-30, 1, -8), Vector3(30, 1, -6), Vector3(0, 1, -22), Vector3(-22, 1, 22), Vector3(20, 1, 24), Vector3(40, 1, 30), Vector3(-12, 1, 36), Vector3(14, 1, 40)]
	while run_started and not run_done and is_inside_tree():
		await wait(randf_range(0.7, 1.4))
		var p: Vector3 = spots[randi() % spots.size()]
		AudioManager.play_sfx(&"metal_crash", p, randf_range(-2.0, 4.0), randf_range(0.8, 1.2))
		FX.burst(&"dust", p, 2.0)
		Events.camera_shake_requested.emit(0.12, 0.3)


func _run_lines() -> void:
	var lines := ["ch6_run_01", "ch6_run_02", "ch6_run_03", "ch6_run_04", "ch6_run_05", "ch6_run_06", "ch6_run_07"]
	var i := 0
	while run_started and not run_done and i < lines.size() and is_inside_tree():
		await wait(1.5)
		if not DialogueManager.is_busy() and not run_done:
			DialogueManager.say(StringName(lines[i]), 1)
			i += 1


func _hz_truck() -> void:
	# a truck cuts across the road at z=20
	var truck := spawn_prop("yard_truck", Vector3(-34, 0.0, 20.0), -90.0, "RunTruck")
	if truck is RigidBody3D:
		(truck as RigidBody3D).freeze = true
	AudioManager.play_sfx(&"engine_rev", truck.global_position, 6.0)
	AudioManager.play_sfx(&"bus_horn", truck.global_position, 4.0, 1.4)
	var vol := LethalVolume.new()
	vol.size = Vector3(4.8, 2.6, 2.8)
	truck.add_child(vol)
	vol.position = Vector3(0, 1.0, 0)
	vol.arm(6.0, &"truck", "back")
	var tw := create_tween()
	tw.tween_property(truck, "global_position", Vector3(34, 0, 20), 4.6 / _speed_k * 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(truck.queue_free)
	_run_nodes.append(truck)


func _hz_barrels() -> void:
	for i in 6:
		var b := spawn_prop("barrel_red", Vector3(-16, 0.0, 30.0 + (i % 2) * 1.6), 0.0, "RunBarrel%d" % i)
		if b is RigidBody3D:
			(b as RigidBody3D).freeze = true
		_knockers.append({"node": b, "r": 1.0})
		var tw := create_tween()
		tw.tween_interval(0.5 * i * _speed_k)
		tw.tween_callback(func() -> void: AudioManager.play_sfx(&"roll_loop", b.global_position, 0.0))
		tw.tween_property(b, "global_position", Vector3(16, 0.0, 30.0 + (i % 2) * 1.6), 3.0 / _speed_k).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(b, "rotation_degrees:z", 900.0, 3.0 / _speed_k)
		tw.tween_callback(b.queue_free)


func _hz_vend() -> void:
	for side in [-1.0, 1.0]:
		var m := spawn_prop("vending_machine_phys", Vector3(side * 5.0, 0, 37.0), 0.0 if side < 0 else 180.0, "RunVend%d" % int(side))
		if m is RigidBody3D:
			(m as RigidBody3D).freeze = true
		var home := m.global_transform
		var tw := create_tween()
		tw.tween_interval(0.9 * _speed_k if side < 0 else 1.5 * _speed_k)
		tw.tween_callback(func() -> void: AudioManager.play_sfx(&"creak", m.global_position, 3.0))
		tw.tween_method(func(k: float) -> void: _tip_about(m, home, home.origin, Vector3(0, 0, 1), -side * 84.0 * k), 0.0, 1.0, 0.8).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			_impact(m.global_position, 1.0)
			_knock_near(m.global_position, 2.6, 7.0))
		_run_nodes.append(m)


func _knock_near(pos: Vector3, radius: float, strength: float) -> void:
	var pl := Director.player
	if pl and pl.global_position.distance_to(pos) < radius:
		var d: Vector3 = (pl.global_position - pos)
		d.y = 0
		pl.knock(d if d.length() > 0.1 else Vector3(0, 0, 1), strength, 0.7)


func _hz_ball() -> void:
	# a wrecking ball sweeps across the road at z=40 (at torso height)
	var pivot := Node3D.new()
	pivot.name = "RunBall"
	level.add_child(pivot)
	pivot.global_position = Vector3(0, 9.0, 40.0)
	var ball := spawn_prop("wrecking_ball", Vector3(0, 9.0, 40.0), 0.0, "RunBallVisual")
	ball.reparent(pivot)
	ball.position = Vector3.ZERO
	ball.scale = Vector3.ONE * 1.35
	var vol := LethalVolume.new()
	vol.size = Vector3(1.9, 1.9, 1.9)
	pivot.add_child(vol)
	vol.position = Vector3(0, -7.6, 0)
	vol.arm(16.0, &"wrecking_ball", "back")
	AudioManager.play_sfx(&"creak", pivot.global_position, 4.0)
	var period := 3.6 / _speed_k
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		pivot.rotation_degrees.z = 42.0 * sin(t / period * TAU), 0.0, 14.0, 14.0)
	tw.tween_callback(pivot.queue_free)
	_run_nodes.append(pivot)
	var whoosh := create_tween().set_loops(4)
	whoosh.tween_interval(period * 0.5)
	whoosh.tween_callback(func() -> void: AudioManager.play_sfx(&"whoosh", Vector3(0, 1.5, 40.0), 3.0))


func _hz_gate() -> void:
	# the gate propane goes off just behind you
	AudioManager.play_sfx(&"explosion", mkp("RunE") + Vector3(0, 1, 6), 6.0)
	for s in [-1.0, 1.0]:
		var p := mkp("RunE") + Vector3(s * 5.0, 0.6, 3.0)
		FX.burst(&"fire", p, 3.0)
		FX.burst(&"debris", p, 2.0)
	Events.camera_shake_requested.emit(0.7, 0.6)
	_knock_near(mkp("RunE") + Vector3(0, 0, 2), 6.0, 5.0)


func _physics_process(_delta: float) -> void:
	if not run_started or run_done:
		return
	for k in _knockers:
		var n: Node3D = k.node
		if is_instance_valid(n) and Director.player and n.global_position.distance_to(Director.player.global_position) < float(k.r):
			var d: Vector3 = Director.player.global_position - n.global_position
			d.y = 0
			Director.player.knock(d if d.length() > 0.05 else Vector3(0, 0, 1), 5.5, 0.5)


func _run_finished() -> void:
	if run_done:
		return
	run_done = true
	run_started = false
	for n in _run_nodes:
		if is_instance_valid(n):
			n.queue_free()
	cine(true)
	player.set_forced_walk(Vector3.ZERO)
	AudioManager.stop_music(0.5)
	AudioManager.play_ambience(&"amb_wind", -8.0)
	Events.camera_shake_requested.emit(0.5, 0.5)
	pickles.teleport_near(player.global_position + Vector3(0, 0, -1.2))
	pickles.command(&"stay")
	await wait(1.2)
	AudioManager.play_sfx(&"big_boom", mkp("Plaza"), 10.0)
	FX.burst(&"dust", mkp("Plaza"), 6.0)
	FX.burst(&"fire", mkp("RunD"), 5.0)
	await wait(1.6)
	await seq(["ch6_out_01", "ch6_out_02", "ch6_out_03"], 0.5)
	AudioManager.stop_music(0.1)
	music("mus_graves", 2.5)
	await _graves_scene()


func _graves_scene() -> void:
	# Doctor Graves is sitting on a folding chair outside the gate, eating a sandwich
	var chair := spawn_prop("folding_chair", mkp("GravesChair"), 0.0, "GravesChair")
	graves = npc(&"graves", "GravesChair", {"talkable": false, "idle": "sit_talk"})
	graves.global_position = mkp("GravesChair") + Vector3(0, 0.05, 0)
	graves.scripted = true
	graves.rotation.y = 0.0
	graves.look_at_player = true
	player.look_at_point(graves.global_position + Vector3(0, 1.0, 0), 0.8)
	await seq(["ch6_graves_01", "ch6_graves_02", "ch6_graves_03"], 0.5)
	await seq(["ch6_real_01", "ch6_real_02", "ch6_real_03", "ch6_real_04"], 0.6)
	sting("sting_reveal")
	SequenceManager.add_clue(&"leash", "The Leash", "The leash did not wrap around Pickles. It wrapped around me. It yanked ME out of the way. Pickles was never in danger. I spent an hour failing to murder my dog.")
	await seq(["ch6_real_05", "ch6_real_06", "ch6_real_07", "ch6_real_08", "ch6_real_09", "ch6_real_10", "ch6_real_11"], 0.6)
	await wait(1.0)
	SaveManager.checkpoint(&"end")
	await Director.fade(true, 1.4)
	await end_to(GameState.Chapter.FINALE)


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("walk", func() -> bool: return player != null and not has_flag("apology_done") and GameState.beat == &"start" and not Director.input_locked and player.global_position.distance_to(mkp("Plaza")) > 6.0, func() -> void: teleport_player("Plaza"))
	for id in STATIONS.keys():
		qa_add("station_" + id, func() -> bool: return has_flag("apology_done") and not busy and not run_started and not sat and not Director.input_locked and int(attempts_by.get(id, 0)) < 1,
				func() -> void:
					pickles.global_position = mkp(STATIONS[id].mark)
					pickles.state = Pickles.State.STAY
					_attempt(id))
	qa_add("sit", func() -> bool: return sit_enabled and not sat and not busy and not Director.input_locked, func() -> void: _sit_scene())
	qa_add("run_dash", func() -> bool: return run_started and not run_done and not Director.input_locked, func() -> void: teleport_player("ExitRun"))
