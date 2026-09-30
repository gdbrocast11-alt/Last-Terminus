extends Node
## Plays voiced dialogue with synchronized subtitles and lip-sync envelopes.
##
## Lines live in res://dialogue/lines.json (built by tools/audio/build_dialogue.py
## from dialogue/src/*.txt). Story lines can be awaited; barks are dropped if
## something more important is already speaking.

signal line_started(line_id: StringName, speaker: StringName, display_name: String, text: String, duration: float)
signal line_finished(line_id: StringName)
signal subtitles_cleared()

const LINES_PATH := "res://dialogue/lines.json"
const VOICE_DIR := "res://audio/voice/"
const ENV_RATE := 25.0

const DISPLAY_NAMES := {
	"eddie": "EDDIE", "brenda": "BRENDA", "dale": "DALE", "tiffany": "TIFFANY", "mills": "OFFICER MILLS",
	"gus": "GUS", "marco": "MARCO", "luis": "LUIS", "graves": "DR. GRAVES", "pa": "STATION PA",
	"news": "NEWS ANCHOR", "stranger": "STRANGER", "kid": "KID", "driver": "BUS DRIVER", "phone": "PHONE",
	"guard": "GUARD", "crowd": "CROWD", "clerk": "CLERK", "narrator": "",
}

var lines: Dictionary = {}
var _speakers: Dictionary = {}          # speaker id -> Node3D
var _voice_3d: AudioStreamPlayer3D
var _voice_2d: AudioStreamPlayer
var _current_id: StringName = &""
var _current_speaker: StringName = &""
var _current_priority := -1
var _current_env: String = ""
var _current_start_msec := 0
var _current_len := 0.0
var _serial := 0
var _skip_requested := false
var sequence_running := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_voice_3d = AudioStreamPlayer3D.new()
	_voice_3d.bus = &"Voice"
	_voice_3d.unit_size = 10.0
	_voice_3d.max_distance = 80.0
	_voice_3d.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_voice_3d)
	_voice_2d = AudioStreamPlayer.new()
	_voice_2d.bus = &"Voice"
	_voice_2d.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_voice_2d)
	load_lines()


func load_lines() -> void:
	lines = {}
	if not FileAccess.file_exists(LINES_PATH):
		push_warning("DialogueManager: %s missing" % LINES_PATH)
		return
	var txt := FileAccess.get_file_as_string(LINES_PATH)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		lines = parsed


func has_line(line_id: StringName) -> bool:
	return lines.has(String(line_id))


func line_text(line_id: StringName) -> String:
	return String(lines.get(String(line_id), {}).get("t", ""))


func register_speaker(speaker: StringName, node: Node3D) -> void:
	_speakers[speaker] = node


func unregister_speaker(speaker: StringName, node: Node3D) -> void:
	if _speakers.get(speaker) == node:
		_speakers.erase(speaker)


func is_busy() -> bool:
	return _current_id != &""


func current_speaker() -> StringName:
	return _current_speaker


## 0..1 mouth openness for the given speaker right now (0 if not speaking).
func mouth_level(speaker: StringName) -> float:
	if _current_id == &"" or speaker != _current_speaker or _current_env.is_empty():
		return 0.0
	var t := float(Time.get_ticks_msec() - _current_start_msec) / 1000.0
	var i := int(t * ENV_RATE)
	if i < 0 or i >= _current_env.length():
		return 0.0
	return float(_current_env.unicode_at(i) - 48) / 9.0


func skip_current() -> void:
	_skip_requested = true


func stop_all() -> void:
	_serial += 1
	_voice_2d.stop()
	_voice_3d.stop()
	var interrupted := _current_id
	if interrupted != &"":
		AudioManager.duck_end()
	_current_id = &""
	_current_speaker = &""
	_current_priority = -1
	subtitles_cleared.emit()
	if interrupted != &"":
		line_finished.emit(interrupted)


## Play one line. Await to wait for it to finish. priority: 0 bark, 1 normal, 2 story-critical.
func say(line_id: StringName, priority: int = 1, pause_after: float = 0.15) -> void:
	var key := String(line_id)
	if not lines.has(key):
		push_warning("DialogueManager: unknown line '%s'" % key)
		await get_tree().process_frame
		return
	if _current_id != &"":
		if priority == 0:
			return  # barks never interrupt or queue
		if priority > _current_priority:
			stop_all()
		else:
			while _current_id != &"":
				await line_finished
	_serial += 1
	var my_serial := _serial
	var d: Dictionary = lines[key]
	var speaker := StringName(d.get("s", "narrator"))
	var text: String = d.get("t", "")
	var dur: float = float(d.get("d", 0.0))
	var voice_path := "%s%s/%s.ogg" % [VOICE_DIR, speaker, key]
	var stream: AudioStream = null
	if ResourceLoader.exists(voice_path):
		stream = load(voice_path)
	if dur <= 0.05:
		dur = maxf(1.2, text.length() * 0.055)
	_current_id = line_id
	_current_speaker = speaker
	_current_priority = priority
	_current_env = String(d.get("env", ""))
	_current_start_msec = Time.get_ticks_msec()
	_current_len = dur
	_skip_requested = false
	AudioManager.duck_begin()
	var display := String(DISPLAY_NAMES.get(String(speaker), String(speaker).to_upper()))
	line_started.emit(line_id, speaker, display, text, dur)
	if stream != null:
		var node: Node3D = _speakers.get(speaker) if is_instance_valid(_speakers.get(speaker)) else null
		var use_3d := node != null and speaker != &"eddie" and not bool(d.get("flat", false))
		if use_3d:
			_voice_3d.stream = stream
			_voice_3d.global_position = node.global_position + Vector3(0, 1.6, 0)
			_voice_3d.play()
		else:
			_voice_2d.stream = stream
			_voice_2d.play()
	# Wait for playback (or the estimated duration if the voice file is missing).
	var t := 0.0
	while t < dur + 0.05 and my_serial == _serial and not _skip_requested:
		await get_tree().process_frame
		if not get_tree().paused:
			t += get_process_delta_time()
		if use_3d_follow(speaker) and _voice_3d.playing:
			var n: Node3D = _speakers.get(speaker) if is_instance_valid(_speakers.get(speaker)) else null
			if n:
				_voice_3d.global_position = n.global_position + Vector3(0, 1.6, 0)
	if my_serial != _serial:
		return  # superseded; whoever superseded us owns the cleanup
	_voice_2d.stop()
	_voice_3d.stop()
	_current_id = &""
	_current_speaker = &""
	_current_priority = -1
	AudioManager.duck_end()
	line_finished.emit(line_id)
	if pause_after > 0.0:
		await get_tree().create_timer(pause_after, false).timeout
	if not is_busy():
		subtitles_cleared.emit()


func use_3d_follow(speaker: StringName) -> bool:
	return speaker != &"eddie" and _speakers.has(speaker)


## Play a list of line ids in order. `gap` is extra silence between lines.
func say_seq(ids: Array, gap: float = 0.2, priority: int = 1) -> void:
	sequence_running = true
	for id in ids:
		await say(StringName(id), priority, gap)
	sequence_running = false


## Fire-and-forget bark. Dropped if anything is speaking.
func bark(line_id: StringName) -> void:
	if is_busy():
		return
	say(line_id, 0, 0.1)


func pick(prefix: String, count: int) -> StringName:
	return StringName("%s_%02d" % [prefix, 1 + randi() % count])
