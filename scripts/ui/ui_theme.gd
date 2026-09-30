class_name UITheme
extends RefCounted
## Shared look: municipal transit signage. Near-black panels, signal-yellow accents.

const BG := Color(0.055, 0.067, 0.082)
const PANEL := Color(0.09, 0.105, 0.125, 0.96)
const YELLOW := Color(0.96, 0.77, 0.18)
const WHITE := Color(0.92, 0.935, 0.95)
const DIM := Color(0.62, 0.66, 0.7)
const TEAL := Color(0.22, 0.68, 0.64)
const RED := Color(0.9, 0.25, 0.2)

static var _theme: Theme
static var _f_head: FontFile
static var _f_body: FontFile
static var _f_body_med: FontFile
static var _f_hand: FontFile


static func head_font() -> FontFile:
	if _f_head == null:
		_f_head = load("res://ui/fonts/BarlowCondensed-Bold.woff2")
	return _f_head


static func body_font() -> FontFile:
	if _f_body == null:
		_f_body = load("res://ui/fonts/Barlow-Regular.woff2")
	return _f_body


static func body_med_font() -> FontFile:
	if _f_body_med == null:
		_f_body_med = load("res://ui/fonts/Barlow-Medium.woff2")
	return _f_body_med


static func hand_font() -> FontFile:
	if _f_hand == null:
		_f_hand = load("res://ui/fonts/Caveat-SemiBold.woff2")
	return _f_hand


static func flat(color: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 2, margin := 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 22
	t.set_color("font_color", "Label", WHITE)
	t.set_color("font_color", "Button", WHITE)
	t.set_color("font_hover_color", "Button", YELLOW)
	t.set_color("font_focus_color", "Button", YELLOW)
	t.set_color("font_pressed_color", "Button", BG)
	t.set_font("font", "Button", head_font())
	t.set_font_size("font_size", "Button", 30)
	t.set_stylebox("normal", "Button", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 14))
	t.set_stylebox("hover", "Button", _bar(Color(1, 1, 1, 0.06)))
	t.set_stylebox("focus", "Button", _bar(Color(1, 1, 1, 0.09)))
	t.set_stylebox("pressed", "Button", flat(YELLOW, Color(0, 0, 0, 0), 0, 0, 14))
	t.set_stylebox("disabled", "Button", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 14))
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.25))
	t.set_stylebox("panel", "PanelContainer", flat(PANEL, Color(1, 1, 1, 0.08), 1, 2, 18))
	t.set_stylebox("panel", "Panel", flat(PANEL, Color(1, 1, 1, 0.08), 1, 2, 18))
	t.set_color("font_color", "CheckButton", WHITE)
	t.set_font("font", "CheckButton", body_med_font())
	t.set_font_size("font_size", "CheckButton", 22)
	t.set_font("font", "OptionButton", body_med_font())
	t.set_font_size("font_size", "OptionButton", 22)
	t.set_stylebox("normal", "OptionButton", flat(Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.15), 1, 2, 10))
	t.set_stylebox("hover", "OptionButton", flat(Color(1, 1, 1, 0.13), YELLOW, 1, 2, 10))
	t.set_stylebox("focus", "OptionButton", flat(Color(1, 1, 1, 0.13), YELLOW, 1, 2, 10))
	t.set_stylebox("pressed", "OptionButton", flat(Color(1, 1, 1, 0.13), YELLOW, 1, 2, 10))
	t.set_color("font_color", "OptionButton", WHITE)
	t.set_stylebox("grabber_area", "HSlider", flat(YELLOW, Color(0, 0, 0, 0), 0, 2, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(YELLOW.lightened(0.2), Color(0, 0, 0, 0), 0, 2, 0))
	t.set_stylebox("slider", "HSlider", flat(Color(1, 1, 1, 0.15), Color(0, 0, 0, 0), 0, 2, 0))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_stylebox("panel", "TooltipPanel", flat(BG, YELLOW, 1, 2, 8))
	_theme = t
	return t


static func _bar(bg: Color) -> StyleBoxFlat:
	var s := flat(bg, YELLOW, 0, 0, 14)
	s.border_width_left = 5
	return s


static func label(text: String, size := 22, color := WHITE, head := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if head:
		l.add_theme_font_override("font", head_font())
	return l
