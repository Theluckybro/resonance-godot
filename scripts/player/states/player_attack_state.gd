extends "res://scripts/player/states/player_state.gd"
class_name PlayerAttackState

@export var idle_state: StringName = &"idle"
@export var run_state: StringName = &"run"

var attack_animation_finished: bool = false


func can_enter(_from_state: Node) -> bool:
	var player := get_player()
	return player != null


func enter(_from_state: Node) -> void:
	var player := get_player()
	if player == null:
		return
	
	attack_animation_finished = false
	player.start_attack()


func exit(_to_state: Node) -> void:
	var player := get_player()
	if player == null:
		return
	player.finish_attack()


func physics_update(_delta: float) -> void:
	var player := get_player()
	if player == null:
		return

	player.lock_attack_motion()
	
	# Check if animation finished
	if not attack_animation_finished:
		var animation_player := player.get_animation_player()
		if animation_player and not animation_player.is_playing():
			attack_animation_finished = true
	
	# Transition out after animation finishes
	if attack_animation_finished:
		if player.has_move_input():
			request_transition(run_state)
		else:
			request_transition(idle_state)
