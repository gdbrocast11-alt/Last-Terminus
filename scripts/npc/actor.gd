class_name Actor
extends NavActor
## A named (or background) human. Handles talk gestures + lip-sync, blinking,
## eye contact, emotions, held props, and death poses. Behaviour beyond that is
## authored by the chapter scripts (routes, warnings, reactions).

signal interacted(player: Node)
signal died(cause: StringName)

enum Mode { IDLE, WALKING, PANIC, DEAD, SCRIPTED, FOLLOW }

const TALK_SETS := {
	"eddie": ["talk_calm", "talk_a", "talk_c"], "brenda": ["talk_a", "talk_b", "talk_c"], "dale": ["talk_b", "talk_a", "argue"],
	"tiffany": ["talk_calm", "talk_b", "talk_a"], "mills": ["talk_calm", "talk_c", "hands_hips"], "gus": ["talk_calm", "clipboard"],
	"marco": ["argue", "talk_a"], "luis": ["argue", "talk_b"], "graves": ["talk_c", "talk_calm", "talk_b"],
}
const EMOTIONS := {
	&"neutral": {"smile": 0.0, "brow": 0.0, "tilt": 0.0, "droop": 0.0},
	&"happy": {"smile": 0.9, "brow": 0.35, "tilt": 0.0, "droop": 0.0},
	&"smug": {"smile": 0.5, "brow": -0.1, "tilt": 0.4, "droop": 0.35},
	&"sad": {"smile": -0.6, "brow": 0.3, "tilt": -0.9, "droop": 0.3},
	&"angry": {"smile": -0.5, "brow": -0.5, "tilt": 0.9, "droop": 0.2},
	&"panic": {"smile": -0.3, "brow": 1.0, "tilt": -0.7, "droop": 0.0},
	&"surprised": {"smile": 0.1, "brow": 1.0, "tilt": 0.0, "droop": 0.0},
	&"deadpan": {"smile": -0.05, "brow": -0.15, "tilt": 0.1, "droop": 0.4},
	&"worried": {"smile": -0.3, "brow": 0.5, "tilt": -0.6, "droop": 0.1},
	&"ecstatic": {"smile": 1.0, "brow": 0.8, "tilt": 0.0, "droop": 0.0},
}

@export var actor_id: StringName = &"stranger_a"
@export var display_name := ""
@export var idle_anim := "idle"
@export var talkable := false
@export var look_at_player := true
@export var prompt := "Talk"

var mode: int = Mode.IDLE
var face: FaceRig
var emotion: StringName = &"neutral"
var alive := true
var _blink_t := 2.0
var _blink_phase := 0.0
var _emo := {"smile": 0.0, "brow": 0.0, "tilt": 0.0, "droop": 0.0}
var _talk_idx := 0
var _talk_t := 0.0
var _speaking := false
var _look_yaw := 0.0
var _look_pitch := 0.0
var held: Dictionary = {}                 ## bone -> Node3D
var mouth_scale := 1.0
var route_index := 0
var protected := false                    ## chain kill checks skip protected actors


func _ready() -> void:
	char_id = String(actor_id)
	super._ready()
	add_to_group("actors")
	if talkable:
		add_to_group("talkable")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)
	DialogueManager.register_speaker(actor_id, self)
	_blink_t = randf_range(1.0, 4.0)
	play_anim(idle_anim)


func _exit_tree() -> void:
	DialogueManager.unregister_speaker(actor_id, self)


func _on_model_ready() -> void:
	if skel == null:
		return
	face = FaceRig.new()
	face.name = "FaceRig"
	skel.add_child(face)
	face.active = true


func _is_loop(n: String) -> bool:
	return not (n in ["death_back", "death_front", "slip", "pickup", "throw", "shrug", "facepalm", "stagger", "dodge_left", "dodge_right", "stand_up", "nod", "shake_head"])


func set_emotion(e: StringName) -> void:
	emotion = e


func attach_prop(bone: String, node: Node3D, xform := Transform3D.IDENTITY) -> void:
	if skel == null:
		return
	var idx := skel.find_bone(bone)
	if idx < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	ba.add_child(node)
	node.transform = xform
	held[bone] = node


func clear_props() -> void:
	for k in held.keys():
		var n: Node = held[k]
		if is_instance_valid(n):
			var p := n.get_parent()
			n.queue_free()
			if p and p is BoneAttachment3D:
				p.queue_free()
	held.clear()


# ------------------------------------------------------------------ interaction
func get_prompt() -> String:
	if not alive or not talkable:
		return ""
	return "%s %s" % [prompt, display_name] if display_name != "" else prompt


func interact(player: Node) -> void:
	if alive and talkable:
		interacted.emit(player)


# ------------------------------------------------------------------ per-frame
func _process(delta: float) -> void:
	if face == null:
		return
	var em: Dictionary = EMOTIONS.get(emotion, EMOTIONS[&"neutral"])
	for k in _emo.keys():
		_emo[k] = lerpf(_emo[k], em[k], clampf(delta * 6.0, 0.0, 1.0))
	face.smile = _emo.smile
	face.brow_raise = _emo.brow
	face.brow_tilt = _emo.tilt
	face.lid_droop = _emo.droop
	# lip-sync
	var lvl := DialogueManager.mouth_level(actor_id) if alive else 0.0
	_speaking = lvl > 0.0 or (DialogueManager.is_busy() and DialogueManager.current_speaker() == actor_id)
	face.mouth_open = lerpf(face.mouth_open, lvl * 0.9 * mouth_scale, clampf(delta * 22.0, 0.0, 1.0))
	# blink
	_blink_t -= delta
	if _blink_t <= 0.0 and _blink_phase <= 0.0:
		_blink_phase = 1.0
		_blink_t = randf_range(2.0, 5.5)
	if _blink_phase > 0.0:
		_blink_phase -= delta * 7.0
	face.blink = clampf(sin(clampf(_blink_phase, 0.0, 1.0) * PI), 0.0, 1.0) if alive else 0.9
	# eye contact
	var tgt_yaw := 0.0
	var tgt_pitch := 0.0
	if alive and look_at_player and Director.player and is_instance_valid(Director.player):
		var to_p: Vector3 = Director.player.global_position + Vector3(0, 1.5, 0) - (global_position + Vector3(0, 1.6, 0))
		if to_p.length() < 9.0:
			var local := global_transform.basis.inverse() * to_p
			tgt_yaw = clampf(rad_to_deg(atan2(-local.x, -local.z)), -35.0, 35.0)
			tgt_pitch = clampf(rad_to_deg(atan2(local.y, Vector2(local.x, local.z).length())), -20.0, 20.0)
	_look_yaw = lerpf(_look_yaw, tgt_yaw, clampf(delta * 8.0, 0.0, 1.0))
	_look_pitch = lerpf(_look_pitch, tgt_pitch, clampf(delta * 8.0, 0.0, 1.0))
	face.look_yaw = _look_yaw
	face.look_pitch = _look_pitch


func _update_anim(delta: float) -> void:
	if not alive or mode == Mode.SCRIPTED or mode == Mode.DEAD:
		return
	var spd := horizontal_speed()
	if spd > 3.2:
		play_anim("panic_run" if mode == Mode.PANIC else "run", 0.2, clampf(spd / 4.4, 0.7, 1.4))
	elif spd > 0.3:
		play_anim("walk", 0.25, clampf(spd / 1.5, 0.7, 1.3))
	elif _speaking:
		_talk_t -= delta
		if _talk_t <= 0.0:
			var set_: Array = TALK_SETS.get(String(actor_id), ["talk_a", "talk_calm"])
			_talk_idx = (_talk_idx + 1) % set_.size()
			_talk_t = randf_range(1.8, 3.2)
			play_anim(set_[_talk_idx], 0.35)
		elif not _current_anim.begins_with("talk") and _current_anim != "argue" and _current_anim != "hands_hips" and _current_anim != "clipboard":
			var set2: Array = TALK_SETS.get(String(actor_id), ["talk_a"])
			play_anim(set2[_talk_idx % set2.size()], 0.3)
	else:
		_talk_t = 0.0
		var target := "panic_idle" if mode == Mode.PANIC else idle_anim
		play_anim(target, 0.35)


# ------------------------------------------------------------------ state helpers
func set_panic(on: bool) -> void:
	if not alive:
		return
	mode = Mode.PANIC if on else Mode.IDLE
	set_emotion(&"panic" if on else &"neutral")


func run_away_to(pos: Vector3) -> void:
	set_panic(true)
	await go_to(pos, true)
	if alive:
		mode = Mode.PANIC


## Blocking death pose. `style`: back | front | slip | flat
func die(cause: StringName = &"generic", style: String = "back", persist := true) -> void:
	if not alive:
		return
	alive = false
	mode = Mode.DEAD
	stop_moving()
	moving = false
	talkable = false
	set_emotion(&"surprised")
	var anim_name: String = {"back": "death_back", "front": "death_front", "slip": "slip"}.get(style, "death_back")
	if anim:
		_current_anim = ""
		play_anim(anim_name, 0.05)
		await get_tree().create_timer(1.0).timeout
		if is_inside_tree():
			play_anim("lie_idle" if style != "front" else "death_front", 0.2)
	collision_layer = 0
	if persist and actor_id in GameState.SURVIVOR_IDS:
		GameState.set_survivor(actor_id, &"dead")
	died.emit(cause)
	Events.npc_died.emit(actor_id, cause)
