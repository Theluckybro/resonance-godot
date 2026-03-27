extends "res://scripts/player/states/player_state.gd"
class_name PlayerRunState

@export var idle_state: StringName = &"idle"
@export var dash_state: StringName = &"dash"
@export var attack_state: StringName = &"attack"


func enter(_from_state: Node) -> void:
	var player := get_player()
	if player == null:
		return
	player.play_required_animation(Player.ANIM_RUN)


func physics_update(delta: float) -> void:
	var player := get_player()
	if player == null:
		return

	if player.is_vestige_inventory_open():
		player.apply_idle_motion(delta)
		request_transition(idle_state)
		return

	if player.is_vestige_primary_pressed() and player.can_use_vestige_slot(0):
		player.try_use_vestige_slot(0)
		return

	if player.is_vestige_secondary_pressed() and player.can_use_vestige_slot(1):
		player.try_use_vestige_slot(1)
		return

	if player.is_vestige_tertiary_pressed() and player.can_use_vestige_slot(2):
		player.try_use_vestige_slot(2)
		return

	if player.is_vestige_quaternary_pressed() and player.can_use_vestige_slot(3):
		player.try_use_vestige_slot(3)
		return

	if player.is_attack_pressed() and player.can_start_attack():
		request_transition(attack_state)
		return

	if player.is_dash_input_pressed() and player.can_start_dash():
		request_transition(dash_state)
		return

	if not player.has_move_input():
		player.apply_idle_motion(delta)
		request_transition(idle_state)
		return

	player.apply_run_motion(delta)
