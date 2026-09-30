class_name PadLook
extends RefCounted
## Right-stick look with a gentle response curve.

static func enabled() -> bool:
	return InputGlyphs.using_gamepad and not Input.get_connected_joypads().is_empty()


static func stick() -> Vector2:
	var v := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down", 0.2)
	return v * (0.35 + 0.65 * v.length())
