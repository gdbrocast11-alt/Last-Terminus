extends Control
## Big centred text: chapter titles, the LAST TERMINUS logo card, death captions.

var _label: Label
var _sub: Label
var _tw: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = UITheme.label("", 96, UITheme.WHITE, true)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 10)
	_label.modulate.a = 0.0
	add_child(_label)
	Events.title_card_requested.connect(show_card)


func show_card(text: String, seconds := 2.0) -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	_label.text = text
	var big := text.length() < 22
	_label.add_theme_font_size_override("font_size", 110 if big else 64)
	_label.modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(_label, "modulate:a", 1.0, 0.25)
	_tw.tween_interval(maxf(0.1, seconds - 0.85))
	_tw.tween_property(_label, "modulate:a", 0.0, 0.6)
