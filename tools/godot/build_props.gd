extends Node
## Turns props/*.glb + props/props_def.json into ready-to-place scenes in
## scenes/props/. Static props get StaticBody3D, rigid props RigidBody3D
## (sleeping until touched), decor gets a bare Node3D. Each scene has a
## "Prop" child (PropComponent) carrying interaction metadata.
## Usage: godot --headless --path . res://tools/godot/builder.tscn -- props

const PropComponentScript := preload("res://scripts/props/prop_component.gd")


func run(_args: Array) -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://props/props_def.json"))
	var ok := 0
	for prop_name in defs.keys():
		var d: Dictionary = defs[prop_name]
		var glb_path := "res://props/%s.glb" % prop_name
		if not ResourceLoader.exists(glb_path):
			push_warning("missing glb " + glb_path)
			continue
		var packed: PackedScene = load(glb_path)
		var model: Node3D = packed.instantiate()
		model.name = "Model"
		BuildUtil.apply_materials(model)
		var root: Node3D
		match d.body:
			"static":
				var sb := StaticBody3D.new()
				sb.collision_layer = 1
				sb.collision_mask = 0
				root = sb
			"rigid":
				var rb := RigidBody3D.new()
				rb.mass = d.mass
				rb.collision_layer = 16
				rb.collision_mask = 1 | 2 | 4 | 8 | 16
				rb.can_sleep = true
				rb.continuous_cd = false
				rb.contact_monitor = false
				rb.linear_damp = 0.15
				rb.angular_damp = 0.4
				rb.sleeping = true
				root = rb
			_:
				root = Node3D.new()
		root.name = prop_name
		root.add_child(model)
		var bb := BuildUtil.combined_aabb(model)
		if d.col != "none" and root is CollisionObject3D:
			var cs := CollisionShape3D.new()
			cs.name = "Collision"
			var shape: Shape3D = null
			match d.col:
				"box":
					var b := BoxShape3D.new()
					b.size = bb.size
					shape = b
					cs.position = bb.get_center()
				"cylinder":
					var cy := CylinderShape3D.new()
					cy.radius = maxf(bb.size.x, bb.size.z) * 0.5
					cy.height = bb.size.y
					shape = cy
					cs.position = bb.get_center()
				"sphere":
					var sp := SphereShape3D.new()
					sp.radius = maxf(bb.size.x, maxf(bb.size.y, bb.size.z)) * 0.5
					shape = sp
					cs.position = bb.get_center()
				"capsule":
					var ca := CapsuleShape3D.new()
					ca.radius = maxf(bb.size.x, bb.size.z) * 0.5
					ca.height = maxf(bb.size.y, ca.radius * 2.0)
					shape = ca
					cs.position = bb.get_center()
				"convex":
					shape = BuildUtil.mesh_shape(model, true, false)
				"trimesh":
					shape = BuildUtil.mesh_shape(model, false, root is StaticBody3D)
					if root is RigidBody3D:
						shape = BuildUtil.mesh_shape(model, true, false)
			cs.shape = shape
			if shape:
				root.add_child(cs)
		var comp := Node.new()
		comp.set_script(PropComponentScript)
		comp.name = "Prop"
		comp.set("prop_id", StringName(prop_name))
		comp.set("grab_class", d.grab if d.grab != null else "")
		comp.set("inspect_line", StringName(d.inspect) if d.inspect != null else &"")
		var tags: PackedStringArray = PackedStringArray()
		for t in d.tags:
			tags.append(t)
		comp.set("tags", tags)
		if d.tags.has("ball") or d.tags.has("fetch"):
			comp.set("fetchable", true)
		root.add_child(comp)
		# Marker points from Blender empties are exported as child nodes named after the marker.
		var err := BuildUtil.save_scene(root, "res://scenes/props/%s.tscn" % prop_name)
		if err == OK:
			ok += 1
		root.free()
	print("BUILD props: ", ok, "/", defs.size())
