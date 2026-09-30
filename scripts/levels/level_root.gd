class_name LevelRoot
extends Node3D
## Root of every generated level scene. Gives chapter scripts convenient lookup
## of markers, props and decor groups, and hooks graphics settings.

var _cache: Dictionary = {}


func _ready() -> void:
	add_to_group("level")
	SettingsManager.apply_to_scene()


func marker(marker_name: String) -> Transform3D:
	var m := get_node_or_null("Markers/" + marker_name) as Marker3D
	if m == null:
		push_warning("LevelRoot: missing marker " + marker_name)
		return Transform3D(Basis.IDENTITY, global_position)
	return m.global_transform


func marker_pos(marker_name: String) -> Vector3:
	return marker(marker_name).origin


func has_marker(marker_name: String) -> bool:
	return get_node_or_null("Markers/" + marker_name) != null


func prop(prop_name: String) -> Node3D:
	if _cache.has(prop_name) and is_instance_valid(_cache[prop_name]):
		return _cache[prop_name]
	var n := find_child(prop_name, true, false) as Node3D
	_cache[prop_name] = n
	if n == null:
		push_warning("LevelRoot: missing prop " + prop_name)
	return n


func prop_comp(prop_name: String) -> PropComponent:
	var p := prop(prop_name)
	return p.get_node_or_null("Prop") as PropComponent if p else null


func light(light_name: String) -> Light3D:
	return get_node_or_null("Lights/" + light_name) as Light3D


func set_deco(group: String, on: bool) -> void:
	for n in get_tree().get_nodes_in_group("deco_" + group):
		if not is_ancestor_of(n):
			continue
		var node := n as Node3D
		node.visible = on
		node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		for c in node.find_children("*", "CollisionObject3D", true, false) + ([node] if node is CollisionObject3D else []):
			(c as CollisionObject3D).collision_layer = 0 if not on else (1 if c is StaticBody3D else 16)


func surface_at(pos: Vector3) -> String:
	return "concrete"
