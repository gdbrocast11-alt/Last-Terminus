extends Chapter
## CHAPTER 5 -- DOCTOR GRAVES EXPLAINS NOTHING. Eddie's apartment. Sandwiches, a theory about the dog,
## and one car key. Graves is the only person in the game allowed to say "Huh" slowly.

var graves: Actor
var seated := false
var theory_done := false
var left_apartment := false
var door_open := false
var _hint_t := 0.0


func _play(beat: StringName) -> void:
	set_group("aftermath", true)
	set_group("ending", false)
	set_group("ending_tiff_alive", false)
	set_group("ending_tiff_dead", false)
	AudioManager.play_ambience(&"amb_apartment", -4.0)
	music("mus_apartment", 2.0)
	_setup_world()
	if beat == &"theory":
		await _resume_theory()
	else:
		await _intro()


func _setup_world() -> void:
	for pair in [["Couch", "ch5_hint_sit"], ["Phone", "ch5_insp_phone"], ["Desk", "ch2_insp_desk"], ["TV", "ch2_insp_tv"], ["Fridge", "ch2_insp_fridge"],
			["Bookshelf", "ch2_insp_shelf"], ["Kettle", "ch2_insp_kettle"], ["Corkboard", "ch2_insp_wall"], ["Bed", "ch2_insp_bed"]]:
		set_inspect(pair[0], pair[1])
	add_inspect(Vector3(-3.1, 0.5, -0.9), Vector3(0.5, 0.3, 0.5), "ch5_insp_sandwich", "InspectSandwich")
	add_inspect(Vector3(-4.9, 1.5, 2.0), Vector3(0.3, 0.5, 0.5), "ch5_insp_photo", "InspectPhoto")
	bind_use("FrontDoor", "Open door", _use_door)
	bind_use("Couch", "Sit down", _use_couch)
	_qa_hooks()


func _intro() -> void:
	await begin_player("EddieStart", "PicklesStart", true, 1.4)
	pickles.command(&"stay")
	title_card("DOCTOR GRAVES EXPLAINS NOTHING", 3.0)
	save(&"start")
	objective("Someone is at the door")
	graves = npc(&"graves", "GravesSpot", {"talkable": false, "idle": "talk_c"})
	graves.global_position = mkp("EndingDoor") + Vector3(0, 0, 4.0)
	graves.visible = false
	graves.collision_layer = 0
	await wait(2.4)
	AudioManager.play_sfx(&"door_close", mkp("EndingDoor"), -8.0)
	await wait(1.0)
	await say("ch5_knock_01")
	await say("ch5_knock_02")
	await say("ch5_knock_03")
	objective("Open the door")
	_idle_hints()


func _resume_theory() -> void:
	await begin_player("EddieStart", "PicklesStart")
	graves = npc(&"graves", "GravesSpot", {"talkable": false, "idle": "talk_c"})
	seated = true
	await _theory_scene()


func _use_door() -> void:
	if door_open or left_apartment:
		if theory_done and not left_apartment:
			await _leave()
		return
	if graves == null:
		return
	door_open = true
	unbind_use("FrontDoor")
	cine(true)
	AudioManager.play_sfx(&"door_open", prop("FrontDoor").global_position)
	graves.visible = true
	graves.collision_layer = 8
	graves.global_position = mkp("EndingDoor")
	music("mus_graves", 1.5)
	graves.move_to(mkp("GravesSpot"), false)
	player.look_at_point(graves.global_position + Vector3(0, 1.6, 0), 0.6)
	await seq(["ch5_enter_01", "ch5_enter_02", "ch5_enter_03"], 0.3)
	await wait_until(func() -> bool: return not graves.moving, 6.0)
	graves.face_point(player.global_position)
	graves.look_at_player = true
	cine(false)
	objective("Sit on the couch")
	save(&"door")
	pickles.command(&"come")


func _use_couch() -> void:
	if not door_open or seated:
		if not door_open:
			bark("ch5_hint_sit")
		return
	seated = true
	unbind_use("Couch")
	await _theory_scene()


func _theory_scene() -> void:
	cine(true)
	objective("")
	# sit: walk to the couch, then lower the eyes
	await walk_player_to(mkp("SofaSit"), 2.2, 0.35, 6.0)
	player.rotation.y = deg_to_rad(-90.0)
	var tw := create_tween()
	tw.tween_property(player.head, "position:y", player.head.position.y - 0.5, 0.7).set_trans(Tween.TRANS_SINE)
	graves.talkable = false
	graves.move_to(mkp("GravesSpot"), false)
	graves.face_point(player.global_position)
	pickles.teleport_near(player.global_position)
	pickles.command(&"stay")
	await seq(["ch5_sit_01", "ch5_sit_02"], 0.3)
	await seq(["ch5_beg_01", "ch5_beg_02", "ch5_beg_03"], 0.3)
	await flash_vision(["ch5_flash_01", "ch5_flash_02"], true)
	await seq(["ch5_beg_04", "ch5_beg_05", "ch5_beg_06", "ch5_beg_07", "ch5_beg_08", "ch5_beg_09"], 0.35)
	music("mus_graves", 0.5)
	await seq(["ch5_theory_01", "ch5_theory_02", "ch5_theory_03", "ch5_theory_04", "ch5_theory_05", "ch5_theory_06", "ch5_theory_07", "ch5_theory_08", "ch5_theory_09"], 0.3)
	sting("sting_reveal")
	await seq(["ch5_theory_10", "ch5_theory_11", "ch5_theory_12"], 0.4)
	SequenceManager.add_clue(&"theory", "Graves' Theory", "The first death was never mine to see. It was Pickles'. I saved him without knowing. Everything since is the universe doing its paperwork. (He has no idea if it's true.)")
	SequenceManager.mark_sequence_unreliable(true)
	await seq(["ch5_leave_01", "ch5_leave_02", "ch5_leave_03"], 0.4)
	# Graves leaves
	graves.move_to(mkp("EndingDoor"), false)
	var tw2 := create_tween()
	tw2.tween_property(player.head, "position:y", player.head.position.y + 0.5, 0.8).set_trans(Tween.TRANS_SINE)
	await wait_until(func() -> bool: return not graves.moving, 8.0)
	AudioManager.play_sfx(&"door_open", mkp("EndingDoor"), -2.0)
	graves.visible = false
	graves.collision_layer = 0
	await wait(1.0)
	AudioManager.play_sfx(&"door_close", mkp("EndingDoor"), -2.0)
	music("mus_apartment", 3.0)
	await wait(1.8)
	await seq(["ch5_spiral_01", "ch5_spiral_02", "ch5_spiral_03", "ch5_spiral_04"], 0.5)
	await seq(["ch5_alone_01", "ch5_alone_02", "ch5_alone_03", "ch5_alone_04", "ch5_alone_05", "ch5_alone_06"], 0.6)
	theory_done = true
	cine(false)
	pickles.command(&"come")
	bind_use("FrontDoor", "Take the car keys and go", _leave)
	objective("Take Pickles for a drive")
	save(&"theory")


func _leave() -> void:
	if left_apartment or not theory_done:
		return
	left_apartment = true
	cine(true)
	await seq(["ch5_pk_01", "ch5_pk_02"], 0.4)
	AudioManager.play_sfx(&"door_open", prop("FrontDoor").global_position)
	AudioManager.stop_music(2.0)
	await Director.fade(true, 1.6)
	await end_to(GameState.Chapter.YARD)


func _idle_hints() -> void:
	while not left_apartment and is_inside_tree():
		await wait(1.0)
		if DialogueManager.is_busy() or Director.input_locked:
			_hint_t = 0.0
			continue
		_hint_t += 1.0
		if _hint_t > 40.0:
			_hint_t = 0.0
			if not door_open:
				bark("ch5_hint_door")
			elif not seated:
				bark("ch5_hint_sit")


func _qa_hooks() -> void:
	qa_add("door", func() -> bool: return graves != null and not door_open and not Director.input_locked and not DialogueManager.is_busy(), func() -> void: _use_door())
	qa_add("couch", func() -> bool: return door_open and not seated and not Director.input_locked, func() -> void: _use_couch())
	qa_add("leave", func() -> bool: return theory_done and not left_apartment and not Director.input_locked, func() -> void: _leave())
