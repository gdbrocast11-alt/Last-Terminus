class_name FPBody
extends Node3D
## Eddie's full body seen from his own eyes: legs and arms come "for free" from
## the shared animation set. The head is collapsed, the spine leans with the
## camera pitch and the right arm can be raised into view for interactions.

var skel: Skeleton3D
var anim: AnimationPlayer
var mod: FPModifier
var reach := 0.0                 ## 0..1 right arm raised forward (holding / using)
var reach_left := 0.0
var look_pitch := 0.0            ## degrees, + = looking up
var point := 0.0                 ## 0..1 pointing pose
var _current := ""


class FPModifier extends SkeletonModifier3D:
	var owner_body: FPBody
	var _idx := {}

	func _i(n: String) -> int:
		if not _idx.has(n):
			_idx[n] = get_skeleton().find_bone(n)
		return _idx[n]

	func _process_modification_with_delta(_delta: float) -> void:
		var s := get_skeleton()
		var b := owner_body
		if s == null or b == null:
			return
		var h := _i("Head")
		if h >= 0:
			s.set_bone_pose_scale(h, Vector3.ONE * 0.001)
		# spine follows pitch a little so looking down shows the belly and legs
		var sp := _i("Spine")
		var ch := _i("Chest")
		var pitch := clampf(b.look_pitch, -80.0, 60.0)
		if sp >= 0:
			var cur := s.get_bone_pose_rotation(sp)
			s.set_bone_pose_rotation(sp, cur * BoneUtil.local_rotation(s, sp, -pitch * -0.25, 0, 0))
		if ch >= 0:
			var cur2 := s.get_bone_pose_rotation(ch)
			s.set_bone_pose_rotation(ch, cur2 * BoneUtil.local_rotation(s, ch, -pitch * -0.15, 0, 0))
		_arm("R", b.reach, b.point)
		_arm("L", b.reach_left, 0.0)

	func _arm(side: String, amt: float, point_amt: float) -> void:
		if amt <= 0.001 and point_amt <= 0.001:
			return
		var s := get_skeleton()
		var ua := _i("UpperArm." + side)
		var la := _i("LowerArm." + side)
		var fi := _i("Fingers." + side)
		var sh := _i("Shoulder." + side)
		var sgn := 1.0 if side == "R" else -1.0
		var k := clampf(amt + point_amt, 0.0, 1.0)
		if ua >= 0:
			var q := BoneUtil.local_rotation(s, ua, 62.0 + 14.0 * point_amt, -sgn * (-8.0), sgn * 10.0)
			s.set_bone_pose_rotation(ua, s.get_bone_pose_rotation(ua).slerp(q, k))
		if la >= 0:
			var q2 := BoneUtil.local_rotation(s, la, 78.0 - 60.0 * point_amt, 0, 0)
			s.set_bone_pose_rotation(la, s.get_bone_pose_rotation(la).slerp(q2, k))
		if fi >= 0:
			var q3 := BoneUtil.local_rotation(s, fi, 0, -sgn * (70.0 * (1.0 - point_amt)), 0)
			s.set_bone_pose_rotation(fi, s.get_bone_pose_rotation(fi).slerp(q3, k))


func setup() -> void:
	var packed := load("res://scenes/characters/eddie.tscn") as PackedScene
	var m := packed.instantiate() as Node3D
	m.name = "Body"
	add_child(m)
	skel = BoneUtil.find_skeleton(m)
	anim = BoneUtil.find_anim_player(m)
	if skel:
		mod = FPModifier.new()
		mod.owner_body = self
		skel.add_child(mod)
		mod.active = true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		g.extra_cull_margin = 2.0
		g.layers = 1 | 2
	if anim:
		anim.playback_default_blend_time = 0.2


func play(anim_name: String, speed := 1.0) -> void:
	if anim == null or not anim.has_animation(anim_name):
		return
	if _current == anim_name:
		anim.speed_scale = speed
		return
	_current = anim_name
	var a := anim.get_animation(anim_name)
	if a:
		a.loop_mode = Animation.LOOP_NONE if anim_name in ["pickup", "throw", "slip", "death_back", "death_front", "stagger"] else Animation.LOOP_LINEAR
	anim.play(anim_name, 0.2, speed)


func drive(speed: float, crouched: bool, airborne: bool, sprinting: bool) -> void:
	if crouched:
		play("crouch_idle", 1.0)
	elif airborne:
		play("idle", 1.0)
	elif speed > 4.4:
		play("run", clampf(speed / 5.4, 0.8, 1.2))
	elif speed > 0.6:
		play("walk", clampf(speed / 3.0, 0.7, 1.25))
	else:
		play("idle", 1.0)
