extends Node
## Tracks the last-used input device and turns actions into on-screen prompt
## text ("E", "LMB", "X" ...). Also owns controller rumble.

var using_gamepad: bool = false
var pad_family: String = "xbox"  # xbox | playstation | nintendo

const XBOX_BUTTONS := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-Up", JOY_BUTTON_DPAD_DOWN: "D-Down", JOY_BUTTON_DPAD_LEFT: "D-Left", JOY_BUTTON_DPAD_RIGHT: "D-Right",
}
const PS_BUTTONS := {
	JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle",
	JOY_BUTTON_BACK: "Share", JOY_BUTTON_START: "Options", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1",
	JOY_BUTTON_DPAD_UP: "D-Up", JOY_BUTTON_DPAD_DOWN: "D-Down", JOY_BUTTON_DPAD_LEFT: "D-Left", JOY_BUTTON_DPAD_RIGHT: "D-Right",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_changed)
	Events.rumble_requested.connect(rumble)
	_refresh_family()


func _input(event: InputEvent) -> void:
	var pad := false
	if event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) < 0.5:
			return
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false
	elif event is InputEventMouseMotion:
		if event.relative.length() < 2.0:
			return
		pad = false
	else:
		return
	if pad != using_gamepad:
		using_gamepad = pad
		Events.input_device_changed.emit(pad)


func _on_joy_changed(_device: int, _connected: bool) -> void:
	_refresh_family()


func _refresh_family() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return
	var n := Input.get_joy_name(pads[0]).to_lower()
	if n.contains("playstation") or n.contains("dualsense") or n.contains("dualshock") or n.contains("ps4") or n.contains("ps5"):
		pad_family = "playstation"
	elif n.contains("nintendo") or n.contains("switch") or n.contains("pro controller"):
		pad_family = "nintendo"
	else:
		pad_family = "xbox"


func pad_button_name(button: int) -> String:
	var table := PS_BUTTONS if pad_family == "playstation" else XBOX_BUTTONS
	return table.get(button, "Btn %d" % button)


func pad_axis_name(axis: int, dir: float) -> String:
	var trig := "R2" if pad_family == "playstation" else "RT"
	var trigl := "L2" if pad_family == "playstation" else "LT"
	match axis:
		JOY_AXIS_TRIGGER_RIGHT: return trig
		JOY_AXIS_TRIGGER_LEFT: return trigl
		JOY_AXIS_LEFT_X: return "Left Stick " + ("Right" if dir > 0 else "Left")
		JOY_AXIS_LEFT_Y: return "Left Stick " + ("Down" if dir > 0 else "Up")
		JOY_AXIS_RIGHT_X: return "Right Stick " + ("Right" if dir > 0 else "Left")
		JOY_AXIS_RIGHT_Y: return "Right Stick " + ("Down" if dir > 0 else "Up")
	return "Axis %d" % axis


## Text shown in prompts for the device currently in use.
func prompt(action: StringName) -> String:
	var slot := "pad" if using_gamepad else "kb1"
	var t: String = SettingsManager.binding_text(action, slot)
	if t == "-" and not using_gamepad:
		t = SettingsManager.binding_text(action, "kb2")
	return t


func rumble(weak: float, strong: float, seconds: float) -> void:
	if not SettingsManager.get_value("input/rumble"):
		return
	for d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), seconds)
