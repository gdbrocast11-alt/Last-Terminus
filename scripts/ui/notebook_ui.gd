extends Control
## Eddie's notebook: OBJECTIVE, THE SEQUENCE, SURVIVORS, CLUES. Tab toggles it;
## the game world is paused while it is open so nothing happens behind the page.

var open := false
var _root: Control
var _pages: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _current := "sequence"
var _diagram: SequenceDiagram
var _objective_label: Label
var _survivors_box: VBoxContainer
var _clues_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.theme()
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var book := PanelContainer.new()
	book.custom_minimum_size = Vector2(1100, 700)
	book.add_theme_stylebox_override("panel", UITheme.flat(Color(0.93, 0.89, 0.8), Color(0.28, 0.2, 0.14), 6, 6, 26))
	center.add_child(book)
	var vb := VBoxContainer.new()
	book.add_child(vb)
	var tabs := HBoxContainer.new()
	vb.add_child(tabs)
	for spec in [["objective", "OBJECTIVE"], ["sequence", "THE SEQUENCE"], ["survivors", "SURVIVORS"], ["clues", "CLUES"]]:
		var b := Button.new()
		b.text = spec[1]
		b.add_theme_color_override("font_color", Color(0.3, 0.22, 0.16))
		b.add_theme_color_override("font_hover_color", Color(0.7, 0.4, 0.05))
		b.add_theme_color_override("font_focus_color", Color(0.7, 0.4, 0.05))
		b.pressed.connect(_select.bind(spec[0]))
		tabs.add_child(b)
		_tab_buttons[spec[0]] = b
	var sep := HSeparator.new()
	vb.add_child(sep)
	var stack := Control.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.custom_minimum_size = Vector2(0, 560)
	vb.add_child(stack)
	# objective
	var p1 := CenterContainer.new()
	p1.set_anchors_preset(Control.PRESET_FULL_RECT)
	_objective_label = Label.new()
	_objective_label.add_theme_font_override("font", UITheme.hand_font())
	_objective_label.add_theme_font_size_override("font_size", 54)
	_objective_label.add_theme_color_override("font_color", Color(0.16, 0.13, 0.28))
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size.x = 900
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1.add_child(_objective_label)
	stack.add_child(p1)
	_pages["objective"] = p1
	# sequence
	_diagram = SequenceDiagram.new()
	_diagram.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(_diagram)
	_pages["sequence"] = _diagram
	# survivors
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_survivors_box = VBoxContainer.new()
	_survivors_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_survivors_box)
	stack.add_child(sc)
	_pages["survivors"] = sc
	# clues
	var sc2 := ScrollContainer.new()
	sc2.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clues_box = VBoxContainer.new()
	_clues_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(_clues_box)
	stack.add_child(sc2)
	_pages["clues"] = sc2
	var hint := UITheme.label("TAB / ESC to close", 16, Color(0.4, 0.3, 0.22, 0.8))
	vb.add_child(hint)
	Events.notebook_updated.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.in_game or Director.transitioning:
		return
	if event.is_action_pressed(&"notebook") and not (Director.pause_menu and Director.pause_menu.get("open")) and not Director.input_locked:
		toggle()
		get_viewport().set_input_as_handled()
	elif open and (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	open = not open
	visible = open
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	get_tree().paused = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if open:
		AudioManager.play_ui(&"notebook_page")
		_refresh()
		_select(_current)


func _select(page: String) -> void:
	_current = page
	for k in _pages.keys():
		(_pages[k] as Control).visible = (k == page)
	for k in _tab_buttons.keys():
		(_tab_buttons[k] as Button).add_theme_color_override("font_color", Color(0.75, 0.42, 0.04) if k == page else Color(0.3, 0.22, 0.16))
	_diagram.queue_redraw()


func _refresh() -> void:
	if _objective_label == null:
		return
	var o := SequenceManager.objective()
	_objective_label.text = o if o != "" else "(nothing to do. enjoy it.)"
	_diagram.queue_redraw()
	for c in _survivors_box.get_children():
		c.queue_free()
	for id in GameState.SURVIVOR_IDS:
		var info: Dictionary = SequenceManager.SURVIVOR_INFO.get(id, {})
		var hb := HBoxContainer.new()
		var st := SequenceManager.survivor_status(id)
		var name_l := Label.new()
		name_l.text = String(info.get("name", id))
		name_l.custom_minimum_size.x = 250
		name_l.add_theme_font_override("font", UITheme.hand_font())
		name_l.add_theme_font_size_override("font_size", 40)
		name_l.add_theme_color_override("font_color", Color(0.16, 0.13, 0.28) if st != "DECEASED" else Color(0.5, 0.1, 0.1))
		hb.add_child(name_l)
		var bio := Label.new()
		bio.text = String(info.get("bio", ""))
		bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio.custom_minimum_size.x = 560
		bio.add_theme_font_override("font", UITheme.hand_font())
		bio.add_theme_font_size_override("font_size", 28)
		bio.add_theme_color_override("font_color", Color(0.25, 0.2, 0.2))
		hb.add_child(bio)
		var stamp := Label.new()
		stamp.text = "[ %s ]" % st
		stamp.add_theme_font_override("font", UITheme.head_font())
		stamp.add_theme_font_size_override("font_size", 26)
		stamp.add_theme_color_override("font_color", Color(0.1, 0.4, 0.25) if st == "ALIVE" else Color(0.65, 0.1, 0.1))
		hb.add_child(stamp)
		_survivors_box.add_child(hb)
	for c in _clues_box.get_children():
		c.queue_free()
	var clues := SequenceManager.clues()
	if clues.is_empty():
		var l := Label.new()
		l.text = "(no clues yet)"
		l.add_theme_font_override("font", UITheme.hand_font())
		l.add_theme_font_size_override("font_size", 36)
		l.add_theme_color_override("font_color", Color(0.4, 0.34, 0.3))
		_clues_box.add_child(l)
	for c in clues:
		var t := Label.new()
		t.text = String(c.title)
		t.add_theme_font_override("font", UITheme.hand_font())
		t.add_theme_font_size_override("font_size", 40)
		t.add_theme_color_override("font_color", Color(0.16, 0.13, 0.28))
		_clues_box.add_child(t)
		var b := Label.new()
		b.text = String(c.text)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 980
		b.add_theme_font_override("font", UITheme.hand_font())
		b.add_theme_font_size_override("font_size", 28)
		b.add_theme_color_override("font_color", Color(0.25, 0.2, 0.2))
		_clues_box.add_child(b)
