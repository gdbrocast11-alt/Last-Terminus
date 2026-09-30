extends Chapter
## CHAPTER 7 -- RETURN TO TERMINUS. The reopening ceremony. Everybody is waiting for the reveal. Eddie decides
## to do absolutely nothing -- and the entire station falls apart around him without touching him.

const HAZARDS := [
	{"who": &"gus", "line": "ch7_sign_gus", "insp": "ch7_insp_sign"},
	{"who": &"dale", "line": "ch7_sign_dale", "insp": "ch7_insp_coffee"},
	{"who": &"mills", "line": "ch7_sign_mills", "insp": "ch7_insp_cart"},
	{"who": &"marco", "line": "ch7_sign_marco", "insp": "ch7_insp_robot"},
	{"who": &"luis", "line": "ch7_sign_luis", "insp": "ch7_insp_escalator"},
	{"who": &"tiffany", "line": "ch7_sign_tiff", "insp": "ch7_insp_cable"},
	{"who": &"brenda", "line": "ch7_sign_brenda", "insp": "ch7_insp_bottle"},
]
const WATCH := ["CoffeeMachine", "ArrivalsBoard", "BaggageCart2", "ScrubRobot", "Escalator", "FinaleBottle", "PianoHoist", "FinaleCrate", "WetSign2", "Train", "Chair1"]

var esc: Escalator
var mills: Actor
var gus: Actor
var dale: Actor
var marco: Actor
var luis: Actor
var tiff: Actor
var brenda: Actor
var graves: Actor
var met: Dictionary = {}
var inspected: Dictionary = {}
var _elapsed := 0.0
var decided := false
var sitting := false
var mayhem_done := false
var _nope_i := 0
var _pa_i := 0
var _sign_i := 0


func _play(beat: StringName) -> void:
	set_group("day1", false)
	set_group("finale", true)
	_setup_world()
	AudioManager.play_ambience(&"amb_station", -6.0)
	music("mus_explore_station", 2.0)
	await _intro()


func _setup_world() -> void:
	esc = Escalator.new()
	level.add_child(esc)
	esc.setup(Vector3(-16.0, 0.0, -0.5), Vector3(-16.0, 5.4, -11.0))
	for pair in [["CoffeeMachine", "ch7_insp_coffee"], ["ArrivalsBoard", "ch7_insp_sign"], ["BaggageCart2", "ch7_insp_cart"], ["ScrubRobot", "ch7_insp_robot"],
			["FinaleBottle", "ch7_insp_bottle"], ["ScaffoldWrench", "ch7_insp_tool"], ["SitBench", "ch7_sit_prompt"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(Vector3(-16, 0.6, 0.4), Vector3(1.9, 1.2, 0.6), "ch7_insp_escalator", "InspectEscalator", 1)
	add_inspect(Vector3(2.0, 10.2, -4.0), Vector3(1.0, 1.6, 1.0), "ch7_insp_cable", "InspectCable", 1)
	for pair2 in [["CoffeeMachine", 2], ["ArrivalsBoard", 2], ["BaggageCart2", 1], ["ScrubRobot", 1], ["FinaleBottle", 1], ["ScaffoldWrench", 1], ["PianoHoist", 2], ["WetSign2", 1]]:
		if prop(pair2[0]) and pc(pair2[0]):
			set_hazard(pair2[0], pair2[1])
	for n in ["FinaleBottle", "FinaleCrate", "Chair1", "WetSign2", "BaggageCart2", "ScrubRobot"]:
		freeze_prop(n)
	var pa := Node3D.new()
	level.add_child(pa)
	pa.global_position = Vector3(0, 10.0, 4.0)
	DialogueManager.register_speaker(&"pa", pa)
	var crowd := Node3D.new()
	level.add_child(crowd)
	crowd.global_position = Vector3(0, 1.6, 8.0)
	DialogueManager.register_speaker(&"crowd", crowd)
	DialogueManager.register_speaker(&"stranger", crowd)
	settle_props(["CoffeeMachine", "FinaleBottle", "BaggageCart2", "ScrubRobot"])
	_spawn_npcs()
	_qa_hooks()


func _spawn_npcs() -> void:
	mills = npc(&"mills", "FinaleMills", {"talkable": true, "idle": "hands_hips"})
	gus = npc(&"gus", "FinaleGus", {"talkable": true, "idle": "clipboard"})
	dale = npc(&"dale", "FinaleDale", {"talkable": true, "idle": "idle_look"})
	marco = npc(&"marco", "FinaleMarco", {"talkable": true, "idle": "argue"})
	luis = npc(&"luis", "FinaleLuis", {"talkable": true, "idle": "argue"})
	graves = npc(&"graves", "FinaleGraves", {"talkable": true, "idle": "talk_c"})
	if GameState.is_alive(&"tiffany"):
		tiff = npc(&"tiffany", "FinaleTiffany", {"talkable": true, "idle": "hold_cup"})
	if GameState.is_alive(&"brenda"):
		brenda = npc(&"brenda", "FinaleBrenda", {"talkable": true, "idle": "phone_film"})
	on_talk(mills, func() -> void: await _meet(&"mills", ["ch7_mills_01", "ch7_mills_02", "ch7_mills_03", "ch7_mills_04"], "ch7_mills_repeat"))
	on_talk(gus, func() -> void: await _meet(&"gus", ["ch7_gus_01", "ch7_gus_02", "ch7_gus_03"], "ch7_gus_repeat"))
	on_talk(dale, func() -> void: await _meet(&"dale", ["ch7_dale_01", "ch7_dale_02", "ch7_dale_03"], "ch7_dale_repeat"))
	on_talk(marco, func() -> void: await _meet(&"marco", ["ch7_ml_01", "ch7_ml_02", "ch7_ml_03", "ch7_ml_04"], "ch7_ml_repeat"))
	on_talk(luis, func() -> void: await _meet(&"marco", ["ch7_ml_01", "ch7_ml_02", "ch7_ml_03", "ch7_ml_04"], "ch7_ml_repeat"))
	on_talk(graves, func() -> void: await _meet(&"graves", ["ch7_graves_01"], "ch7_graves_repeat"))
	if tiff:
		on_talk(tiff, func() -> void: await _meet(&"tiffany", ["ch7_tiff_01", "ch7_tiff_02", "ch7_tiff_03", "ch7_tiff_04"], "ch7_tiff_repeat"))
	if brenda:
		on_talk(brenda, func() -> void: await _meet(&"brenda", ["ch7_brenda_01", "ch7_brenda_02", "ch7_brenda_03"], "ch7_brenda_repeat"))


func _meet(id: StringName, lines: Array, repeat_line: String) -> void:
	if not met.has(id):
		met[id] = true
		await seq(lines, 0.25)
		if id == &"dale" and not GameState.is_alive(&"brenda"):
			await seq(["ch7_brenda_dead_01", "ch7_brenda_dead_02"], 0.3)
		if id == &"gus" and not GameState.is_alive(&"tiffany"):
			await say("ch7_tiff_dead_01")
	else:
		await say(repeat_line)


# ============================================================================ intro + waiting
func _intro() -> void:
	await begin_player("FinaleStart", "PicklesStart")
	teleport_player("FinaleStart")
	pickles.teleport_near(player.global_position + Vector3(1.2, 0, 0))
	pickles.leash_enabled = false
	title_card("RETURN TO TERMINUS", 3.0)
	sting("sting_title_card", -6.0)
	objective("Find out what's going to happen")
	save(&"start")
	_pa_loop()
	_clock_loop()
	await seq(["ch7_arrive_01", "ch7_arrive_02"], 0.4)


func _pa_loop() -> void:
	var lines := ["ch7_pa_01", "ch7_pa_02", "ch7_pa_03", "ch7_pa_04"]
	await wait(4.0)
	while not decided and is_inside_tree():
		if not DialogueManager.is_busy():
			AudioManager.play_sfx(&"pa_chime", Vector3(0, 10, 4), -4.0)
			DialogueManager.say(StringName(lines[_pa_i % lines.size()]), 0)
			_pa_i += 1
		await wait(24.0)


func _clock_loop() -> void:
	# The ceremony "countdown": people start pointing out hazards, Eddie starts to hope for a reveal.
	while not decided and is_inside_tree():
		await wait(1.0)
		if Director.input_locked:
			continue
		_elapsed += 1.0
		if _elapsed == 45.0 or (_elapsed > 45.0 and int(_elapsed) % 40 == 0 and _sign_i < HAZARDS.size()):
			await _hazard_call()
		var enough := (_elapsed > 100.0 and met.size() >= 3) or _elapsed > 190.0
		if enough and not decided:
			await _decision()
			return


func _hazard_call() -> void:
	if _sign_i >= HAZARDS.size() or DialogueManager.is_busy():
		return
	var h: Dictionary = HAZARDS[_sign_i]
	_sign_i += 1
	if h.who == &"brenda" and brenda == null:
		return
	if h.who == &"tiffany" and tiff == null:
		return
	DialogueManager.bark(StringName(h.line))
	if _sign_i == 3:
		bark("ch7_expect_01")


# ============================================================================ the decision
func _decision() -> void:
	decided = true
	cine(true)
	objective("")
	if DialogueManager.is_busy():
		await wait_speech()
	await seq(["ch7_expect_01", "ch7_expect_02", "ch7_expect_03"], 0.4)
	await say("ch7_expect_04")
	await say("ch7_expect_05")
	await wait(0.6)
	music("mus_finale_doom", 2.0)
	await seq(["ch7_decide_01", "ch7_decide_02", "ch7_decide_03", "ch7_decide_04", "ch7_decide_05"], 0.8)
	# walk to the bench and sit
	var bench := prop("SitBench")
	if bench:
		bench.collision_layer = 0
	await walk_player_to(mkp("FinaleBench") + Vector3(0.0, 0, 1.1), 2.0, 0.35, 14.0)
	player.rotation.y = 0.0
	var tw := create_tween()
	tw.tween_property(player.head, "position:y", player.head.position.y - 0.5, 0.8).set_trans(Tween.TRANS_SINE)
	pickles.begin_scripted()
	pickles.scripted = true
	pickles.global_position = mkp("FinaleBench") + Vector3(-1.5, 0.0, 1.0)
	pickles.play_anim("sit", 0.2)
	for a: Actor in [mills, gus, dale, marco, luis, graves]:
		a.look_at_player = true
		a.talkable = false
	# Mills et al. try to talk him out of it
	await seq(["ch7_urge_01", "ch7_urge_02", "ch7_urge_03", "ch7_urge_04", "ch7_urge_05", "ch7_urge_06", "ch7_urge_07"], 0.4)
	sitting = true
	title_card("DO ABSOLUTELY NOTHING", 3.0)
	sting("sting_mystery")
	player.frozen = true            # movement + interaction refused, but he can still look around
	Director.lock_input(false)
	Director.set_hud_visible(false)
	save(&"nothing")
	await wait(2.5)
	_nope_watch()
	await _mayhem()


func _nope_watch() -> void:
	while not mayhem_done and is_inside_tree():
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"use_item") or Input.is_action_just_pressed(&"pickles_command"):
			if not DialogueManager.is_busy():
				DialogueManager.say(StringName("ch7_nope_0%d" % (1 + (_nope_i % 5))), 1)
				_nope_i += 1


# ============================================================================ the mega-chain
func _mayhem() -> void:
	var c := _build_chain()
	c.finished.connect(func(_r: Dictionary) -> void: mayhem_done = true)
	c.music_group = &"chain_a"
	c.music_stems = ["perc", "bass", "mar", "str", "brass"]
	AudioManager.play_layered(&"chain_a", ["perc", "bass", "mar", "str", "brass"], 1)
	c.step_fired.connect(_on_mayhem_step)
	c.start()
	await wait_until(func() -> bool: return mayhem_done, 90.0)
	mayhem_done = true
	await _aftermath()


func _on_mayhem_step(sid: StringName) -> void:
	match sid:
		&"steam": DialogueManager.say(&"ch7_c_light", 1)
		&"cart": DialogueManager.say(&"ch7_c_cart", 1)
		&"sign": DialogueManager.say(&"ch7_c_wet", 1)
		&"cable": DialogueManager.say(&"ch7_c_plug", 1)
		&"bottle": DialogueManager.say(&"ch7_c_bottle", 1)
		&"ceiling": DialogueManager.say(&"ch7_c_ceiling", 1)
		&"train": DialogueManager.say(&"ch7_c_train", 1)
		&"piano": DialogueManager.say(&"ch7_c_piano", 1)
		&"pile":
			DialogueManager.say(&"ch7_c_eddie", 1)


func _build_chain() -> AccidentChain:
	var S: Array = []
	var pile := mkp("PileCenter")
	S.append(Ch.step("steam", [], 1.5, 2.4, [
		Ch.sfx("steam_hiss", "CoffeeMachine", {"db": 4.0}),
		Ch.fx("steam", "CoffeeMachine", {"scale": 2.4, "offset": Vector3(0, 0.9, 0)}),
		Ch.tip("CoffeeMachine", "CoffeeMachine", Vector3(0, 0, 1), 12, 0.7, {"ease": "in_out", "bounce": 1.0}),
		Ch.sfx("clang", "CoffeeMachine", {"at_t": 0.9}),
	]))
	S.append(Ch.step("sign", ["steam"], 0.6, 3.2, [
		Ch.sfx("creak", "ArrivalsBoard", {"db": 3.0}),
		Ch.tip("ArrivalsBoard", Vector3(24.4, 9.0, 4.0), Vector3(0, 0, 1), 40, 0.8, {"ease": "in", "bounce": 1.0}),
		Ch.move("ArrivalsBoard", Vector3(20.5, 0.1, 5.2), 0.9, {"ease": "in_cubic", "at_t": 0.8}),
		Ch.sfx("metal_crash", Vector3(20.5, 0, 5.2), {"at_t": 1.7, "db": 4.0}),
		Ch.fx("dust", Vector3(20.5, 0.3, 5.2), {"scale": 2.0, "at_t": 1.7}),
		Ch.move("ArrivalsBoard", pile + Vector3(3.0, 0.1, 0.5), 1.4, {"ease": "out", "at_t": 1.8}),
	]))
	S.append(Ch.step("cart", ["sign"], 0.2, 4.2, [
		Ch.sfx("thump", "BaggageCart2"),
		Ch.loop("cart_rattle", "BaggageCart2", 3.8, {"db": -2.0}),
		Ch.move("BaggageCart2", Vector3(10.0, 0, 1.5), 2.0, {"ease": "in", "keep_rot": true}),
		Ch.move("BaggageCart2", pile + Vector3(-1.5, 0, 1.5), 1.8, {"ease": "out", "at_t": 2.0, "keep_rot": true}),
		Ch.sfx("cloth_rustle", "BaggageCart2", {"at_t": 0.4}),
	]))
	S.append(Ch.step("robot", ["sign"], 0.9, 4.4, [
		Ch.loop("roll_loop", "ScrubRobot", 4.0, {"db": -3.0}),
		Ch.move("ScrubRobot", Vector3(11.0, 0, 6.0), 1.4, {"ease": "in_out"}),
		Ch.move("ScrubRobot", Vector3(8.5, 0, 3.0), 1.2, {"at_t": 1.4, "spin": Vector3.UP, "turns": 1.0, "keep_rot": true}),
		Ch.move("ScrubRobot", pile + Vector3(1.0, 0, -0.5), 1.4, {"at_t": 2.6, "ease": "out", "keep_rot": true}),
		Ch.sfx("squeak", "ScrubRobot", {"at_t": 2.0}),
	]))
	S.append(Ch.step("escalator", ["cart"], 0.3, 3.0, [
		Ch.fn(func() -> void: esc.jam()),
		Ch.sfx("metal_crash", "InspectEscalator", {"db": 4.0}),
		Ch.fx("spark", Vector3(-16, 1.0, 0), {"scale": 2.2}),
		Ch.tip("Escalator", Vector3(-16.0, 0.0, -0.5), Vector3(0, 0, 1), 9, 1.4, {"ease": "in", "bounce": 1.0}),
		Ch.cam({"shake": 0.4, "rumble": 0.5}),
		Ch.fx("dust", Vector3(-16, 0.5, 0), {"scale": 2.4, "at_t": 0.8}),
	]))
	S.append(Ch.step("bottle", ["robot"], 0.2, 4.0, [
		Ch.loop("roll_loop", "FinaleBottle", 3.6, {"db": -2.0}),
		Ch.move("FinaleBottle", Vector3(6.8, 0.0, 7.8), 3.6, {"ease": "out", "spin": Vector3(0, 0, 1), "turns": 3.0, "keep_rot": true}),
		Ch.sfx("clink", Vector3(6.8, 0, 7.8), {"at_t": 3.5}),
	]))
	S.append(Ch.step("cable", ["escalator"], 0.4, 3.4, [
		Ch.fn(func() -> void: _cable_whip()),
		Ch.sfx("zap", Vector3(6, 6, 6), {"db": 4.0}),
		Ch.sfx("spark", Vector3(6, 3, 6), {"at_t": 0.8, "db": 3.0}),
		Ch.fx("spark", Vector3(6, 4, 6), {"scale": 2.0, "at_t": 0.8}),
	]))
	S.append(Ch.step("train", ["cable"], 0.2, 4.0, [
		Ch.sfx("train_horn", Vector3(0, 1, -28), {"db": 8.0}),
		Ch.sfx("train_pass", Vector3(0, 1, -28), {"db": 6.0}),
		Ch.move("Train", Vector3(-22.0, -0.95, -29.9), 3.2, {"ease": "in", "keep_rot": true}),
		Ch.cam({"shake": 0.35, "rumble": 0.6, "rumble_d": 2.0}),
		Ch.sfx("metal_crash", Vector3(-22, 1, -29.9), {"at_t": 3.1, "db": 5.0}),
		Ch.fx("dust", Vector3(-22, 1, -29.9), {"scale": 3.0, "at_t": 3.1}),
	]))
	S.append(Ch.step("piano", ["bottle"], 0.4, 3.6, [
		Ch.sfx("snap", "PianoHoist", {"db": 5.0}),
		Ch.fx("spark", Vector3(3.6, 11.4, 3.4), {"scale": 1.4}),
		Ch.move("PianoHoist", Vector3(3.6, 0.0, 3.4), 1.0, {"ease": "in_cubic", "at_t": 0.4, "keep_rot": true}),
		Ch.sfx("big_boom", Vector3(3.6, 0, 3.4), {"at_t": 1.4, "db": 8.0}),
		Ch.sfx("clang", Vector3(3.6, 0, 3.4), {"at_t": 1.45, "pitch": 0.5}),
		Ch.fx("dust", Vector3(3.6, 0.4, 3.4), {"scale": 4.0, "at_t": 1.45}),
		Ch.debris(Vector3(3.6, 0.6, 3.4), 24, 5.0, {"at_t": 1.45, "life": 12.0}),
		Ch.cam({"shake": 0.9, "rumble": 1.0, "rumble_d": 0.8, "at_t": 1.45}),
		Ch.say("ch7_c_eddie2", 1, 2.4),
	]))
	S.append(Ch.step("ceiling", ["piano"], 0.3, 3.2, [
		Ch.sfx("debris_rumble", Vector3(0, 8, 4), {"db": 3.0}),
		Ch.debris(Vector3(-8, 10.5, 2), 26, 1.0, {"dir": Vector3.DOWN, "life": 12.0}),
		Ch.debris(Vector3(10, 10.5, -2), 26, 1.0, {"dir": Vector3.DOWN, "life": 12.0, "at_t": 0.6}),
		Ch.debris(Vector3(0, 10.5, 11), 20, 1.0, {"dir": Vector3.DOWN, "life": 12.0, "at_t": 1.2}),
		Ch.fx("dust", Vector3(0, 5, 4), {"scale": 5.0, "at_t": 0.4}),
		Ch.cam({"shake": 0.6, "rumble": 0.8, "rumble_d": 1.5}),
		Ch.move("FinaleCrate", pile + Vector3(0.5, 0.0, 1.0), 1.4, {"arc": 2.0, "at_t": 0.8, "spin": Vector3(1, 0, 1), "turns": 1.0}),
		Ch.move("WetSign2", pile + Vector3(-1.0, 0.0, 2.0), 1.2, {"arc": 1.4, "at_t": 1.0, "spin": Vector3(0, 0, 1), "turns": 1.0}),
		Ch.move("Chair1", pile + Vector3(1.6, 0.0, -1.2), 1.3, {"arc": 1.6, "at_t": 1.2, "spin": Vector3(1, 0, 0), "turns": 1.0}),
	]))
	S.append(Ch.step("pile", ["ceiling", "train"], 0.6, 2.6, [
		Ch.sfx("sigh_comic", Vector3(3, 1, 5), {"db": -2.0}),
		Ch.fn(func() -> void: _pickles_on_pile()),
		Ch.stinger("sting_finale_flop"),
	]))
	S.append(Ch.step("silence", ["pile"], 1.2, 3.0, [
		Ch.fn(func() -> void: AudioManager.set_layers(1)),
		Ch.music({"track": "mus_finale_confused", "fade": 2.0}),
	]))
	return make_chain("ch7_mayhem", S, {"max_time": 60.0, "reroute_dialogue": false})


func _cable_whip() -> void:
	var pivot := Node3D.new()
	level.add_child(pivot)
	pivot.global_position = Vector3(7.0, 9.6, 6.4)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.03
	cm.height = 7.0
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.06)
	mi.material_override = mat
	pivot.add_child(mi)
	mi.position = Vector3(0, -3.5, 0)
	pivot.rotation_degrees.z = -55.0
	var tw := create_tween()
	tw.tween_property(pivot, "rotation_degrees:z", 55.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_callback(func() -> void: FX.burst(&"spark", pivot.global_position + Vector3(0, -6.6, 0), 1.6))
	tw.tween_property(pivot, "rotation_degrees:z", -20.0, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pivot, "rotation_degrees:z", 8.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(pivot.queue_free)


func _pickles_on_pile() -> void:
	var top := mkp("PileCenter") + Vector3(0.0, 1.5, 0.0)
	pickles.scripted = true
	var t := create_tween()
	t.tween_property(pickles, "global_position", top, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func() -> void:
		pickles.play_anim("scratch", 0.1)
		AudioManager.play_sfx(&"pk_paw", top))


# ============================================================================ aftermath
func _aftermath() -> void:
	await wait(1.2)
	await say("ch7_c_pickles")
	await wait(0.9)
	await say("ch7_after_01")
	AudioManager.play_sfx(&"pa_chime", Vector3(0, 10, 4), 0.0)
	await say("ch7_pa_susp")
	await wait(1.2)
	graves.look_at_player = true
	await seq(["ch7_graves_huh", "ch7_graves_02", "ch7_graves_03", "ch7_graves_04", "ch7_graves_05", "ch7_graves_06", "ch7_graves_07"], 0.5)
	AchievementManager.unlock(&"the_last_stop")
	await seq(["ch7_ml_end_01", "ch7_ml_end_02", "ch7_ml_end_03"], 0.3)
	await say("ch7_dale_end")
	await say("ch7_gus_end")
	await say("ch7_mills_end")
	# Eddie stands up and takes it in
	var tw := create_tween()
	tw.tween_property(player.head, "position:y", player.head.position.y + 0.5, 0.8).set_trans(Tween.TRANS_SINE)
	player.look_at_point(mkp("PileCenter") + Vector3(0, 1.6, 0), 1.0)
	await wait(1.6)
	await seq(["ch7_final_01", "ch7_final_02", "ch7_final_03"], 0.9)
	pickles.play_oneshot("bark", 0.8)
	AudioManager.play_sfx(&"pk_bark", top_of_pile(), 2.0)
	SequenceManager.add_clue(&"gave_up", "It Gave Up", "I did absolutely nothing. Everything happened -- and none of it touched me. Graves: 'Maybe it gave up.'")
	await wait(2.5)
	SaveManager.checkpoint(&"end")
	AudioManager.stop_music(2.0)
	await Director.fade(true, 1.6)
	await end_to(GameState.Chapter.ENDING)


func top_of_pile() -> Vector3:
	return mkp("PileCenter") + Vector3(0, 1.5, 0)


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("talk_mills", func() -> bool: return not decided and not busy_talk and not Director.input_locked and _elapsed > 3.0, func() -> void: _run_talk(mills, func() -> void: await _meet(&"mills", ["ch7_mills_01", "ch7_mills_02", "ch7_mills_03", "ch7_mills_04"], "ch7_mills_repeat")))
	qa_add("skip_clock", func() -> bool: return not decided and _elapsed > 12.0 and not busy_talk and not Director.input_locked, func() -> void: _elapsed = 195.0)
