extends "res://scripts/enemies/states/enemy_state.gd"
class_name EnemyAttackState

@export var chase_state: StringName = &"chase"
@export var idle_state: StringName = &"idle"

var attack_elapsed: float = 0.0
var active_hit_checked: bool = false


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return

	attack_elapsed = 0.0
	active_hit_checked = false
	enemy.reset_melee_attack_cycle()
	enemy.set_visual_state(&"attack")
	enemy.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	if enemy.is_dead_state():
		return

	if not enemy.has_valid_target_player():
		enemy.begin_melee_attack_cooldown()
		request_transition(idle_state)
		return

	attack_elapsed += delta

	var windup_end := enemy.melee_windup_sec
	var active_end := windup_end + enemy.melee_active_sec
	var recover_end := active_end + enemy.melee_recover_sec

	if attack_elapsed < windup_end:
		enemy.apply_idle_motion(delta)
	elif attack_elapsed < active_end:
		if enemy.uses_ground_slam_attack():
			enemy.apply_idle_motion(delta)
		else:
			enemy.apply_melee_lunge_motion(delta)
		if not active_hit_checked:
			if enemy.uses_ground_slam_attack():
				enemy.perform_melee_ground_slam()
			else:
				enemy.try_apply_melee_hit()
			active_hit_checked = true
	else:
		enemy.apply_idle_motion(delta)

	if attack_elapsed >= recover_end:
		enemy.begin_melee_attack_cooldown()
		enemy.reset_melee_attack_cycle()
		if enemy.is_player_in_aggro_range():
			request_transition(chase_state)
		else:
			request_transition(idle_state)


func exit(_to_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.reset_melee_attack_cycle()
