extends "res://scripts/enemies/states/melee_fast_state.gd"
class_name MeleeFastIdleState

@export var chase_state: StringName = &"chase"


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.set_visual_state(EnemyMeleeFast.STATE_IDLE)


func physics_update(delta: float) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return

	enemy.apply_idle_motion(delta)
	if enemy.is_player_in_aggro_range():
		request_transition(chase_state)
