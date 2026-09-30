extends Node
## Global signal bus. Systems talk through these signals instead of holding
## references to each other, so chapters, props and UI stay decoupled.

# --- accident / chain framework -------------------------------------------
signal intervention(kind: StringName, id: StringName, data: Dictionary)
signal chain_started(chain_id: StringName)
signal chain_step_fired(chain_id: StringName, step_id: StringName)
signal chain_step_blocked(chain_id: StringName, step_id: StringName)
signal chain_rerouted(chain_id: StringName, from_step: StringName, to_step: StringName)
signal chain_finished(chain_id: StringName, result: Dictionary)

# --- people ---------------------------------------------------------------
signal npc_died(npc_id: StringName, cause: StringName)
signal npc_saved(npc_id: StringName)
signal player_died(reason: StringName)
signal pickles_survived(event_id: StringName)
signal pickles_command(command: StringName)

# --- presentation ---------------------------------------------------------
signal objective_changed(text: String)
signal hint_requested(text: String, seconds: float)
signal camera_shake_requested(amount: float, seconds: float)
signal rumble_requested(weak: float, strong: float, seconds: float)
signal flash_requested(color: Color, seconds: float)
signal premonition_started(id: StringName)
signal premonition_ended(id: StringName)
signal fade_requested(to_black: bool, seconds: float)
signal title_card_requested(text: String, seconds: float)

# --- meta -----------------------------------------------------------------
signal checkpoint_saved(chapter: int, beat: StringName)
signal chapter_changed(chapter: int)
signal achievement_unlocked(id: StringName)
signal notebook_updated()
signal input_device_changed(is_gamepad: bool)
signal settings_changed()
