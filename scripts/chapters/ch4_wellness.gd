extends Chapter
## CHAPTER 4 -- THE ALIGNMENT POP-UP (Riverbend Community Recreation Center).
## Tiffany's keynote. Gus quietly defuses every hazard in the building; the machine keeps rerouting to the ones
## he can't reach: the chandelier over Tiffany and Marco's treadmill. The player's tools: the winch and the safety key.

const GUS_PLAN := [
	{"t": 35.0, "id": "strip", "marker": "GusBar", "flag": "strip_fixed", "look": "BarStrip", "lines": ["ch4_gag_strip_03"]},
	{"t": 62.0, "id": "candle", "marker": "GusCandle", "flag": "candle_fixed", "look": "CandlesStageL", "lines": ["ch4_gag_candle_01"]},
	{"t": 88.0, "id": "steam", "marker": "GusSteam", "flag": "steam_fixed", "look": "SteamGen", "lines": ["ch4_gag_steam_01"]},
	{"t": 112.0, "id": "tread", "marker": "GusTread", "flag": "tread_fixed", "look": "Treadmill3", "lines": ["ch4_gag_tread_01"]},
	{"t": 130.0, "id": "stage", "marker": "GusStage", "flag": "stage_fixed", "look": "Stage", "lines": ["ch4_gag_stage_01"]},
	{"t": 146.0, "id": "speaker", "marker": "GusSpeaker", "flag": "speaker_fixed", "look": "SpeakerR", "lines": ["ch4_gag_speaker_01"]},
]
const KEYNOTE_AT := 170.0
const WATCH := ["SpareJug", "SpeakerR", "SpeakerL", "CandlesCurtainR", "Curtain3", "Curtain4", "Chandelier", "BarStrip", "Stage", "tiffany"]

var tiff: Actor
var gus: Actor
var marco: Actor
var luis: Actor
var brenda: Actor
var chain: AccidentChain
var tchain: AccidentChain
var _clock := 0.0
var keynote_started := false
var vision_done := false
var chain_done := false
var tread_done := false
var outcome_done := false
var greeted := false
var gus_met := false
var key_pulled := false
var fire_happened := false
var _chand_vol: LethalVolume
var _gus_busy := false
var _gus_lines := 0


func _play(beat: StringName) -> void:
	_setup_world()
	AudioManager.play_ambience(&"amb_wellness", -6.0)
	music("mus_wellness", 2.0)
	if beat == &"keynote":
		await _resume_keynote()
	else:
		await _intro()


# ============================================================================ setup
func _setup_world() -> void:
	for pair in [["Stage", "ch4_insp_stage"], ["SpeakerL", "ch4_insp_speaker"], ["SpeakerR", "ch4_insp_speaker"], ["CandlesStageL", "ch4_insp_candles"],
			["CandlesStageR", "ch4_insp_candles"], ["CandlesCurtainL", "ch4_insp_candles"], ["Winch", "ch4_insp_winch"], ["BarBlender", "ch4_insp_blender"],
			["BarStrip", "ch4_insp_strip"], ["BarStrip2", "ch4_insp_strip"], ["SteamGen", "ch4_insp_steam"], ["Sauna", "ch4_insp_sauna"], ["Treadmill1", "ch4_insp_tread"],
			["Treadmill2", "ch4_insp_tread"], ["Treadmill3", "ch4_insp_tread"], ["Gong", "ch4_insp_gong"], ["DumbbellRack", "ch4_insp_weights"], ["Mat_0_0", "ch4_insp_mat"],
			["Fountain", "ch4_insp_fountain"], ["PlungePool", "ch4_insp_pool"], ["MirrorWall", "ch4_insp_mirror"], ["SafetyKey_Marco", "ch4_insp_key"], ["FountainStrip", "ch4_insp_strip"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(Vector3(0, 6.5, -11.4), Vector3(1.8, 2.6, 1.8), "ch4_insp_crystals", "InspectChandelier", 2)
	add_inspect(Vector3(-19.6, 1.0, 0.0), Vector3(0.3, 2.0, 8.0), "ch4_insp_mirror", "InspectMirror")
	for pair2 in [["Chandelier", 2], ["Winch", 1], ["BarStrip", 2], ["CandlesCurtainR", 2], ["CandlesStageL", 1], ["SteamGen", 1], ["Treadmill1", 2], ["SpeakerR", 1], ["Gong", 1], ["Fountain", 1]]:
		if prop(pair2[0]) and pc(pair2[0]):
			set_hazard(pair2[0], pair2[1])
	# actions
	bind_use("Winch", "Lower the chandelier", _use_winch)
	bind_use("SafetyKey_Marco", "Pull safety key", _pull_key)
	bind_use("BarStrip", "Unplug strip", func() -> void: _player_fix("strip", "BarStrip"))
	bind_use("SteamValve", "Close steam valve", func() -> void: _player_fix("steam", "SteamValve"))
	bind_use("CandlesStageL", "Blow out candles", func() -> void: _player_fix("candle", "CandlesStageL"))
	for n in ["Winch", "BarStrip", "SteamValve", "CandlesStageL", "SafetyKey_Marco"]:
		if prop(n):
			prop(n).set_meta("state", "armed")
	_chand_vol = make_lethal("ChandVol", Vector3(0, 1.8, -11.9), Vector3(2.4, 2.6, 2.6))
	_spawn_npcs()
	settle_props(["SpareJug", "SpeakerL", "SpeakerR", "BarStrip", "CandlesCurtainR", "SafetyKey_Marco"])
	_qa_hooks()


func _spawn_npcs() -> void:
	tiff = npc(&"tiffany", "TiffanyLobby", {"talkable": true, "idle": "hold_cup"})
	gus = npc(&"gus", "GusSpot", {"talkable": true, "idle": "clipboard"})
	marco = npc(&"marco", "MarcoTread", {"talkable": false, "idle": "run"})
	luis = npc(&"luis", "LuisTread", {"talkable": false, "idle": "run"})
	for a: Actor in [marco, luis]:
		a.scripted = true
		a.global_position += Vector3(0, 0.34, 0)
		a.rotation.y = -PI * 0.5
		a.play_anim("run", 0.1, 0.6)
	on_talk(tiff, _talk_tiff)
	on_talk(gus, _talk_gus)
	if GameState.is_alive(&"brenda"):
		brenda = npc(&"brenda", "BrendaSpot", {"talkable": true, "idle": "phone_film"})
		on_talk(brenda, func() -> void: await seq(["ch4_brenda_hi_01", "ch4_brenda_hi_02"], 0.2))
	var st_ids := [&"stranger_a", &"stranger_b", &"stranger_c", &"stranger_d"]
	var st_marks := ["StrangerBlend", "StrangerA", "StrangerB", "StrangerC"]
	var st_idle := ["idle", "idle_look", "check_watch", "idle"]
	for i in 4:
		var s := npc(st_ids[i], st_marks[i], {"idle": st_idle[i], "node_name": "Guest%d" % (i + 1)})
		s.name = "Guest%d" % (i + 1)


# ============================================================================ intro
func _intro() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	title_card("THE ALIGNMENT POP-UP", 3.0)
	sting("sting_title_card", -6.0)
	objective("Find Tiffany")
	save(&"start")
	_clock_loop()
	_gus_routine()
	await say("ch4_arrive_01")
	await wait_until(func() -> bool: return player.global_position.z < 26.0)
	await say("ch4_arrive_02")
	await wait_until(func() -> bool: return tiff.global_position.distance_to(player.global_position) < 6.0)
	await _tiff_greeting()


func _resume_keynote() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	teleport_player("Lobby")
	pickles.teleport_near(player.global_position)
	greeted = true
	gus_met = true
	_clock = KEYNOTE_AT - 20.0
	tiff.teleport(mkp("TiffanyMat"))
	_clock_loop()
	_gus_routine()


func _tiff_greeting() -> void:
	if greeted:
		return
	greeted = true
	cine(true)
	tiff.look_at_player = true
	player.look_at_point(tiff.global_position + Vector3(0, 1.5, 0), 0.5)
	await seq(["ch4_tiff_greet_01", "ch4_tiff_greet_02", "ch4_tiff_greet_03", "ch4_tiff_greet_04", "ch4_tiff_greet_05", "ch4_tiff_greet_06"], 0.2)
	cine(false)
	tiff.move_to(mkp("TiffanyMat"), false)
	objective("Find Gus. Keep an eye on things.")
	save(&"greeted")


func _talk_tiff() -> void:
	if not greeted:
		await _tiff_greeting()
		return
	await say("ch4_tiff_repeat_0%d" % (1 + randi() % 3))


func _talk_gus() -> void:
	if not gus_met:
		gus_met = true
		await seq(["ch4_gus_intro_01", "ch4_gus_intro_02", "ch4_gus_intro_03", "ch4_gus_intro_04", "ch4_gus_intro_05", "ch4_gus_intro_06", "ch4_gus_intro_07"], 0.15)
		await seq(["ch4_gus_talk_01", "ch4_gus_talk_02", "ch4_gus_talk_03"], 0.2)
		objective("Keep Tiffany safe. The keynote starts soon.")
		save(&"gus")
		return
	await say("ch4_gus_line_0%d" % (1 + randi() % 7))


func _clock_loop() -> void:
	while not keynote_started and is_inside_tree():
		await wait(1.0)
		if Director.input_locked:
			continue
		_clock += 1.0
		if _clock >= KEYNOTE_AT:
			break
	await _keynote()


# ============================================================================ Gus
func _gus_routine() -> void:
	for step: Dictionary in GUS_PLAN:
		await wait_until(func() -> bool: return _clock >= float(step.t) or keynote_started)
		if keynote_started:
			return
		await _gus_fix(step)
	await wait_until(func() -> bool: return keynote_started)


func _gus_fix(step: Dictionary) -> void:
	_gus_busy = true
	gus.talkable = false
	gus.move_to(mkp(step.marker), false, 30.0)
	await gus.arrived
	gus.face_point(prop(step.look).global_position if prop(step.look) else mkp(step.marker))
	if has_flag(step.flag):
		# the player got there first
		if player.global_position.distance_to(gus.global_position) < 9.0:
			if step.id == "strip":
				await seq(["ch4_gag_strip_01", "ch4_gag_strip_02", "ch4_gag_strip_03", "ch4_gag_strip_04"], 0.2)
			elif step.id == "steam":
				await seq(["ch4_gag_steam_02", "ch4_gag_steam_03"], 0.2)
	else:
		gus.play_anim("work_low", 0.2)
		await wait(2.4)
		_apply_fix(step.id)
		flag(step.flag)
		GameState.bump(&"gus_fixes")
		if GameState.count(&"gus_fixes") >= 3:
			AchievementManager.unlock(&"safety_first")
		for l in step.lines:
			DialogueManager.say(StringName(l), 1)
		await wait(1.6)
	gus.play_anim("clipboard", 0.3)
	gus.talkable = true
	_gus_busy = false


func _apply_fix(id: String) -> void:
	match id:
		"strip":
			prop("BarStrip").set_meta("state", "fixed")
			unbind_use("BarStrip")
			AudioManager.play_sfx(&"plug_pull", prop("BarStrip").global_position)
		"candle":
			for n in ["CandlesStageL", "CandlesStageR", "CandlesCurtainL", "CandlesCurtainR"]:
				var c := prop(n)
				if c:
					c.set_meta("state", "fixed")
			unbind_use("CandlesStageL")
			AudioManager.play_sfx(&"click_soft", prop("CandlesStageL").global_position)
		"steam":
			prop("SteamValve").set_meta("state", "fixed")
			unbind_use("SteamValve")
			AudioManager.play_sfx(&"valve_turn", prop("SteamValve").global_position)
		"tread":
			AudioManager.play_sfx(&"click_soft", mkp("GusTread"))
		"stage":
			AudioManager.play_sfx(&"clang", prop("Stage").global_position, -4.0)
		"speaker":
			prop("SpeakerR").set_meta("state", "fixed")
			AudioManager.play_sfx(&"clang", prop("SpeakerR").global_position, -4.0)


func _player_fix(id: String, prop_name: String) -> void:
	var f := id + "_fixed"
	if has_flag(f):
		return
	flag(f)
	prop(prop_name).set_meta("state", "fixed")
	unbind_use(prop_name)
	_apply_fix(id)
	AudioManager.play_sfx(&"click_soft", prop(prop_name).global_position)
	if id == "strip":
		await seq(["ch4_gag_strip_01"], 0.1)
	elif id == "candle":
		await say("ch4_gag_candle_02")
	elif id == "steam":
		await say("ch4_gag_steam_02")
	Events.intervention.emit(&"use", StringName(prop_name), {})


# ============================================================================ the winch + the key
func _use_winch() -> void:
	if prop("Winch").get_meta("state") == "lowered":
		return
	prop("Winch").set_meta("state", "lowered")
	unbind_use("Winch")
	bark("ch4_winch")
	AudioManager.play_sfx(&"creak", prop("Winch").global_position, 2.0)
	var loop := AudioManager.attach_loop(&"treadmill_belt", prop("Winch"), -6.0, 18.0)
	var ch := prop("Chandelier")
	var tw := create_tween()
	tw.tween_property(ch, "global_position", Vector3(0, 3.78, -11.4), 6.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if is_instance_valid(loop):
			loop.queue_free()
		AudioManager.play_sfx(&"clink", ch.global_position, 0.0)
		flag("chandelier_lowered"))
	Events.intervention.emit(&"use", &"Winch", {})


func _pull_key() -> void:
	if key_pulled:
		return
	key_pulled = true
	prop("SafetyKey_Marco").set_meta("state", "pulled")
	unbind_use("SafetyKey_Marco")
	AudioManager.play_sfx(&"snap", prop("SafetyKey_Marco").global_position)
	AudioManager.play_sfx(&"click_soft", prop("SafetyKey_Marco").global_position)
	flag("key_pulled")


# ============================================================================ keynote
func _keynote() -> void:
	keynote_started = true
	objective("The keynote is starting")
	cine(true)
	if player.interact.held:
		player.interact.drop()
	if _gus_busy:
		await wait(1.5)
	# everyone takes position
	tiff.talkable = false
	tiff.stop_moving()
	tiff.move_to(mkp("TiffanyStage"), false)
	await wait_until(func() -> bool: return not tiff.moving, 12.0)
	tiff.face_point(mkp("Lobby"))
	tiff.look_at_player = false
	tiff.play_anim("talk_calm", 0.3)
	AudioManager.play_sfx(&"pa_chime", mkp("TiffanyStage"), -2.0)
	cine(false)
	music("mus_wellness", 0.5)
	await seq(["ch4_keynote_01", "ch4_keynote_02"], 0.3)
	if not vision_done:
		vision_done = true
		await _do_vision()
	await seq(["ch4_keynote_03", "ch4_keynote_04"], 0.3)
	save(&"keynote")
	objective("Save Tiffany. The winch is behind the stage.")
	_start_machines()


func _do_vision() -> void:
	chain = _build_chain(true)
	var shots := [
		{"t": 0.0, "cam": Vector3(14.0, 1.6, -3.5), "look": Vector3(17.6, 1.2, -6.4), "fov": 56.0, "line": "ch4_c_blender"},
		{"step": "spark", "cam": Vector3(12.0, 1.0, -5.0), "look": Vector3(14.5, 0.1, -6.9), "fov": 60.0, "line": "ch4_c_spark"},
		{"step": "feedback", "cam": Vector3(1.0, 1.7, -3.0), "look": Vector3(4.6, 1.6, -10.6), "fov": 60.0, "line": "ch4_c_feedback"},
		{"step": "curtain", "cam": Vector3(1.0, 1.4, -6.0), "look": Vector3(5.2, 1.4, -14.9), "fov": 60.0, "line": "ch4_c_curtain"},
		{"step": "sprinkler", "cam": Vector3(0.0, 1.2, -3.0), "look": Vector3(0.0, 6.5, -9.0), "fov": 68.0, "line": "ch4_c_sprinkler"},
		{"step": "chandelier", "cam": Vector3(-3.5, 1.3, -6.5), "look": Vector3(0.0, 3.5, -11.5), "fov": 62.0, "line": "ch4_c_chandelier"},
	]
	await vision(&"ch4_wellness", chain, WATCH, shots, {"max": 24.0})
	chain.queue_free()
	chain = null
	await wait(0.4)
	cine(false)


# ============================================================================ machines
func _start_machines() -> void:
	chain = _build_chain(false)
	chain.finished.connect(_on_chain_finished)
	chain.music_group = &"chain_a"
	chain.music_stems = ["perc", "bass", "mar", "str", "brass"]
	AudioManager.play_layered(&"chain_a", ["perc", "bass", "mar", "str", "brass"], 1)
	chain.start()
	chain.step_fired.connect(func(sid: StringName) -> void:
		if sid in [&"sprinkler", &"curtain"]:
			fire_happened = true)
	_treadmill_gag()


func _build_chain(is_vision: bool) -> AccidentChain:
	var S: Array = []
	S.append(Ch.step("blend", [], 2.0, 3.0, [
		Ch.npc("stranger_a", "anim", {"name": "flail"}),
		Ch.sfx("blender_loop", "BarBlender", {"db": 2.0}),
		Ch.tip("SpareJug", Vector3(17.9, 1.02, -5.2), Vector3(1, 0, 0), 110, 0.7, {"ease": "in", "at_t": 1.0}),
		Ch.fx("smoothie", Vector3(15.0, 0.9, -6.9), {"scale": 1.8, "at_t": 1.6}),
		Ch.fx("decal", Vector3(14.6, 0.03, -6.9), {"what": "puddle", "size": 2.4, "color": Color(0.85, 0.3, 0.6, 0.8), "at_t": 1.7}),
		Ch.sfx("wet_splat", Vector3(14.8, 0.1, -6.9), {"at_t": 1.7}),
	], {}))
	S.append(Ch.step("spark", ["blend"], 0.6, 2.0, [
		Ch.sfx("zap", "BarStrip", {"db": 3.0}),
		Ch.fx("spark", "BarStrip", {"scale": 1.8}),
		Ch.light("BarGlow", "flicker", {"n": 8, "end_on": true}),
		Ch.fx("smoke", "BarStrip", {"scale": 0.8, "at_t": 0.5}),
	], {"blockers": [Ch.is_state("BarStrip", "fixed")], "live": false, "by": "gus"}))
	S.append(Ch.step("feedback", ["spark"], 0.4, 3.0, [
		Ch.sfx("tv_static", "SpeakerR", {"db": 4.0}),
		Ch.sfx("buzz", "SpeakerR", {"at_t": 0.4, "db": 2.0}),
		Ch.tip("SpeakerR", Vector3(4.6, 0, -10.6), Vector3(0, 0, 1), -55, 1.1, {"ease": "in", "bounce": 1.0, "at_t": 0.8}),
		Ch.sfx("metal_crash", "SpeakerR", {"at_t": 1.9}),
		Ch.cam({"shake": 0.3, "at_t": 1.9}),
	], {"blockers": [Ch.is_state("SpeakerR", "fixed")], "live": false, "by": "gus"}))
	S.append(Ch.step("curtain", ["feedback"], 0.3, 3.2, [
		Ch.tip("CandlesCurtainR", Vector3(5.2, 0.0, -14.9), Vector3(1, 0, 0), -80, 0.9, {"ease": "in"}),
		Ch.fx("fire", "CandleCurtain", {"scale": 1.6, "dur": 9.0, "at": "Curtain4", "offset": Vector3(0, 1.0, 0)}),
		Ch.fx("fire", "CandleCurtain", {"scale": 1.4, "dur": 9.0, "at": "Curtain3", "offset": Vector3(0, 1.2, 0), "at_t": 0.8}),
		Ch.loop("fire_crackle", "Curtain4", 9.0, {"db": 0.0}),
		Ch.light("StageSpot", "flicker", {"n": 6, "end_on": true, "at_t": 1.0}),
	], {"blockers": [Ch.is_state("CandlesCurtainR", "fixed")], "live": false, "by": "gus"}))
	S.append(Ch.step("sprinkler", ["curtain"], 0.6, 3.4, [
		Ch.sfx("sprinkler_burst", "SprinklerB", {"db": 3.0}),
		Ch.loop("water_spray", "SprinklerB", 10.0, {"db": -2.0}),
		Ch.fx("splash", "SprinklerA", {"scale": 2.0, "dur": 9.0, "at": "SprinklerA"}),
		Ch.fx("splash", "SprinklerB", {"scale": 2.0, "dur": 9.0, "at": "SprinklerB"}),
		Ch.fx("splash", "SprinklerC", {"scale": 2.0, "dur": 9.0, "at": "SprinklerC"}),
		Ch.fx("decal", Vector3(0, 0.66, -9.0), {"what": "puddle", "size": 5.0, "color": Color(0.5, 0.7, 0.95, 0.5), "at_t": 1.0}),
	], {"any": ["curtain"]}))
	# the universe reroutes to the chandelier no matter which step Gus defused
	var ch_steps := [
		Ch.step("chandelier", ["sprinkler"], 1.0, 2.6, _chandelier_actions(), {"blockers": [Ch.is_state("Winch", "lowered"), Ch.is_state("Chandelier", "dropping")], "live": true, "saved_line": "ch4_tiff_saved_01"}),
		Ch.alt("chandelier_b", "spark", 2.5, 2.6, _chandelier_actions(), {"blockers": [Ch.is_state("Winch", "lowered"), Ch.is_state("Chandelier", "dropping")], "live": true, "by": "gus", "saved_line": "ch4_tiff_saved_01"}),
		Ch.alt("chandelier_c", "feedback", 2.5, 2.6, _chandelier_actions(), {"blockers": [Ch.is_state("Winch", "lowered"), Ch.is_state("Chandelier", "dropping")], "live": true, "by": "gus"}),
		Ch.alt("chandelier_d", "curtain", 2.5, 2.6, _chandelier_actions(), {"blockers": [Ch.is_state("Winch", "lowered"), Ch.is_state("Chandelier", "dropping")], "live": true, "by": "gus"}),
	]
	S.append_array(ch_steps)
	return make_chain("ch4_pop_up", S, {"vision": is_vision, "speed": 2.4 if is_vision else 1.0, "max_time": 80.0, "reroute_dialogue": false})


func _chandelier_actions() -> Array:
	return [
		Ch.state("Chandelier", "dropping"),
		Ch.sfx("creak", "InspectChandelier", {"db": 3.0}),
		Ch.sfx("snap", "InspectChandelier", {"at_t": 0.8, "db": 3.0}),
		Ch.fx("spark", "InspectChandelier", {"scale": 1.4, "at_t": 0.8}),
		Ch.move("Chandelier", Vector3(0, 3.78, -11.4), 1.0, {"ease": "in_cubic", "at_t": 1.0, "release": false}),
		Ch.sfx("glass_break", Vector3(0, 0.9, -11.4), {"at_t": 2.0, "db": 5.0}),
		Ch.sfx("clang", Vector3(0, 0.9, -11.4), {"at_t": 2.0}),
		Ch.fx("debris", Vector3(0, 0.9, -11.4), {"scale": 2.5, "at_t": 2.0}),
		Ch.fx("spark", Vector3(0, 0.9, -11.4), {"scale": 2.0, "at_t": 2.0}),
		Ch.cam({"shake": 0.7, "rumble": 0.8, "at_t": 2.0}),
		Ch.say("ch4_c_tiff_no", 2),
		Ch.kill("ChandVol", "tiffany", "chandelier", "front", {"at_t": 2.05}),
	]


func _on_chain_finished(_result: Dictionary) -> void:
	chain_done = true
	AudioManager.set_layers(1)
	_check_outcome()


# ============================================================================ Marco and Luis
func _treadmill_gag() -> void:
	tchain = make_chain("ch4_treadmill", [
		Ch.step("banter", [], 0.5, 8.0, [Ch.seq(["ch4_ml_tread_01", "ch4_ml_tread_02", "ch4_ml_tread_03", "ch4_ml_tread_04"], 1)], {}),
		Ch.step("runaway", ["banter"], 0.6, 6.0, [
			Ch.loop("treadmill_belt", "Treadmill1", 7.0, {"db": 2.0}),
			Ch.seq(["ch4_ml_run_01", "ch4_ml_run_02", "ch4_ml_run_03"], 2),
			Ch.anim("marco", "run", {"speed": 2.4}),
		], {"blockers": [Ch.is_state("SafetyKey_Marco", "pulled")], "live": true, "saved_line": "ch4_ml_saved_01"}),
		Ch.step("thrown", ["runaway"], 0.5, 3.0, [
			Ch.move("marco", "MarcoFall", 0.7, {"arc": 1.6, "keep_rot": true}),
			Ch.npc("marco", "anim", {"name": "flail"}),
			Ch.sfx("thump", "MarcoFall", {"at_t": 0.7, "db": 5.0}),
			Ch.sfx("glass_break", "MarcoFall", {"at_t": 0.75}),
			Ch.cam({"shake": 0.4, "at_t": 0.7}),
			Ch.seq(["ch4_ml_hit_01", "ch4_ml_hit_02", "ch4_ml_hit_03"], 1),
		], {"live": false}),
	], {"max_time": 40.0, "reroute_dialogue": false})
	tchain.finished.connect(func(_r: Dictionary) -> void:
		tread_done = true
		if key_pulled:
			marco.scripted = false
			marco.global_position = mkp("MarcoTread") + Vector3(1.4, 0.0, 0.0)
			marco.play_anim("stagger", 0.1)
			await seq(["ch4_ml_saved_01", "ch4_ml_saved_02", "ch4_ml_saved_03", "ch4_ml_saved_04"], 0.2)
		else:
			marco.play_anim("lie_idle", 0.2)
		_check_outcome())
	tchain.start()


# ============================================================================ outcome
func _check_outcome() -> void:
	if outcome_done or not chain_done or not tread_done:
		return
	outcome_done = true
	await wait(1.2)
	if not tiff.alive:
		await _dead_outcome()
	else:
		await _saved_outcome()
	await _finish_chapter()


func _saved_outcome() -> void:
	cine(true)
	GameState.set_survivor(&"tiffany", &"alive")
	AudioManager.stinger(&"sting_saved")
	tiff.look_at_player = true
	tiff.set_emotion(&"worried" if fire_happened else &"happy")
	player.look_at_point(tiff.global_position + Vector3(0, 1.5, 0), 0.6)
	if fire_happened:
		await seq(["ch4_tiff_shaken_01", "ch4_tiff_shaken_02", "ch4_tiff_shaken_03"], 0.3)
	else:
		await seq(["ch4_tiff_saved_01", "ch4_tiff_saved_02", "ch4_tiff_saved_03"], 0.3)
		AchievementManager.unlock(&"aligned")
	await seq(["ch4_diagram_01", "ch4_diagram_02", "ch4_diagram_03"], 0.3)
	SequenceManager.mark_sequence_unreliable(true)
	SequenceManager.add_clue(&"order", "It Isn't The Order", "Tiffany survived and Kevin didn't. The sequence is wrong. It goes for whoever is available -- unless Gus has already fixed it.")
	await _gong_gag()
	cine(false)


func _dead_outcome() -> void:
	cine(true)
	GameState.set_survivor(&"tiffany", &"dead")
	AudioManager.play_music(&"mus_explore_low", 2.0)
	player.look_at_point(mkp("TiffanyStage") + Vector3(0, 0.8, 0), 0.8)
	await wait(1.4)
	await seq(["ch4_tiff_dead_01", "ch4_tiff_dead_02"], 0.4)
	await say("ch4_tiff_dead_03")
	SequenceManager.mark_sequence_unreliable(true)
	SequenceManager.add_clue(&"order", "It Isn't The Order", "Tiffany was next in the sequence. She went exactly as written. Gus told her about the ribbon.")
	await seq(["ch4_end_01", "ch4_end_02", "ch4_end_03"], 0.3)
	cine(false)


func _gong_gag() -> void:
	# Gus: "Gong's loose." (it falls, harmlessly, exactly where he warned)
	gus.move_to(mkp("GusGong"), false)
	await gus.arrived
	await seq(["ch4_gus_end_01"], 0.2)
	var g := prop("Gong")
	var tw := create_tween()
	tw.tween_property(g, "rotation_degrees:x", 82.0, 0.7).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		AudioManager.play_sfx(&"gong", g.global_position, 6.0)
		Events.camera_shake_requested.emit(0.2, 0.4))
	await wait(1.8)
	await seq(["ch4_gus_end_02"], 0.2)
	await seq(["ch4_end_01", "ch4_end_02", "ch4_end_03"], 0.3)


func _finish_chapter() -> void:
	SaveManager.checkpoint(&"end")
	AudioManager.play_music(&"mus_graves", 2.0)
	await wait(1.0)
	AudioManager.play_sfx(&"phone_buzz", null, 2.0)
	await wait(1.6)
	await seq(["ch4_graves_call_01", "ch4_graves_call_02", "ch4_graves_call_03", "ch4_graves_call_04", "ch4_graves_call_05"], 0.25)
	await wait(0.6)
	await Director.fade(true, 1.2)
	await end_to(GameState.Chapter.GRAVES)


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("greet", func() -> bool: return not greeted and not Director.input_locked and tiff.global_position.distance_to(player.global_position) > 6.0, func() -> void: player.global_position = tiff.global_position + Vector3(0, 0.1, 3.0))
	qa_add("gus", func() -> bool: return greeted and not gus_met and not busy_talk and not Director.input_locked, func() -> void: _run_talk(gus, _talk_gus))
	qa_add("skip_clock", func() -> bool: return gus_met and not keynote_started and _clock > 60.0 and not Director.input_locked, func() -> void: _clock = KEYNOTE_AT)
	qa_add("winch", func() -> bool: return keynote_started and chain != null and chain.running, func() -> void:
			_use_winch()
			_pull_key())
