extends Control
## Pause: RESUME / SETTINGS / CONTROLS / RESTART CHECKPOINT / MAIN MENU.

var _dim: ColorRect
var _menu: PanelContainer
var _settings: SettingsPanel
var _info: Label
var _confirm_menu := false
var _menu_btn: Button
var open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_menu = PanelContainer.new()
	center.add_child(_menu)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(440, 0)
	_menu.add_child(vb)
	vb.add_child(UITheme.label("PAUSED", 56, UITheme.YELLOW, true))
	_info = UITheme.label("", 18, UITheme.DIM)
	vb.add_child(_info)
	for spec in [["RESUME", resume], ["SETTINGS", _open_settings], ["CONTROLS", _open_controls], ["RESTART CHECKPOINT", _restart]]:
		var b := Button.new()
		b.text = spec[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(spec[1])
		vb.add_child(b)
	_menu_btn = Button.new()
	_menu_btn.text = "MAIN MENU"
	_menu_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_menu_btn.pressed.connect(_main_menu)
	vb.add_child(_menu_btn)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		_menu.visible = true
		_focus_first())
	center.add_child(_settings)


func toggle() -> void:
	if open:
		resume()
	else:
		pause_game()


func pause_game() -> void:
	if Director.notebook and Director.notebook.get("open"):
		return
	open = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu.visible = true
	_settings.visible = false
	_confirm_menu = false
	_menu_btn.text = "MAIN MENU"
	_info.text = "%s   |   %d:%02d" % [GameState.CHAPTER_NAMES.get(GameState.chapter, ""), int(GameState.play_time) / 60, int(GameState.play_time) % 60]
	AudioManager.play_ui(&"ui_click")
	_focus_first()


func resume() -> void:
	open = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SettingsManager.save_settings()


func _focus_first() -> void:
	for c in _menu.find_children("*", "Button", true, false):
		(c as Button).grab_focus()
		break


func _open_settings() -> void:
	_menu.visible = false
	_settings.visible = true
	_settings.refresh()
	_settings._tabs.current_tab = 0


func _open_controls() -> void:
	_open_settings()
	_settings._tabs.current_tab = _settings._tabs.get_tab_count() - 1


func _restart() -> void:
	resume()
	Director.restart_checkpoint()


func _main_menu() -> void:
	if not _confirm_menu:
		_confirm_menu = true
		_menu_btn.text = "MAIN MENU  (press again to confirm)"
		return
	resume()
	Director.go_to_title()


func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		if _settings.visible:
			_settings._on_back()
		else:
			resume()
		get_viewport().set_input_as_handled()
