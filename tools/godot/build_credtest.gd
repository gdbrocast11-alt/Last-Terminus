extends Node
func run(_args: Array) -> void:
	await get_tree().process_frame
	var layer := CanvasLayer.new()
	layer.layer = 60
	get_tree().root.add_child(layer)
	var cs := CreditsScreen.new()
	layer.add_child(cs)
	cs.start(false)
	for i in 5:
		await get_tree().process_frame
	print("CRED cs.size=", cs.size, " vp=", cs.get_viewport_rect().size, " win=", get_window().size, " children=", cs.get_child_count())
	for c in cs.get_children():
		print("CRED child ", c.get_class(), " ", (c as Control).size, " ", (c as Control).position)
	get_tree().quit()
