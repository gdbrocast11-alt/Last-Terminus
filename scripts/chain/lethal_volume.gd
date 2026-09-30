class_name LethalVolume
extends Area3D
## A box that hurts people while armed. Containment is tested geometrically (not
## through physics overlaps) so the outcome is deterministic. Pickles is
## exempt: whatever happens to him is resolved by authored "luck" gags.

signal victim(node: Node)

@export var size := Vector3(2, 2, 2)
var armed := false
var cause: StringName = &"accident"
var style := "back"
var _left := 0.0
var _hit: Dictionary = {}


func _ready() -> void:
	collision_layer = 64
	collision_mask = 0
	monitoring = false
	add_to_group("lethal_volumes")
	if get_child_count() == 0:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		add_child(cs)
	else:
		for c in get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
				size = ((c as CollisionShape3D).shape as BoxShape3D).size


func arm(seconds: float, why: StringName = &"accident", death_style := "back") -> void:
	armed = true
	_left = seconds
	cause = why
	style = death_style
	_hit.clear()


func disarm() -> void:
	armed = false


func contains(n: Node3D) -> bool:
	var local := to_local(n.global_position + Vector3(0, 0.9, 0))
	var h := size * 0.5
	return absf(local.x) <= h.x and absf(local.y) <= h.y + 0.5 and absf(local.z) <= h.z


func _physics_process(delta: float) -> void:
	if not armed:
		return
	_left -= delta
	if _left <= 0.0:
		armed = false
		return
	for a in get_tree().get_nodes_in_group("actors"):
		var ac := a as Actor
		if ac.alive and not ac.protected and not _hit.has(ac) and contains(ac):
			_hit[ac] = true
			ac.die(cause, style)
			FX.blood(ac.global_position)
			victim.emit(ac)
	var pl := Director.player
	if pl and not pl.dead and not _hit.has(pl) and contains(pl):
		_hit[pl] = true
		pl.die(cause)
		victim.emit(pl)
	var pk := Director.pickles
	if pk and not _hit.has(pk) and contains(pk):
		_hit[pk] = true
		(pk as Pickles).survive(cause)
