class_name SettingsPanel
extends PanelContainer
## Tabbed settings: Graphics / Audio / Gameplay / Comfort & Access / Subtitles / Controls.
## Every change applies immediately and is persisted on close.

signal closed

var _tabs: TabContainer
var _rows: Dictionary = {}


func _ready() -> void:
	theme = UITheme.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(1040, 640)
	var vb := VBoxContainer.new()
	add_child(vb)
	var head := UITheme.label("SETTINGS", 44, UITheme.YELLOW, true)
	vb.add_child(head)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_override("font_selected", UITheme.head_font())
	_tabs.add_theme_font_override("font_unselected", UITheme.head_font())
	_tabs.add_theme_font_size_override("font_size", 26)
	_tabs.add_theme_color_override("font_selected_color", UITheme.YELLOW)
	_tabs.add_theme_color_override("font_unselected_color", UITheme.DIM)
	_tabs.add_theme_stylebox_override("panel", UITheme.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 4))
	vb.add_child(_tabs)
	_build_graphics()
	_build_audio()
	_build_gameplay()
	_build_comfort()
	_build_subtitles()
	var controls := ControlsPanel.new()
	controls.name = "Controls"
	_tabs.add_child(controls)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(_on_back)
	vb.add_child(back)
	visibility_changed.connect(func() -> void:
		if visible:
			refresh())


func _page(tab_name: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = tab_name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	sc.add_child(vb)
	_tabs.add_child(sc)
	return vb


func _row(parent: Control, text: String, control: Control) -> void:
	var hb := HBoxContainer.new()
	var l := UITheme.label(text, 22, UITheme.WHITE)
	l.custom_minimum_size.x = 380
	hb.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(control)
	parent.add_child(hb)


func _slider(page: Control, key: String, text: String, mn: float, mx: float, step: float, pct := false) -> void:
	var hb := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.custom_minimum_size = Vector2(340, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := UITheme.label("", 20, UITheme.YELLOW, true)
	v.custom_minimum_size.x = 90
	s.value_changed.connect(func(val: float) -> void:
		SettingsManager.set_value(key, val)
		v.text = "%d%%" % int(val * 100) if pct else ("%.2f" % val))
	hb.add_child(s)
	hb.add_child(v)
	_row(page, text, hb)
	_rows[key] = [s, v, pct]


func _toggle(page: Control, key: String, text: String) -> void:
	var c := CheckButton.new()
	c.toggled.connect(func(on: bool) -> void: SettingsManager.set_value(key, on))
	_row(page, text, c)
	_rows[key] = [c]


func _option(page: Control, key: String, text: String, items: Array, values: Array = []) -> void:
	var o := OptionButton.new()
	for i in items.size():
		o.add_item(String(items[i]), i)
	o.item_selected.connect(func(idx: int) -> void: SettingsManager.set_value(key, values[idx] if not values.is_empty() else idx))
	_row(page, text, o)
	_rows[key] = [o, values]


func _build_graphics() -> void:
	var p := _page("Graphics")
	_option(p, "graphics/preset", "Graphics preset", SettingsManager.PRESET_NAMES)
	var res_items: Array = []
	for r in SettingsManager.RESOLUTIONS:
		res_items.append("%d x %d" % [r.x, r.y])
	_option(p, "graphics/resolution", "Resolution", res_items)
	_option(p, "graphics/display_mode", "Display mode", SettingsManager.DISPLAY_MODES)
	_toggle(p, "graphics/vsync", "VSync")
	var caps: Array = []
	for c in SettingsManager.FRAME_CAPS:
		caps.append("Unlimited" if c == 0 else "%d FPS" % c)
	_option(p, "graphics/frame_cap", "Frame cap", caps)
	_slider(p, "graphics/fov", "Field of view", 60.0, 110.0, 1.0)
	_slider(p, "graphics/render_scale", "Render scale", 0.5, 1.0, 0.05, true)


func _build_audio() -> void:
	var p := _page("Audio")
	_slider(p, "audio/master", "Master volume", 0.0, 1.0, 0.01, true)
	_slider(p, "audio/music", "Music", 0.0, 1.0, 0.01, true)
	_slider(p, "audio/voices", "Voices", 0.0, 1.0, 0.01, true)
	_slider(p, "audio/effects", "Effects", 0.0, 1.0, 0.01, true)


func _build_gameplay() -> void:
	var p := _page("Gameplay")
	_slider(p, "input/mouse_sensitivity", "Mouse sensitivity", 0.1, 3.0, 0.05)
	_slider(p, "input/pad_sensitivity", "Controller sensitivity", 0.2, 3.0, 0.05)
	_toggle(p, "input/invert_y", "Invert Y axis")
	_toggle(p, "input/sprint_toggle", "Sprint: toggle (off = hold)")
	_toggle(p, "input/crouch_toggle", "Crouch: toggle (off = hold)")
	_toggle(p, "input/rumble", "Controller vibration")
	_option(p, "gameplay/gore", "Gore", ["Full", "Reduced"], ["full", "reduced"])
	_toggle(p, "gameplay/skip_seen_premonitions", "Allow skipping premonitions already seen")


func _build_comfort() -> void:
	var p := _page("Comfort")
	_slider(p, "comfort/head_bob", "Head bob", 0.0, 1.0, 0.05, true)
	_slider(p, "comfort/camera_shake", "Camera shake", 0.0, 1.0, 0.05, true)
	_slider(p, "comfort/motion_blur", "Motion blur", 0.0, 1.0, 0.05, true)
	_slider(p, "comfort/premonition_distortion", "Premonition distortion", 0.0, 1.0, 0.05, true)
	_toggle(p, "comfort/flash_reduction", "Reduce flashes")
	_toggle(p, "comfort/hazard_cues", "Hazard cues use shapes and markers (never colour alone)")


func _build_subtitles() -> void:
	var p := _page("Subtitles")
	_toggle(p, "subtitles/enabled", "Subtitles")
	_slider(p, "subtitles/size", "Subtitle size", 0.75, 1.8, 0.05, true)
	_toggle(p, "subtitles/speaker_names", "Speaker names")


func refresh() -> void:
	for key in _rows.keys():
		var r: Array = _rows[key]
		var v: Variant = SettingsManager.get_value(key)
		var c: Control = r[0]
		if c is HSlider:
			(c as HSlider).set_value_no_signal(float(v))
			(r[1] as Label).text = "%d%%" % int(float(v) * 100) if r[2] else "%.2f" % float(v)
		elif c is CheckButton:
			(c as CheckButton).set_pressed_no_signal(bool(v))
		elif c is OptionButton:
			var values: Array = r[1]
			var idx := int(v) if values.is_empty() else maxi(0, values.find(v))
			(c as OptionButton).select(idx)


func _on_back() -> void:
	SettingsManager.save_settings()
	closed.emit()
