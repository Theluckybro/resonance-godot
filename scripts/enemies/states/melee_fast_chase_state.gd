extends "res://scripts/enemies/states/melee_fast_state.gd"
class_name MeleeFastChaseState

@export var idle_state: StringName = &"idle"


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.set_visual_state(EnemyMeleeFast.STATE_CHASE)


func physics_update(delta: float) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return

	if not enemy.is_player_in_aggro_range():
		enemy.apply_idle_motion(delta)
		request_transition(idle_state)
		return

	enemy.apply_chase_motion(delta)
