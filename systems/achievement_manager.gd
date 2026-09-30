extends Node
## Local achievements (no platform SDK). Persisted globally in
## user://achievements.json so they survive New Game.

const PATH := "user://achievements.json"

const DEFS := {
	&"good_boy": {"name": "GOOD BOY", "desc": "Complete the game."},
	&"bad_owner": {"name": "BAD OWNER", "desc": "Attempt five lethal Pickles setups."},
	&"seriously": {"name": "SERIOUSLY?", "desc": "Attempt ten."},
	&"not_going_to_die": {"name": "HE'S NOT GOING TO DIE, MAN", "desc": "Persist far beyond reason."},
	&"safety_first": {"name": "SAFETY FIRST", "desc": "Watch Gus disarm three hazards without being asked."},
	&"not_like_that": {"name": "NOT LIKE THAT", "desc": "Prevent one accident and immediately cause another."},
	&"i_knew_it": {"name": "I KNEW IT", "desc": "Let Dale be right about something."},
	&"the_last_stop": {"name": "THE LAST STOP", "desc": "Survive the Terminus finale."},
	&"everybody_lives": {"name": "BODY COUNT: ZERO", "desc": "Finish the game with every survivor alive."},
	&"flamingo_truth": {"name": "THE FLAMINGO INCIDENT", "desc": "Learn what the bloody flamingo really was."},
	&"belly_rub": {"name": "BELLY RUB", "desc": "Pet Pickles ten times."},
	&"hazard_perspective": {"name": "HAZARD PERSPECTIVE", "desc": "Inspect thirty hazards. Eddie is fine."},
	&"paranoia_focus": {"name": "EYES OPEN", "desc": "Use danger intuition twenty times."},
	&"viral": {"name": "GOING VIRAL", "desc": "Brenda's video does numbers. Not the way she planned."},
	&"aligned": {"name": "PERFECTLY ALIGNED", "desc": "Get Tiffany through the pop-up with her brand intact."},
}

var unlocked: Dictionary = {}
var progress_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()


func is_unlocked(id: StringName) -> bool:
	return unlocked.has(String(id))


func unlock(id: StringName) -> void:
	if not DEFS.has(id) or is_unlocked(id):
		return
	unlocked[String(id)] = Time.get_unix_time_from_system()
	_save()
	Events.achievement_unlocked.emit(id)
	AudioManager.play_ui(&"achievement")


## Increment a persistent counter and unlock when it reaches `target`.
func progress(id: StringName, target: int, amount: int = 1) -> void:
	if is_unlocked(id):
		return
	var v: int = int(progress_counts.get(String(id), 0)) + amount
	progress_counts[String(id)] = v
	if v >= target:
		unlock(id)
	else:
		_save()


func reset_progress_counter(id: StringName) -> void:
	progress_counts.erase(String(id))


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		unlocked = parsed.get("unlocked", {})
		progress_counts = parsed.get("progress", {})


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked, "progress": progress_counts}))
