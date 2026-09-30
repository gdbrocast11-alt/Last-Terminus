class_name BoneUtil
extends RefCounted
## Bone pose helpers for skeletons exported from Blender with our conventions.
## Rotations are specified like in the Blender animation scripts: degrees about
## the rig's rest-space axes (X right, Y forward, Z up), applied in the parent's
## frame, then converted to Godot's Y-up / -Z-forward local pose rotation.


## Basis for a Blender-axes XYZ Euler rotation expressed in Godot axes.
static func blender_basis(rx: float, ry: float, rz: float) -> Basis:
	var bx := Basis(Vector3.RIGHT, deg_to_rad(rx))
	var by := Basis(Vector3.BACK, deg_to_rad(-ry))     # Blender +Y is Godot -Z
	var bz := Basis(Vector3.UP, deg_to_rad(rz))
	return bz * by * bx


static func local_rotation(skel: Skeleton3D, bone: int, rx: float, ry: float, rz: float) -> Quaternion:
	var rest := skel.get_bone_global_rest(bone).basis
	return (rest.inverse() * blender_basis(rx, ry, rz) * rest).get_rotation_quaternion()


static func find_bone(skel: Skeleton3D, bone_name: String) -> int:
	return skel.find_bone(bone_name)


static func find_skeleton(root: Node) -> Skeleton3D:
	var found := root.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if found.size() > 0 else null


static func find_anim_player(root: Node) -> AnimationPlayer:
	var found := root.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if found.size() > 0 else null
