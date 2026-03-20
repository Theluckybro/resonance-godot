extends "res://scripts/player/states/player_state.gd"
class_name PlayerDeadState


func enter(_from_state: Node) -> void:
	var player := get_player()
	if player == null:
		return
	player.start_death()


func physics_update(delta: float) -> void:
	var player := get_player()
	if player == null:
		return
	player.apply_idle_motion(delta)
