extends Node
## Eddie's notebook data: the current objective, THE SEQUENCE (his handwritten
## order of who is next), discovered clues and survivor bios. The data itself is
## stored inside GameState.flags so checkpoints capture it for free.

const SURVIVOR_INFO := {
	&"brenda": {"name": "Brenda Bolt", "bio": "DIY streamer. Films everything. Actually good with tools."},
	&"dale": {"name": "Dale Krieger", "bio": "Conspiracy guy. Usually wrong. Records everything."},
	&"tiffany": {"name": "Tiffany Vale", "bio": "Wellness brand. Believes in her energy. Brand voice: relentless."},
	&"mills": {"name": "Officer Mills", "bio": "Transit security. Threw me out. Accidentally saved a lot of people."},
	&"gus": {"name": "Gus Pemberton", "bio": "Retired safety inspector. Cannot be killed by anything he has already fixed."},
	&"marco": {"name": "Marco", "bio": "Competitive. Keeps score."},
	&"luis": {"name": "Luis", "bio": "Competitive. Disputes the score."},
}

const K_CLUES := &"_clues"
const K_SEQUENCE := &"_sequence"
const K_OBJECTIVE := &"_objective"
const K_SEQ_UNRELIABLE := &"_seq_unreliable"


func objective() -> String:
	return String(GameState.get_flag(K_OBJECTIVE, ""))


func set_objective(text: String) -> void:
	GameState.set_flag(K_OBJECTIVE, text)
	Events.objective_changed.emit(text)


func clear_objective() -> void:
	set_objective("")


func sequence() -> Array:
	return GameState.get_flag(K_SEQUENCE, [])


func set_sequence(order: Array) -> void:
	GameState.set_flag(K_SEQUENCE, order.duplicate())
	Events.notebook_updated.emit()


## After the wellness pop-up, the diagram stops being trustworthy.
func mark_sequence_unreliable(value: bool = true) -> void:
	GameState.set_flag(K_SEQ_UNRELIABLE, value)
	Events.notebook_updated.emit()


func sequence_unreliable() -> bool:
	return GameState.has_flag(K_SEQ_UNRELIABLE)


func clues() -> Array:
	return GameState.get_flag(K_CLUES, [])


func has_clue(clue_id: StringName) -> bool:
	for c in clues():
		if c.get("id", "") == String(clue_id):
			return true
	return false


func add_clue(clue_id: StringName, title: String, text: String) -> void:
	if has_clue(clue_id):
		return
	var arr: Array = clues().duplicate()
	arr.append({"id": String(clue_id), "title": title, "text": text})
	GameState.set_flag(K_CLUES, arr)
	Events.notebook_updated.emit()
	Events.hint_requested.emit("Notebook updated: " + title, 3.0)
	AudioManager.play_ui(&"notebook_scribble")


func survivor_status(id: StringName) -> String:
	var s: StringName = GameState.survivors.get(id, &"alive")
	match s:
		&"alive": return "ALIVE"
		&"dead": return "DECEASED"
		&"injured": return "SHAKEN"
	return String(s).to_upper()
