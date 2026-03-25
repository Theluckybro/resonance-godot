extends Node

signal total_changed(new_total: int, delta: int)
signal goblin_charge_changed(new_total: int, delta: int)
signal orc_charge_changed(new_total: int, delta: int)
signal skeleton_charge_changed(new_total: int, delta: int)

var total_vestige: int = 0
var goblin_charges: int = 0
var orc_charges: int = 0
var skeleton_charges: int = 0


func get_total() -> int:
	return total_vestige


func get_goblin_charges() -> int:
	return goblin_charges


func get_orc_charges() -> int:
	return orc_charges


func get_skeleton_charges() -> int:
	return skeleton_charges


func add_vestige(amount: int = 1) -> int:
	if amount <= 0:
		return total_vestige

	total_vestige += amount
	total_changed.emit(total_vestige, amount)
	return total_vestige


func add_goblin_charge(amount: int = 1) -> int:
	if amount <= 0:
		return goblin_charges

	goblin_charges += amount
	goblin_charge_changed.emit(goblin_charges, amount)
	return goblin_charges


func consume_goblin_charge(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if goblin_charges < amount:
		return false

	goblin_charges -= amount
	goblin_charge_changed.emit(goblin_charges, -amount)
	return true


func add_orc_charge(amount: int = 1) -> int:
	if amount <= 0:
		return orc_charges

	orc_charges += amount
	orc_charge_changed.emit(orc_charges, amount)
	return orc_charges


func consume_orc_charge(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if orc_charges < amount:
		return false

	orc_charges -= amount
	orc_charge_changed.emit(orc_charges, -amount)
	return true


func add_skeleton_charge(amount: int = 1) -> int:
	if amount <= 0:
		return skeleton_charges

	skeleton_charges += amount
	skeleton_charge_changed.emit(skeleton_charges, amount)
	return skeleton_charges


func consume_skeleton_charge(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if skeleton_charges < amount:
		return false

	skeleton_charges -= amount
	skeleton_charge_changed.emit(skeleton_charges, -amount)
	return true


func reset() -> void:
	total_vestige = 0
	total_changed.emit(total_vestige, 0)
	goblin_charges = 0
	goblin_charge_changed.emit(goblin_charges, 0)
	orc_charges = 0
	orc_charge_changed.emit(orc_charges, 0)
	skeleton_charges = 0
	skeleton_charge_changed.emit(skeleton_charges, 0)
