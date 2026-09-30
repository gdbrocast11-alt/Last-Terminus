extends Node
## Entry scene: waits one frame for the autoloads, then opens the title screen.

func _ready() -> void:
	await get_tree().process_frame
	if "--qa-autoplay" in OS.get_cmdline_user_args() or "--qa-autoplay" in OS.get_cmdline_args():
		var qa := load("res://scripts/qa/qa_autoplay.gd") as GDScript
		if qa:
			add_child(qa.new())
			return
	Director.go_to_title()
