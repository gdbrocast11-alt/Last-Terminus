class_name BuildUtil
extends RefCounted
## Helpers shared by the headless scene builders (tools/godot/build_*.gd).

const MAT_DIR := "res://materials/"
static var _mats: Dictionary = {}


static func material(mat_name: String) -> Material:
	if _mats.has(mat_name):
		return _mats[mat_name]
	var p := MAT_DIR + mat_name + ".tres"
	var m: Material = load(p) if ResourceLoader.exists(p) else null
	_mats[mat_name] = m
	return m


## Recursively assign library materials to every mesh surface by material name.
static func apply_materials(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var nm := src.resource_name if src else ""
			var lib := material(nm)
			if lib:
				mi.set_surface_override_material(s, lib)
			elif nm != "":
				push_warning("BuildUtil: no library material '%s'" % nm)


static func combined_aabb(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var local: Transform3D = _relative_xform(mi, root)
		var bb: AABB = local * mi.get_aabb()
		if first:
			out = bb
			first = false
		else:
			out = out.merge(bb)
	return out


static func _relative_xform(n: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


static func own_recursive(node: Node, owner_node: Node) -> void:
	## Own every descendant. Nodes that come from an instanced glb are made "editable children" of the
	## scene being saved so that overrides applied to them (library materials!) survive packing.
	for c in node.get_children():
		c.owner = owner_node
		if c.scene_file_path != "" and c != owner_node:
			owner_node.set_editable_instance(c, true)
		own_recursive(c, owner_node)


static func save_scene(root: Node, path: String) -> int:
	own_recursive(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %s: %d" % [path, err])
		return err
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return ResourceSaver.save(ps, path)


static func mesh_shape(root: Node3D, convex: bool, trimesh: bool) -> Shape3D:
	var merged := ArrayMesh.new()
	# Merge all surfaces into one mesh in root space.
	var faces := PackedVector3Array()
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var xf := _relative_xform(mi, root)
		for tri in mi.mesh.get_faces():
			faces.append(xf * tri)
	if faces.is_empty():
		return null
	if trimesh:
		var s := ConcavePolygonShape3D.new()
		s.set_faces(faces)
		return s
	var pts := PackedVector3Array()
	for v in faces:
		pts.append(v)
	var cs := ConvexPolygonShape3D.new()
	cs.points = pts
	return cs
