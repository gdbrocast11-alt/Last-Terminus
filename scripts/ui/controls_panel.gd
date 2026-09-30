class_name ControlsPanel
extends VBoxContainer
## Full remapping: keyboard / mouse (two slots) and controller, with conflict
## clearing handled by SettingsManager.rebind().

var _listening: Button = null
var _listen_action: StringName
var _listen_slot := ""
var _buttons: Dictionary = {}


func _ready() -> void:
	theme = UITheme.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(grid)
	for h in ["ACTION", "KEYBOARD / MOUSE", "ALTERNATE", "CONTROLLER"]:
		grid.add_child(UITheme.label(h, 18, UITheme.YELLOW, true))
	for a in SettingsManager.ACTIONS:
		var l := UITheme.label(SettingsManager.ACTION_LABELS[a], 21)
		l.custom_minimum_size.x = 300
		grid.add_child(l)
		for slot in ["kb1", "kb2", "pad"]:
			var b := Button.new()
			b.custom_minimum_size = Vector2(210, 36)
			b.add_theme_font_size_override("font_size", 20)
			b.add_theme_font_override("font", UITheme.body_med_font())
			b.pressed.connect(_begin_listen.bind(b, a, slot))
			grid.add_child(b)
			_buttons[[a, slot]] = b
	var reset := Button.new()
	reset.text = "RESET TO DEFAULTS"
	reset.pressed.connect(func() -> void:
		SettingsManager.reset_bindings()
		_refresh())
	add_child(reset)
	Events.settings_changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for k in _buttons.keys():
		var b: Button = _buttons[k]
		b.text = SettingsManager.binding_text(k[0], k[1])


func _begin_listen(b: Button, action: StringName, slot: String) -> void:
	_listening = b
	_listen_action = action
	_listen_slot = slot
	b.text = "press input..."


func _input(event: InputEvent) -> void:
	if _listening == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish(null)
		get_viewport().set_input_as_handled()
		return
	var accept := false
	if _listen_slot == "pad":
		accept = (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.6)
	else:
		accept = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)
	if accept:
		_finish(event)
		get_viewport().set_input_as_handled()


func _finish(event: InputEvent) -> void:
	if event != null:
		SettingsManager.rebind(_listen_action, _listen_slot, event)
	_listening = null
	_refresh()
