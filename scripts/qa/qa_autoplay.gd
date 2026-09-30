extends Node
## Automated playthrough bot. Drives a New Game (or a chosen chapter) by firing the
## QA hooks each chapter controller registers (`qa_add`), watches for stalls and
## reports timings. Usage:
##   godot --path . --rendering-driver vulkan -- --qa-autoplay [--qa-from=N] [--qa-until=N] [--qa-speed=3] [--qa-shots=/dir]
## Exit code 0 = reached the target chapter / credits, 2 = stalled, 3 = script error budget exceeded.

var t := 0.0
var _tick := 0.0
var _last_progress := 0.0
var _last_chapter := -1
var _last_beat := ""
var from_chapter := 1
var until_chapter := 99
var shots_dir := ""
var hooks_fired := 0
var stall_limit := 150.0
var _started := false
var _chapter_start_t := 0.0
var _summary: Array[String] = []
var shot_times: Array[float] = []
var start_beat := ""
var full := false
var _credits_seen := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--qa-from="):
			from_chapter = int(a.substr(10))
		elif a.begins_with("--qa-until="):
			until_chapter = int(a.substr(11))
		elif a.begins_with("--qa-speed="):
			Engine.time_scale = float(a.substr(11))
		elif a.begins_with("--qa-shots="):
			shots_dir = a.substr(11)
		elif a.begins_with("--qa-shot-times="):
			for x in a.substr(16).split(","):
				shot_times.append(float(x))
		elif a.begins_with("--qa-beat="):
			start_beat = a.substr(10)
		elif a == "--qa-full":
			full = true
		elif a == "--qa-nointervene":
			GameState.set_flag(&"qa_nointervene", true)
		elif a.begins_with("--qa-stall="):
			stall_limit = float(a.substr(11))
	process_mode = Node.PROCESS_MODE_ALWAYS
	AccidentChain.trace = true
	print("QA start from=%d until=%d speed=%.1f" % [from_chapter, until_chapter, Engine.time_scale])
	Events.achievement_unlocked.connect(func(id: StringName) -> void: print("QA achievement: ", id))
	Events.chapter_changed.connect(_on_chapter)
	Events.chain_started.connect(func(id: StringName) -> void: print("QA chain start ", id))
	Events.chain_step_blocked.connect(func(id: StringName, sid: StringName) -> void: print("QA chain BLOCKED ", id, ".", sid))
	Events.chain_finished.connect(func(id: StringName, r: Dictionary) -> void: print("QA chain finished ", id, " deaths=", r.deaths, " blocked=", r.blocked, " saved=", r.saved))
	Events.npc_died.connect(func(id: StringName, cause: StringName) -> void: print("QA npc died ", id, " ", cause))
	Events.player_died.connect(func(reason: StringName) -> void: print("QA player died ", reason))
	await get_tree().process_frame
	var keep_flags: Dictionary = GameState.flags.duplicate()
	if start_beat != "":
		GameState.reset()
		GameState.flags = keep_flags
		GameState.in_game = true
		Director.load_chapter(from_chapter, StringName(start_beat))
	elif from_chapter <= 1:
		Director.start_new_game()
	else:
		Director.start_from_chapter(from_chapter)
	_started = true


func _on_chapter(ch: int) -> void:
	var name_: String = GameState.CHAPTER_NAMES.get(ch, "?")
	var line := "QA chapter -> %d %s at t=%.1fs (prev chapter took %.1fs)" % [ch, name_, t, t - _chapter_start_t]
	print(line)
	_summary.append(line)
	_chapter_start_t = t
	_last_progress = t
	if ch == GameState.Chapter.CREDITS:
		_credits_seen = true
		if not full:
			_finish(0)
		return
	if ch > until_chapter:
		_finish(0)


func _process(delta: float) -> void:
	if not _started:
		return
	t += delta
	_tick += delta
	if not shot_times.is_empty() and t >= shot_times[0]:
		var st: float = shot_times.pop_front()
		_shot("t%03d" % int(st))
	if _tick < 0.4:
		return
	_tick = 0.0
	if GameState.chapter != _last_chapter or String(GameState.beat) != _last_beat:
		_last_chapter = GameState.chapter
		_last_beat = String(GameState.beat)
		_last_progress = t
		print("QA state chapter=%d beat=%s t=%.1f" % [_last_chapter, _last_beat, t])
	if _credits_seen and full and not GameState.in_game:
		print("QA reached the title screen after credits (completed=%s)" % SaveManager.game_completed())
		_finish(0)
		return
	var ch := Director.chapter_node as Chapter
	if ch == null or Director.transitioning:
		return
	# long lines never block the bot
	if DialogueManager.is_busy() and t - _last_progress > 25.0:
		DialogueManager.skip_current()
	for h: Dictionary in ch.qa:
		if h.done:
			continue
		if bool((h.cond as Callable).call()):
			h.done = true
			hooks_fired += 1
			_last_progress = t
			print("QA hook [%s] t=%.1f" % [h.name, t])
			(h.act as Callable).call()
			break
	if t - _last_progress > stall_limit:
		_report_stall(ch)
		_finish(2)


func _report_stall(ch: Chapter) -> void:
	print("QA STALL in chapter %d beat %s. objective='%s' busy=%s" % [GameState.chapter, GameState.beat, SequenceManager.objective(), DialogueManager.is_busy()])
	for c in ch.get_children():
		if c is AccidentChain:
			print("QA chain %s: %s" % [c.name, ", ".join((c as AccidentChain).debug_lines())])
	for h: Dictionary in ch.qa:
		print("QA   hook %s done=%s cond=%s" % [h.name, h.done, (h.cond as Callable).call()])
	if shots_dir != "":
		_shot("stall")


func _shot(tag: String) -> void:
	if shots_dir == "":
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	get_viewport().get_texture().get_image().save_png("%s/ch%d_%s.png" % [shots_dir, GameState.chapter, tag])


func _finish(code: int) -> void:
	print("QA SUMMARY (%d hooks fired, %.1fs game time, exit %d)" % [hooks_fired, t, code])
	for l in _summary:
		print("  ", l)
	get_tree().quit(code)
