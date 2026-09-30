extends Node
## Title scene shell. builder.tscn -- ui_scenes
func run(_args: Array) -> void:
	var n := Node3D.new()
	n.name = "Title"
	n.set_script(load("res://scripts/ui/title_screen.gd"))
	BuildUtil.save_scene(n, "res://scenes/title.tscn")
	n.free()
	print("BUILD ui_scenes")
