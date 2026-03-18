extends "res://scripts/systems/fsm/state.gd"
class_name MeleeFastState


func get_enemy() -> EnemyMeleeFast:
	return context as EnemyMeleeFast
