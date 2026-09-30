class_name PropComponent
extends Node
## Behaviour shared by every interactive prop. Lives as a child node named
## "Prop" of a StaticBody3D / RigidBody3D so gameplay code can discover it from
## any collider. Holds grab class, inspect line, hazard level and "home"
## transform (used by chains to detect that the player moved something).

signal used(player: Node)            ## E pressed while looking at it (if verb set)
signal struck(player: Node)          ## LMB "hit" on it (if hit_verb set)
signal grabbed(player: Node)
signal released(player: Node)
signal inspected(player: Node)

@export var prop_id: StringName = &""
@export var grab_class: String = ""  # "", light, medium, heavy
@export var inspect_line: StringName = &""
@export_range(0, 2) var hazard: int = 0
@export var tags: PackedStringArray = PackedStringArray()
@export var use_verb: String = ""
@export var hit_verb: String = ""
@export var can_use := true
@export var fetchable := false        ## Pickles may fetch it
@export var throw_strength := 9.0

var body: Node3D
var home_xform := Transform3D.IDENTITY
var held_by: Node = null
var pickles_holding := false
var _inspect_count := 0


func _ready() -> void:
	body = get_parent() as Node3D
	add_to_group("props")
	if prop_id == &"" and body:
		prop_id = StringName(body.name)
	if hazard > 0:
		add_to_group("hazards")
	if fetchable:
		add_to_group("fetchables")
	call_deferred("_capture_home")


func _capture_home() -> void:
	if body and body.is_inside_tree():
		home_xform = body.global_transform


func reset_home() -> void:
	if body:
		body.global_transform = home_xform
		if body is RigidBody3D:
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO


func moved_distance() -> float:
	if body == null:
		return 0.0
	return body.global_position.distance_to(home_xform.origin)


func is_held() -> bool:
	return held_by != null or pickles_holding


func has_tag(t: String) -> bool:
	return tags.has(t)


func is_grabbable() -> bool:
	return grab_class != "" and can_use and body is RigidBody3D


func can_interact() -> bool:
	return can_use and (is_grabbable() or use_verb != "" or inspect_line != &"")


func prompt_text() -> String:
	if not can_use:
		return ""
	if use_verb != "":
		return use_verb
	if is_grabbable():
		return "Pick up"
	if inspect_line != &"":
		return "Inspect"
	return ""


func do_inspect(player: Node) -> void:
	inspected.emit(player)
	_inspect_count += 1
	if inspect_line != &"":
		DialogueManager.say(inspect_line, 0)
	if _inspect_count == 1 and hazard > 0:
		AchievementManager.progress(&"hazard_perspective", 30)


func do_use(player: Node) -> void:
	used.emit(player)


func do_hit(player: Node) -> void:
	struck.emit(player)


## Switch between scripted (kinematic) and simulated motion. Chains freeze a
## prop while a tween drives it, then release it so physics can settle.
func set_scripted(on: bool) -> void:
	if body is RigidBody3D:
		var rb := body as RigidBody3D
		if on:
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			rb.freeze = true
		else:
			rb.freeze = false
			rb.sleeping = false
