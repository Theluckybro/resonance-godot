extends Node
class_name GameInput

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"

const ACTION_ATTACK: StringName = &"action_attack"
const ACTION_DASH: StringName = &"action_dash"
const ACTION_VESTIGE_1: StringName = &"action_vestige_1"
const ACTION_VESTIGE_2: StringName = &"action_vestige_2"

const UI_UP: StringName = &"ui_up"
const UI_DOWN: StringName = &"ui_down"
const UI_LEFT: StringName = &"ui_left"
const UI_RIGHT: StringName = &"ui_right"
const UI_ACCEPT: StringName = &"ui_accept"
const UI_CANCEL: StringName = &"ui_cancel"
const UI_MENU: StringName = &"ui_menu"
const UI_PAUSE: StringName = &"ui_pause"

const DEBUG_TOGGLE_HITBOXES: StringName = &"debug_toggle_hitboxes"
const DEBUG_SPAWN_VESTIGE: StringName = &"debug_spawn_vestige"

const REQUIRED_ACTIONS: Array[StringName] = [
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	ACTION_ATTACK,
	ACTION_DASH,
	ACTION_VESTIGE_1,
	ACTION_VESTIGE_2,
	UI_UP,
	UI_DOWN,
	UI_LEFT,
	UI_RIGHT,
	UI_ACCEPT,
	UI_CANCEL,
	UI_MENU,
	UI_PAUSE,
	DEBUG_TOGGLE_HITBOXES,
	DEBUG_SPAWN_VESTIGE,
]


static func movement_vector() -> Vector2:
	return Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN)


static func get_missing_actions() -> PackedStringArray:
	var missing := PackedStringArray()
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			missing.append(String(action_name))
	return missing


static func is_setup_valid() -> bool:
	return get_missing_actions().is_empty()
