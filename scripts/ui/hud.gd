extends Control
## Minimal HUD: crosshair dot, contextual prompts, objective, transient hints.

var _prompts: VBoxContainer
var _objective: Label
var _obj_panel: PanelContainer
var _hint: Label
var _dot: ColorRect
var _hint_t := 0.0
var _obj_timer := 0.0
var _last_prompt_key := ""


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot = ColorRect.new()
	_dot.color = Color(1, 1, 1, 0.55)
	_dot.custom_minimum_size = Vector2(5, 5)
	_dot.set_anchors_preset(Control.PRESET_CENTER)
	_dot.position = Vector2(-2.5, -2.5)
	_dot.size = Vector2(5, 5)
	add_child(_dot)
	_prompts = VBoxContainer.new()
	_prompts.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompts.position = Vector2(-160, -230)
	_prompts.size = Vector2(320, 100)
	_prompts.alignment = BoxContainer.ALIGNMENT_END
	_prompts.add_theme_constant_override("separation", 4)
	add_child(_prompts)
	_obj_panel = PanelContainer.new()
	_obj_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_obj_panel.position = Vector2(28, 26)
	_obj_panel.add_theme_stylebox_override("panel", UITheme.flat(Color(0.04, 0.05, 0.06, 0.55), Color(0, 0, 0, 0), 0, 2, 12))
	add_child(_obj_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	_obj_panel.add_child(vb)
	vb.add_child(UITheme.label("OBJECTIVE", 15, UITheme.YELLOW, true))
	_objective = UITheme.label("", 22, UITheme.WHITE)
	vb.add_child(_objective)
	_obj_panel.visible = false
	_hint = UITheme.label("", 24, UITheme.WHITE)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position = Vector2(-400, -150)
	_hint.size = Vector2(800, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.modulate.a = 0.0
	add_child(_hint)
	Events.objective_changed.connect(_on_objective)
	Events.hint_requested.connect(show_hint)
	_on_objective(SequenceManager.objective())


func _on_objective(text: String) -> void:
	_objective.text = text
	_obj_panel.visible = text != ""
	if text != "":
		_obj_panel.modulate.a = 0.0
		create_tween().tween_property(_obj_panel, "modulate:a", 1.0, 0.6)
		_obj_timer = 0.0


func show_hint(text: String, seconds := 3.0) -> void:
	_hint.text = text
	_hint_t = seconds
	create_tween().tween_property(_hint, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	if not visible:
		return
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			create_tween().tween_property(_hint, "modulate:a", 0.0, 0.5)
	var pl := Director.player as Player
	if pl == null or pl.interact == null:
		return
	var prompts: Array = pl.interact.prompts
	var key := str(prompts) + str(InputGlyphs.using_gamepad)
	_dot.color = Color(1.0, 0.86, 0.35, 0.95) if pl.interact.target != null else Color(1, 1, 1, 0.5)
	_dot.size = Vector2(9, 9) if pl.interact.target != null else Vector2(5, 5)
	_dot.position = -_dot.size * 0.5
	if key != _last_prompt_key:
		_last_prompt_key = key
		for c in _prompts.get_children():
			c.queue_free()
		for i in prompts.size():
			var p: Dictionary = prompts[i]
			_prompts.add_child(_prompt_row(String(p.action), String(p.text), i == 0))


func _prompt_row(action: String, text: String, primary: bool) -> Control:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	var key := PanelContainer.new()
	key.add_theme_stylebox_override("panel", UITheme.flat(UITheme.YELLOW if primary else Color(0.92, 0.93, 0.95, 0.85), Color(0, 0, 0, 0), 0, 3, 8))
	var kl := UITheme.label(InputGlyphs.prompt(StringName(action)), 20, UITheme.BG, true)
	key.add_child(kl)
	hb.add_child(key)
	var tl := UITheme.label(text, 22 if primary else 19, UITheme.WHITE if primary else UITheme.DIM)
	tl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	tl.add_theme_constant_override("outline_size", 5)
	hb.add_child(tl)
	return hb
