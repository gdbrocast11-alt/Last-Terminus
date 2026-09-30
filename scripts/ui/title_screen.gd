extends Node3D
## Title: Terminus Station signage in the dark, a dying fluorescent tube, Pickles
## strolling through the background and, if you wait, something falling that he
## casually avoids.

const IDLE_GAG_SECONDS := 42.0

var cam: Camera3D
var sign_node: Node3D
var tube: SpotLight3D
var fixture: Node3D
var pickles: Pickles
var ui: CanvasLayer
var menu: VBoxContainer
var settings: SettingsPanel
var credits: Control
var _idle := 0.0
var _gag_done := false
var _flicker_t := 0.0
var _pa_t := 14.0
var _pk_t := 8.0
var _t := 0.0
var _busy := false


func _ready() -> void:
	GameState.in_game = false
	get_tree().paused = false
	_build_world()
	_build_ui()
	AudioManager.play_music(&"mus_title", 1.5)
	AudioManager.play_ambience(&"amb_station", -16.0)
	await Director.fade(false, 1.2)


func _prop(scene: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var n := (load("res://scenes/props/%s.tscn" % scene) as PackedScene).instantiate() as Node3D
	add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw
	if n is RigidBody3D:
		(n as RigidBody3D).freeze = true
	return n


func _build_world() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var fcs := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(60, 1, 40)
	fcs.shape = fb
	floor_body.add_child(fcs)
	fcs.position.y = -0.5
	add_child(floor_body)
	var floor_mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(60, 0.2, 40)
	floor_mi.mesh = bm
	floor_mi.material_override = BuildUtilRuntime.material("TerrazzoDark")
	floor_mi.position.y = -0.1
	add_child(floor_mi)
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(40, 12, 0.5)
	wall.mesh = wm
	wall.material_override = BuildUtilRuntime.material("WallGrey")
	wall.position = Vector3(0, 6, -9.2)
	add_child(wall)
	for x in [-9.0, 9.0]:
		var col := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.9, 12, 0.9)
		col.mesh = cm
		col.material_override = BuildUtilRuntime.material("Concrete")
		col.position = Vector3(x, 6, -6)
		add_child(col)
	sign_node = _prop("sign_terminus_hall", Vector3(0, 3.7, -8.9), 180)
	sign_node.scale = Vector3(1.25, 1.25, 1.25)
	_prop("bench", Vector3(4.6, 0, -5.0), 180)
	_prop("trash_bin", Vector3(-6.2, 0, -5.6))
	_prop("wet_floor_sign", Vector3(-3.0, 0, -2.0), 30)
	fixture = _prop("light_fixture", Vector3(-2.0, 6.0, -3.5))
	tube = SpotLight3D.new()
	tube.spot_range = 22.0
	tube.spot_angle = 55.0
	tube.light_energy = 6.0
	tube.light_color = Color(0.85, 1.0, 0.92)
	tube.shadow_enabled = true
	tube.position = Vector3(0, 7.5, 1.0)
	tube.rotation_degrees = Vector3(-72, 0, 0)
	tube.light_volumetric_fog_energy = 1.6
	add_child(tube)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.4, 0.5, 0.8)
	fill.light_energy = 0.5
	fill.omni_range = 18.0
	fill.position = Vector3(0, 2.5, 3.0)
	add_child(fill)
	var we := WorldEnvironment.new()
	we.environment = EnvBuilder.make({"kind": "interior", "bg": [0.005, 0.006, 0.01], "ambient": [0.06, 0.08, 0.12], "ambient_energy": 1.0, "fog": 0.035,
		"fog_color": [0.35, 0.42, 0.5], "vfog": true, "grade": "cool_teal", "exposure": 1.0, "sdfgi": false})
	we.camera_attributes = EnvBuilder.make_camera_attrs({})
	we.add_to_group("world_environment")
	add_child(we)
	cam = Camera3D.new()
	cam.fov = 48
	cam.position = Vector3(0, 1.75, 7.5)
	cam.current = true
	add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0.5, 2.5, -8), Vector3.UP)
	pickles = (load("res://scenes/pickles.tscn") as PackedScene).instantiate() as Pickles
	add_child(pickles)
	pickles.position = Vector3(-20, 0.05, -3.4)
	pickles.begin_scripted()
	SettingsManager.apply_to_scene()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme()
	ui.add_child(root)
	var box := VBoxContainer.new()
	box.position = Vector2(90, 90)
	box.custom_minimum_size = Vector2(620, 0)
	box.add_theme_constant_override("separation", -34)
	root.add_child(box)
	var bar := ColorRect.new()
	bar.color = UITheme.YELLOW
	bar.custom_minimum_size = Vector2(150, 10)
	box.add_child(bar)
	var logo1 := UITheme.label("LAST", 150, UITheme.WHITE, true)
	logo1.add_theme_constant_override("line_spacing", -30)
	logo1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	logo1.add_theme_constant_override("outline_size", 8)
	box.add_child(logo1)
	var logo2 := UITheme.label("TERMINUS", 118, UITheme.YELLOW, true)
	logo2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	logo2.add_theme_constant_override("outline_size", 8)
	box.add_child(logo2)
	var tag := UITheme.label("THE LAST STOP YOU'LL EVER NEED", 22, UITheme.DIM, true)
	box.add_child(tag)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 2)
	box.add_child(menu)
	_add_button("NEW GAME", _on_new)
	var cont := _add_button("CONTINUE", _on_continue)
	cont.disabled = not SaveManager.has_save()
	if SaveManager.game_completed():
		_add_button("CHAPTERS", _on_chapters)
	_add_button("SETTINGS", _on_settings)
	_add_button("CREDITS", _on_credits)
	if not OS.has_feature("web"):
		_add_button("QUIT", func() -> void: get_tree().quit())
	for b in menu.get_children():
		if not (b as Button).disabled:
			(b as Button).grab_focus()
			break
	var ver := UITheme.label("v1.0  |  original story, art, music and voices", 15, Color(1, 1, 1, 0.35))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(90, -40)
	root.add_child(ver)
	settings = SettingsPanel.new()
	settings.visible = false
	settings.set_anchors_preset(Control.PRESET_CENTER)
	settings.position = Vector2(440, 150)
	settings.closed.connect(func() -> void:
		settings.visible = false
		box.visible = true)
	root.add_child(settings)
	var chapters := VBoxContainer.new()
	chapters.name = "ChapterList"
	chapters.visible = false
	chapters.position = Vector2(90, 300)
	root.add_child(chapters)


func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func() -> void:
		AudioManager.play_ui(&"ui_click")
		cb.call())
	b.mouse_entered.connect(func() -> void: AudioManager.play_ui(&"ui_hover", -8.0))
	b.focus_entered.connect(func() -> void: AudioManager.play_ui(&"ui_hover", -8.0))
	menu.add_child(b)
	return b


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or (event is InputEventMouseMotion and event.relative.length() > 3):
		_idle = 0.0


func _process(delta: float) -> void:
	_t += delta
	_idle += delta
	# camera drifts very slowly
	cam.position.x = sin(_t * 0.11) * 0.5
	cam.position.y = 1.75 + sin(_t * 0.07) * 0.06
	cam.look_at(Vector3(0.5 + sin(_t * 0.05) * 0.3, 2.5, -8), Vector3.UP)
	# dying fluorescent
	_flicker_t -= delta
	if _flicker_t <= 0.0:
		var burst := randf() < 0.3
		tube.light_energy = 6.0 if not burst else randf_range(0.0, 2.0)
		_flicker_t = randf_range(0.03, 0.09) if burst else randf_range(0.6, 3.5)
		if burst and randf() < 0.4:
			AudioManager.play_sfx(&"fluorescent_flicker", Vector3(0, 6, 0), -14.0)
	# PA announcements
	_pa_t -= delta
	if _pa_t <= 0.0 and not DialogueManager.is_busy():
		_pa_t = randf_range(28.0, 46.0)
		DialogueManager.bark(DialogueManager.pick("ch1_pa", 6))
	# Pickles strolls by
	_pk_t -= delta
	if _pk_t <= 0.0 and pickles.state == Pickles.State.SCRIPTED and not pickles.moving:
		_pk_t = randf_range(30.0, 55.0)
		_walk_pickles(false)
	if _idle > IDLE_GAG_SECONDS and not _gag_done:
		_gag_done = true
		_idle_gag()


func _walk_pickles(with_gag: bool) -> void:
	var z := -3.4
	pickles.teleport(Vector3(-18, 0.05, z))
	pickles.walk_speed = 1.7
	pickles.move_to(Vector3(18, 0.05, z), false, 40.0)


func _idle_gag() -> void:
	# Pickles trots to the spot; the fixture drops; he keeps going.
	pickles.teleport(Vector3(-4.6, 0.05, -3.5))
	pickles.move_to(Vector3(10, 0.05, -3.5), false, 20.0)
	AudioManager.play_sfx(&"creak", fixture.global_position, -4.0)
	await get_tree().create_timer(2.6).timeout
	var tw := create_tween()
	tw.tween_property(fixture, "position:y", 0.06, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		AudioManager.play_sfx(&"clang", fixture.global_position, 2.0)
		FX.burst(&"spark", fixture.global_position + Vector3(0, 0.1, 0))
		FX.burst(&"dust", fixture.global_position, 0.8))


func _on_new() -> void:
	if _busy:
		return
	_busy = true
	AudioManager.stop_music(0.8)
	await Director.fade(true, 0.8)
	Director.start_new_game()


func _on_continue() -> void:
	if _busy:
		return
	_busy = true
	AudioManager.stop_music(0.8)
	await Director.fade(true, 0.8)
	if not await Director.continue_game():
		_busy = false


func _on_settings() -> void:
	menu.get_parent().visible = false
	settings.visible = true
	settings.refresh()


func _on_credits() -> void:
	var c := CreditsScreen.new()
	c.finished.connect(func() -> void: pass)
	ui.add_child(c)
	c.start(true)


func _on_chapters() -> void:
	var list := ui.get_child(0).get_node("ChapterList") as VBoxContainer
	list.visible = not list.visible
	for c in list.get_children():
		c.queue_free()
	if not list.visible:
		return
	for ch in [GameState.Chapter.STATION, GameState.Chapter.AFTERMATH, GameState.Chapter.STORE, GameState.Chapter.WELLNESS, GameState.Chapter.GRAVES,
			GameState.Chapter.YARD, GameState.Chapter.FINALE, GameState.Chapter.ENDING]:
		var b := Button.new()
		b.text = "   " + GameState.CHAPTER_NAMES[ch]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(func() -> void:
			await Director.fade(true, 0.6)
			Director.start_from_chapter(ch))
		list.add_child(b)
