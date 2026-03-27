extends Node

signal pause_toggled(is_paused: bool, context: StringName)

const PAUSE_CONTEXT_NONE: StringName = &"none"
const PAUSE_CONTEXT_MENU: StringName = &"menu"
const PAUSE_CONTEXT_INVENTORY: StringName = &"inventory"

var _is_paused: bool = false
var _pause_context: StringName = PAUSE_CONTEXT_NONE
var _muffle_bus_index: int = -1
var _base_muffle_volume_db: float = 0.0
var _input_consumed: bool = false

const PAUSE_MUFFLE_FACTOR: float = 0.3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	if GameInput.is_pause_pressed():
		if _input_consumed:
			return
		# Ignore pause hotkey while inventory pause is active.
		if _is_paused and _pause_context == PAUSE_CONTEXT_INVENTORY:
			_input_consumed = true
			return
		if _is_paused and _pause_context == PAUSE_CONTEXT_MENU:
			resume()
		else:
			pause_menu()
		_input_consumed = true
	else:
		_input_consumed = false


func _ensure_muffle_bus() -> void:
	if _muffle_bus_index != -1:
		return

	# Prioritize BGM bus for the underwater-like pause effect.
	_muffle_bus_index = AudioServer.get_bus_index("BGM")
	if _muffle_bus_index == -1:
		_muffle_bus_index = AudioServer.get_bus_index("Master")


func _apply_muffle() -> void:
	_ensure_muffle_bus()
	if _muffle_bus_index == -1:
		return
	AudioServer.set_bus_volume_db(_muffle_bus_index, _base_muffle_volume_db + linear_to_db(PAUSE_MUFFLE_FACTOR))


func _restore_muffle_bus_volume() -> void:
	_ensure_muffle_bus()
	if _muffle_bus_index == -1:
		return
	AudioServer.set_bus_volume_db(_muffle_bus_index, _base_muffle_volume_db)


func pause_menu() -> void:
	if _is_paused:
		return

	_ensure_muffle_bus()
	if _muffle_bus_index != -1:
		_base_muffle_volume_db = AudioServer.get_bus_volume_db(_muffle_bus_index)

	_is_paused = true
	_pause_context = PAUSE_CONTEXT_MENU
	get_tree().paused = true
	_apply_muffle()
	pause_toggled.emit(true, PAUSE_CONTEXT_MENU)


func resume() -> void:
	if not _is_paused:
		return

	_is_paused = false
	_pause_context = PAUSE_CONTEXT_NONE
	get_tree().paused = false
	_restore_muffle_bus_volume()
	pause_toggled.emit(false, PAUSE_CONTEXT_NONE)


func pause_for_inventory() -> bool:
	if _is_paused:
		return _pause_context == PAUSE_CONTEXT_INVENTORY

	_ensure_muffle_bus()
	if _muffle_bus_index != -1:
		_base_muffle_volume_db = AudioServer.get_bus_volume_db(_muffle_bus_index)

	_is_paused = true
	_pause_context = PAUSE_CONTEXT_INVENTORY
	get_tree().paused = true
	_apply_muffle()
	pause_toggled.emit(true, PAUSE_CONTEXT_INVENTORY)
	return true


func resume_from_inventory() -> bool:
	if not _is_paused:
		return true
	if _pause_context != PAUSE_CONTEXT_INVENTORY:
		return false

	_is_paused = false
	_pause_context = PAUSE_CONTEXT_NONE
	get_tree().paused = false
	_restore_muffle_bus_volume()
	pause_toggled.emit(false, PAUSE_CONTEXT_NONE)
	return true
