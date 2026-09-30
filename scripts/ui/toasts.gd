extends Control
## Achievement + notebook toasts, top-right.

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_box.position = Vector2(-380, 24)
	_box.size = Vector2(350, 10)
	add_child(_box)
	Events.achievement_unlocked.connect(_on_achievement)


func _on_achievement(id: StringName) -> void:
	var d: Dictionary = AchievementManager.DEFS.get(id, {})
	push_toast("ACHIEVEMENT", String(d.get("name", id)), String(d.get("desc", "")))


func push_toast(head: String, title: String, sub: String) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UITheme.flat(Color(0.05, 0.06, 0.075, 0.94), UITheme.YELLOW, 0, 2, 14))
	var sb: StyleBoxFlat = pc.get_theme_stylebox("panel")
	sb.border_width_left = 6
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	pc.add_child(vb)
	vb.add_child(UITheme.label(head, 14, UITheme.YELLOW, true))
	vb.add_child(UITheme.label(title, 26, UITheme.WHITE, true))
	if sub != "":
		var s := UITheme.label(sub, 17, UITheme.DIM)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 300
		vb.add_child(s)
	_box.add_child(pc)
	pc.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.3)
	tw.tween_interval(4.5)
	tw.tween_property(pc, "modulate:a", 0.0, 0.6)
	tw.tween_callback(pc.queue_free)
