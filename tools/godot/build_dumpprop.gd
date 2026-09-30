extends Node
## builder.tscn -- dumpprop <chapter> <beat> <prop> [prop ...]  : prints the node tree + collision shapes of level props
func run(args: Array) -> void:
	await get_tree().process_frame
	GameState.reset()
	GameState.in_game = true
	await Director.load_chapter(int(args[0]), StringName(args[1]))
	for i in 60:
		await get_tree().physics_frame
	var lv: LevelRoot = Director.level as LevelRoot
	for n in args.slice(2):
		var node: Node3D = lv.prop(n)
		if node == null:
			print("DUMP ", n, " MISSING")
			continue
		print("DUMP ", n, " ", node.get_class(), " pos=", node.global_position, " layer=", node.get("collision_layer"))
		_walk(node, 1)
	get_tree().quit()


func _walk(n: Node, depth: int) -> void:
	for c in n.get_children():
		var extra := ""
		if c is CollisionShape3D:
			var cs := c as CollisionShape3D
			extra = " shape=" + str(cs.shape) + " gpos=" + str(cs.global_position)
			if cs.shape is BoxShape3D:
				extra += " size=" + str((cs.shape as BoxShape3D).size)
		if c is MeshInstance3D:
			extra = " aabb=" + str((c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb())
		print("DUMP ", "  ".repeat(depth), c.name, " ", c.get_class(), " inTree=", c.is_inside_tree(), " path=", c.get_path() if c.is_inside_tree() else "-", extra)
		if depth < 3:
			_walk(c, depth + 1)
