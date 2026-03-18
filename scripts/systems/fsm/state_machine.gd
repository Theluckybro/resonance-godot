extends Node
class_name StateMachine

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: StringName = &""
@export var use_automatic_updates: bool = false
@export var debug_logging: bool = false

var context: Node
var blackboard: Dictionary = {}

var _states: Dictionary = {}
var _current_state: Node = null
var _is_transitioning: bool = false
var _started: bool = false
var _pending_transition: StringName = &""


func _ready() -> void:
	_collect_states()
	if context == null:
		context = get_parent()
	_setup_states()

	if use_automatic_updates:
		start()


func _physics_process(delta: float) -> void:
	if not use_automatic_updates:
		return
	physics_step(delta)


func _process(delta: float) -> void:
	if not use_automatic_updates:
		return
	process_step(delta)


func set_context(context_node: Node) -> void:
	context = context_node
	if _states.is_empty():
		return
	_setup_states()


func get_context() -> Node:
	return context


func set_blackboard_value(key: StringName, value: Variant) -> void:
	blackboard[key] = value


func get_blackboard_value(key: StringName, default_value: Variant = null) -> Variant:
	if not blackboard.has(key):
		return default_value
	return blackboard[key]


func start() -> void:
	if _started and _current_state != null:
		return

	if _states.is_empty():
		_collect_states()
		_setup_states()

	if initial_state == StringName():
		push_error("StateMachine initial_state is empty on %s" % name)
		return

	_started = true
	request_transition(initial_state)


func physics_step(delta: float) -> void:
	if _current_state == null:
		return
	_current_state.physics_update(delta)


func process_step(delta: float) -> void:
	if _current_state == null:
		return
	_current_state.process_update(delta)


func request_transition(target_state_name: StringName) -> void:
	if target_state_name == StringName():
		return
	if not _started:
		return

	if _is_transitioning:
		_pending_transition = target_state_name
		return

	_perform_transition(target_state_name)
	_flush_pending_transitions()


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func get_current_state_name() -> StringName:
	if _current_state == null:
		return &""

	var state_name_value: Variant = _current_state.get("state_name")
	if state_name_value is StringName:
		return state_name_value
	if state_name_value is String:
		return StringName(state_name_value)
	return &""


func _collect_states() -> void:
	_states.clear()
	for child in get_children():
		if not child.has_method("setup"):
			continue
		if not child.has_method("enter") or not child.has_method("exit"):
			continue

		var state_name_value: Variant = child.get("state_name")
		var parsed_state_name := StringName()
		if state_name_value is StringName:
			parsed_state_name = state_name_value
		elif state_name_value is String:
			parsed_state_name = StringName(state_name_value)

		if parsed_state_name == StringName():
			push_error("FSMState %s has empty state_name in %s" % [child.name, name])
			continue
		if _states.has(parsed_state_name):
			push_error("Duplicate FSM state_name %s in %s" % [parsed_state_name, name])
			continue

		_states[parsed_state_name] = child


func _setup_states() -> void:
	for state_key in _states.keys():
		var state_node: Node = _states[state_key]
		state_node.setup(self, context)


func _perform_transition(target_state_name: StringName) -> void:
	if not _states.has(target_state_name):
		push_error("StateMachine %s cannot transition to unknown state: %s" % [name, target_state_name])
		return

	var target_state: Node = _states[target_state_name]
	if _current_state == target_state:
		return

	if _current_state != null and not _current_state.can_exit(target_state):
		return
	if not target_state.can_enter(_current_state):
		return

	var previous_state: Node = _current_state
	var previous_name: StringName = &""
	if previous_state != null:
		var previous_name_value: Variant = previous_state.get("state_name")
		if previous_name_value is StringName:
			previous_name = previous_name_value
		elif previous_name_value is String:
			previous_name = StringName(previous_name_value)

	_is_transitioning = true
	if previous_state != null:
		previous_state.exit(target_state)

	_current_state = target_state
	target_state.enter(previous_state)
	_is_transitioning = false

	if debug_logging:
		print("StateMachine %s transition: %s -> %s" % [name, previous_name, target_state_name])

	state_changed.emit(previous_name, target_state_name)


func _flush_pending_transitions() -> void:
	var guard := 0
	while _pending_transition != StringName() and guard < 16:
		var next_state := _pending_transition
		_pending_transition = StringName()
		_perform_transition(next_state)
		guard += 1

	if guard >= 16:
		push_error("StateMachine %s aborted transition loop. Check circular transitions." % name)
		_pending_transition = StringName()
