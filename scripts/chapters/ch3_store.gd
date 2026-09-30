extends Chapter
## CHAPTER 3 -- TOOLBERT'S HOME CENTER (Brenda's after-hours shoot).
## Paint aisle -> tools (premonition of the Rube Goldberg machine) -> prep window -> coin flip -> chain
## -> Brenda is saved (or not) -> Dale arrives -> on to Tiffany.

const WATCH := ["Coin", "PowerStrip", "PlugCord", "NailGun", "PaintStack", "RollingLadder", "FanRack", "DisplayFan", "SaleBanner", "TireTop", "TireLow", "HoseReel",
		"Sprinklers", "LowerHandle", "FlamingoPallet", "LostShoe", "brenda", "CornDogCart", "Compressor"]
const PREP_TIME := 170.0

var brenda: Actor
var chain: AccidentChain
var flip_done := false
var vision_done := false
var chain_running := false
var resolved := false
var _prep := 0.0
var _chat_i := 0
var _pallet_vol: LethalVolume
var _pickles_corn_said := false
var _paint_fell := false


func _play(beat: StringName) -> void:
	_setup_world()
	AudioManager.play_ambience(&"amb_store", -5.0)
	music("mus_store", 2.0)
	if beat == &"prep":
		await _resume_prep()
	else:
		await _intro()


# ============================================================================ world
func _setup_world() -> void:
	# after hours: a few tubes flicker / are out
	for l in ["Tube_-24_-18", "Tube_8_18"]:
		var lt := level.light(l)
		if lt:
			lt.visible = false
	for pair in [["Compressor", "ch3_insp_compressor"], ["PowerStrip", "ch3_insp_strip"], ["NailGun", "ch3_insp_nailgun"], ["PaintStack", "ch3_insp_stack"],
			["PaintShaker", "ch3_insp_shaker"], ["SawTable", "ch3_insp_saw"], ["StepLadder", "ch3_insp_stepladder"], ["RollingLadder", "ch3_insp_ladder"],
			["FanRack", "ch3_insp_fan"], ["TireRack", "ch3_insp_tire"], ["PropaneCage", "ch3_insp_propane"], ["CornDogCart", "ch3_insp_fryer"], ["RedFlamingo", "ch3_insp_flamingo"],
			["Forklift", "ch3_insp_forklift"], ["HoseReel", "ch3_insp_hose"], ["Sprinklers", "ch3_insp_sprinkler"], ["FlatbedCart", "ch3_insp_cart"], ["Wheelbarrow1", "ch3_insp_wheelbarrow"],
			["BrendaTripod", "ch3_insp_tripod"], ["Coin", "ch3_insp_coin"], ["LowerHandle", "ch3_insp_handle"], ["Gnome1", "ch3_insp_gnome"], ["Mower", "ch3_insp_mower"],
			["PaintMixer", "ch3_insp_mixer"], ["TripCord", "ch3_insp_cord"], ["ChainHoist", "ch3_insp_chain"], ["TireTop", "ch3_insp_tire"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(Vector3(14.0, 6.2, -1.6), Vector3(1.6, 1.0, 1.6), "ch3_insp_fan", "InspectFan", 1)
	add_inspect(Vector3(17.5, 4.6, -1.6), Vector3(3.2, 1.6, 0.4), "ch3_insp_banner", "InspectBanner", 1)
	add_inspect(Vector3(8.0, 4.0, -4.0), Vector3(0.5, 1.8, 0.5), "ch3_insp_chain", "InspectHoist")
	# hazard cues for the danger-intuition (Q) view
	for pair2 in [["Coin", 1], ["PowerStrip", 2], ["Compressor", 2], ["NailGun", 2], ["PaintStack", 2], ["RollingLadder", 2], ["FanRack", 2], ["TireTop", 1], ["HoseReel", 1],
			["Sprinklers", 2], ["LowerHandle", 2], ["FlamingoPallet", 2], ["CornDogCart", 1], ["PropaneCage", 1], ["TripCord", 1]]:
		set_hazard(pair2[0], pair2[1])
	for hz in ["Coin"]:
		var cpc := pc(hz)
		cpc.fetchable = true
		cpc.add_to_group("fetchables")
	# verbs on the interventions (these props are used, not carried)
	bind_use("PowerStrip", "Unplug", _unplug_strip)
	bind_use("Compressor", "Close air valve", _close_valve)
	bind_use("NailGun", "Engage safety", _nail_safety)
	bind_use("RollingLadder", "Set wheel brake", _brake_ladder)
	bind_use("Sprinklers", "Close water valve", _close_sprinklers)
	bind_use("LowerHandle", "Pin handle", _pin_handle)
	# state flags live in node meta so the chain can read them
	for n in ["PowerStrip", "Compressor", "NailGun", "RollingLadder", "Sprinklers", "LowerHandle"]:
		prop(n).set_meta("state", "armed")
	freeze_prop("FlamingoPallet")
	_pallet_vol = make_lethal("PalletVol", Vector3(26.0, 1.2, 7.4), Vector3(3.6, 2.6, 3.6))
	pc("TireTop").grabbed.connect(func(_p: Node) -> void: _say_once("took_tire", "ch3_took_tire"))
	pc("Coin").grabbed.connect(func(_p: Node) -> void: _say_once("took_coin", "ch3_took_coin"))
	pc("PaintStack").grabbed.connect(func(_p: Node) -> void: _say_once("took_cans", "ch3_took_cans"))
	trigger_marker("CornDogSpot", Vector3(5, 3, 5), _on_corn_dog, true)
	settle_props(["Coin", "PowerStrip", "NailGun", "PaintStack", "RollingLadder", "TireTop", "TireLow", "Wheelbarrow1", "LostShoe", "PaintWetSign", "GardenWetSign", "Compressor", "CornDogCart"])
	_qa_hooks()


func _say_once(f: String, line: String) -> void:
	if has_flag(f):
		return
	flag(f)
	bark(line)


func _on_corn_dog() -> void:
	if _pickles_corn_said or chain_running:
		return
	_pickles_corn_said = true
	await seq(["ch3_c_pickles_corn", "ch3_c_pickles_corn2"], 0.3)


# ============================================================================ intro + paint + tools
func _intro() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	title_card("TOOLBERT'S HOME CENTER", 2.8)
	sting("sting_title_card", -6.0)
	objective("Go inside")
	brenda = npc(&"brenda", "BrendaIntro", {"talkable": false, "idle": "phone_film"})
	on_talk(brenda, _talk_brenda_idle)
	save(&"start")
	await say("ch3_arrive_01")
	await wait_until(func() -> bool: return player.global_position.z < 27.0)
	await say("ch3_arrive_02")
	await wait_until(func() -> bool: return player.global_position.z < 23.0 and brenda.global_position.distance_to(player.global_position) < 8.0)
	await _brenda_intro()


func _brenda_intro() -> void:
	cine(true)
	brenda.look_at_player = true
	brenda.play_anim("wave", 0.2)
	player.look_at_point(brenda.global_position + Vector3(0, 1.5, 0), 0.6)
	await seq(["ch3_brenda_intro_01", "ch3_brenda_intro_02", "ch3_brenda_intro_03", "ch3_brenda_intro_04", "ch3_brenda_intro_05", "ch3_brenda_intro_06",
			"ch3_brenda_intro_07", "ch3_brenda_intro_08", "ch3_brenda_intro_09"], 0.2)
	brenda.mode = Actor.Mode.IDLE
	cine(false)
	flag("intro_done")
	await say("ch3_brenda_go")
	brenda.talkable = true
	objective("Follow Brenda to the paint aisle")
	await _paint_segment()


func _talk_brenda_idle() -> void:
	if not has_flag("brenda_chat"):
		flag("brenda_chat")
		await say("ch3_hint_talk")
		return
	await say("ch3_brenda_chat_01" if randf() > 0.5 else "ch3_brenda_chat_02")


func _wait_near(a: Actor, dist: float, hint_line := "") -> void:
	var t := 0.0
	while a.global_position.distance_to(player.global_position) > dist and is_inside_tree():
		await wait(0.5)
		t += 0.5
		if hint_line != "" and t > 40.0:
			t = 0.0
			bark(hint_line)


func _paint_segment() -> void:
	brenda.move_to(mkp("BrendaPaint"), false)
	await brenda.arrived
	brenda.face_point(prop("PaintMixer").global_position)
	await _wait_near(brenda, 7.0, "ch3_hint_talk")
	flag("at_paint")
	save(&"paint")
	await seq(["ch3_brenda_paint_01", "ch3_brenda_paint_02"], 0.3)
	AudioManager.play_sfx(&"paint_shaker", mkp("BrendaPaint") + Vector3(0.5, 1, 0))
	var loop := AudioManager.attach_loop(&"paint_shaker", prop("PaintShaker"), 0.0, 20.0)
	await wait(2.5)
	await say("ch3_brenda_paint_03")
	await wait(9.0)
	if is_instance_valid(loop):
		loop.queue_free()
	AudioManager.play_sfx(&"ting", prop("PaintShaker").global_position)
	objective("Follow Brenda to the power-tool aisle")
	await say("ch3_hint_investigate")
	brenda.move_to(mkp("BrendaTools"), false)
	await brenda.arrived
	brenda.face_point(mkp("TripodSpot"))
	brenda.play_anim("work_reach", 0.3)
	await _wait_near(brenda, 8.0, "ch3_hint_talk")
	await _tools_segment()


# ============================================================================ premonition + prep
func _tools_segment() -> void:
	cine(true)
	brenda.play_anim("phone_film", 0.3)
	player.look_at_point(mkp("BrendaTools") + Vector3(0, 1.5, 0), 0.5)
	await say("ch3_brenda_tools_01")
	await _do_vision()
	# prep window
	brenda.talkable = true
	brenda.play_anim("work_reach", 0.3)
	objective("Something in here is going to kill Brenda. Stop it.")
	save(&"prep")
	cine(false)
	_prep_loop()


func _do_vision() -> void:
	vision_done = true
	chain = _build_chain(true)
	var shots := [
		{"t": 0.0, "cam": Vector3(-1.2, 1.6, -7.2), "look": Vector3(0.9, 1.1, -9.8), "fov": 55.0, "line": "ch3_prem_coin"},
		{"step": "strip", "cam": Vector3(3.0, 1.0, -8.0), "look": Vector3(4.6, 0.1, -10.2), "fov": 60.0, "line": "ch3_prem_cable"},
		{"step": "nail", "cam": Vector3(7.0, 1.6, -8.5), "look": Vector3(10.0, 1.3, -11.8), "fov": 58.0, "line": "ch3_prem_nail"},
		{"step": "ladder", "cam": Vector3(11.0, 1.4, -8.0), "look": Vector3(15.2, 1.6, -9.0), "fov": 62.0},
		{"step": "fan", "cam": Vector3(11.0, 1.7, 1.5), "look": Vector3(14.0, 4.5, -1.6), "fov": 62.0, "line": "ch3_prem_fan"},
		{"step": "tire", "cam": Vector3(16.0, 1.3, -3.0), "cam_to": Vector3(20.0, 1.3, -1.0), "look": Vector3(23.0, 0.4, -2.0), "fov": 66.0, "hold": 4.0, "line": "ch3_prem_tire"},
		{"step": "sprinkler", "cam": Vector3(18.5, 1.3, 6.5), "look": Vector3(20.0, 1.0, 2.6), "fov": 58.0, "line": "ch3_prem_oil"},
		{"step": "slip", "cam": Vector3(19.0, 1.5, 9.0), "look": Vector3(22.6, 0.6, 6.0), "fov": 58.0, "line": "ch3_prem_shoe"},
		{"step": "forklift", "cam": Vector3(23.0, 1.3, 9.5), "look": Vector3(27.0, 1.2, 7.0), "fov": 56.0, "line": "ch3_prem_handle"},
		{"step": "rain", "cam": Vector3(22.5, 1.2, 8.5), "look": Vector3(27.0, 3.0, 8.0), "fov": 60.0, "line": "ch3_prem_flamingo"},
	]
	await vision(&"ch3_store", chain, WATCH, shots, {"max": 26.0})
	chain.queue_free()
	chain = null
	await wait(0.3)


func _resume_prep() -> void:
	await begin_player("PlayerStart", "PicklesStart")
	teleport_player("EddieShoot")
	pickles.teleport_near(player.global_position)
	brenda = npc(&"brenda", "BrendaTools", {"talkable": true, "idle": "work_reach"})
	on_talk(brenda, _talk_brenda_idle)
	vision_done = true
	objective("Something in here is going to kill Brenda. Stop it.")
	_prep_loop()


func _prep_loop() -> void:
	_prep = 0.0
	while not flip_done and is_inside_tree():
		await wait(1.0)
		if Director.input_locked:
			continue
		_prep += 1.0
		if int(_prep) % 32 == 0 and not DialogueManager.is_busy():
			DialogueManager.bark(StringName("ch3_brenda_chat_0%d" % (1 + (_chat_i % 3))))
			_chat_i += 1
		if _prep >= PREP_TIME:
			break
	await _start_flip()


func _start_flip() -> void:
	if flip_done:
		return
	flip_done = true
	chain_running = true
	brenda.talkable = false
	brenda.stop_moving()
	brenda.face_point(mkp("TripodSpot"))
	objective("STOP THE MACHINE")
	music("mus_store", 0.3)
	AudioManager.play_layered(&"chain_a", ["perc", "bass", "mar", "str", "brass"], 1)
	await say("ch3_brenda_tools_02")
	await say("ch3_c_coin")
	chain = _build_chain(false)
	chain.finished.connect(_on_chain_finished)
	chain.music_group = &"chain_a"
	chain.music_stems = ["perc", "bass", "mar", "str", "brass"]
	chain.start()
	# comic cues along the way
	chain.step_fired.connect(_on_step)


func _on_step(sid: StringName) -> void:
	match sid:
		&"strip": bark("ch3_c_spark")
		&"compressor": bark("ch3_c_hiss")
		&"nail": bark("ch3_c_nail")
		&"ladder": bark("ch3_c_ladder")
		&"sprinkler": bark("ch3_c_sprinkler")
		&"slip": DialogueManager.say(&"ch3_c_slip", 2)
		&"rain": DialogueManager.say(&"ch3_c_die", 2)


# ============================================================================ interventions
func _set_state(n: String, s: String) -> void:
	prop(n).set_meta("state", s)


func _unplug_strip() -> void:
	if prop("PowerStrip").get_meta("state") == "unplugged":
		bark("ch3_replug")
		return
	_set_state("PowerStrip", "unplugged")
	AudioManager.play_sfx(&"plug_pull", prop("PowerStrip").global_position)
	var cord := prop("PlugCord")
	if cord:
		cord.visible = false
	bark("ch3_unplug")
	Events.intervention.emit(&"use", &"PowerStrip", {})


func _close_valve() -> void:
	if prop("Compressor").get_meta("state") == "closed":
		return
	_set_state("Compressor", "closed")
	AudioManager.play_sfx(&"valve_turn", prop("Compressor").global_position)
	bark("ch3_valve")


func _nail_safety() -> void:
	if prop("NailGun").get_meta("state") == "safe":
		return
	_set_state("NailGun", "safe")
	AudioManager.play_sfx(&"click_soft", prop("NailGun").global_position)
	bark("ch3_safety")


func _brake_ladder() -> void:
	if prop("RollingLadder").get_meta("state") == "braked":
		return
	_set_state("RollingLadder", "braked")
	AudioManager.play_sfx(&"clang", prop("RollingLadder").global_position, -6.0)
	bark("ch3_brake")


func _close_sprinklers() -> void:
	if prop("Sprinklers").get_meta("state") == "closed":
		return
	_set_state("Sprinklers", "closed")
	AudioManager.play_sfx(&"valve_turn", prop("Sprinklers").global_position)
	bark("ch3_valve")


func _pin_handle() -> void:
	if prop("LowerHandle").get_meta("state") == "pinned":
		return
	_set_state("LowerHandle", "pinned")
	AudioManager.play_sfx(&"clang", prop("LowerHandle").global_position, -4.0)
	bark("ch3_pin")


func _sign_near_slip() -> bool:
	for n in ["PaintWetSign", "GardenWetSign"]:
		var s := prop(n)
		if s and s.global_position.distance_to(mkp("BrendaSlip")) < 2.2 and s.global_transform.basis.y.y > 0.7:
			return true
	return false


# ============================================================================ the chain
func _build_chain(is_vision: bool) -> AccidentChain:
	var S: Array = []
	var pcoin := "Coin"
	# 1 -- coin
	S.append(Ch.step("coin", [], 0.6, 2.6, [
		Ch.sfx("coin_spin", "Coin"),
		Ch.move("Coin", "CoinEnd", 1.8, {"arc": 0.35, "spin": Vector3(1, 0, 0), "turns": 5.0, "ease": "in_out"}),
		Ch.sfx("coin_drop", "CoinEnd", {"at_t": 1.7}),
	], {"blockers": [Ch.held(pcoin), Ch.moved(pcoin, 0.35), Ch.pickles_has(pcoin)], "live": true, "by": "player"}))
	S.append(Ch.alt("coin_alt", "coin", 3.5, 2.2, [
		Ch.say("ch3_c_coin", 1),
		Ch.fn(func() -> void: _spawn_coin_alt()),
		Ch.sfx("coin_drop", "CoinEnd", {"at_t": 1.8}),
	]))
	# 2 -- power strip sparks
	S.append(Ch.step("strip", [], 0.4, 1.6, [
		Ch.sfx("spark", "StripSpark", {"db": 3.0}),
		Ch.fx("spark", "StripSpark", {"scale": 1.6}),
		Ch.sfx("zap", "StripSpark", {"at_t": 0.4}),
		Ch.light("Tube_8_-6", "flicker", {"n": 6, "end_on": true}),
		Ch.fx("smoke", "StripSpark", {"scale": 0.8, "at_t": 0.5}),
	], {"any": ["coin", "coin_alt"], "blockers": [Ch.is_state("PowerStrip", "unplugged"), Ch.moved("PowerStrip", 0.5)]}))
	S.append(Ch.alt("strip_alt", "strip", 3.4, 1.6, [
		Ch.sfx("cloth_rustle", "TripCord"),
		Ch.sfx("plug_in", "StripSpark", {"at_t": 0.8}),
		Ch.sfx("spark", "StripSpark", {"at_t": 1.0, "db": 3.0}),
		Ch.fx("spark", "StripSpark", {"scale": 1.6, "at_t": 1.0}),
		Ch.fn(func() -> void: prop("PlugCord").visible = true),
	]))
	# 3 -- compressor over-pressure
	S.append(Ch.step("compressor", [], 0.5, 2.6, [
		Ch.loop("engine_rev", "Compressor", 2.4, {"db": -4.0}),
		Ch.sfx("hose_hiss", "Compressor", {"at_t": 0.6}),
		Ch.fx("steam", "CompressorTop", {"scale": 1.2, "at_t": 0.6}),
		Ch.tip("Compressor", "Compressor", Vector3(0, 0, 1), 1.6, 0.25, {"ease": "in_out"}),
		Ch.cam({"shake": 0.12}),
	], {"any": ["strip", "strip_alt"], "blockers": [Ch.is_state("Compressor", "closed")]}))
	S.append(Ch.alt("compressor_alt", "compressor", 3.2, 2.0, [
		Ch.sfx("zap", "CompressorTop"),
		Ch.sfx("hose_hiss", "Compressor", {"at_t": 0.5}),
		Ch.fx("steam", "CompressorTop", {"scale": 1.6, "at_t": 0.5}),
	]))
	# 4 -- nail gun whips and fires into the paint pyramid
	S.append(Ch.step("nail", [], 0.4, 2.2, [
		Ch.tip("NailGun", "NailGun", Vector3(0, 1, 0), 24, 0.35, {"ease": "in_out"}),
		Ch.sfx("nail_gun", "NailGun", {"at_t": 0.45, "db": 4.0}),
		Ch.fn(func() -> void: _shoot_nail()),
		Ch.fx("spark", "NailMuzzle", {"scale": 1.0, "at_t": 0.45}),
	], {"any": ["compressor", "compressor_alt"], "blockers": [Ch.is_state("NailGun", "safe"), Ch.held("NailGun"), Ch.moved("NailGun", 0.8)]}))
	S.append(Ch.alt("nail_alt", "nail", 3.0, 2.0, [
		Ch.sfx("clang", "NailGun"),
		Ch.impulse("NailGun", Vector3(1, 0.6, 0), 2.5),
		Ch.sfx("nail_gun", "NailGun", {"at_t": 0.8, "db": 4.0}),
		Ch.fn(func() -> void: _shoot_nail()),
	]))
	# 5 -- paint pyramid falls
	S.append(Ch.step("stack", [], 0.3, 3.0, [
		Ch.sfx("metal_crash", "StackTop", {"db": 1.0}),
		Ch.tip("PaintStack", Vector3(13.2, 0.0, -12.0), Vector3(0, 0, 1), -92, 1.1, {"ease": "in", "bounce": 1.0}),
		Ch.fx("paint", "StackTop", {"scale": 1.8, "at_t": 0.5}),
		Ch.fx("decal", Vector3(13.2, 0.03, -10.6), {"what": "splat_2", "size": 2.6, "color": Color(0.7, 0.03, 0.06, 0.9), "at_t": 0.9}),
		Ch.sfx("wet_splat", "StackTop", {"at_t": 0.9}),
		Ch.fn(func() -> void: _paint_fell = true),
		Ch.cam({"shake": 0.15}),
	], {"any": ["nail", "nail_alt"], "blockers": [Ch.moved("PaintStack", 1.2), Ch.held("PaintStack")]}))
	S.append(Ch.alt("shelf_alt", "stack", 2.4, 2.4, [
		Ch.sfx("nail_gun", "RailShelf3", {"db": 2.0}),
		Ch.sfx("metal_crash", "RailShelf3", {"at_t": 0.8}),
		Ch.fx("paint", Vector3(16.0, 1.4, -10.0), {"scale": 1.4, "at_t": 0.8}),
		Ch.debris(Vector3(15.0, 1.6, -10.0), 8, 2.5, {"at_t": 0.8}),
	]))
	# 6 -- rolling ladder
	S.append(Ch.step("ladder", [], 0.2, 4.2, [
		Ch.loop("roll_loop", "RollingLadder", 4.0, {"db": -2.0}),
		Ch.move("RollingLadder", "LadderEnd", 3.6, {"ease": "in", "keep_rot": true}),
		Ch.sfx("clang", "LadderEnd", {"at_t": 3.5, "db": 3.0}),
	], {"any": ["stack", "shelf_alt"], "blockers": [Ch.is_state("RollingLadder", "braked"), Ch.moved("RollingLadder", 1.0)]}))
	S.append(Ch.alt("ladder_alt", "ladder", 2.6, 3.6, [
		Ch.loop("roll_loop", "Wheelbarrow1", 3.4, {"db": -3.0}),
		Ch.move("Wheelbarrow1", Vector3(14.6, 0.0, -1.0), 3.2, {"ease": "in"}),
		Ch.sfx("clang", "FanRack", {"at_t": 3.1, "db": 3.0}),
	]))
	# 7 -- fan rack tips, display fan drops
	S.append(Ch.step("fan", [], 0.2, 3.6, [
		Ch.tip("FanRack", Vector3(14.0, 0.0, -1.6), Vector3(1, 0, 0), 48, 1.4, {"ease": "in", "bounce": 1.0}),
		Ch.sfx("fan_wobble", "DisplayFan", {"db": 2.0}),
		Ch.move("DisplayFan", "FanFallTo", 1.3, {"ease": "in_cubic", "spin": Vector3.UP, "turns": 3.0, "at_t": 0.9}),
		Ch.sfx("metal_crash", "FanFallTo", {"at_t": 2.2}),
		Ch.fx("spark", "FanFallTo", {"scale": 1.3, "at_t": 2.2}),
		Ch.cam({"shake": 0.3, "at_t": 2.2}),
	], {"any": ["ladder", "ladder_alt"]}))
	# 8 -- banner rope snaps
	S.append(Ch.step("banner", ["fan"], 0.3, 2.0, [
		Ch.sfx("snap", "BannerLow"),
		Ch.tip("SaleBanner", Vector3(20.9, 4.6, -1.6), Vector3(0, 0, 1), 85, 1.2, {"ease": "in_cubic"}),
		Ch.sfx("cloth_rustle", "BannerLow", {"at_t": 0.3}),
		Ch.sfx("thump", "BannerLow", {"at_t": 1.2}),
	]))
	# 9 -- the tire rolls
	S.append(Ch.step("tire", ["banner"], 0.2, 5.2, [
		Ch.loop("roll_loop", "TireTop", 5.0, {"db": -3.0}),
		Ch.roll("TireTop", "TireEnd", 4.8, Vector3.RIGHT, 4.0, {"ease": "in"}),
		Ch.sfx("bounce_plastic", "TireEnd", {"at_t": 4.7}),
	], {"blockers": [Ch.held("TireTop"), Ch.moved("TireTop", 0.8)]}))
	S.append(Ch.alt("tire_alt", "tire", 1.8, 4.6, [
		Ch.loop("roll_loop", "TireLow", 4.5, {"db": -3.0}),
		Ch.roll("TireLow", "TireEnd", 4.3, Vector3.RIGHT, 4.0, {"ease": "in"}),
		Ch.sfx("bounce_plastic", "TireEnd", {"at_t": 4.2}),
	]))
	# 10 -- hose reel whips
	S.append(Ch.step("hose", [], 0.0, 2.2, [
		Ch.sfx("hose_hiss", "HoseWhip"),
		Ch.tip("HoseReel", "HoseReel", Vector3(0, 1, 0), 70, 0.9, {"ease": "out"}),
		Ch.sfx("clang", "HoseWhip", {"at_t": 0.5}),
		Ch.fx("splash", "HoseWhip", {"scale": 1.0, "at_t": 0.6}),
	], {"any": ["tire", "tire_alt"]}))
	# 11 -- sprinklers burst on the garden floor
	S.append(Ch.step("sprinkler", ["hose"], 0.2, 3.2, [
		Ch.sfx("sprinkler_burst", "SprinklerBurst", {"db": 3.0}),
		Ch.loop("water_spray", "Sprinklers", 12.0, {"db": 0.0}),
		Ch.fx("splash", "SprinklerBurst", {"scale": 2.0, "dur": 10.0, "at": "Sprinklers", "offset": Vector3(0, 0.7, 0)}),
		Ch.fx("decal", "BrendaSlip", {"what": "puddle", "size": 4.0, "color": Color(0.5, 0.7, 0.9, 0.6), "at_t": 0.8}),
	], {"blockers": [Ch.is_state("Sprinklers", "closed")]}))
	S.append(Ch.alt("oil_alt", "sprinkler", 1.0, 3.0, [
		Ch.tip("CornDogCart", Vector3(20.0, 0.0, 2.4), Vector3(0, 0, 1), 32, 1.0, {"ease": "in", "bounce": 1.0}),
		Ch.sfx("metal_crash", "OilSpot", {"at_t": 0.8}),
		Ch.fx("smoke", "OilSpot", {"scale": 1.0, "at_t": 0.9}),
		Ch.fx("decal", "OilSpot", {"what": "puddle", "size": 3.6, "color": Color(0.75, 0.55, 0.05, 0.85), "at_t": 1.0}),
		Ch.sfx("sizzle", "OilSpot", {"at_t": 1.0}),
	]))
	# 12 -- Brenda slips (she is on her way to the garden centre for the finale)
	S.append(Ch.step("slip", [], 0.9, 3.0, [
		Ch.npc("brenda", "anim", {"name": "slip"}),
		Ch.move("LostShoe", "BrendaGarden", 1.0, {"arc": 2.2, "spin": Vector3(1, 0, 0), "turns": 2.0}),
		Ch.sfx("comic_slide_down", "BrendaSlip"),
		Ch.sfx("squeak", "BrendaSlip", {"at_t": 0.2}),
		Ch.move("brenda", "BrendaGarden", 1.3, {"ease": "out", "keep_rot": true}),
	], {"any": ["sprinkler", "oil_alt"], "blockers": [Ch.blocker_fn(_sign_near_slip)], "live": false, "saved_line": "ch3_sign"}))
	# 13 -- she grabs the emergency-lowering handle
	S.append(Ch.step("forklift", ["slip"], 0.3, 2.2, [
		Ch.sfx("forklift_beep", "HandlePivot"),
		Ch.tip("LowerHandle", "HandlePivot", Vector3(1, 0, 0), 62, 0.5, {"ease": "in", "bounce": 1.0}),
		Ch.sfx("whirr", "ForkliftPallet", {"at_t": 0.5, "db": 2.0}),
		Ch.tip("FlamingoPallet", Vector3(28.0, 3.0, 8.0), Vector3(0, 0, 1), 8, 1.6, {"ease": "in_out"}),
	], {"blockers": [Ch.is_state("LowerHandle", "pinned")], "live": false, "saved_line": "ch3_pin"}))
	# 14 -- flamingo rain
	S.append(Ch.step("rain", ["forklift"], 0.2, 3.0, [
		Ch.tip("FlamingoPallet", Vector3(28.0, 3.0, 8.0), Vector3(0, 0, 1), 78, 0.9, {"ease": "in_cubic"}),
		Ch.fn(func() -> void: _rain_flamingos()),
		Ch.sfx("metal_crash", "PalletDrop", {"at_t": 0.8, "db": 3.0}),
		Ch.cam({"shake": 0.5, "at_t": 0.8}),
		Ch.kill("PalletVol", "brenda", "flamingos", "front", {"at_t": 0.9}),
		Ch.fx("paint", "PalletDrop", {"scale": 2.0, "at_t": 0.9}),
		Ch.fx("decal", "PalletDrop", {"what": "splat_1", "size": 3.0, "color": Color(0.7, 0.03, 0.06, 0.9), "at_t": 1.0}),
	], {"live": false}))
	# Brenda walks to the garden centre while the machine runs (nav in the real run, tween in the vision)
	var walk_step: Dictionary
	if is_vision:
		walk_step = Ch.step("brenda_walk", [], 0.0, 1.0, [
			Ch.move("brenda", "BrendaWalkA", 2.0, {"keep_rot": true}),
			Ch.move("brenda", "BrendaWalkB", 3.0, {"at_t": 2.0, "keep_rot": true}),
			Ch.move("brenda", "BrendaSlip", 3.0, {"at_t": 5.0, "keep_rot": true}),
		], {"any": ["nail", "nail_alt"]})
	else:
		walk_step = Ch.step("brenda_walk", [], 0.5, 1.0, [
			Ch.npc("brenda", "walk", {"to": "BrendaSlip"}),
		], {"any": ["nail", "nail_alt"]})
	S.append(walk_step)
	var c := make_chain("ch3_store", S, {"vision": is_vision, "speed": 2.2 if is_vision else 1.0, "max_time": 90.0})
	return c


func _spawn_coin_alt() -> void:
	# Brenda pulls another coin out of her pocket
	var coin := spawn_prop("coin", mkp("CoinStart"), 0.0, "PocketCoin")
	if coin is RigidBody3D:
		(coin as RigidBody3D).freeze = true
	var tw := create_tween()
	tw.tween_property(coin, "global_position", mkp("CoinEnd"), 1.6)
	tw.tween_callback(coin.queue_free)


func _shoot_nail() -> void:
	var nail := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.01
	cm.bottom_radius = 0.01
	cm.height = 0.12
	nail.mesh = cm
	level.add_child(nail)
	var a := mkp("NailMuzzle")
	var b := mkp("StackTop")
	nail.global_position = a
	nail.look_at_from_position(a, b, Vector3.UP)
	nail.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var tw := create_tween()
	tw.tween_property(nail, "global_position", b, 0.28)
	tw.tween_callback(nail.queue_free)


func _rain_flamingos() -> void:
	for i in 8:
		var f := spawn_prop("flamingo_red" if i == 0 or (_paint_fell and i % 2 == 0) else "flamingo", Vector3(27.6 - i * 0.25, 3.2 + (i % 3) * 0.4, 7.4 + (i % 4) * 0.5), randf() * 360.0, "RainFlamingo%d" % i)
		if f is RigidBody3D:
			(f as RigidBody3D).apply_central_impulse(Vector3(-2.5 - randf() * 2.0, 1.0, randf_range(-1.0, 1.0)))
			(f as RigidBody3D).angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
			get_tree().create_timer(14.0, false).timeout.connect(f.queue_free)


# ============================================================================ resolution
func _on_chain_finished(result: Dictionary) -> void:
	if resolved:
		return
	resolved = true
	chain_running = false
	AudioManager.set_layers(1)
	music("mus_store", 2.0)
	objective("")
	if not brenda.alive:
		await _dead_path()
	else:
		await _saved_path(result)


func _saved_path(_result: Dictionary) -> void:
	AudioManager.stinger(&"sting_saved")
	GameState.set_survivor(&"brenda", &"alive")
	GameState.set_flag(&"brenda_saved", true)
	brenda.mode = Actor.Mode.IDLE
	brenda.stop_moving()
	brenda.scripted = false
	brenda.set_emotion(&"happy")
	cine(true)
	# she may still be on her way to the flamingo aisle: bring her to the shot
	if brenda.global_position.distance_to(mkp("BrendaFinal")) > 2.5:
		await Director.fade(true, 0.4)
		brenda.teleport(mkp("BrendaFinal"))
		teleport_player("EddieShoot")
		player.global_position = mkp("BrendaFinal") + Vector3(-3.0, 0.1, -1.5)
		pickles.teleport_near(player.global_position)
		await Director.fade(false, 0.4)
	brenda.play_anim("hands_hips", 0.3)
	player.look_at_point(brenda.global_position + Vector3(0, 1.5, 0), 0.6)
	await seq(["ch3_saved_brenda_01", "ch3_saved_brenda_02", "ch3_saved_brenda_03"], 0.3)
	# Flamingo Fresh Coat
	if _paint_fell:
		await seq(["ch3_flamingo_paint_01", "ch3_flamingo_paint_02"], 0.3)
	else:
		await seq(["ch3_flamingo_01", "ch3_flamingo_02", "ch3_flamingo_03", "ch3_flamingo_04", "ch3_flamingo_05"], 0.3)
	AchievementManager.unlock(&"flamingo_truth")
	SequenceManager.add_clue(&"flamingo", "The Flamingo Incident", "It was paint. It was just paint. Brenda is alive. The machine reroutes when I block it -- and it always ends where it started.")
	# Dale
	await _dale_arrives(true)
	await seq(["ch3_end_01", "ch3_end_02"], 0.4)
	await _leave_chapter()


func _dead_path() -> void:
	GameState.set_survivor(&"brenda", &"dead")
	AudioManager.play_music(&"mus_explore_low", 2.0)
	cine(true)
	player.look_at_point(mkp("PalletDrop") + Vector3(0, 0.5, 0), 0.8)
	await wait(1.6)
	await seq(["ch3_dead_01", "ch3_dead_02", "ch3_dead_03"], 0.6)
	await say("ch3_flamingo_dead")
	AchievementManager.unlock(&"flamingo_truth")
	AchievementManager.unlock(&"viral")
	SequenceManager.add_clue(&"flamingo", "The Flamingo Incident", "It was paint. It was just paint. I couldn't stop it. Brenda is gone; her last video is still recording.")
	await _dale_arrives(false)
	await say("ch3_end_dead")
	await _leave_chapter()


func _dale_arrives(brenda_alive: bool) -> void:
	var dale := npc(&"dale", "DaleDoor", {"idle": "idle"})
	dale.set_panic(true)
	dale.move_to(mkp("BrendaFinal") + Vector3(-4.0, 0, 0), true, 25.0)
	await wait_until(func() -> bool: return dale.global_position.distance_to(player.global_position) < 4.5 or not dale.moving, 22.0)
	dale.set_panic(false)
	dale.stop_moving()
	dale.face_point(player.global_position)
	dale.look_at_player = true
	if brenda_alive:
		await seq(["ch3_dale_arrive", "ch3_dale_01", "ch3_dale_02"], 0.25)
		AchievementManager.unlock(&"i_knew_it")
		await seq(["ch3_dale_03", "ch3_dale_04", "ch3_dale_05"], 0.25)
	else:
		await seq(["ch3_dale_arrive", "ch3_dale_dead_01", "ch3_dale_dead_02"], 0.4)
	await seq(["ch3_dale_tiff_01", "ch3_dale_tiff_02", "ch3_dale_tiff_03"], 0.3)


func _leave_chapter() -> void:
	SaveManager.checkpoint(&"end")
	await wait(0.8)
	AudioManager.stop_music(1.5)
	await Director.fade(true, 1.2)
	await end_to(GameState.Chapter.WELLNESS)


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("enter", func() -> bool: return brenda != null and not has_flag("intro_done") and player.global_position.z > 23.5 and not Director.input_locked,
			func() -> void: player.global_position = Vector3(0.0, 0.1, 19.0))
	qa_add("follow_paint", func() -> bool: return brenda != null and has_flag("intro_done") and not has_flag("at_paint") and brenda.global_position.distance_to(mkp("BrendaPaint")) < 3.0 and player.global_position.distance_to(brenda.global_position) > 7.0 and not Director.input_locked,
			func() -> void: player.global_position = brenda.global_position + Vector3(2.5, 0.1, 0.5))
	qa_add("follow_tools", func() -> bool: return brenda != null and has_flag("at_paint") and not vision_done and brenda.global_position.distance_to(mkp("BrendaTools")) < 3.0 and player.global_position.distance_to(brenda.global_position) > 7.0 and not Director.input_locked,
			func() -> void: teleport_player("EddieShoot"))
	qa_add("skip_prep", func() -> bool: return vision_done and not flip_done and _prep > 4.0 and not Director.input_locked, func() -> void: _prep = PREP_TIME)
	qa_add("intervene", func() -> bool: return flip_done and chain != null and chain.running and not GameState.has_flag(&"qa_nointervene"), func() -> void:
			_pin_handle()
			_unplug_strip())
