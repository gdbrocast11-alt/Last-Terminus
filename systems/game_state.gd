extends Node
## Authoritative runtime state for one playthrough: chapter, beat, flags,
## survivor fates and counters. Everything here is serialisable so that
## SaveManager can snapshot it at each checkpoint.

enum Chapter { TITLE, STATION, AFTERMATH, STORE, WELLNESS, GRAVES, YARD, FINALE, ENDING, CREDITS }

const CHAPTER_NAMES := {
	Chapter.TITLE: "Title",
	Chapter.STATION: "Terminus Station",
	Chapter.AFTERMATH: "Aftermath",
	Chapter.STORE: "Toolbert's Home Center",
	Chapter.WELLNESS: "The Alignment Pop-Up",
	Chapter.GRAVES: "Doctor Graves Explains Nothing",
	Chapter.YARD: "Halloran Yard",
	Chapter.FINALE: "Return to Terminus",
	Chapter.ENDING: "A Normal Evening",
	Chapter.CREDITS: "Credits",
}

const SURVIVOR_IDS: Array[StringName] = [&"brenda", &"dale", &"tiffany", &"mills", &"gus", &"marco", &"luis"]
## Survivors whose fate is decided by the player. Everyone else is protected
## by absurd luck (or, in Gus's case, by paperwork).
const MORTAL_IDS: Array[StringName] = [&"brenda", &"tiffany"]

var chapter: int = Chapter.TITLE
var beat: StringName = &"start"
var flags: Dictionary = {}
var survivors: Dictionary = {}
var counters: Dictionary = {}
var play_time: float = 0.0
var seen_premonitions: Dictionary = {}
var in_game: bool = false


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if in_game and not get_tree().paused:
		play_time += delta


func reset() -> void:
	chapter = Chapter.TITLE
	beat = &"start"
	flags = {}
	counters = {}
	seen_premonitions = {}
	play_time = 0.0
	survivors = {}
	for id in SURVIVOR_IDS:
		survivors[id] = &"alive"
	survivors[&"kevin"] = &"alive"


func set_flag(key: StringName, value: Variant = true) -> void:
	flags[key] = value


func has_flag(key: StringName) -> bool:
	return bool(flags.get(key, false))


func get_flag(key: StringName, default: Variant = null) -> Variant:
	return flags.get(key, default)


func bump(key: StringName, amount: int = 1) -> int:
	var v: int = int(counters.get(key, 0)) + amount
	counters[key] = v
	return v


func count(key: StringName) -> int:
	return int(counters.get(key, 0))


func set_survivor(id: StringName, status: StringName) -> void:
	survivors[id] = status
	Events.notebook_updated.emit()


func is_alive(id: StringName) -> bool:
	return survivors.get(id, &"alive") == &"alive"


func alive_count() -> int:
	var n := 0
	for id in SURVIVOR_IDS:
		if is_alive(id):
			n += 1
	return n


func snapshot() -> Dictionary:
	return {
		"chapter": chapter,
		"beat": String(beat),
		"flags": flags.duplicate(true),
		"survivors": _stringify(survivors),
		"counters": counters.duplicate(true),
		"seen_premonitions": seen_premonitions.duplicate(true),
		"play_time": play_time,
	}


func restore(data: Dictionary) -> void:
	reset()
	chapter = int(data.get("chapter", Chapter.STATION))
	beat = StringName(data.get("beat", "start"))
	flags = _sanitize_dict(data.get("flags", {}))
	counters = _sanitize_dict(data.get("counters", {}))
	seen_premonitions = _sanitize_dict(data.get("seen_premonitions", {}))
	play_time = float(data.get("play_time", 0.0))
	var s: Dictionary = data.get("survivors", {})
	for k in s.keys():
		survivors[StringName(k)] = StringName(s[k])


func _stringify(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		out[String(k)] = String(d[k])
	return out


## JSON round-trips turn StringName keys into Strings and ints into floats.
func _sanitize_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		var v: Variant = d[k]
		if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1.0e9:
			v = int(v)
		out[StringName(k)] = v
	return out
