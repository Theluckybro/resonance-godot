extends Node

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"

const ACTION_ATTACK: StringName = &"action_attack"
const ACTION_DASH: StringName = &"action_dash"
const ACTION_VESTIGE_Q: StringName = &"action_vestige_q"
const ACTION_VESTIGE_E: StringName = &"action_vestige_e"
const ACTION_VESTIGE_R: StringName = &"action_vestige_r"
const ACTION_VESTIGE_SHIFT: StringName = &"action_vestige_shift"
const ACTION_VESTIGE_INVENTORY: StringName = &"action_vestige_inventory"

const UI_UP: StringName = &"ui_up"
const UI_DOWN: StringName = &"ui_down"
const UI_LEFT: StringName = &"ui_left"
const UI_RIGHT: StringName = &"ui_right"
const UI_ACCEPT: StringName = &"ui_accept"
const UI_CANCEL: StringName = &"ui_cancel"
const UI_MENU: StringName = &"ui_menu"
const UI_PAUSE: StringName = &"ui_pause"

const DEBUG_TOGGLE_HITBOXES: StringName = &"debug_toggle_hitboxes"

const REQUIRED_ACTIONS: Array[StringName] = [
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	ACTION_ATTACK,
	ACTION_DASH,
	ACTION_VESTIGE_Q,
	ACTION_VESTIGE_E,
	ACTION_VESTIGE_R,
	ACTION_VESTIGE_SHIFT,
	ACTION_VESTIGE_INVENTORY,
	UI_UP,
	UI_DOWN,
	UI_LEFT,
	UI_RIGHT,
	UI_ACCEPT,
	UI_CANCEL,
	UI_MENU,
	UI_PAUSE,
	DEBUG_TOGGLE_HITBOXES,
]


func movement_vector() -> Vector2:
	return Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN)


func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_ATTACK)


func is_dash_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_DASH)


func is_vestige_q_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_VESTIGE_Q)


func is_vestige_e_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_VESTIGE_E)


func is_vestige_r_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_VESTIGE_R)


func is_vestige_shift_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_VESTIGE_SHIFT)


func is_vestige_primary_pressed() -> bool:
	return is_vestige_q_pressed()


func is_vestige_secondary_pressed() -> bool:
	return is_vestige_e_pressed()


func is_vestige_tertiary_pressed() -> bool:
	return is_vestige_r_pressed()


func is_vestige_quaternary_pressed() -> bool:
	return is_vestige_shift_pressed()


func is_vestige_inventory_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_VESTIGE_INVENTORY)


func is_pause_pressed() -> bool:
	return Input.is_action_just_pressed(UI_PAUSE)


func get_missing_actions() -> PackedStringArray:
	var missing := PackedStringArray()
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			missing.append(String(action_name))
	return missing


func is_setup_valid() -> bool:
	return get_missing_actions().is_empty()
