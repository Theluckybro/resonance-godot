extends "res://scripts/enemies/states/enemy_state.gd"
class_name EnemyDeadState


func enter(_from_state: Node) -> void:
	var enemy := get_enemy()
	if enemy == null:
		return
	enemy.set_visual_state(&"dead")
	enemy.on_enter_dead_state()


func physics_update(_delta: float) -> void:
	# Dead state is terminal for this enemy.
	pass
