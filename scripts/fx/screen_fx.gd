class_name ScreenFX
extends CanvasLayer
## Owns the full-screen post-process quad. Everything intense is scaled by the
## player's comfort settings (flash reduction, premonition distortion, blur).

var rect: ColorRect
var mat: ShaderMaterial
var _tweens: Dictionary = {}
var _t := 0.0


func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/screen_fx.gdshader")
	rect.material = mat
	add_child(rect)
	Events.flash_requested.connect(flash)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	mat.set_shader_parameter("time_fx", _t)


func set_fx(param: StringName, value: Variant) -> void:
	mat.set_shader_parameter(param, value)


func tween_fx(param: StringName, to: float, seconds: float) -> void:
	if _tweens.has(param) and (_tweens[param] as Tween).is_valid():
		(_tweens[param] as Tween).kill()
	var from: Variant = mat.get_shader_parameter(param)
	if from == null:
		from = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(param, v), float(from), to, seconds)
	_tweens[param] = tw


func flash(color: Color = Color.WHITE, seconds: float = 0.25) -> void:
	var k := 0.35 if SettingsManager.get_value("comfort/flash_reduction") else 1.0
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash", 0.9 * k)
	tween_fx(&"flash", 0.0, seconds)


func reset_all() -> void:
	for p in [&"vignette", &"aberration", &"desat", &"tint_amount", &"blur", &"wobble", &"flash", &"film_grain", &"scanlines"]:
		mat.set_shader_parameter(p, 0.0)
	mat.set_shader_parameter("contrast", 1.0)
	mat.set_shader_parameter("exposure", 1.0)
