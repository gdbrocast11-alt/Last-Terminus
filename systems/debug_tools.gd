extends Node
## Developer overlay (F1). Only active when SettingsManager.developer_mode is
## true (editor runs or --dev). Compiled out of behaviour in release builds.

var overlay: Control
var stats_label: Label
var visible_overlay := false
var show_hazard_nodes := false
var _timer := 0.0


var _shot_path := ""
var _shot_frames := 0
var _shot_quit := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(SettingsManager.developer_mode)
	# QA hook: godot ... -- --shot=/tmp/x.png --shot-frames=180 (captures the running game, then quits)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot_path = a.substr(7)
		elif a.begins_with("--shot-frames="):
			_shot_frames = int(a.substr(14))
		elif a == "--shot-stay":
			_shot_quit = false
	if _shot_path != "":
		set_process(true)


func _input(event: InputEvent) -> void:
	if not SettingsManager.developer_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle()


func toggle() -> void:
	visible_overlay = not visible_overlay
	if visible_overlay and overlay == null:
		_build()
	if overlay:
		overlay.visible = visible_overlay
	set_process(visible_overlay)
	if visible_overlay:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _build() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	overlay = PanelContainer.new()
	overlay.position = Vector2(12, 12)
	layer.add_child(overlay)
	var vb := VBoxContainer.new()
	overlay.add_child(vb)
	stats_label = Label.new()
	vb.add_child(stats_label)
	var chap := OptionButton.new()
	for c in GameState.CHAPTER_NAMES.keys():
		if c != GameState.Chapter.TITLE and c != GameState.Chapter.CREDITS:
			chap.add_item(GameState.CHAPTER_NAMES[c], c)
	chap.item_selected.connect(func(i: int) -> void: Director.start_from_chapter(chap.get_item_id(i)))
	vb.add_child(chap)
	for spec in [
		["Restart checkpoint", func() -> void: Director.restart_checkpoint()],
		["Summon Pickles", func() -> void: _summon_pickles()],
		["Reset Pickles", func() -> void: _reset_pickles()],
		["Trigger chain", func() -> void: _trigger_chain()],
		["Toggle hazard nodes", func() -> void: show_hazard_nodes = not show_hazard_nodes],
		["Survivors: all alive", func() -> void: _force_survivors(&"alive")],
		["Brenda dead", func() -> void: GameState.set_survivor(&"brenda", &"dead")],
		["Tiffany dead", func() -> void: GameState.set_survivor(&"tiffany", &"dead")],
		["Fire premonition", func() -> void: Events.premonition_started.emit(&"debug")],
	]:
		var b := Button.new()
		b.text = spec[0]
		b.pressed.connect(spec[1])
		vb.add_child(b)


func _process(delta: float) -> void:
	if _shot_path != "":
		_shot_frames -= 1
		if _shot_frames <= 0:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			print("SHOT ", _shot_path)
			_shot_path = ""
			if _shot_quit:
				get_tree().quit()
			return
	_timer += delta
	if _timer < 0.25 or stats_label == null:
		return
	_timer = 0.0
	var fps := Engine.get_frames_per_second()
	var draw := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objs := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var vram := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	var phys := Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	var pos := Vector3.ZERO
	if Director.player:
		pos = Director.player.global_position
	stats_label.text = "FPS %d  draws %d  prims %dk  objs %d  vram %.0fMB  phys %d  mem %.0fMB\nchapter %s beat %s  pos %s  time %.0fs" % [
		fps, draw, prims / 1000, objs, vram, phys, OS.get_static_memory_usage() / 1048576.0,
		GameState.CHAPTER_NAMES.get(GameState.chapter, "?"), GameState.beat, pos.snapped(Vector3.ONE * 0.1), GameState.play_time]


func _summon_pickles() -> void:
	if Director.pickles and Director.player and Director.pickles.has_method("teleport_near"):
		Director.pickles.teleport_near(Director.player.global_position)


func _reset_pickles() -> void:
	_summon_pickles()
	if Director.pickles and Director.pickles.has_method("command"):
		Director.pickles.command(&"come")


func _trigger_chain() -> void:
	for c in get_tree().get_nodes_in_group("accident_chains"):
		if c.has_method("start"):
			c.start()


func _force_survivors(status: StringName) -> void:
	for id in GameState.SURVIVOR_IDS:
		GameState.set_survivor(id, status)
