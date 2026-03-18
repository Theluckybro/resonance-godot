extends "res://scripts/systems/fsm/state.gd"
class_name EnemyState

const EnemyScript = preload("res://scripts/enemies/enemy.gd")


func get_enemy() -> EnemyScript:
	return context as EnemyScript
