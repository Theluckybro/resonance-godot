extends "res://scripts/enemies/states/melee_fast_state.gd"
class_name MeleeFastHitStunState

@export var idle_state: StringName = &"idle"
@export var chase_state: StringName = &"chase"


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.set_visual_state(EnemyMeleeFast.STATE_HIT_STUN)


func physics_update(delta: float) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return

	enemy.update_hit_stun_motion(delta)
	if not enemy.is_hit_stun_finished():
		return

	if enemy.is_player_in_aggro_range():
		request_transition(chase_state)
		return

	request_transition(idle_state)
