extends Node
## Headless build runner. Runs inside the normal game tree so autoloads exist.
##   godot --headless --path . res://tools/godot/builder.tscn -- <task> [args...]
## Tasks map to res://tools/godot/build_<task>.gd, each implementing run(args).

func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("builder: no task given")
		get_tree().quit(1)
		return
	var path := "res://tools/godot/build_%s.gd" % args[0]
	var script := load(path) as GDScript
	if script == null:
		push_error("builder: cannot load " + path)
		get_tree().quit(1)
		return
	var inst: Node = script.new()
	if inst == null:
		push_error("builder: script failed to compile: " + path)
		get_tree().quit(1)
		return
	get_tree().create_timer(900.0).timeout.connect(func() -> void:
		push_error("builder: watchdog timeout")
		get_tree().quit(2))
	add_child(inst)
	await inst.run(args.slice(1))
	get_tree().quit()
