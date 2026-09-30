extends Node
## Kills the player mid-chapter and checks the checkpoint respawn.  builder.tscn -- diecheck <chapter> <beat>

func run(args: Array) -> void:
	await get_tree().process_frame
	GameState.reset()
	GameState.in_game = true
	var ch := int(args[0])
	var beat := StringName(args[1])
	SaveManager.delete_save()
	await Director.load_chapter(ch, beat)
	for i in 240:
		await get_tree().physics_frame
	print("DIE before: chapter=", GameState.chapter, " beat=", GameState.beat, " player=", is_instance_valid(Director.player))
	var old := Director.player
	Director.player.die(&"test")
	for i in 600:
		await get_tree().physics_frame
	var p := Director.player
	print("DIE after: player valid=", is_instance_valid(p), " same=", p == old, " dead=", p.dead if is_instance_valid(p) else "n/a", " chapter=", GameState.chapter, " beat=", GameState.beat, " input_locked=", Director.input_locked, " fade=", Director.fade_rect.color.a)
