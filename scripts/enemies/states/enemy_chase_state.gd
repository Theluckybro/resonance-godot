extends "res://scripts/enemies/states/enemy_state.gd"
class_name EnemyChaseState

@export var idle_state: StringName = &"idle"


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.set_visual_state(&"chase")


func physics_update(delta: float) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return

	if not enemy.is_player_in_aggro_range():
		enemy.apply_idle_motion(delta)
		request_transition(idle_state)
		return

	enemy.apply_chase_motion(delta)
