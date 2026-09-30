extends Node
## builder.tscn -- savetest : checkpoint round trip, corrupted-save fallback, Continue into a mid-game beat.

var _fails := 0


func _check(name: String, ok: bool, extra := "") -> void:
	print("SAVE ", "ok   " if ok else "FAIL ", name, " ", extra)
	if not ok:
		_fails += 1


func run(_args: Array) -> void:
	await get_tree().process_frame
	SaveManager.delete_save()
	GameState.reset()
	GameState.in_game = true
	GameState.chapter = GameState.Chapter.STORE
	GameState.set_survivor(&"brenda", &"dead")
	GameState.set_flag(&"custom_flag", 7)
	SequenceManager.set_sequence(["kevin", "brenda", "eddie"])
	SequenceManager.add_clue(&"sequence", "THE SEQUENCE", "Kevin. Brenda. Me, last.")
	GameState.bump(&"deaths", 3)
	SaveManager.checkpoint(&"prep")
	_check("has_save", SaveManager.has_save())

	GameState.reset()
	_check("reset clears", GameState.survivors[&"brenda"] == &"alive" and GameState.chapter == GameState.Chapter.TITLE)
	_check("load_into_state", SaveManager.load_into_state())
	_check("chapter", GameState.chapter == GameState.Chapter.STORE)
	_check("beat", GameState.beat == &"prep", str(GameState.beat))
	_check("survivor", GameState.survivors[&"brenda"] == &"dead")
	_check("flag int", int(GameState.get_flag(&"custom_flag", 0)) == 7)
	_check("sequence", SequenceManager.sequence().size() == 3)
	_check("clue", SequenceManager.has_clue(&"sequence"))
	_check("counter", GameState.count(&"deaths") == 3)

	# second checkpoint rolls the first into the backup; corrupt the primary and Continue must still work
	GameState.chapter = GameState.Chapter.WELLNESS
	SaveManager.checkpoint(&"keynote")
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	GameState.reset()
	_check("corrupt primary falls back to backup", SaveManager.load_into_state() and GameState.chapter == GameState.Chapter.STORE, str(GameState.chapter))

	# tampered checksum
	SaveManager.checkpoint(&"again")
	var txt := FileAccess.get_file_as_string(SaveManager.SAVE_PATH).replace("STORE", "x").replace("\"chapter\\\":3", "\"chapter\\\":9")
	var f2 := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f2.store_string(txt)
	f2.close()
	var d := SaveManager.read_save()
	_check("tamper never yields chapter 9", d.is_empty() or int(d.get("chapter", 0)) != 9)

	# Continue really loads the chapter
	SaveManager.delete_save()
	var cg_none: bool = await Director.continue_game()
	_check("no save after delete", not SaveManager.has_save() and not cg_none)
	GameState.reset()
	GameState.chapter = GameState.Chapter.GRAVES
	GameState.set_survivor(&"tiffany", &"dead")
	SaveManager.checkpoint(&"theory")
	GameState.reset()
	var ok: bool = await Director.continue_game()
	for i in 240:
		await get_tree().physics_frame
	_check("continue_game", ok, "chapter=" + str(GameState.chapter) + " beat=" + str(GameState.beat))
	_check("continue restored tiffany dead", GameState.survivors[&"tiffany"] == &"dead")
	_check("continue built the apartment", Director.level != null and Director.player != null)
	SaveManager.delete_save()
	print("SAVETEST failures: ", _fails)
	get_tree().quit()
