extends "res://scripts/player/states/player_state.gd"
class_name PlayerDashState

@export var idle_state: StringName = &"idle"
@export var run_state: StringName = &"run"


func can_enter(_from_state: Node) -> bool:
	var player := get_player()
	return player != null and player.can_start_dash()


func enter(_from_state: Node) -> void:
	var player := get_player()
	if player == null:
		return

	player.start_dash()
	player.play_required_animation(Player.ANIM_DASH)


func physics_update(delta: float) -> void:
	var player := get_player()
	if player == null:
		return

	player.tick_dash(delta)
	if not player.is_dash_finished():
		return

	player.finish_dash()
	if player.has_move_input():
		request_transition(run_state)
		return

	request_transition(idle_state)
