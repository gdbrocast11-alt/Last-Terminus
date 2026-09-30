extends Node
## Builds tiny scenes for the player and Pickles (their nodes are constructed in code).
## builder.tscn -- core

func run(_args: Array) -> void:
	var p := CharacterBody3D.new()
	p.name = "Player"
	p.set_script(load("res://scripts/player/player.gd"))
	BuildUtil.save_scene(p, "res://scenes/player.tscn")
	p.free()
	var d := CharacterBody3D.new()
	d.name = "Pickles"
	d.set_script(load("res://scripts/pickles/pickles.gd"))
	BuildUtil.save_scene(d, "res://scenes/pickles.tscn")
	d.free()
	print("BUILD core")
