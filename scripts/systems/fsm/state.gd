extends Node
class_name FSMState

@export var state_name: StringName = &""

var state_machine: Node
var context: Node


func setup(machine: Node, state_context: Node) -> void:
	state_machine = machine
	context = state_context


func can_enter(_from_state: Node) -> bool:
	return true


func can_exit(_to_state: Node) -> bool:
	return true


func enter(_from_state: Node) -> void:
	pass


func exit(_to_state: Node) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func process_update(_delta: float) -> void:
	pass


func request_transition(target_state: StringName) -> void:
	if state_machine == null:
		return
	state_machine.request_transition(target_state)


func get_context_node() -> Node:
	return context
