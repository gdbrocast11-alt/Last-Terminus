extends Node
## Persistent user settings: graphics presets, audio mix, comfort/accessibility
## options and remappable input. Stored in user://settings.cfg.

const CONFIG_PATH := "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const PRESET_NAMES: Array[String] = ["Low", "Medium", "High", "Ultra"]
const DISPLAY_MODES: Array[String] = ["Windowed", "Borderless", "Fullscreen"]
const FRAME_CAPS: Array[int] = [0, 30, 60, 90, 120, 144, 240]

## Remappable gameplay actions in the order they appear in the controls menu.
const ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"sprint", &"crouch", &"jump", &"interact", &"use_item", &"secondary",
	&"pickles_command", &"focus", &"drop_item", &"notebook", &"pause",
	&"look_up", &"look_down", &"look_left", &"look_right",
]

const ACTION_LABELS := {
	&"move_forward": "Move forward", &"move_back": "Move back", &"move_left": "Move left", &"move_right": "Move right",
	&"sprint": "Sprint", &"crouch": "Crouch", &"jump": "Jump / Mantle", &"interact": "Interact / Talk",
	&"use_item": "Use / Throw", &"secondary": "Inspect / Rotate", &"pickles_command": "Command Pickles",
	&"focus": "Focus (danger intuition)", &"drop_item": "Drop / Reset", &"notebook": "Notebook", &"pause": "Pause",
	&"look_up": "Look up (stick)", &"look_down": "Look down (stick)", &"look_left": "Look left (stick)", &"look_right": "Look right (stick)",
}

const DEFAULTS := {
	"graphics/preset": 2,
	"graphics/resolution": 2,
	"graphics/display_mode": 0,
	"graphics/vsync": true,
	"graphics/frame_cap": 0,
	"graphics/fov": 78.0,
	"graphics/render_scale": 1.0,
	"input/mouse_sensitivity": 1.0,
	"input/pad_sensitivity": 1.0,
	"input/invert_y": false,
	"input/sprint_toggle": false,
	"input/crouch_toggle": true,
	"input/rumble": true,
	"comfort/head_bob": 1.0,
	"comfort/camera_shake": 1.0,
	"comfort/motion_blur": 0.35,
	"comfort/flash_reduction": false,
	"comfort/premonition_distortion": 1.0,
	"comfort/hazard_cues": true,
	"audio/master": 0.9,
	"audio/music": 0.75,
	"audio/voices": 1.0,
	"audio/effects": 0.9,
	"subtitles/enabled": true,
	"subtitles/size": 1.0,
	"subtitles/speaker_names": true,
	"gameplay/gore": "full",
	"gameplay/skip_seen_premonitions": true,
}

var values: Dictionary = {}
var bindings: Dictionary = {}  # action -> {"kb1": Dictionary, "kb2": Dictionary, "pad": Dictionary}
var developer_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	developer_mode = OS.has_feature("editor") or OS.get_cmdline_user_args().has("--dev") or OS.get_cmdline_args().has("--dev")
	_register_default_actions()
	load_settings()
	apply_all()


# --------------------------------------------------------------------------
# values
# --------------------------------------------------------------------------
func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS[key])


func set_value(key: String, value: Variant, apply: bool = true) -> void:
	values[key] = value
	if apply:
		_apply_key(key)
	Events.settings_changed.emit()


func reduced_gore() -> bool:
	return get_value("gameplay/gore") == "reduced"


func _apply_key(key: String) -> void:
	if key.begins_with("graphics/"):
		if key == "graphics/preset":
			apply_graphics()
		else:
			apply_display()
	elif key.begins_with("audio/"):
		apply_audio()


func apply_all() -> void:
	apply_display()
	apply_audio()
	apply_graphics()


# --------------------------------------------------------------------------
# display / graphics
# --------------------------------------------------------------------------
func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: int = get_value("graphics/display_mode")
	var res: Vector2i = RESOLUTIONS[clampi(get_value("graphics/resolution"), 0, RESOLUTIONS.size() - 1)]
	match mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(res)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())
			DisplayServer.window_set_position(DisplayServer.screen_get_position())
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if get_value("graphics/vsync") else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FRAME_CAPS[clampi(get_value("graphics/frame_cap"), 0, FRAME_CAPS.size() - 1)]


## Per-preset renderer parameters. Environment-level toggles are applied to
## every WorldEnvironment in group "world_environment" by apply_to_environment().
func preset_params(preset: int) -> Dictionary:
	match clampi(preset, 0, 3):
		0:
			return {"dir_shadow": 1024, "pos_shadow": 1024, "soft_shadow": 0, "msaa": 0, "taa": false, "fxaa": true,
				"ssao": false, "ssil": false, "ssr": false, "sdfgi": false, "vfog": false, "glow": true, "dof": false,
				"lod_threshold": 3.0, "shadow_distance": 28.0, "ssao_quality": 0, "vfog_size": 48, "vfog_depth": 48,
				"ssr_steps": 24, "sdfgi_cascades": 2, "decals": true, "particle_scale": 0.5, "max_lights": 6, "dir_splits": 1, "omni_shadows": 0}
		1:
			return {"dir_shadow": 2048, "pos_shadow": 2048, "soft_shadow": 1, "msaa": 0, "taa": true, "fxaa": false,
				"ssao": true, "ssil": false, "ssr": false, "sdfgi": false, "vfog": true, "glow": true, "dof": false,
				"lod_threshold": 2.0, "shadow_distance": 45.0, "ssao_quality": 1, "vfog_size": 64, "vfog_depth": 64,
				"ssr_steps": 32, "sdfgi_cascades": 2, "decals": true, "particle_scale": 0.75, "max_lights": 10, "dir_splits": 2, "omni_shadows": 1}
		2:
			return {"dir_shadow": 4096, "pos_shadow": 4096, "soft_shadow": 3, "msaa": 0, "taa": true, "fxaa": false,
				"ssao": true, "ssil": true, "ssr": true, "sdfgi": true, "vfog": true, "glow": true, "dof": true,
				"lod_threshold": 1.0, "shadow_distance": 70.0, "ssao_quality": 2, "vfog_size": 96, "vfog_depth": 96,
				"ssr_steps": 64, "sdfgi_cascades": 3, "decals": true, "particle_scale": 1.0, "max_lights": 16, "dir_splits": 4, "omni_shadows": 3}
		_:
			return {"dir_shadow": 8192, "pos_shadow": 8192, "soft_shadow": 4, "msaa": 1, "taa": true, "fxaa": false,
				"ssao": true, "ssil": true, "ssr": true, "sdfgi": true, "vfog": true, "glow": true, "dof": true,
				"lod_threshold": 0.7, "shadow_distance": 110.0, "ssao_quality": 3, "vfog_size": 128, "vfog_depth": 128,
				"ssr_steps": 128, "sdfgi_cascades": 4, "decals": true, "particle_scale": 1.0, "max_lights": 24, "dir_splits": 4, "omni_shadows": 8}


func apply_graphics() -> void:
	var p := preset_params(get_value("graphics/preset"))
	if DisplayServer.get_name() != "headless":
		RenderingServer.directional_shadow_atlas_set_size(p.dir_shadow, true)
		RenderingServer.positional_soft_shadow_filter_set_quality(p.soft_shadow as RenderingServer.ShadowQuality)
		RenderingServer.directional_soft_shadow_filter_set_quality(p.soft_shadow as RenderingServer.ShadowQuality)
		RenderingServer.environment_set_ssao_quality(p.ssao_quality as RenderingServer.EnvironmentSSAOQuality, true, 0.5, 2, 50.0, 300.0)
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM, true, 0.5, 4, 50.0, 300.0)
		RenderingServer.environment_set_volumetric_fog_volume_size(p.vfog_size, p.vfog_depth)
		RenderingServer.environment_set_volumetric_fog_filter_active(p.vfog_size >= 64)
		RenderingServer.gi_set_use_half_resolution(int(get_value("graphics/preset")) < 3)
	var vp := get_viewport()
	if vp != null:
		vp.positional_shadow_atlas_size = p.pos_shadow
		vp.msaa_3d = p.msaa as Viewport.MSAA
		vp.use_taa = p.taa
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if p.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
		vp.mesh_lod_threshold = p.lod_threshold
		vp.scaling_3d_scale = clampf(get_value("graphics/render_scale"), 0.5, 1.0)
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR if vp.scaling_3d_scale >= 0.999 else Viewport.SCALING_3D_MODE_FSR2
		vp.use_debanding = true
		vp.use_occlusion_culling = true
	apply_to_scene()


func apply_to_scene() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("world_environment"):
		if n is WorldEnvironment:
			apply_to_environment(n.environment, n.camera_attributes)
	var pp := preset_params(get_value("graphics/preset"))
	for l in get_tree().get_nodes_in_group("graphics_directional"):
		if l is DirectionalLight3D:
			var dl := l as DirectionalLight3D
			dl.directional_shadow_max_distance = pp.shadow_distance
			dl.directional_shadow_mode = {1: DirectionalLight3D.SHADOW_ORTHOGONAL, 2: DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS}.get(int(pp.dir_splits), DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	# cap shadow-casting omni/spot lights and the total number of active lights per preset
	var shadow_budget: int = int(pp.omni_shadows)
	var light_budget: int = int(pp.max_lights)
	var lights := get_tree().get_nodes_in_group("level_lights")
	lights.sort_custom(func(a: Node, b: Node) -> bool: return float((a as Light3D).light_energy) * float((a as Light3D).omni_range if a is OmniLight3D else 8.0) > float((b as Light3D).light_energy) * float((b as Light3D).omni_range if b is OmniLight3D else 8.0))
	var used := 0
	var shadowed := 0
	for n in lights:
		var lt := n as Light3D
		if lt == null:
			continue
		var wants_shadow: bool = lt.has_meta("wants_shadow") and bool(lt.get_meta("wants_shadow"))
		lt.set_meta("budget_off", used >= light_budget)
		if used >= light_budget:
			lt.shadow_enabled = false
		else:
			used += 1
			if wants_shadow and shadowed < shadow_budget:
				lt.shadow_enabled = true
				shadowed += 1
			else:
				lt.shadow_enabled = false


func apply_to_environment(env: Environment, cam_attrs: CameraAttributes) -> void:
	if env == null:
		return
	var p := preset_params(get_value("graphics/preset"))
	env.ssao_enabled = p.ssao
	env.ssil_enabled = p.ssil
	env.ssr_enabled = p.ssr
	env.ssr_max_steps = p.ssr_steps
	env.sdfgi_enabled = p.sdfgi and bool(env.get_meta("sdfgi_allowed", true))
	env.sdfgi_cascades = p.sdfgi_cascades
	env.volumetric_fog_enabled = p.vfog and bool(env.get_meta("vfog_allowed", true))
	env.glow_enabled = p.glow
	if cam_attrs is CameraAttributesPractical:
		cam_attrs.dof_blur_far_enabled = p.dof and bool(cam_attrs.get_meta("dof_allowed", false))
		cam_attrs.dof_blur_near_enabled = false


# --------------------------------------------------------------------------
# audio
# --------------------------------------------------------------------------
func apply_audio() -> void:
	AudioManager.set_bus_linear(&"Master", get_value("audio/master"))
	AudioManager.set_bus_linear(&"Music", get_value("audio/music"))
	AudioManager.set_bus_linear(&"Voice", get_value("audio/voices"))
	AudioManager.set_bus_linear(&"SFX", get_value("audio/effects"))


# --------------------------------------------------------------------------
# input
# --------------------------------------------------------------------------
func _default_bindings() -> Dictionary:
	var k := func(code: int) -> Dictionary: return {"t": "key", "c": code}
	var m := func(btn: int) -> Dictionary: return {"t": "mouse", "c": btn}
	var b := func(btn: int) -> Dictionary: return {"t": "pad", "c": btn}
	var a := func(axis: int, dir: float) -> Dictionary: return {"t": "axis", "c": axis, "d": dir}
	return {
		&"move_forward": {"kb1": k.call(KEY_W), "kb2": k.call(KEY_UP), "pad": a.call(JOY_AXIS_LEFT_Y, -1.0)},
		&"move_back": {"kb1": k.call(KEY_S), "kb2": k.call(KEY_DOWN), "pad": a.call(JOY_AXIS_LEFT_Y, 1.0)},
		&"move_left": {"kb1": k.call(KEY_A), "kb2": k.call(KEY_LEFT), "pad": a.call(JOY_AXIS_LEFT_X, -1.0)},
		&"move_right": {"kb1": k.call(KEY_D), "kb2": k.call(KEY_RIGHT), "pad": a.call(JOY_AXIS_LEFT_X, 1.0)},
		&"look_up": {"kb1": {}, "kb2": {}, "pad": a.call(JOY_AXIS_RIGHT_Y, -1.0)},
		&"look_down": {"kb1": {}, "kb2": {}, "pad": a.call(JOY_AXIS_RIGHT_Y, 1.0)},
		&"look_left": {"kb1": {}, "kb2": {}, "pad": a.call(JOY_AXIS_RIGHT_X, -1.0)},
		&"look_right": {"kb1": {}, "kb2": {}, "pad": a.call(JOY_AXIS_RIGHT_X, 1.0)},
		&"sprint": {"kb1": k.call(KEY_SHIFT), "kb2": {}, "pad": b.call(JOY_BUTTON_LEFT_STICK)},
		&"crouch": {"kb1": k.call(KEY_CTRL), "kb2": k.call(KEY_C), "pad": b.call(JOY_BUTTON_B)},
		&"jump": {"kb1": k.call(KEY_SPACE), "kb2": {}, "pad": b.call(JOY_BUTTON_A)},
		&"interact": {"kb1": k.call(KEY_E), "kb2": {}, "pad": b.call(JOY_BUTTON_X)},
		&"use_item": {"kb1": m.call(MOUSE_BUTTON_LEFT), "kb2": {}, "pad": a.call(JOY_AXIS_TRIGGER_RIGHT, 1.0)},
		&"secondary": {"kb1": m.call(MOUSE_BUTTON_RIGHT), "kb2": {}, "pad": a.call(JOY_AXIS_TRIGGER_LEFT, 1.0)},
		&"pickles_command": {"kb1": k.call(KEY_F), "kb2": {}, "pad": b.call(JOY_BUTTON_Y)},
		&"focus": {"kb1": k.call(KEY_Q), "kb2": {}, "pad": b.call(JOY_BUTTON_LEFT_SHOULDER)},
		&"drop_item": {"kb1": k.call(KEY_R), "kb2": {}, "pad": b.call(JOY_BUTTON_RIGHT_SHOULDER)},
		&"notebook": {"kb1": k.call(KEY_TAB), "kb2": {}, "pad": b.call(JOY_BUTTON_BACK)},
		&"pause": {"kb1": k.call(KEY_ESCAPE), "kb2": {}, "pad": b.call(JOY_BUTTON_START)},
	}


func _register_default_actions() -> void:
	bindings = _default_bindings()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)


func _event_from_binding(b: Dictionary) -> InputEvent:
	if b.is_empty():
		return null
	match b.get("t", ""):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = int(b.c) as Key
			return e
		"mouse":
			var e := InputEventMouseButton.new()
			e.button_index = int(b.c) as MouseButton
			return e
		"pad":
			var e := InputEventJoypadButton.new()
			e.button_index = int(b.c) as JoyButton
			return e
		"axis":
			var e := InputEventJoypadMotion.new()
			e.axis = int(b.c) as JoyAxis
			e.axis_value = float(b.d)
			return e
	return null


func apply_inputs() -> void:
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		var slots: Dictionary = bindings.get(action, {})
		for slot in ["kb1", "kb2", "pad"]:
			var ev := _event_from_binding(slots.get(slot, {}))
			if ev != null:
				InputMap.action_add_event(action, ev)
	# Keep menu navigation working on pad and keyboard regardless of remaps.
	_ensure_ui_pad_events()


func _ensure_ui_pad_events() -> void:
	var pairs := {&"ui_accept": JOY_BUTTON_A, &"ui_cancel": JOY_BUTTON_B, &"ui_up": JOY_BUTTON_DPAD_UP,
		&"ui_down": JOY_BUTTON_DPAD_DOWN, &"ui_left": JOY_BUTTON_DPAD_LEFT, &"ui_right": JOY_BUTTON_DPAD_RIGHT}
	for a in pairs.keys():
		var has := false
		for ev in InputMap.action_get_events(a):
			if ev is InputEventJoypadButton and ev.button_index == pairs[a]:
				has = true
		if not has:
			var e := InputEventJoypadButton.new()
			e.button_index = pairs[a] as JoyButton
			InputMap.action_add_event(a, e)


func rebind(action: StringName, slot: String, event: InputEvent) -> void:
	var b := {}
	if event is InputEventKey:
		b = {"t": "key", "c": event.physical_keycode if event.physical_keycode != 0 else event.keycode}
	elif event is InputEventMouseButton:
		b = {"t": "mouse", "c": event.button_index}
	elif event is InputEventJoypadButton:
		b = {"t": "pad", "c": event.button_index}
	elif event is InputEventJoypadMotion:
		b = {"t": "axis", "c": event.axis, "d": signf(event.axis_value)}
	else:
		return
	# Clear the same binding from any other action to avoid silent conflicts.
	for other in ACTIONS:
		if other == action:
			continue
		for s in ["kb1", "kb2", "pad"]:
			if bindings[other][s] == b:
				bindings[other][s] = {}
	bindings[action][slot] = b
	apply_inputs()
	save_settings()
	Events.settings_changed.emit()


func clear_binding(action: StringName, slot: String) -> void:
	bindings[action][slot] = {}
	apply_inputs()
	save_settings()


func reset_bindings() -> void:
	bindings = _default_bindings()
	apply_inputs()
	save_settings()
	Events.settings_changed.emit()


func binding_text(action: StringName, slot: String) -> String:
	var b: Dictionary = bindings.get(action, {}).get(slot, {})
	if b.is_empty():
		return "-"
	match b.t:
		"key":
			return OS.get_keycode_string(int(b.c) as Key).to_upper()
		"mouse":
			return {MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB"}.get(int(b.c), "Mouse %d" % int(b.c))
		"pad":
			return InputGlyphs.pad_button_name(int(b.c))
		"axis":
			return InputGlyphs.pad_axis_name(int(b.c), float(b.d))
	return "-"


# --------------------------------------------------------------------------
# persistence
# --------------------------------------------------------------------------
func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in values.keys():
		var parts: PackedStringArray = String(k).split("/", true, 1)
		cfg.set_value(parts[0], parts[1], values[k])
	for action in ACTIONS:
		cfg.set_value("bindings", String(action), JSON.stringify(bindings[action]))
	cfg.save(CONFIG_PATH)


func load_settings() -> void:
	values = {}
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		for section in cfg.get_sections():
			if section == "bindings":
				for action in cfg.get_section_keys(section):
					var parsed: Variant = JSON.parse_string(String(cfg.get_value(section, action)))
					if parsed is Dictionary and bindings.has(StringName(action)):
						for slot in ["kb1", "kb2", "pad"]:
							if parsed.has(slot) and parsed[slot] is Dictionary:
								bindings[StringName(action)][slot] = _fix_binding(parsed[slot])
				continue
			for key in cfg.get_section_keys(section):
				var full := "%s/%s" % [section, key]
				if DEFAULTS.has(full):
					values[full] = _coerce(cfg.get_value(section, key), DEFAULTS[full])
	apply_inputs()


func _fix_binding(b: Dictionary) -> Dictionary:
	if b.has("c"):
		b["c"] = int(b["c"])
	return b


func _coerce(v: Variant, template: Variant) -> Variant:
	if template is float:
		return float(v)
	if template is int and not (template is bool):
		return int(v)
	return v
