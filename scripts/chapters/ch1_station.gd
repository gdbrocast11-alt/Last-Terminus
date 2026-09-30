extends Chapter
## CHAPTER 1 -- TERMINUS STATION.
## Free-roam first day at Centennial Transit Center -> premonition -> panic -> thrown out
## by Officer Mills -> the collapse seen through the glass from the forecourt.

const CROWD := ["CrowdA", "CrowdB", "CrowdC", "CrowdD", "CrowdE", "CrowdF"]
const WANDER := ["EnterHall", "BenchSit", "TicketSpot", "PremSpot", "KidSpot", "DaleSpot", "GusSpot", "BrendaSpot"]
const PA_LINES := ["ch1_pa_01", "ch1_pa_02", "ch1_pa_03", "ch1_pa_04", "ch1_pa_05", "ch1_pa_06"]
const WATCH := ["TiffanyCup", "ScrubRobot", "BaggageCart", "Sculpture", "SkyLinkPod", "Escalator", "Stool1", "CounterCup"]
const NAMES := {&"kid": "Kid", &"brenda": "Brenda", &"dale": "Dale", &"tiffany": "Tiffany", &"gus": "Gus", &"marco": "Marco", &"luis": "Luis", &"mills": "Officer Mills"}

var esc: Escalator
var disaster: AccidentChain
var ticket_done := false
var vision_done := false
var panic := false
var alarm_pulled := false
var arrested := false
var kid_done := false
var kid_asked := false
var warned: Dictionary = {}
var strangers: Array[Actor] = []
var _panic_time := 0.0
var _pa_i := 0
var _pa_node: Node3D
var _crowd_node: Node3D
var _machine_node: Node3D


func _play(beat: StringName) -> void:
	set_group("finale", false)
	set_group("day1", true)
	_setup_world()
	AudioManager.play_ambience(&"amb_station")
	if beat == &"panic":
		await _resume_panic()
	else:
		await _intro()


# ============================================================================ setup
func _setup_world() -> void:
	esc = Escalator.new()
	esc.name = "EscalatorConveyor"
	level.add_child(esc)
	esc.setup(Vector3(-16.0, 0.0, -0.5), Vector3(-16.0, 5.4, -11.0))
	# speakers for the public address / crowd voices
	_pa_node = Node3D.new()
	level.add_child(_pa_node)
	_pa_node.global_position = Vector3(0, 10.0, 4.0)
	DialogueManager.register_speaker(&"pa", _pa_node)
	_crowd_node = Node3D.new()
	level.add_child(_crowd_node)
	_crowd_node.global_position = Vector3(-4, 1.6, 9.0)
	DialogueManager.register_speaker(&"crowd", _crowd_node)
	DialogueManager.register_speaker(&"stranger", _crowd_node)
	_machine_node = prop("TicketMachine")
	if _machine_node:
		DialogueManager.register_speaker(&"machine", _machine_node)
	# kid's ball: only Pickles can get it (it is "under the bench")
	var ball := rb("KidBall")
	if ball:
		ball.freeze = true
		var bpc := pc("KidBall")
		bpc.fetchable = true
		bpc.grab_class = ""
		bpc.add_to_group("fetchables")
	# inspect lines on props that already exist in the level
	for pair in [["BaggageCart", "ch1_insp_cart"], ["ScrubRobot", "ch1_insp_scrub"], ["JuiceCounter", "ch1_insp_smoothie"], ["WetSign", "ch1_insp_sign"],
			["ElecPanel", "ch1_insp_panel"], ["PigeonStatue", "ch1_insp_pigeon"], ["BenchKid", "ch1_insp_bench"], ["SitBench", "ch1_insp_bench"],
			["Suitcase1", "ch1_insp_luggage"], ["AlarmHandle", "ch1_insp_handle"], ["InfoKiosk", "ch1_insp_map"], ["Scaffold1", "ch1_scaffold_01"]]:
		set_inspect(pair[0], pair[1])
	for hz in ["BaggageCart", "ScrubRobot", "WetSign", "ElecPanel", "AlarmHandle", "TiffanyCup"]:
		set_hazard(hz, 1)
	add_inspect(Vector3(0, 6.0, 2.0), Vector3(4.8, 1.4, 4.8), "ch1_insp_sculpture", "InspectSculpture", 1)
	add_inspect(Vector3(0, 11.4, -2.0), Vector3(30, 0.3, 14), "ch1_insp_ceiling", "InspectCeiling", 1)
	add_inspect(Vector3(-16, 0.6, 0.4), Vector3(1.9, 1.2, 0.6), "ch1_insp_escalator", "InspectEscalator", 1)
	add_inspect(Vector3(14, 7.4, -15.9), Vector3(6.4, 3.2, 2.6), "ch1_insp_skylink", "InspectSkyLink", 1)
	add_inspect(Vector3(-23.3, 5.5, 10.0), Vector3(0.6, 1.3, 1.3), "ch1_insp_clock", "InspectClock")
	add_inspect(Vector3(0, 1.6, -25.4), Vector3(16, 3.2, 0.3), "ch1_insp_train", "InspectTrain")
	_spawn_npcs()
	settle_props(["TiffanyCup", "BaggageCart", "ScrubRobot", "Stool1", "CounterCup"])
	trigger_marker("BarrierSpot", Vector3(10, 3, 5), _on_barrier, false)
	trigger_marker("EnterHall", Vector3(14, 3, 3), _on_enter_hall, true)
	_qa_hooks()


func _spawn_npcs() -> void:
	var kid := npc(&"kid", "KidSpot", {"talkable": true, "idle": "idle"})
	var brenda := npc(&"brenda", "BrendaSpot", {"talkable": true, "idle": "phone_film"})
	var dale := npc(&"dale", "DaleSpot", {"talkable": true, "idle": "idle_look"})
	var tiff := npc(&"tiffany", "TiffanySpot", {"talkable": true, "idle": "hold_cup"})
	var gus := npc(&"gus", "GusSpot", {"talkable": true, "idle": "clipboard"})
	var marco := npc(&"marco", "MarcoSpot", {"talkable": true, "idle": "argue"})
	var luis := npc(&"luis", "LuisSpot", {"talkable": true, "idle": "argue"})
	var mills := npc(&"mills", "MillsSpot", {"talkable": true, "idle": "hands_hips"})
	for a in [kid, brenda, dale, tiff, gus, marco, luis, mills]:
		a.display_name = NAMES.get(a.actor_id, "")
	# background commuters
	var st_ids := [&"stranger_a", &"stranger_b", &"stranger_c", &"stranger_d"]
	var st_marks := ["EnterHall", "TicketSpot", "BenchSit", "PremSpot"]
	var st_idles := ["check_watch", "phone_ear", "idle", "idle_look"]
	for i in 4:
		var s := npc(st_ids[i], st_marks[i], {"idle": st_idles[i], "node_name": "Commuter%d" % (i + 1)})
		strangers.append(s)
	_wander_loop(strangers[0])
	_wander_loop(strangers[2])
	# conversations
	on_talk(kid, _talk_kid)
	on_talk(brenda, _talk_brenda)
	on_talk(dale, _talk_dale)
	on_talk(tiff, _talk_tiffany)
	on_talk(gus, _talk_gus)
	on_talk(marco, _talk_ml)
	on_talk(luis, _talk_ml)
	on_talk(mills, _talk_mills)
	# Marco and Luis argue forever
	kid.look_at_player = true


func _wander_loop(a: Actor) -> void:
	while is_instance_valid(a) and a.alive and not panic:
		await wait(randf_range(5.0, 12.0))
		if panic or not is_instance_valid(a):
			return
		var m: String = WANDER[randi() % WANDER.size()]
		a.move_to(mkp(m) + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)), false)


# ============================================================================ intro
func _intro() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	pickles.leash_enabled = true
	music("mus_explore_station", 2.0)
	sting("sting_title_card", -6.0)
	title_card("TERMINUS STATION", 3.0)
	objective("Buy a ticket for the 8:14 to Riverside")
	save(&"start")
	_pa_loop()
	_arrival_lines()
	await wait(2.5)
	hint("Move with %s / %s    Look with the mouse    Interact: %s" % [InputGlyphs.prompt(&"move_forward"), InputGlyphs.prompt(&"move_left"), InputGlyphs.prompt(&"interact")], 6.0)


func _arrival_lines() -> void:
	await wait(1.8)
	await seq(["ch1_arrive_01", "ch1_arrive_02"], 0.3)
	await wait_until(func() -> bool: return player.global_position.z < 19.0)
	await say("ch1_arrive_03")


func _on_enter_hall() -> void:
	if not ticket_done and not vision_done:
		hint("Pickles follows you. Look at things and press %s to inspect, or ask %s for his help." % [InputGlyphs.prompt(&"secondary"), InputGlyphs.prompt(&"pickles_command")], 6.0)


func _pa_loop() -> void:
	while not panic and is_inside_tree():
		await wait(randf_range(28.0, 42.0))
		if panic or vision_done:
			return
		AudioManager.play_sfx(&"pa_chime", _pa_node.global_position, -4.0)
		DialogueManager.say(StringName(PA_LINES[_pa_i % PA_LINES.size()]), 0)
		_pa_i += 1


# ============================================================================ conversations
func _talk_kid() -> void:
	if kid_done:
		await say("ch1_kid_done")
		return
	if not kid_asked:
		kid_asked = true
		await seq(["ch1_kid_01", "ch1_kid_02", "ch1_kid_03", "ch1_kid_04"], 0.25)
		objective("Get Pickles to fetch the ball under the bench")
		hint("Look at the ball and press %s to send Pickles." % InputGlyphs.prompt(&"pickles_command"), 7.0)
		_watch_ball()
	else:
		await say("ch1_kid_wait_01" if randf() > 0.5 else "ch1_kid_wait_02")


func _watch_ball() -> void:
	var ball := rb("KidBall")
	var kid := actor(&"kid")
	var t := 0.0
	while not kid_done and is_inside_tree():
		await wait(0.4)
		t += 0.4
		if t == 12.0 or (t > 12.0 and t < 12.5):
			bark("ch1_kid_hint")
		var bpc := pc("KidBall")
		if ball and kid and not bpc.is_held() and not ball.freeze and ball.global_position.distance_to(kid.global_position) < 2.3:
			kid_done = true
			kid.play_anim("cheer", 0.2)
			await seq(["ch1_kid_05", "ch1_kid_06"], 0.25)
			if ticket_done:
				objective("Get to platform four")
			else:
				objective("Buy a ticket for the 8:14 to Riverside")
			GameState.set_flag(&"junior_inspector", true)
			return


func _talk_brenda() -> void:
	if not has_flag("talked_brenda"):
		flag("talked_brenda")
		await seq(["ch1_brenda_01", "ch1_brenda_02", "ch1_brenda_03", "ch1_brenda_04", "ch1_brenda_05"], 0.25)
	else:
		await say("ch1_brenda_repeat_01" if randf() > 0.5 else "ch1_brenda_repeat_02")


func _talk_dale() -> void:
	if not has_flag("talked_dale"):
		flag("talked_dale")
		await seq(["ch1_dale_01", "ch1_dale_02", "ch1_dale_03"], 0.25)
	else:
		await say("ch1_dale_repeat_01" if randf() > 0.5 else "ch1_dale_repeat_02")


func _talk_tiffany() -> void:
	if not has_flag("talked_tiffany"):
		flag("talked_tiffany")
		await seq(["ch1_tiffany_01", "ch1_tiffany_02", "ch1_tiffany_03", "ch1_tiffany_04", "ch1_tiffany_05"], 0.25)
	else:
		await say("ch1_tiffany_repeat_01" if randf() > 0.5 else "ch1_tiffany_repeat_02")


func _talk_gus() -> void:
	if not has_flag("talked_gus"):
		flag("talked_gus")
		await seq(["ch1_gus_01", "ch1_gus_02", "ch1_gus_03", "ch1_gus_04", "ch1_gus_05"], 0.25)
	else:
		await say("ch1_gus_repeat_01" if randf() > 0.5 else "ch1_gus_repeat_02")


func _talk_ml() -> void:
	if not has_flag("talked_ml"):
		flag("talked_ml")
		await seq(["ch1_ml_01", "ch1_ml_02", "ch1_ml_03", "ch1_ml_04", "ch1_ml_05"], 0.2)
	else:
		await say("ch1_ml_repeat_01" if randf() > 0.5 else "ch1_ml_repeat_02")


func _talk_mills() -> void:
	if not has_flag("talked_mills"):
		flag("talked_mills")
		await seq(["ch1_mills_01", "ch1_mills_02", "ch1_mills_03", "ch1_mills_04"], 0.25)
	else:
		await say("ch1_mills_repeat_01")


# ============================================================================ ticket + barrier
func _use_ticket() -> void:
	if busy_talk or DialogueManager.is_busy():
		return
	if ticket_done:
		await say("ch1_ticket_repeat")
		return
	busy_talk = true
	await seq(["ch1_ticket_01", "ch1_ticket_02", "ch1_ticket_03", "ch1_ticket_04", "ch1_ticket_05", "ch1_ticket_06"], 0.2)
	ticket_done = true
	busy_talk = false
	AudioManager.play_sfx(&"click_soft", mkp("TicketSpot"))
	objective("Get to platform four")
	save(&"ticket")
	await say("ch1_arrive_04")


func _on_barrier() -> void:
	if vision_done or panic:
		return
	if not has_flag("barrier_lines"):
		flag("barrier_lines")
		await seq(["ch1_barrier_01", "ch1_barrier_02"], 0.3)
	if ticket_done and not vision_done and not busy_talk:
		await _do_vision()


# ============================================================================ premonition
func _do_vision() -> void:
	vision_done = true
	cine(true)
	objective("")
	for a in npcs.values():
		(a as Actor).stop_moving()
	await wait(0.3)
	disaster = _build_disaster(true)
	var shots := [
		{"t": 0.0, "cam": Vector3(11.4, 1.4, 7.8), "look": Vector3(13.0, 0.85, 6.0), "fov": 55.0, "line": "ch1_prem_01"},
		{"step": "robot", "cam": Vector3(9.5, 1.5, 11.5), "look": Vector3(12.0, 0.5, 8.0), "fov": 60.0},
		{"step": "cart", "cam": Vector3(9.0, 0.7, 9.5), "cam_to": Vector3(-2.5, 0.9, 8.5), "look": Vector3(2.0, 0.6, 5.0), "fov": 66.0, "hold": 3.0, "line": "ch1_prem_04"},
		{"step": "esc_hit", "cam": Vector3(-8.0, 1.8, 6.0), "look": Vector3(-15.0, 1.2, -1.0), "fov": 60.0, "line": "ch1_prem_03"},
		{"step": "cable1", "cam": Vector3(5.5, 1.6, 9.0), "look": Vector3(0.0, 8.0, 2.0), "fov": 62.0, "line": "ch1_prem_02"},
		{"step": "sculpt_fall", "cam": Vector3(1.0, 1.1, 9.5), "look": Vector3(0.0, 2.2, 2.0), "fov": 58.0, "line": "ch1_prem_05"},
		{"step": "ceiling", "cam": Vector3(0.0, 1.0, 12.5), "look": Vector3(0.0, 9.5, -2.0), "fov": 68.0},
	]
	await vision(&"ch1_station", disaster, WATCH, shots, {"max": 18.0})
	disaster.queue_free()
	disaster = null
	esc.restart()
	# snap back: Eddie is standing where he was
	await wait(0.4)
	await seq(["ch1_prem_06"], 0.2)
	await seq(["ch1_snap_01", "ch1_snap_02", "ch1_snap_03"], 0.2)
	_begin_panic()


# ============================================================================ panic
func _begin_panic() -> void:
	panic = true
	cine(false)
	music("mus_chase", 1.0)
	AudioManager.set_layers(1)
	objective("Get everyone out")
	Director.set_hud_visible(true)
	bind_use("AlarmHandle", "Pull alarm", _pull_alarm)
	pc("TiffanyCup").grabbed.connect(_on_cup_grabbed)
	for a in strangers:
		a.set_panic(false)
	_setup_warnings()
	save(&"panic")
	_panic_watch()
	await wait(1.0)
	await say("ch1_panic_hint")


func _resume_panic() -> void:
	# checkpoint reload: the vision already happened, player starts near the barrier
	await begin_player("PlayerStart", "PicklesStart")
	teleport_player("PremSpot")
	pickles.teleport_near(player.global_position)
	ticket_done = true
	vision_done = true
	_pa_loop()
	_begin_panic()


func _setup_warnings() -> void:
	for id in [&"brenda", &"dale", &"tiffany", &"gus", &"marco", &"luis"]:
		var a := actor(id)
		var cb: Callable
		match id:
			&"brenda": cb = func() -> void: await _warn(&"brenda", ["ch1_warn_brenda_01", "ch1_warn_brenda_02", "ch1_warn_brenda_03", "ch1_warn_brenda_04"], false)
			&"dale": cb = func() -> void: await _warn(&"dale", ["ch1_warn_dale_01", "ch1_warn_dale_02"], true)
			&"tiffany": cb = func() -> void: await _warn(&"tiffany", ["ch1_warn_tiffany_01", "ch1_warn_tiffany_02"], true)
			&"gus": cb = func() -> void: await _warn(&"gus", ["ch1_warn_gus_01", "ch1_warn_gus_02", "ch1_warn_gus_03", "ch1_warn_gus_04", "ch1_warn_gus_05", "ch1_warn_gus_06"], true)
			_: cb = func() -> void: await _warn_ml()
		# replace the chatter handler with the warning handler
		for cn in a.interacted.get_connections():
			a.interacted.disconnect(cn.callable)
		on_talk(a, cb)


func _warn(id: StringName, lines: Array, leaves: bool) -> void:
	if warned.has(id):
		return
	await seq(lines, 0.2)
	warned[id] = true
	GameState.bump(&"warned")
	if leaves:
		var a := actor(id)
		a.run_away_to(mkp(CROWD[warned.size() % CROWD.size()]))
	_check_evac()


func _warn_ml() -> void:
	if warned.has(&"marco"):
		return
	await seq(["ch1_warn_ml_01", "ch1_warn_ml_02", "ch1_warn_ml_03", "ch1_warn_ml_04", "ch1_warn_ml_05", "ch1_warn_ml_06"], 0.2)
	warned[&"marco"] = true
	warned[&"luis"] = true
	GameState.bump(&"warned", 2)
	actor(&"marco").run_away_to(mkp("CrowdA"))
	actor(&"luis").run_away_to(mkp("CrowdB"))
	_check_evac()


func _check_evac() -> void:
	if warned.size() >= 5 and not arrested:
		objective("Officer Mills is coming")


func _pull_alarm() -> void:
	if alarm_pulled or arrested:
		return
	alarm_pulled = true
	unbind_use("AlarmHandle")
	AudioManager.play_sfx(&"switch_click", prop("AlarmHandle").global_position)
	var loop := AudioManager.attach_loop(&"alarm_loop", prop("AlarmHandle"), -2.0, 60.0)
	Events.camera_shake_requested.emit(0.1, 0.4)
	await say("ch1_panic_alarm")
	DialogueManager.say(&"ch1_panic_alarm_pa", 1)
	for a in strangers:
		a.run_away_to(mkp(CROWD[randi() % CROWD.size()]))
	if is_instance_valid(loop):
		loop.name = "AlarmLoop"


func _on_cup_grabbed(_p: Node) -> void:
	if has_flag("cup_taken"):
		return
	flag("cup_taken")
	await seq(["ch1_panic_grabcup", "ch1_panic_grabcup_reply"], 0.15)


func _panic_watch() -> void:
	while panic and not arrested and is_inside_tree():
		await wait(0.5)
		_panic_time += 0.5
		if DialogueManager.is_busy() and not alarm_pulled:
			continue
		if alarm_pulled and _panic_time > 3.0:
			await _arrest()
			return
		if _panic_time > 100.0 or (warned.size() >= 5 and _panic_time > 20.0):
			await _arrest()
			return
		# ambient panic barks
		if int(_panic_time) % 17 == 0 and not DialogueManager.is_busy():
			DialogueManager.bark(StringName("ch1_panic_stranger_0%d" % (1 + randi() % 3)))


# ============================================================================ arrest + collapse
func _arrest() -> void:
	arrested = true
	objective("")
	cine(true)
	if player.interact.held:
		player.interact.drop()
	var mills := actor(&"mills")
	mills.look_at_player = true
	mills.move_to(player.global_position, true)
	await wait_until(func() -> bool: return mills.global_position.distance_to(player.global_position) < 2.8, 8.0)
	mills.stop_moving()
	mills.face_point(player.global_position)
	player.look_at_point(mills.global_position + Vector3(0, 1.5, 0), 0.5)
	await seq(["ch1_mills_arrest_01", "ch1_mills_arrest_02", "ch1_mills_arrest_03", "ch1_mills_arrest_04", "ch1_mills_arrest_05", "ch1_mills_arrest_06", "ch1_mills_arrest_07"], 0.15)
	DialogueManager.say(&"ch1_exit_01", 1)
	_exit_chatter()
	# march outside: everybody is herded to the forecourt
	for a in strangers:
		a.run_away_to(mkp(CROWD[randi() % CROWD.size()]))
	await walk_player_to(mkp("DoorInside"), 2.6, 0.8, 9.0)
	await walk_player_to(mkp("ExitDoor"), 2.6, 0.8, 6.0)
	await Director.fade(true, 0.5)
	_teleport_crowd()
	teleport_player("WatchSpot")
	player.rotation.y = 0.0
	player.pitch = deg_to_rad(6.0)
	pickles.teleport(mkp("WatchPickles"))
	pickles.command(&"stay")
	music("mus_explore_low", 1.0)
	AudioManager.set_muffled(0.0, 0.1)
	await wait(0.4)
	await Director.fade(false, 0.7)
	await _collapse_scene()


func _teleport_crowd() -> void:
	var order := [&"tiffany", &"gus", &"marco", &"luis", &"dale", &"brenda", &"kid", &"mills"]
	for i in order.size():
		var a := actor(order[i])
		a.stop_moving()
		a.set_panic(false)
		a.teleport(mkp(CROWD[i % CROWD.size()]) + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)))
		a.talkable = false
		a.look_at_player = false
		a.face_point(mkp("SculptureFloor"))
		a.play_anim("idle", 0.1)
	actor(&"mills").teleport(mkp("MillsOut"))
	actor(&"mills").face_point(player.global_position)
	for i in strangers.size():
		var s := strangers[i]
		s.stop_moving()
		s.set_panic(false)
		s.teleport(mkp(CROWD[(i + 3) % CROWD.size()]) + Vector3(1.4, 0, 1.2))
		s.face_point(mkp("SculptureFloor"))
	actor(&"brenda").play_anim("phone_film", 0.2)
	actor(&"dale").play_anim("idle_look", 0.2)


func _collapse_scene() -> void:
	# The chain runs against an empty hall while everybody watches from outside.
	AudioManager.stop_music(2.0)
	await seq(["ch1_out_01", "ch1_out_02", "ch1_out_03", "ch1_out_04", "ch1_out_05"], 0.5)
	disaster = _build_disaster(false)
	disaster.start()
	music("mus_premonition", 2.0)
	# hold until the sculpture starts to sway, then the reveal
	await wait_until(func() -> bool: return disaster.is_done("cable1") or not disaster.running, 30.0)
	player.look_at_point(Vector3(0, 6.0, 2.0), 1.2)
	await say("ch1_out_06")
	await say("ch1_out_07")
	await wait_until(func() -> bool: return not disaster.running, 60.0)
	await wait(1.5)
	AudioManager.set_muffled(0.0, 1.0)
	await seq(["ch1_after_01", "ch1_after_02", "ch1_after_03", "ch1_after_04", "ch1_after_05", "ch1_after_06"], 0.35)
	await wait(1.2)
	SaveManager.checkpoint(&"end")
	await Director.fade(true, 1.2)
	title_card("ELEVEN DAYS LATER", 2.6)
	await wait(2.4)
	await end_to(GameState.Chapter.AFTERMATH)


# ============================================================================ the disaster chain
func _build_disaster(is_vision: bool) -> AccidentChain:
	var S: Array = []
	S.append(Ch.step("cup", [], 0.4, 1.1, [
		Ch.move("TiffanyCup", "CupFloor", 0.75, {"arc": 0.4, "spin": Vector3(1, 0, 0.5), "turns": 1.6, "ease": "in"}),
		Ch.sfx("clink", "CupFloor", {"at_t": 0.7}),
		Ch.fx("smoothie", "CupFloor", {"scale": 1.5, "at_t": 0.72}),
		Ch.fx("decal", "CupFloor", {"what": "puddle", "size": 2.0, "color": Color(0.85, 0.2, 0.55, 0.8), "at_t": 0.75}),
	], {"blockers": [Ch.held("TiffanyCup"), Ch.moved("TiffanyCup", 0.6)], "live": false, "saved_line": "gen_reroute_03"}))
	S.append(Ch.alt("cup_alt", "cup", 1.2, 1.2, [
		Ch.tip("Stool1", "Stool1", Vector3(0, 0, 1), 88, 0.6, {"ease": "in", "bounce": 1.0}),
		Ch.sfx("clang", "Stool1", {"at_t": 0.55}),
		Ch.move("CounterCup", "CupFloor", 0.8, {"arc": 0.5, "spin": Vector3(1, 0, 0), "turns": 1.0, "ease": "in"}),
		Ch.fx("smoothie", "CupFloor", {"scale": 1.4, "at_t": 0.8}),
		Ch.fx("decal", "CupFloor", {"what": "puddle", "size": 2.0, "color": Color(0.85, 0.2, 0.55, 0.8), "at_t": 0.8}),
	]))
	S.append(Ch.step("robot", [], 0.9, 3.4, [
		Ch.loop("roll_loop", "ScrubRobot", 3.0, {"db": -6.0}),
		Ch.move("ScrubRobot", "ScrubTarget", 1.7, {"ease": "in_out"}),
		Ch.move("ScrubRobot", "ScrubSlide", 1.5, {"spin": Vector3.UP, "turns": 0.75, "ease": "out", "at_t": 1.7, "keep_rot": true}),
		Ch.sfx("comic_slide_whistle", "ScrubTarget", {"at_t": 1.7}),
		Ch.sfx("squeak", "ScrubSlide", {"at_t": 2.6}),
	], {"any": ["cup", "cup_alt"]}))
	S.append(Ch.step("cart", ["robot"], 0.2, 5.6, [
		Ch.sfx("thump", "BaggageCart"),
		Ch.loop("cart_rattle", "BaggageCart", 5.6, {"db": -3.0}),
		Ch.move("BaggageCart", "CartMid", 3.4, {"ease": "in", "keep_rot": true}),
		Ch.move("BaggageCart", "CartCrash", 2.1, {"ease": "in", "at_t": 3.4, "keep_rot": true}),
		Ch.sfx("whoosh", "BaggageCart", {"at_t": 1.2}),
	]))
	S.append(Ch.step("esc_hit", ["cart"], 0.0, 2.4, [
		Ch.sfx("metal_crash", "CartCrash", {"db": 3.0}),
		Ch.fx("spark", "CartCrash", {"scale": 2.0, "offset": Vector3(0, 0.6, 0)}),
		Ch.fn(func() -> void: esc.jam()),
		Ch.tip("Escalator", "EscBase", Vector3(0, 0, 1), -11, 1.8, {"ease": "in", "bounce": 1.0}),
		Ch.cam({"shake": 0.5, "rumble": 0.6}),
		Ch.sfx("creak", "EscBase", {"at_t": 0.5}),
		Ch.fx("dust", "CartCrash", {"scale": 2.0, "at_t": 0.4}),
		Ch.sfx("fluorescent_flicker", "SculptureFloor", {"at_t": 0.3}),
	]))
	var pivot := Vector3(0, 11.6, 2.0)
	var wob := [3.5, 5.0, 7.0, 9.5, 12.0, 15.0]
	var prev := "esc_hit"
	for i in 6:
		var sid := "cable%d" % (i + 1)
		S.append(Ch.step(sid, [prev], 0.5 + (0.25 if i == 0 else 0.0), 0.7, [
			Ch.sfx("snap", pivot + Vector3(cos(i * 1.05) * 1.6, -0.3, sin(i * 1.05) * 1.6)),
			Ch.fx("spark", pivot + Vector3(cos(i * 1.05) * 1.6, -0.3, sin(i * 1.05) * 1.6), {"scale": 1.3}),
			Ch.tip("Sculpture", pivot, Vector3(cos(i * 1.7), 0, sin(i * 1.7)), wob[i] * (1.0 if i % 2 == 0 else -1.0), 0.6, {"ease": "in_out"}),
			Ch.sfx("creak", pivot, {"at_t": 0.2, "db": -3.0}),
			Ch.cam({"shake": 0.15 + 0.05 * i}),
		]))
		prev = sid
	S.append(Ch.step("sculpt_fall", ["cable6"], 0.15, 1.9, [
		Ch.move("Sculpture", Vector3(0, 5.95, 2.0), 1.15, {"ease": "in_cubic", "release": false}),
		Ch.sfx("whoosh", "SculptureFloor", {"db": 3.0}),
		Ch.sfx("big_boom", "SculptureFloor", {"db": 6.0, "at_t": 1.1}),
		Ch.fx("dust", "SculptureFloor", {"scale": 3.5, "at_t": 1.1}),
		Ch.fx("debris", "SculptureFloor", {"scale": 2.5, "at_t": 1.1}),
		Ch.debris("SculptureFloor", 30, 6.0, {"at_t": 1.1, "life": 8.0}),
		Ch.cam({"shake": 0.9, "rumble": 1.0, "rumble_d": 0.8, "at_t": 1.1}),
		Ch.fx("decal", "SculptureFloor", {"what": "scorch", "size": 4.5, "color": Color(0.1, 0.1, 0.1, 0.7), "at_t": 1.15}),
	]))
	S.append(Ch.step("ceiling", ["sculpt_fall"], 0.3, 2.4, [
		Ch.sfx("debris_rumble", "SculptureFloor", {"db": 2.0}),
		Ch.debris(Vector3(-4, 10.5, 0), 22, 1.0, {"dir": Vector3.DOWN, "life": 8.0}),
		Ch.debris(Vector3(6, 10.5, 4), 22, 1.0, {"dir": Vector3.DOWN, "life": 8.0, "at_t": 0.5}),
		Ch.fx("dust", Vector3(0, 6, 0), {"scale": 4.0, "at_t": 0.2}),
		Ch.cam({"shake": 0.6, "rumble": 0.7, "rumble_d": 1.2}),
	]))
	S.append(Ch.step("pod", ["esc_hit"], 3.2, 2.6, [
		Ch.sfx("creak", "InspectSkyLink", {"db": 2.0}),
		Ch.tip("SkyLinkPod", Vector3(20.5, 7.4, -15.9), Vector3(0, 0, 1), -35, 1.6, {"ease": "in", "bounce": 1.0}),
		Ch.sfx("metal_crash", "InspectSkyLink", {"at_t": 1.5, "db": 2.0}),
		Ch.fx("spark", "InspectSkyLink", {"scale": 2.0, "at_t": 1.5}),
	]))
	if not is_vision:
		S.append(Ch.step("windows", ["sculpt_fall"], 0.9, 2.6, [
			Ch.fn(_shatter_glass),
			Ch.sfx("glass_break", Vector3(-8, 2, 18), {"db": 4.0}),
			Ch.sfx("glass_break", Vector3(8, 2, 18), {"db": 4.0, "at_t": 0.3}),
			Ch.fx("dust", Vector3(0, 1.5, 19.5), {"scale": 5.0, "dir": Vector3(0, 0.3, 1)}),
			Ch.fx("debris", Vector3(-8, 2, 19), {"scale": 2.0}),
			Ch.fx("debris", Vector3(8, 2, 19), {"scale": 2.0, "at_t": 0.2}),
			Ch.cam({"shake": 0.7, "rumble": 0.8}),
		]))
		S.append(Ch.step("aftermath", ["windows", "ceiling"], 1.5, 2.0, [
			Ch.sfx("pa_chime", "InspectCeiling", {"db": -2.0}),
			Ch.fx("smoke", Vector3(0, 0.5, 2), {"scale": 3.0}),
		]))
	var c := make_chain("ch1_disaster", S, {"vision": is_vision, "speed": 1.7 if is_vision else 1.0, "max_time": 60.0, "reroute_dialogue": not is_vision})
	return c


func _shatter_glass() -> void:
	var g := level.find_child("station_glass*", true, false) as Node3D
	if g:
		g.visible = false


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("ticket", func() -> bool: return not ticket_done and not vision_done, func() -> void: _use_ticket())
	qa_add("barrier", func() -> bool: return ticket_done and not vision_done and not busy_talk, func() -> void: teleport_player("BarrierSpot"))
	qa_add("alarm", func() -> bool: return panic and not alarm_pulled and not arrested and _panic_time > 3.0, func() -> void: _pull_alarm())


## The crowd, Brenda-adjacent bystanders and Eddie all talk over the march out of the station.
func _exit_chatter() -> void:
	for id in ["ch1_exit_02", "ch1_exit_03", "ch1_exit_04", "ch1_exit_05"]:
		await wait(1.6)
		if not is_inside_tree():
			return
		DialogueManager.bark(StringName(id))
