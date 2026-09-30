class_name Escalator
extends Node3D
## Conveyor behaviour for the station escalator: carries the player (and Pickles)
## up the slope while running and plays the hum. `jam()` stops it with a grind.

var base := Vector3.ZERO
var top := Vector3.ZERO
var speed := 0.55
var running := true
var _area: Area3D
var _hum: AudioStreamPlayer3D
var _riders: Array[Node3D] = []


func setup(base_pos: Vector3, top_pos: Vector3, width := 1.6) -> void:
	base = base_pos
	top = top_pos
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2 | 4
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var dir := top - base
	bs.size = Vector3(width, 1.6, dir.length())
	cs.shape = bs
	_area.add_child(cs)
	add_child(_area)
	_area.global_position = (base + top) * 0.5 + Vector3(0, 0.9, 0)
	_area.look_at(_area.global_position + dir, Vector3.UP)
	_area.body_entered.connect(func(b: Node3D) -> void:
		if not _riders.has(b):
			_riders.append(b))
	_area.body_exited.connect(func(b: Node3D) -> void: _riders.erase(b))
	_hum = AudioManager.attach_loop(&"escalator_hum", self, -8.0, 22.0)
	if _hum:
		_hum.global_position = (base + top) * 0.5 + Vector3(0, 1.0, 0)


func _physics_process(delta: float) -> void:
	if not running:
		return
	var dir := (top - base).normalized()
	for r in _riders:
		if is_instance_valid(r) and r is CharacterBody3D and (r as CharacterBody3D).is_on_floor():
			r.global_position += dir * speed * delta


func jam() -> void:
	running = false
	if _hum and is_instance_valid(_hum):
		_hum.stop()
	AudioManager.play_sfx(&"escalator_jam", (base + top) * 0.5, 2.0)


func restart() -> void:
	running = true
	if _hum and is_instance_valid(_hum):
		_hum.play()
