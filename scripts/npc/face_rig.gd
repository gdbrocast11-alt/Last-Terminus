class_name FaceRig
extends SkeletonModifier3D
## Drives the facial bones (jaw, lids, eyes, brows, mouth corners) after the body
## animation has been applied. Values are set by Actor each frame.

var mouth_open := 0.0     ## 0..1 (lip-sync)
var blink := 0.0          ## 0..1
var smile := 0.0          ## -1..1
var brow_raise := 0.0     ## -1..1
var brow_tilt := 0.0      ## -1 (sad) .. 1 (angry)
var lid_droop := 0.0      ## 0..1
var look_yaw := 0.0       ## degrees, + = character's left
var look_pitch := 0.0     ## degrees, + = up
var hide_head := false    ## first-person body: collapse the head

var _b := {}
var _rest_pos := {}


func _bone(n: String) -> int:
	if not _b.has(n):
		var s := get_skeleton()
		_b[n] = s.find_bone(n) if s else -1
		if _b[n] >= 0:
			_rest_pos[n] = s.get_bone_rest(_b[n]).origin
	return _b[n]


func _process_modification_with_delta(_delta: float) -> void:
	var s := get_skeleton()
	if s == null:
		return
	var j := _bone("Jaw")
	if j >= 0:
		s.set_bone_pose_rotation(j, BoneUtil.local_rotation(s, j, -mouth_open * 24.0, 0, 0))
	for side in ["L", "R"]:
		var sgn := 1.0 if side == "L" else -1.0
		var lid := _bone("LidU." + side)
		if lid >= 0:
			var close := clampf(blink + lid_droop * 0.45, 0.0, 1.0)
			s.set_bone_pose_rotation(lid, BoneUtil.local_rotation(s, lid, -close * 64.0 + 8.0, 0, 0))
		var eye := _bone("Eye." + side)
		if eye >= 0:
			s.set_bone_pose_rotation(eye, BoneUtil.local_rotation(s, eye, look_pitch, 0, look_yaw))
		var brow := _bone("Brow." + side)
		if brow >= 0:
			var rp: Vector3 = _rest_pos["Brow." + side]
			s.set_bone_pose_position(brow, rp + Vector3(0, brow_raise * 0.008 + (0.004 if brow_tilt < 0 else 0.0) * -brow_tilt, 0))
			s.set_bone_pose_rotation(brow, BoneUtil.local_rotation(s, brow, 0, -sgn * brow_tilt * 22.0, 0))
		var mc := _bone("MouthC." + side)
		if mc >= 0:
			var rp2: Vector3 = _rest_pos["MouthC." + side]
			s.set_bone_pose_position(mc, rp2 + Vector3(sgn * -0.002 * absf(smile), smile * 0.006, 0))
	if hide_head:
		var h := _bone("Head")
		if h >= 0:
			s.set_bone_pose_scale(h, Vector3.ONE * 0.001)
