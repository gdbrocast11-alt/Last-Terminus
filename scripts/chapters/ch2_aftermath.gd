extends Chapter
## CHAPTER 2 -- AFTERMATH. Eddie's over-secured apartment, eleven days after the station.
## TV news -> phone/voicemails -> calls (Marco & Luis, Doctor Graves) -> writing THE SEQUENCE -> leave.

const INSPECT := [
	["TV", "ch2_insp_tv"], ["Couch", "ch2_insp_couch"], ["Desk", "ch2_insp_desk"], ["PicklesVest", "ch2_insp_vest"], ["Kettle", "ch2_insp_kettle"],
	["FrontDoor", "ch2_insp_door"], ["Bookshelf", "ch2_insp_shelf"], ["Bed", "ch2_insp_bed"], ["Extinguisher1", "ch2_insp_extinguisher"],
	["Stove", "ch2_insp_oven"], ["Corkboard", "ch2_insp_wall"], ["Fridge", "ch2_insp_fridge"], ["BedLamp", "ch2_insp_lamp"], ["BedHelmet", "ch2_insp_bed"],
]

var tv_done := false
var phone_done := false
var calls_done := false
var notebook_done := false
var left := false
var bowl_fed := false
var _idle := 0.0
var _hints_given := 0


func _play(beat: StringName) -> void:
	set_group("aftermath", true)
	set_group("ending", false)
	set_group("ending_tiff_alive", false)
	set_group("ending_tiff_dead", false)
	AudioManager.play_ambience(&"amb_apartment", -4.0)
	music("mus_apartment", 2.0)
	_setup_world()
	match beat:
		&"calls", &"notebook":
			await _resume(beat)
		_:
			await _intro()


func _setup_world() -> void:
	for pair in INSPECT:
		set_inspect(pair[0], pair[1])
	add_inspect(mkp("WindowSpot") + Vector3(0, 1.4, -0.6), Vector3(2.2, 1.3, 0.5), "ch2_insp_window", "InspectWindow", 1)
	add_inspect(Vector3(-3.75, 0.42, -1.5), Vector3(0.5, 0.4, 0.5), "ch2_insp_corners", "InspectFoam")
	add_inspect(Vector3(-2.0, 0.3, 3.9), Vector3(0.4, 0.4, 0.3), "ch2_insp_outlet", "InspectOutlet")
	add_inspect(Vector3(-3.0, 0.05, -1.2), Vector3(2.4, 0.15, 1.6), "ch2_insp_rug", "InspectRug")
	add_inspect(Vector3(-4.85, 1.2, 2.0), Vector3(0.3, 1.4, 2.4), "ch2_insp_clippings", "InspectClippings")
	# actions
	bind_use("TV", "Watch the news", _use_tv)
	bind_use("Phone", "Check phone", _use_phone)
	bind_use("Notebook", "Write it down", _use_notebook)
	bind_use("PicklesBowl", "Feed Pickles", _use_bowl)
	bind_use("FrontDoor", "Leave", _use_door)
	# the phone is not grabbable during the chapter; the notebook lives on the desk
	for n in ["Phone", "Notebook"]:
		var c := pc(n)
		if c:
			c.grab_class = ""
	set_hazard("Kettle", 1)
	set_hazard("Stove", 1)
	set_hazard("BedLamp", 1)
	_qa_hooks()
	_idle_hints()


func _intro() -> void:
	await begin_player("EddieStart", "PicklesStart", true, 0.0)
	Director.fade_rect.color.a = 1.0
	player.frozen = true
	player.pitch = deg_to_rad(35.0)
	player.screen_fx.set_fx(&"blur", 0.85)
	pickles.command(&"stay")
	save(&"start")
	await wait(0.6)
	Director.fade(false, 2.4)
	title_card("ELEVEN DAYS LATER", 2.6)
	var tw := create_tween()
	tw.tween_property(player, "pitch", 0.0, 3.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_method(func(v: float) -> void: player.screen_fx.set_fx(&"blur", v), 0.85, 0.0, 3.0)
	await seq(["ch2_wake_01", "ch2_wake_02", "ch2_wake_03"], 0.4)
	player.frozen = false
	pickles.command(&"come")
	objective("Check the news")
	hint("The TV has been on for eleven days.", 5.0)


func _resume(beat: StringName) -> void:
	await begin_player("EddieStart", "PicklesStart")
	tv_done = true
	phone_done = true
	if beat == &"notebook":
		calls_done = true
		objective("Write down what you remember (the notebook on the desk)")
	else:
		await _calls()


# ============================================================================ beats
func _use_tv() -> void:
	if tv_done:
		AudioManager.play_sfx(&"tv_static", mkp("TVSpot"), -6.0)
		return
	if busy_talk:
		return
	busy_talk = true
	tv_done = true
	unbind_use("TV")
	AudioManager.play_sfx(&"switch_click", prop("TV").global_position)
	cine(true)
	player.look_at_point(prop("TV").global_position + Vector3(0, 0.5, 0), 0.6)
	await wait(0.7)
	SequenceManager.add_clue(&"kevin", "Kevin Lindqvist", "Survivor of the collapse. Killed by an oversized novelty check that fell from a parade float. Not the ceiling. Not the escalator.")
	await seq(["ch2_tv_01", "ch2_tv_02", "ch2_tv_03"], 0.3)
	await seq(["ch2_tv_04", "ch2_tv_05", "ch2_tv_06", "ch2_tv_07"], 0.35)
	cine(false)
	busy_talk = false
	objective("Check your phone (bedroom)")
	save(&"tv")


func _use_phone() -> void:
	if phone_done:
		await say("ch2_phone_02")
		return
	if busy_talk:
		return
	busy_talk = true
	phone_done = true
	unbind_use("Phone")
	cine(true)
	AudioManager.play_sfx(&"message_ping", prop("Phone").global_position)
	await seq(["ch2_phone_01", "ch2_phone_02"], 0.3)
	AudioManager.play_sfx(&"phone_buzz", prop("Phone").global_position)
	for vm in ["ch2_vm_brenda", "ch2_vm_dale", "ch2_vm_tiffany", "ch2_vm_gus", "ch2_vm_marco", "ch2_vm_luis", "ch2_vm_mills"]:
		AudioManager.play_sfx(&"message_ping", null, -8.0)
		await say(vm, 1)
		await wait(0.25)
	cine(false)
	busy_talk = false
	save(&"phone")
	await wait(2.0)
	await _calls()


func _calls() -> void:
	# the phone rings again: Marco & Luis, then Doctor Graves
	objective("Answer the phone")
	for i in 5:
		AudioManager.play_sfx(&"phone_buzz", prop("Phone").global_position, 2.0)
		await wait(1.0)
		if Input.is_action_pressed(&"interact"):
			break
	cine(true)
	await seq(["ch2_call_marco_01", "ch2_call_luis_01", "ch2_call_marco_02", "ch2_call_luis_02", "ch2_call_marco_03", "ch2_call_luis_03", "ch2_call_marco_04", "ch2_call_luis_04",
			"ch2_call_eddie_01", "ch2_call_marco_05", "ch2_call_luis_05", "ch2_call_eddie_02", "ch2_call_marco_06", "ch2_call_luis_06"], 0.15)
	await wait(1.4)
	AudioManager.play_sfx(&"phone_buzz", prop("Phone").global_position, 2.0)
	await wait(1.2)
	music("mus_graves", 1.5)
	await seq(["ch2_call_graves_01", "ch2_call_eddie_03", "ch2_call_graves_02", "ch2_call_graves_03", "ch2_call_eddie_04", "ch2_call_graves_04", "ch2_call_eddie_05", "ch2_call_graves_05",
			"ch2_call_eddie_06", "ch2_call_graves_06", "ch2_call_graves_07", "ch2_call_eddie_07", "ch2_call_graves_08"], 0.2)
	SequenceManager.add_clue(&"graves", "Doctor Mortimer Graves", "County coroner. Called me about Kevin. 'Death is a stickler for order.' Mid-sandwich at all times.")
	cine(false)
	calls_done = true
	music("mus_apartment", 2.0)
	objective("Write down what you remember (the notebook on the desk)")
	save(&"calls")


func _use_notebook() -> void:
	if not calls_done:
		await say("ch2_hint_call")
		return
	if notebook_done:
		Director.notebook.call("toggle") if Director.notebook.has_method("toggle") else null
		return
	if busy_talk:
		return
	busy_talk = true
	notebook_done = true
	unbind_use("Notebook")
	cine(true)
	player.look_at_point(prop("Notebook").global_position, 0.6)
	AudioManager.play_sfx(&"notebook_scribble", prop("Notebook").global_position)
	await seq(["ch2_seq_01", "ch2_seq_02"], 0.2)
	SequenceManager.set_sequence(["kevin", "brenda", "tiffany", "marco", "luis", "dale", "mills", "gus", "eddie"])
	AudioManager.play_sfx(&"notebook_page", null, -2.0)
	SequenceManager.add_clue(&"sequence", "THE SEQUENCE", "Kevin. Brenda. Tiffany. Marco and Luis. Dale. Mills. Gus. Me, last. Brenda is next.")
	Events.hint_requested.emit("THE SEQUENCE has been added to your notebook (%s)." % InputGlyphs.prompt(&"notebook"), 5.0)
	await seq(["ch2_seq_03", "ch2_seq_04", "ch2_seq_05", "ch2_seq_06", "ch2_seq_07"], 0.2)
	await flash_vision(["ch2_prem_01", "ch2_prem_02"])
	cine(false)
	busy_talk = false
	objective("Take Pickles to Toolbert's Home Center")
	await say("ch2_leave_01")
	save(&"notebook")


func _use_bowl() -> void:
	if bowl_fed:
		await say("ch2_bowl_02")
		return
	bowl_fed = true
	pickles.teleport_near(prop("PicklesBowl").global_position)
	pickles.play_oneshot("eat", 3.0)
	AudioManager.play_sfx(&"pk_eat", prop("PicklesBowl").global_position)
	await say("ch2_bowl_01")


func _use_door() -> void:
	if left:
		return
	if not notebook_done:
		await say("ch2_hint_notyet")
		return
	if busy_talk:
		return
	left = true
	busy_talk = true
	cine(true)
	AudioManager.play_sfx(&"door_open", prop("FrontDoor").global_position)
	await say("ch2_leave_02")
	pickles.command(&"come")
	AudioManager.stop_music(1.5)
	await Director.fade(true, 1.2)
	await end_to(GameState.Chapter.STORE)


func _idle_hints() -> void:
	while not left and is_inside_tree():
		await wait(1.0)
		if DialogueManager.is_busy() or Director.input_locked:
			_idle = 0.0
			continue
		_idle += 1.0
		if _idle > 42.0:
			_idle = 0.0
			_hints_given += 1
			if not tv_done:
				bark("ch2_pet_hint" if _hints_given % 3 == 0 else "ch2_insp_tv")
			elif not phone_done:
				bark("ch2_hint_call")
			elif not notebook_done and calls_done:
				bark("ch2_hint_seq")
			elif notebook_done:
				bark("ch2_hint_leave")


func _qa_hooks() -> void:
	qa_add("tv", func() -> bool: return not tv_done and not Director.input_locked, func() -> void: _use_tv())
	qa_add("phone", func() -> bool: return tv_done and not phone_done and not busy_talk, func() -> void: _use_phone())
	qa_add("notebook", func() -> bool: return calls_done and not notebook_done and not busy_talk, func() -> void: _use_notebook())
	qa_add("leave", func() -> bool: return notebook_done and not left and not busy_talk and not DialogueManager.is_busy(), func() -> void: _use_door())
