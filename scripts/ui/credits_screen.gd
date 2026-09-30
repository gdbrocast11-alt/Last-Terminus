class_name CreditsScreen
extends Control
## Rolling credits. Cheerful municipal transit safety music underneath.

signal finished

const LINES := [
	["h", "LAST TERMINUS"],
	["s", "The last stop you'll ever need."],
	["", ""],
	["r", "Created with Claude Code"],
	["s", "Game design, story and dialogue, programming, level design,\n3D modelling, rigging and animation, technical art, sound design,\ncomposition, voice direction, QA and build engineering\nwere all performed by Claude (Anthropic) in a single automated session."],
	["", ""],
	["r", "Starring (synthetic voices)"],
	["s", "Eddie Mercer\nBrenda Bolt\nDale Krieger\nTiffany Vale\nOfficer Mills\nGus Pemberton\nMarco and Luis\nDr. Mortimer Graves\nand PICKLES"],
	["s", "All human voices are original synthetic voices made with Kokoro-82M.\nNo real performers were imitated. Pickles is a good boy."],
	["", ""],
	["r", "Engine and tools"],
	["s", "Godot Engine 4.7  (MIT License)\nBlender 5.2 LTS  (GPL)  -  every model, rig and animation is procedural\nKokoro-82M by hexgrad  (Apache 2.0)  and kokoro-onnx  (MIT)\nONNX Runtime  (MIT)\neSpeak NG  (GPL 3, used offline for phonemization)\nFluidSynth  (LGPL)  with the FluidR3 GM SoundFont  (MIT)\nPython, NumPy, SciPy, SoundFile, mido, Pillow\nFFmpeg  and  SoX"],
	["", ""],
	["r", "Typefaces"],
	["s", "Barlow and Barlow Condensed by Jeremy Tribby  (SIL Open Font License)\nCaveat by Impallari Type  (SIL Open Font License)"],
	["", ""],
	["r", "Music and sound"],
	["s", "Every music cue, sound effect and Pickles vocalisation was synthesised\nfor this game. The soundtrack was composed as code.\nCredits track: \"Please Stand Behind The Yellow Line\" (original)."],
	["", ""],
	["r", "Textures and models"],
	["s", "Generated procedurally. No third-party art was used."],
	["", ""],
	["r", "Special thanks"],
	["s", "To every dog who has ever survived something ridiculous."],
	["", ""],
	["s", "Any resemblance to real transit centers, hardware stores, wellness brands,\nsafety inspectors or coroners is coincidental. Coincidence, however,\nis a theme of the game."],
	["", ""],
	["r", "Thank you for playing"],
	["s", "Thank you for riding Centennial Transit.\nPlease take all of your belongings, and your dog."],
]

var _scroll: Control
var _speed := 62.0
var _y := 0.0
var _done := false
var _from_menu := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	# directly under a CanvasLayer there is no Control parent to size us
	if not (get_parent() is Control):
		_fit()
		get_viewport().size_changed.connect(_fit)


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func start(from_menu := false) -> void:
	_from_menu = from_menu
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.045, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_scroll = VBoxContainer.new()
	_scroll.custom_minimum_size.x = 1000
	add_child(_scroll)
	for l in LINES:
		var kind: String = l[0]
		if kind == "":
			var s := Control.new()
			s.custom_minimum_size = Vector2(0, 60)
			_scroll.add_child(s)
			continue
		var lab := Label.new()
		lab.text = l[1]
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.custom_minimum_size.x = 1000
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		match kind:
			"h":
				lab.add_theme_font_override("font", UITheme.head_font())
				lab.add_theme_font_size_override("font_size", 120)
				lab.add_theme_color_override("font_color", UITheme.YELLOW)
			"r":
				lab.add_theme_font_override("font", UITheme.head_font())
				lab.add_theme_font_size_override("font_size", 40)
				lab.add_theme_color_override("font_color", UITheme.WHITE)
			_:
				lab.add_theme_font_override("font", UITheme.body_med_font())
				lab.add_theme_font_size_override("font_size", 26)
				lab.add_theme_color_override("font_color", UITheme.DIM)
		_scroll.add_child(lab)
	await get_tree().process_frame
	_scroll.position = Vector2((get_viewport_rect().size.x - 1000) * 0.5, get_viewport_rect().size.y)
	_y = _scroll.position.y
	if _from_menu:
		AudioManager.play_music(&"mus_credits", 1.0)


func _process(delta: float) -> void:
	if _scroll == null or _done:
		return
	var boost := 4.0 if (Input.is_action_pressed(&"interact") or Input.is_action_pressed(&"jump")) else 1.0
	_y -= _speed * delta * boost
	_scroll.position.y = _y
	if _y < -_scroll.size.y - 80:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _from_menu and (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		_finish()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	if _from_menu:
		AudioManager.play_music(&"mus_title", 1.0)
		queue_free()
