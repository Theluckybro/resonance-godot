extends Node

signal total_changed(new_total: int, delta: int)

var total_vestige: int = 0


func get_total() -> int:
	return total_vestige


func add_vestige(amount: int = 1) -> int:
	if amount <= 0:
		return total_vestige

	total_vestige += amount
	total_changed.emit(total_vestige, amount)
	return total_vestige


func reset() -> void:
	total_vestige = 0
	total_changed.emit(total_vestige, 0)
