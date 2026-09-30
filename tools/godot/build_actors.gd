extends Node
## Spawns a line-up of actors with given idle anims in a level and screenshots them.
## builder.tscn -- actors <level> <marker> <out.png> [anim ...]

func run(args: Array) -> void:
	await get_tree().process_frame
	Director.fade_rect.color.a = 0.0
	var lv: Node3D = (load("res://scenes/levels/%s.tscn" % args[0]) as PackedScene).instantiate()
	Director.world.add_child(lv)
	var xf: Transform3D = lv.marker(args[1])
	var pl := Director.spawn_player(xf)
	pl.rotation.y = 0.0
	Director.set_hud_visible(false)
	var ids := ["brenda", "dale", "tiffany", "gus", "marco", "mills", "kid", "stranger_a"]
	var anims: Array = args.slice(3) if args.size() > 3 else ["idle"]
	var i := 0
	for id in ids:
		var a := Actor.new()
		a.actor_id = StringName(id)
		a.idle_anim = anims[i % anims.size()]
		Director.world.add_child(a)
		a.global_position = xf.origin + Vector3(-7.0 + i * 2.0, 0.05, -4.0)
		a.rotation.y = 0.0
		i += 1
	get_tree().root.size = Vector2i(1280, 720)
	for k in 60:
		await get_tree().process_frame
	for a in get_tree().get_nodes_in_group("actors"):
		print("ACTOR ", (a as Actor).actor_id, " anim=", (a as Actor).current_anim(), " playing=", (a as Actor).anim.is_playing() if (a as Actor).anim else false)
	get_tree().root.get_texture().get_image().save_png(args[2])
	print("SHOT saved ", args[2])
