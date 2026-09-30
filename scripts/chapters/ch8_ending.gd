extends Chapter
## CHAPTER 8 -- A NORMAL EVENING. Months later. Eddie's apartment is a normal apartment; a walk with Pickles;
## every hazard on the street is fine; "Nah."; the bus; "Ow."; credits; and the CCTV footage that explains everything.

const APT_INSPECT := [
	["DaleBinder", "ch8_dale_binder"], ["MillsPostcard", "ch8_mills_card"], ["FridgeSchedule", "ch8_insp_fridge"], ["GusFlyer", "ch8_gus_flyer"],
	["Scoreboard", "ch8_ml_score"], ["GravesNote", "ch8_graves_note"], ["Couch", "ch8_insp_couch"], ["Bed", "ch8_insp_bed"], ["Desk", "ch8_insp_desk"],
	["ExtinguisherEnd", "ch8_insp_extinguisher"],
]
const STREET_LINES := [
	{"at": -52.0, "line": "ch8_ladder"}, {"at": -40.0, "line": "ch8_mower"}, {"at": -26.0, "line": "ch8_truck"}, {"at": -8.0, "line": "ch8_ac"},
	{"at": 1.0, "line": "ch8_kid"}, {"at": 12.0, "line": "ch8_cyclist"}, {"at": 23.0, "line": "ch8_dig"}, {"at": 34.0, "line": "ch8_bottle"},
]

var left_home := false
var tv_done := false
var phone_done := false
var has_leash := false
var crossing := false
var street_lines_done := 0
var cctv_layer: CanvasLayer
var _cctv_t := 0.0
var bus: Node3D


func _play(beat: StringName) -> void:
	if beat == &"cctv":
		await _dev_cctv()
	elif String(beat).begins_with("street"):
		await _street()
	else:
		await _apartment()


# ============================================================================ apartment
func _apartment() -> void:
	set_group("aftermath", false)
	set_group("ending", true)
	set_group("ending_tiff_alive", GameState.is_alive(&"tiffany"))
	set_group("ending_tiff_dead", not GameState.is_alive(&"tiffany"))
	AudioManager.play_ambience(&"amb_apartment", -4.0)
	music("mus_apartment", 2.0)
	for pair in APT_INSPECT:
		set_inspect(pair[0], pair[1])
	# inspect proxies for the flat decor
	var tiff_line := "ch8_tiff_card" if GameState.is_alive(&"tiffany") else "ch8_tiff_card_dead"
	add_inspect(Vector3(-4.35, 0.85, 2.5), Vector3(0.4, 0.4, 0.4), "ch8_dale_binder", "InspectBinder")
	add_inspect(Vector3(-4.3, 0.85, 1.2), Vector3(0.3, 0.2, 0.3), "ch8_mills_card", "InspectPostcard")
	add_inspect(Vector3(1.2, 1.4, 3.6), Vector3(0.4, 0.4, 0.3), "ch8_insp_fridge", "InspectSchedule")
	add_inspect(Vector3(1.55, 1.2, 3.6), Vector3(0.3, 0.4, 0.3), "ch8_gus_flyer", "InspectFlyer")
	add_inspect(Vector3(0.95, 1.2, 3.6), Vector3(0.3, 0.3, 0.3), tiff_line, "InspectTiffCard")
	add_inspect(Vector3(-4.85, 1.35, -2.9), Vector3(0.3, 0.7, 1.0), "ch8_ml_score", "InspectScore")
	add_inspect(Vector3(-3.2, 0.55, -1.0), Vector3(0.4, 0.2, 0.4), "ch8_graves_note", "InspectNote")
	add_inspect(mkp("WindowSpot") + Vector3(0, 1.4, -0.6), Vector3(2.2, 1.3, 0.5), "ch8_insp_window", "InspectWindow")
	add_inspect(Vector3(-4.6, 0.3, 3.2), Vector3(0.6, 0.6, 0.5), "ch8_insp_bed", "InspectHelmet")
	bind_use("TV", "Watch TV", _watch_tv)
	bind_use("Phone", "Check messages", _check_phone)
	add_use(Vector3(-4.85, 1.0, 3.6), Vector3(0.4, 0.8, 0.5), "Take the leash", _take_leash, "LeashUse")
	bind_use("FrontDoor", "Go for a walk", _use_door)
	_qa_hooks()
	await begin_player("EndingStart", "PicklesStart", true, 0.0)
	Director.fade_rect.color.a = 1.0
	player.screen_fx.set_fx(&"blur", 0.6)
	title_card("SEVERAL MONTHS LATER", 3.0)
	save(&"start")
	await wait(1.0)
	Director.fade(false, 2.2)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: player.screen_fx.set_fx(&"blur", v), 0.6, 0.0, 2.5)
	await say("ch8_card")
	await seq(["ch8_wake_01", "ch8_wake_02"], 0.5)
	pickles.command(&"come")
	objective("Have a normal evening")
	await wait(2.0)
	await say("ch8_pickles_fine")
	_idle_hints()


func _watch_tv() -> void:
	if busy_talk:
		return
	busy_talk = true
	cine(true)
	player.look_at_point(prop("TV").global_position + Vector3(0, 0.6, 0), 0.5)
	AudioManager.play_sfx(&"tv_static", prop("TV").global_position, -8.0)
	await wait(0.6)
	if GameState.is_alive(&"brenda"):
		await seq(["ch8_tv_brenda", "ch8_tv_brenda_ed"], 0.3)
	else:
		await seq(["ch8_tv_brenda_dead", "ch8_tv_brenda_dead_ed"], 0.4)
		AchievementManager.unlock(&"viral")
	cine(false)
	busy_talk = false
	tv_done = true


func _check_phone() -> void:
	if busy_talk or phone_done:
		return
	busy_talk = true
	phone_done = true
	cine(true)
	AudioManager.play_sfx(&"message_ping", prop("Phone").global_position)
	await seq(["ch8_ml_vm_marco", "ch8_ml_vm_luis", "ch8_mills_vm"], 0.35)
	cine(false)
	busy_talk = false


func _take_leash() -> void:
	if has_leash:
		return
	has_leash = true
	var lu := level.get_node_or_null("LeashUse")
	if lu:
		lu.queue_free()
	AudioManager.play_sfx(&"pickup", prop("LeashHook").global_position)
	await say("ch8_leash")
	objective("Take Pickles for a walk")


func _use_door() -> void:
	if left_home or busy_talk:
		return
	if not has_leash and not tv_done and not phone_done:
		await say("ch8_hint_talk")
		return
	left_home = true
	cine(true)
	await say("ch8_door")
	AudioManager.play_sfx(&"door_open", prop("FrontDoor").global_position)
	AudioManager.stop_music(1.5)
	await Director.fade(true, 1.0)
	GameState.beat = &"street"
	await Director.load_chapter(GameState.Chapter.ENDING, &"street")


func _idle_hints() -> void:
	var t := 0.0
	while not left_home and is_inside_tree():
		await wait(1.0)
		if DialogueManager.is_busy() or Director.input_locked:
			t = 0.0
			continue
		t += 1.0
		if t > 45.0:
			t = 0.0
			bark("ch8_hint_go" if (tv_done or phone_done) else "ch8_hint_talk")


## Developer/QA shortcut (--qa-beat=cctv): jump straight to the security-camera epilogue.
func _dev_cctv() -> void:
	bus = prop("Bus")
	for n in ["SignWordA", "SignWordEnd", "SignWordB"]:
		freeze_prop(n)
	if bus is RigidBody3D:
		(bus as RigidBody3D).freeze = true
	await begin_player("WalkStart", "PicklesStart", true, 0.0)
	await _cctv()


# ============================================================================ street
func _street() -> void:
	AudioManager.play_ambience(&"amb_street", -5.0)
	music("mus_ending_walk", 2.0)
	bus = prop("Bus")
	for n in ["SignWordA", "SignWordEnd", "SignWordB"]:
		freeze_prop(n)
	if bus is RigidBody3D:
		(bus as RigidBody3D).freeze = true
	bus.visible = false
	set_hazard("Bottle", 1)
	for pair in [["LadderHouse", "ch8_ladder"], ["Mower", "ch8_mower"], ["AcUnit", "ch8_ac"], ["Baseball", "ch8_kid"], ["Excavator", "ch8_dig"], ["Bottle", "ch8_bottle"], ["Bicycle", "ch8_cyclist"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(mkp("KidSpot") + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 1.2), "ch8_kid", "InspectKid", 1)
	add_inspect(prop("PipeTruck").global_position + Vector3(0, 1.0, 0), Vector3(2.4, 2.2, 7.4), "ch8_truck", "InspectTruck", 1)
	# life on the street
	var mower_loop := AudioManager.attach_loop(&"engine_idle", prop("Mower"), -4.0, 24.0)
	var kid := npc(&"kid", "KidSpot", {"idle": "idle", "look": false})
	kid.rotation.y = PI
	_kid_toss(kid)
	_cyclist()
	await begin_player("WalkStart", "PicklesStart", true, 1.2)
	player.rotation.y = deg_to_rad(-90.0)
	pickles.leash_enabled = false
	title_card("A NORMAL EVENING", 2.6)
	objective("Take a normal walk")
	save(&"street")
	await seq(["ch8_walk_01", "ch8_walk_02"], 0.5)
	flag("street_ready")
	_walk_watch()
	trigger_marker("Crosswalk", Vector3(6, 3, 4), _crosswalk, true)
	_qa_street()
	if is_instance_valid(mower_loop):
		mower_loop.max_distance = 26.0


func _walk_watch() -> void:
	var i := 0
	while i < STREET_LINES.size() and is_inside_tree() and not crossing:
		await wait(0.4)
		var h: Dictionary = STREET_LINES[i]
		if player.global_position.x > float(h.at):
			if not DialogueManager.is_busy():
				DialogueManager.say(StringName(h.line), 1)
				i += 1
				street_lines_done = i
				if i == 3:
					bark("ch8_walk_03")
			elif player.global_position.x > float(h.at) + 20.0:
				i += 1


func _kid_toss(kid: Actor) -> void:
	var ball := prop("Baseball")
	if ball == null:
		return
	if ball is RigidBody3D:
		(ball as RigidBody3D).freeze = true
	var base := kid.global_position + Vector3(0.3, 1.4, -0.4)
	while is_inside_tree() and not crossing:
		var tw := create_tween()
		tw.tween_property(ball, "global_position", base + Vector3(0.2, 1.6, 0.1), 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(ball, "global_position", base, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		await wait(0.2)


func _cyclist() -> void:
	var bike := prop("Bicycle")
	if bike == null:
		return
	if bike is RigidBody3D:
		(bike as RigidBody3D).freeze = true
	var rider := npc(&"stranger_c", "CyclistA", {"idle": "sit_idle", "look": false, "node_name": "Cyclist"})
	rider.scripted = true
	var from := mkp("CyclistA")
	var to := mkp("CyclistB")
	while is_inside_tree() and not crossing:
		var tw := create_tween()
		tw.tween_method(func(k: float) -> void:
			var p := from.lerp(to, k)
			bike.global_position = p
			bike.rotation_degrees.y = 90.0
			rider.global_position = p + Vector3(0, 0.3, 0)
			rider.rotation.y = -PI * 0.5, 0.0, 1.0, 16.0)
		await tw.finished
		bike.global_position = from
		await wait(3.0)


# ============================================================================ the crossing
func _crosswalk() -> void:
	if crossing:
		return
	crossing = true
	cine(true)
	objective("")
	AudioManager.stop_music(2.0)
	await walk_player_to(mkp("Crosswalk") + Vector3(0, 0, 0.4), 1.8, 0.3, 8.0)
	player.rotation.y = PI
	player.set_forced_walk(Vector3.ZERO)
	pickles.teleport_near(player.global_position + Vector3(0.8, 0, 0.3))
	pickles.command(&"stay")
	await wait(0.6)
	await say("ch8_breath")
	# the WALK lamp comes on
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1, 1, 1)
	lamp.light_energy = 1.4
	lamp.omni_range = 4.0
	level.add_child(lamp)
	lamp.global_position = prop("Signal").global_position + Vector3(0, 3.0, 0.4)
	AudioManager.play_sfx(&"ting", lamp.global_position, 0.0)
	await wait(0.9)
	await say("ch8_nah")
	await say("ch8_ok")
	pickles.command(&"come")
	await walk_player_to(mkp("CrossMid") + Vector3(0, 0, -0.6), 2.0, 0.4, 8.0)
	player.set_forced_walk(Vector3.ZERO)
	await wait(0.8)
	# what is that noise
	player.look_at_point(Vector3(-40, 1.8, 1.8), 0.9)
	AudioManager.play_sfx(&"engine_rev", Vector3(-70, 1, 1.8), 6.0)
	await wait(1.1)
	bus.visible = true
	bus.global_position = Vector3(-95, 0.0, 1.8)
	bus.rotation_degrees = Vector3(0, -90, 0)
	AudioManager.play_sfx(&"bus_horn", Vector3(-70, 1.5, 1.8), 8.0)
	var loop := AudioManager.attach_loop(&"engine_rev", bus, 4.0, 90.0)
	var tw := create_tween()
	tw.tween_property(bus, "global_position", Vector3(32.0, 0.0, 1.8), 2.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	player.look_at_point(Vector3(-20, 1.8, 1.8), 0.4)
	AudioManager.play_sfx(&"bus_horn", Vector3(-30, 1.5, 1.8), 10.0, 1.05)
	await tw.finished
	# HONK -- black
	AudioManager.play_sfx(&"bus_horn", player.global_position + Vector3(-6, 1.5, 0), 12.0, 1.1)
	Director.fade_rect.color.a = 1.0
	if is_instance_valid(loop):
		loop.queue_free()
	AudioManager.play_sfx(&"bus_crash", Vector3(60, 1, 0), 10.0)
	AudioManager.play_sfx(&"tinnitus", null, -4.0)
	# what really happened is only visible on the security camera; from here: a crash and a very long silence
	_stage_wreck()
	await wait(2.6)
	await _after_crash()


func _stage_wreck() -> void:
	bus.global_position = Vector3(60.6, 1.3, 0.5)
	bus.rotation_degrees = Vector3(0, -90, 24)
	for n in ["SignWordA", "SignWordB"]:
		var w := prop(n)
		w.global_position += Vector3(randf_range(1.0, 3.0), -1.8, randf_range(-5.0, 5.0))
		w.rotation_degrees = Vector3(randf_range(-80, 80), randf_range(0, 360), randf_range(-60, 60))
	FX.burst(&"smoke", Vector3(60.6, 3.0, 0.5), 4.0)
	FX.burst(&"dust", Vector3(61, 1.0, 0), 6.0)
	var sm := FX.emitter(&"smoke", bus, Vector3(-1.8, 3.6, 0), 2.0)
	sm.emitting = true


func _after_crash() -> void:
	# Eddie is lying in the crosswalk, unharmed
	var head_y := player.head.position.y
	player.head.position.y = head_y - 1.15
	player.extra_roll = deg_to_rad(80.0)
	player.pitch = deg_to_rad(20.0)
	player.rotation.y = deg_to_rad(90.0)
	player.screen_fx.set_fx(&"blur", 0.8)
	pickles.global_position = mkp("CrossMid") + Vector3(-1.0, 0, 0.6)
	pickles.play_anim("sit_alert", 0.1)
	Director.fade(false, 3.2)
	await wait(2.8)
	await say("ch8_ow")
	await wait(0.6)
	pickles.bark()
	await say("ch8_okay_01")
	await wait(0.4)
	pickles.play_oneshot("happy", 1.5)
	await say("ch8_okay_02")
	var tw := create_tween()
	tw.tween_property(player.head, "position:y", head_y, 1.2).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(player, "extra_roll", 0.0, 1.2)
	tw.parallel().tween_property(player, "pitch", 0.0, 1.2)
	tw.parallel().tween_method(func(v: float) -> void: player.screen_fx.set_fx(&"blur", v), 0.8, 0.0, 1.2)
	await wait(1.6)
	player.look_at_point(Vector3(60.0, 2.0, 0.0), 1.4)
	await wait(1.8)
	await say("ch8_bus_fucked")
	await wait(2.0)
	# credits
	await Director.fade(true, 1.8)
	await _credits()


# ============================================================================ credits + CCTV
func _credits() -> void:
	GameState.chapter = GameState.Chapter.CREDITS
	Events.chapter_changed.emit(GameState.Chapter.CREDITS)
	Director.set_hud_visible(false)
	if GameState.alive_count() == GameState.SURVIVOR_IDS.size():
		AchievementManager.unlock(&"everybody_lives")
	AudioManager.play_music(&"mus_credits", 1.5)
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var cs := CreditsScreen.new()
	layer.add_child(cs)
	await Director.fade(false, 0.6)
	cs.start(false)
	await cs.finished
	await Director.fade(true, 1.2)
	layer.queue_free()
	await _cctv()


func _cctv() -> void:
	AudioManager.stop_music(1.0)
	# reset the world to the moment before
	bus.global_position = Vector3(-110, 0.0, 1.8)
	bus.rotation_degrees = Vector3(0, -90, 0)
	bus.visible = true
	for n in ["SignWordA", "SignWordB"]:
		var w := prop(n)
		w.global_position = Vector3(61.7, 2.2, -2.86 if n == "SignWordA" else 3.62)
		w.rotation_degrees = Vector3(0, 90, 0)
	player.visible = false
	player.global_position = Vector3(44, -20, 0)
	# parked out of the picture: no gravity (Pickles' out-of-bounds failsafe follows a falling player) and no collisions
	player.frozen = true
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0
	pickles.scripted = true
	pickles.begin_scripted()
	pickles.global_position = mkp("CrossMid") + Vector3(0.9, 0, 0.5)
	pickles.rotation.y = PI
	pickles.play_anim("sit", 0.1)
	var eddie := npc(&"eddie", "CrossMid", {"idle": "idle", "look": false, "node_name": "EddieCctv"})
	eddie.global_position = mkp("CrossMid")
	eddie.rotation.y = PI
	# security camera + overlay: the lens frames the crosswalk and the sign in one shot
	var cam := Camera3D.new()
	level.add_child(cam)
	cam.global_position = mkp("CctvCam")
	cam.fov = 62.0
	cam.look_at(Vector3(53.0, 0.9, 0.0), Vector3.UP)
	cam.current = true
	cctv_layer = CanvasLayer.new()
	cctv_layer.layer = 70
	add_child(cctv_layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/screen_fx.gdshader")
	mat.set_shader_parameter("desat", 0.95)
	mat.set_shader_parameter("scanlines", 0.5)
	mat.set_shader_parameter("film_grain", 0.16)
	mat.set_shader_parameter("vignette", 0.45)
	mat.set_shader_parameter("contrast", 1.2)
	mat.set_shader_parameter("aberration", 0.004)
	mat.set_shader_parameter("tint", Color(0.8, 1.0, 0.85))
	mat.set_shader_parameter("tint_amount", 0.3)
	rect.material = mat
	cctv_layer.add_child(rect)
	var label := Label.new()
	label.position = Vector2(48, 36)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	cctv_layer.add_child(label)
	var rec := Label.new()
	rec.text = "REC"
	rec.add_theme_font_size_override("font_size", 30)
	rec.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	rec.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rec.position = Vector2(1720, 36)
	cctv_layer.add_child(rec)
	_cctv_t = 0.0
	var upd := func() -> void:
		var sec := 42127 + int(_cctv_t)
		label.text = "CAM 04   TERMINUS AVE / CROSSWALK\n26-09-30   %02d:%02d:%02d" % [sec / 3600, (sec / 60) % 60, sec % 60]
	upd.call()
	await Director.fade(false, 0.6)
	# ---- the footage
	var clock := create_tween().set_loops(40)
	clock.tween_interval(1.0)
	clock.tween_callback(func() -> void:
		_cctv_t += 1.0
		upd.call())
	await wait(3.2)
	# the bus comes in fast
	var run := create_tween()
	run.tween_property(bus, "global_position", Vector3(28.0, 0.0, 1.8), 2.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	AudioManager.play_sfx(&"bus_horn", Vector3(0, 1.5, 1.8), -4.0, 1.05)
	await run.finished
	# AXLE FAILURE: the front axle snaps, wheels shoot off, the nose digs in and the bus becomes a ramp
	AudioManager.play_sfx(&"snap", bus.global_position, 6.0)
	AudioManager.play_sfx(&"metal_crash", bus.global_position, 6.0)
	FX.burst(&"spark", bus.global_position + Vector3(2.5, 0.3, 1.0), 4.0)
	FX.burst(&"dust", bus.global_position + Vector3(2.5, 0.3, 0), 3.0)
	_fly_wheel(bus.global_position + Vector3(3.4, 0.5, 1.2), Vector3(6, 7, 6))
	_fly_wheel(bus.global_position + Vector3(3.4, 0.5, -0.6), Vector3(8, 9, -9))
	var launch := create_tween()
	launch.tween_method(func(k: float) -> void:
		var x := lerpf(28.0, 60.4, k)
		var y := sin(k * PI) * 5.2
		bus.global_position = Vector3(x, y, 1.8 - 1.3 * k)
		bus.rotation_degrees = Vector3(0, -90, lerpf(-6.0, 12.0, k) + sin(k * PI) * 18.0), 0.0, 1.0, 1.9).set_trans(Tween.TRANS_LINEAR)
	# Eddie and Pickles look up as it flies over them
	await wait(0.7)
	eddie.play_anim("dodge_left", 0.1)
	pickles.play_oneshot("look_back", 1.2)
	AudioManager.play_sfx(&"whoosh", mkp("CrossMid") + Vector3(0, 4, 0), 8.0)
	await launch.finished
	# impact: the outer words of the sign fly off, leaving THE END
	AudioManager.play_sfx(&"bus_crash", Vector3(61, 2, 0), 10.0)
	Events.camera_shake_requested.emit(0.3, 0.4)
	FX.burst(&"dust", Vector3(61.5, 1.5, 0), 6.0)
	FX.burst(&"debris", Vector3(61.5, 2.5, 0), 4.0)
	var wa := prop("SignWordA")
	var wb := prop("SignWordB")
	for w: Node3D in [wa, wb]:
		var side := -1.0 if w == wa else 1.0
		var tw := create_tween()
		tw.tween_method(func(k: float) -> void:
			w.global_position = Vector3(61.7 - 5.0 * k, 2.2 + sin(k * PI) * 3.5 - 2.0 * k * k, (-2.86 if w == wa else 3.62) + side * 4.5 * k)
			w.rotation_degrees = Vector3(k * 360.0, 90.0, k * 200.0), 0.0, 1.0, 1.1)
	bus.global_position = Vector3(60.7, 1.0, 0.7)
	bus.rotation_degrees = Vector3(0, -90, 26)
	await wait(2.4)
	# Pickles inspects the sign
	pickles.scripted = true
	pickles.play_anim("trot", 0.1)
	var walk := create_tween()
	walk.tween_property(pickles, "global_position", Vector3(59.5, 0, 3.6), 3.0)
	pickles.face_point(Vector3(60.5, 0, 3.6))
	await walk.finished
	pickles.rotation.y = -PI * 0.5
	pickles.play_anim("sniff_stand", 0.1)
	await wait(1.4)
	var pee := FX.emitter(&"pee", pickles, Vector3(0.0, 0.4, 0.3), 1.0)
	AudioManager.play_sfx(&"gurgle", pickles.global_position, -4.0)
	await wait(2.4)
	if is_instance_valid(pee):
		pee.emitting = false
	AudioManager.stinger(&"sting_good_boy")
	AchievementManager.unlock(&"good_boy")
	pickles.play_anim("happy", 0.1)
	await wait(2.8)
	# THE END
	await Director.fade(true, 1.4)
	if is_instance_valid(clock):
		clock.kill()
	cctv_layer.queue_free()
	var end_layer := CanvasLayer.new()
	end_layer.layer = 80
	add_child(end_layer)
	var end_label := Label.new()
	end_label.text = "THE END"
	end_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 120)
	end_label.add_theme_font_override("font", UITheme.head_font())
	end_label.add_theme_color_override("font_color", UITheme.YELLOW)
	end_layer.add_child(end_label)
	await wait(3.5)
	SaveManager.mark_completed()
	SaveManager.delete_save()
	await Director.go_to_title()


func _fly_wheel(from: Vector3, vel: Vector3) -> void:
	var w := spawn_prop("tire", from, 0.0, "FlyingWheel")
	if w is RigidBody3D:
		(w as RigidBody3D).linear_velocity = vel
		(w as RigidBody3D).angular_velocity = Vector3(8, 3, 6)
		(w as RigidBody3D).collision_layer = 0
	get_tree().create_timer(6.0, false).timeout.connect(w.queue_free)


# ============================================================================ QA
func _qa_hooks() -> void:
	qa_add("tv", func() -> bool: return not tv_done and not busy_talk and not Director.input_locked and player != null, func() -> void: _watch_tv())
	qa_add("leash", func() -> bool: return tv_done and not has_leash and not busy_talk and not Director.input_locked, func() -> void: _take_leash())
	qa_add("door", func() -> bool: return has_leash and not left_home and not busy_talk and not Director.input_locked and not DialogueManager.is_busy(), func() -> void: _use_door())


func _qa_street() -> void:
	qa_add("walk", func() -> bool: return not crossing and player != null and not Director.input_locked and has_flag("street_ready"), func() -> void: teleport_player("Crosswalk"))
