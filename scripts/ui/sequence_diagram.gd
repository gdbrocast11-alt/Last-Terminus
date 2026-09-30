class_name SequenceDiagram
extends Control
## Eddie's handwritten diagram of who is next. Drawn procedurally: names in
## loose boxes, arrows between them, dead people struck through, and -- once
## the pop-up has ruined the theory -- scribbles, question marks and extra arrows.

func _draw() -> void:
	var order: Array = SequenceManager.sequence()
	var font := UITheme.hand_font()
	var unreliable := SequenceManager.sequence_unreliable()
	if order.is_empty():
		draw_string(font, Vector2(30, 80), "(nothing written down yet)", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.25, 0.22, 0.2, 0.7))
		return
	var n := order.size()
	var cols := 3
	var cw := size.x / cols
	var rh := 108.0
	var pts: Array[Vector2] = []
	for i in n:
		var r := i / cols
		var c := i % cols
		if r % 2 == 1:
			c = cols - 1 - c
		var p := Vector2(cw * (c + 0.5), 70 + r * rh)
		# deterministic wobble so it looks handwritten but stable
		p += Vector2(sin(i * 12.9898) * 14.0, cos(i * 78.233) * 10.0)
		pts.append(p)
	for i in n - 1:
		_arrow(pts[i], pts[i + 1], unreliable and i % 2 == 1)
	for i in n:
		var id := StringName(order[i])
		var nm := _display(id)
		var dead: bool = GameState.survivors.get(id, &"alive") == &"dead"
		var ink := Color(0.16, 0.13, 0.28) if not dead else Color(0.45, 0.1, 0.1)
		var w := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
		var rect := Rect2(pts[i] - Vector2(w * 0.5 + 12, 30), Vector2(w + 24, 52))
		_wobbly_box(rect, ink)
		draw_string(font, pts[i] + Vector2(-w * 0.5, 10), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, ink)
		draw_string(UITheme.head_font(), rect.position + Vector2(-6, -6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.4, 0.3, 0.2, 0.9))
		if dead:
			draw_line(rect.position + Vector2(-8, rect.size.y * 0.5), rect.position + Vector2(rect.size.x + 8, rect.size.y * 0.35), Color(0.55, 0.06, 0.06), 4.0)
			draw_line(rect.position + Vector2(-6, rect.size.y * 0.7), rect.position + Vector2(rect.size.x + 6, rect.size.y * 0.55), Color(0.55, 0.06, 0.06), 3.0)
		elif unreliable and i > 0:
			draw_string(font, rect.position + Vector2(rect.size.x + 4, 6), "???", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.7, 0.15, 0.1))
	if unreliable:
		for i in 6:
			var a := Vector2(60 + i * 140, size.y - 54 + sin(i * 3.1) * 12)
			draw_polyline(PackedVector2Array([a, a + Vector2(70, -22), a + Vector2(20, -12), a + Vector2(90, 12)]), Color(0.6, 0.15, 0.1, 0.5), 2.0)
		draw_string(font, Vector2(30, size.y - 14), "the order is NOT the order.", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.6, 0.1, 0.08))


func _display(id: StringName) -> String:
	if id == &"eddie":
		return "ME"
	if id == &"kevin":
		return "Kevin"
	return String(SequenceManager.SURVIVOR_INFO.get(id, {}).get("name", String(id).capitalize())).split(" ")[0]


func _arrow(a: Vector2, b: Vector2, shaky: bool) -> void:
	var d := (b - a)
	var dir := d.normalized()
	var s := a + dir * 46.0
	var e := b - dir * 46.0
	var col := Color(0.2, 0.17, 0.3, 0.85)
	var mid := (s + e) * 0.5 + Vector2(-dir.y, dir.x) * (10.0 if not shaky else 24.0)
	draw_polyline(PackedVector2Array([s, mid, e]), col, 3.0)
	draw_line(e, e - dir.rotated(0.5) * 16.0, col, 3.0)
	draw_line(e, e - dir.rotated(-0.5) * 16.0, col, 3.0)


func _wobbly_box(r: Rect2, col: Color) -> void:
	var p := PackedVector2Array([r.position, r.position + Vector2(r.size.x, 2), r.position + r.size, r.position + Vector2(-2, r.size.y), r.position + Vector2(1, -2)])
	draw_polyline(p, col, 2.5)
