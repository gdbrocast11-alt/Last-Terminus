extends Node
## One autosave slot with a rolling backup, plus a tiny meta file that
## remembers completion (unlocks chapter restart from the title screen).
## Writes are atomic (temp file + rename) and checksummed so a crash during
## a checkpoint can never leave a corrupt save that blocks Continue.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const TEMP_PATH := "user://save.tmp"
const META_PATH := "user://meta.json"
const VERSION := 3

var meta: Dictionary = {"completed": false, "max_chapter": 1, "best_time": 0.0}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_meta()


func has_save() -> bool:
	return not read_save().is_empty()


func checkpoint(beat: StringName) -> void:
	GameState.beat = beat
	# The state is stored as a JSON string so the checksum survives the
	# int->float conversion that a JSON round trip would otherwise cause.
	var state_json := JSON.stringify(GameState.snapshot())
	var payload := {"version": VERSION, "state_json": state_json, "checksum": state_json.hash(),
		"saved_at": Time.get_datetime_string_from_system()}
	_write_atomic(JSON.stringify(payload))
	if GameState.chapter > int(meta.get("max_chapter", 1)):
		meta["max_chapter"] = GameState.chapter
		_save_meta()
	Events.checkpoint_saved.emit(GameState.chapter, beat)


func read_save() -> Dictionary:
	for path in [SAVE_PATH, BACKUP_PATH]:
		var d := _read_file(path)
		if not d.is_empty():
			return d
	return {}


func load_into_state() -> bool:
	var d := read_save()
	if d.is_empty():
		return false
	GameState.restore(d)
	return true


func delete_save() -> void:
	for p in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func mark_completed() -> void:
	meta["completed"] = true
	meta["max_chapter"] = GameState.Chapter.CREDITS
	var best: float = float(meta.get("best_time", 0.0))
	if best <= 0.0 or GameState.play_time < best:
		meta["best_time"] = GameState.play_time
	_save_meta()


func game_completed() -> bool:
	return bool(meta.get("completed", false))


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not parsed.has("state_json") or not parsed.has("checksum"):
		return {}
	var state_json: String = String(parsed["state_json"])
	if int(parsed.get("checksum", -1)) != state_json.hash():
		push_warning("SaveManager: checksum mismatch in %s" % path)
		return {}
	var state: Variant = JSON.parse_string(state_json)
	return state if state is Dictionary else {}


func _write_atomic(text: String) -> void:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % TEMP_PATH)
		return
	f.store_string(text)
	f.close()
	var abs_save := ProjectSettings.globalize_path(SAVE_PATH)
	var abs_bak := ProjectSettings.globalize_path(BACKUP_PATH)
	var abs_tmp := ProjectSettings.globalize_path(TEMP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(abs_save, abs_bak)
	DirAccess.rename_absolute(abs_tmp, abs_save)


func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	if parsed is Dictionary:
		for k in parsed.keys():
			meta[k] = parsed[k]


func _save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta))
