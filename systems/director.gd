extends Node
## Scene flow. Owns the World container (current level + chapter controller +
## player + Pickles), persistent UI layers, fades, loading and checkpoint restore.

const PLAYER_SCENE := "res://scenes/player.tscn"
const PICKLES_SCENE := "res://scenes/pickles.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

const CHAPTER_LEVELS := {
	GameState.Chapter.STATION: "res://scenes/levels/station.tscn",
	GameState.Chapter.AFTERMATH: "res://scenes/levels/apartment.tscn",
	GameState.Chapter.STORE: "res://scenes/levels/store.tscn",
	GameState.Chapter.WELLNESS: "res://scenes/levels/wellness.tscn",
	GameState.Chapter.GRAVES: "res://scenes/levels/apartment.tscn",
	GameState.Chapter.YARD: "res://scenes/levels/yard.tscn",
	GameState.Chapter.FINALE: "res://scenes/levels/station.tscn",
	GameState.Chapter.ENDING: "res://scenes/levels/apartment.tscn",
}
const CHAPTER_SCRIPTS := {
	GameState.Chapter.STATION: "res://scripts/chapters/ch1_station.gd",
	GameState.Chapter.AFTERMATH: "res://scripts/chapters/ch2_aftermath.gd",
	GameState.Chapter.STORE: "res://scripts/chapters/ch3_store.gd",
	GameState.Chapter.WELLNESS: "res://scripts/chapters/ch4_wellness.gd",
	GameState.Chapter.GRAVES: "res://scripts/chapters/ch5_graves.gd",
	GameState.Chapter.YARD: "res://scripts/chapters/ch6_yard.gd",
	GameState.Chapter.FINALE: "res://scripts/chapters/ch7_finale.gd",
	GameState.Chapter.ENDING: "res://scripts/chapters/ch8_ending.gd",
}

signal level_ready(level: Node)
signal loading_progress(ratio: float)

var world: Node3D
var ui_layer: CanvasLayer
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var loading_label: Label
var hud: Control
var pause_menu: Control
var notebook: Control
var title_card: Control

var level: Node = null
var chapter_node: Node = null
var player: CharacterBody3D = null
var pickles: CharacterBody3D = null
var current_scene_path := ""
var transitioning := false
var pause_locked := false
var input_locked := false
var _fade_tween: Tween
var _restarting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = Node3D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.layer = 10
	add_child(ui_layer)
	fade_layer = CanvasLayer.new()
	fade_layer.name = "Fade"
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	loading_label = Label.new()
	loading_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	loading_label.position = Vector2(-320, -70)
	loading_label.modulate.a = 0.0
	fade_layer.add_child(loading_label)
	Events.fade_requested.connect(func(to_black: bool, s: float) -> void: fade(to_black, s))
	Events.player_died.connect(_on_player_died)
	_build_ui()


func _build_ui() -> void:
	var scripts := {
		"hud": "res://scripts/ui/hud.gd",
		"notebook": "res://scripts/ui/notebook_ui.gd",
		"pause": "res://scripts/ui/pause_menu.gd",
		"subtitles": "res://scripts/ui/subtitles.gd",
		"toasts": "res://scripts/ui/toasts.gd",
		"title_card": "res://scripts/ui/title_card.gd",
	}
	for key in scripts.keys():
		var path: String = scripts[key]
		if not ResourceLoader.exists(path):
			continue
		var c: Control = (load(path) as GDScript).new()
		c.name = String(key).capitalize().replace(" ", "")
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_layer.add_child(c)
		match key:
			"hud": hud = c
			"notebook": notebook = c
			"pause": pause_menu = c
			"title_card": title_card = c
	set_hud_visible(false)


func set_hud_visible(v: bool) -> void:
	if hud:
		hud.visible = v


# --------------------------------------------------------------------------
# fades
# --------------------------------------------------------------------------
func fade(to_black: bool, seconds: float = 0.6) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if seconds <= 0.0:
		fade_rect.color.a = 1.0 if to_black else 0.0
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "color:a", 1.0 if to_black else 0.0, seconds)
	await _fade_tween.finished


func fade_out_in(seconds: float = 0.4, hold: float = 0.2) -> void:
	await fade(true, seconds)
	await get_tree().create_timer(hold).timeout
	await fade(false, seconds)


# --------------------------------------------------------------------------
# game flow
# --------------------------------------------------------------------------
func start_new_game() -> void:
	GameState.reset()
	SaveManager.delete_save()
	GameState.in_game = true
	await load_chapter(GameState.Chapter.STATION, &"start")


func continue_game() -> bool:
	if not SaveManager.load_into_state():
		return false
	GameState.in_game = true
	await load_chapter(GameState.chapter, GameState.beat)
	return true


func start_from_chapter(chapter: int) -> void:
	## Chapter restart after completion / developer chapter select.
	var keep_flags := GameState.flags.duplicate(true)
	GameState.reset()
	if chapter >= GameState.Chapter.WELLNESS:
		GameState.set_survivor(&"brenda", &"alive")
	GameState.flags = keep_flags if OS.has_feature("editor") else {}
	GameState.in_game = true
	await load_chapter(chapter, &"start")


func load_chapter(chapter: int, beat: StringName = &"start") -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().paused = false
	GameState.chapter = chapter
	GameState.beat = beat
	GameState.in_game = true
	Events.chapter_changed.emit(chapter)
	await fade(true, 0.5)
	_clear_level()
	set_hud_visible(false)
	DialogueManager.stop_all()
	var path: String = CHAPTER_LEVELS.get(chapter, "")
	if path.is_empty():
		transitioning = false
		return
	var packed := await _load_scene(path, GameState.CHAPTER_NAMES.get(chapter, ""))
	if packed == null:
		push_error("Director: failed to load %s" % path)
		transitioning = false
		return
	level = packed.instantiate()
	world.add_child(level)
	current_scene_path = path
	SettingsManager.apply_to_scene()
	var script_path: String = CHAPTER_SCRIPTS.get(chapter, "")
	if not script_path.is_empty() and ResourceLoader.exists(script_path):
		chapter_node = (load(script_path) as GDScript).new()
		chapter_node.name = "Chapter"
		chapter_node.set("level", level)
		chapter_node.set("start_beat", beat)
		world.add_child(chapter_node)
	transitioning = false
	level_ready.emit(level)


func _load_scene(path: String, label: String) -> PackedScene:
	loading_label.text = "LOADING  " + label.to_upper()
	loading_label.modulate.a = 1.0
	ResourceLoader.load_threaded_request(path)
	var progress: Array = []
	while true:
		var st := ResourceLoader.load_threaded_get_status(path, progress)
		if progress.size() > 0:
			loading_progress.emit(progress[0])
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loading_label.modulate.a = 0.0
			return null
		await get_tree().process_frame
	var res := ResourceLoader.load_threaded_get(path) as PackedScene
	loading_label.modulate.a = 0.0
	return res


func _clear_level() -> void:
	if chapter_node and is_instance_valid(chapter_node):
		chapter_node.queue_free()
	chapter_node = null
	if level and is_instance_valid(level):
		level.queue_free()
	level = null
	player = null
	pickles = null
	for c in world.get_children():
		c.queue_free()
	input_locked = false
	pause_locked = false


## Swap to another level scene inside the same chapter (e.g. apartment -> street).
func change_level(path: String, label: String = "") -> void:
	await fade(true, 0.5)
	if chapter_node:
		chapter_node.queue_free()
		chapter_node = null
	if level:
		level.queue_free()
	for c in world.get_children():
		c.queue_free()
	player = null
	pickles = null
	var packed := await _load_scene(path, label)
	level = packed.instantiate()
	world.add_child(level)
	current_scene_path = path
	SettingsManager.apply_to_scene()
	level_ready.emit(level)


func go_to_title() -> void:
	get_tree().paused = false
	GameState.in_game = false
	set_hud_visible(false)
	DialogueManager.stop_all()
	AudioManager.set_muffled(0.0, 0.1)
	await fade(true, 0.4)
	_clear_level()
	await get_tree().process_frame
	get_tree().change_scene_to_file(TITLE_SCENE)
	await get_tree().process_frame
	await fade(false, 0.8)


func restart_checkpoint() -> void:
	if _restarting:
		return
	_restarting = true
	get_tree().paused = false
	var d := SaveManager.read_save()
	if d.is_empty():
		# No checkpoint yet in this chapter: restart chapter start.
		var ch := GameState.chapter
		GameState.beat = &"start"
		await load_chapter(ch, &"start")
	else:
		GameState.restore(d)
		await load_chapter(GameState.chapter, GameState.beat)
	_restarting = false


func _on_player_died(_reason: StringName) -> void:
	pass  # the chapter controller decides how to present it; see respawn_after_death()


## Shared death presentation: brief freeze, cut to red, reload checkpoint.
func respawn_after_death(caption: String = "") -> void:
	if _restarting:
		return
	input_locked = true
	if title_card and caption != "":
		Events.title_card_requested.emit(caption, 1.6)
	await get_tree().create_timer(1.2).timeout
	await restart_checkpoint()


# --------------------------------------------------------------------------
# spawning
# --------------------------------------------------------------------------
func spawn_player(xform: Transform3D) -> CharacterBody3D:
	if player and is_instance_valid(player):
		player.queue_free()
	var scene := load(PLAYER_SCENE) as PackedScene
	player = scene.instantiate()
	world.add_child(player)
	player.global_transform = xform
	set_hud_visible(true)
	return player


func spawn_pickles(xform: Transform3D) -> CharacterBody3D:
	if pickles and is_instance_valid(pickles):
		pickles.queue_free()
	var scene := load(PICKLES_SCENE) as PackedScene
	pickles = scene.instantiate()
	world.add_child(pickles)
	pickles.global_transform = xform
	return pickles


func lock_input(v: bool) -> void:
	input_locked = v


# --------------------------------------------------------------------------
# pause
# --------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and GameState.in_game and not transitioning and not pause_locked:
		if pause_menu and pause_menu.has_method("toggle"):
			pause_menu.toggle()
			get_viewport().set_input_as_handled()
