extends Control
## Speaker-labelled subtitles synced to voice lines. Size and speaker names are
## user options. The label text is never colour-only: the speaker is spelled out.

var _panel: PanelContainer
var _label: RichTextLabel
var _hide_gen := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.theme()
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.flat(Color(0.02, 0.025, 0.03, 0.72), Color(0, 0, 0, 0), 0, 4, 16))
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.visible = false
	add_child(_panel)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(900, 0)
	_label.add_theme_font_override("normal_font", UITheme.body_med_font())
	_label.add_theme_font_override("bold_font", UITheme.head_font())
	_panel.add_child(_label)
	DialogueManager.line_started.connect(_on_line)
	DialogueManager.subtitles_cleared.connect(_on_clear)
	Events.settings_changed.connect(_apply_size)
	_apply_size()


func _apply_size() -> void:
	var sc: float = SettingsManager.get_value("subtitles/size")
	var fs := int(26 * sc)
	for k in ["normal_font_size", "bold_font_size"]:
		_label.add_theme_font_size_override(k, fs)
	_label.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.56, 560.0, 1500.0)


func _on_line(_id: StringName, _speaker: StringName, display: String, text: String, _dur: float) -> void:
	if not SettingsManager.get_value("subtitles/enabled"):
		return
	_hide_gen += 1
	var body := text
	if SettingsManager.get_value("subtitles/speaker_names") and display != "":
		_label.text = "[b][color=#f5c52e]%s[/color][/b]  %s" % [display, body]
	else:
		_label.text = body
	_panel.visible = true
	_panel.reset_size()
	_panel.position = Vector2((get_viewport_rect().size.x - _panel.size.x) * 0.5, get_viewport_rect().size.y - _panel.size.y - 70)


func _on_clear() -> void:
	_panel.visible = false
