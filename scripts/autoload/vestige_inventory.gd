extends Node

signal total_changed(new_total: int, delta: int)
signal goblin_charge_changed(new_total: int, delta: int)
signal orc_charge_changed(new_total: int, delta: int)
signal skeleton_charge_changed(new_total: int, delta: int)
signal slot_changed(slot_index: int, species_id: String)
signal loadout_changed(slots: Array[String])

const SPECIES_GOBLIN: String = "goblin"
const SPECIES_ORC: String = "orc"
const SPECIES_SKELETON: String = "skeleton"
const SLOT_COUNT: int = 4

var total_vestige: int = 0
var goblin_charges: int = 0
var orc_charges: int = 0
var skeleton_charges: int = 0
var equipped_slots: Array[String] = ["", "", "", ""]
var last_equip_error: String = ""


func get_total() -> int:
	return total_vestige


func get_equipped_slots() -> Array[String]:
	return equipped_slots.duplicate()


func get_equipped_species(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= equipped_slots.size():
		return ""
	return equipped_slots[slot_index]


func get_last_equip_error() -> String:
	return last_equip_error


func equip_vestige_to_slot(species_id: String, slot_index: int) -> bool:
	last_equip_error = ""
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		last_equip_error = "Slot tidak valid."
		return false

	var normalized_species := species_id.strip_edges().to_lower()
	if not _is_supported_species(normalized_species):
		last_equip_error = "Spesies vestige tidak didukung."
		return false

	if _is_species_equipped_in_other_slot(normalized_species, slot_index):
		last_equip_error = "%s sudah dipasang di slot lain." % _display_name(normalized_species)
		return false

	equipped_slots[slot_index] = normalized_species
	slot_changed.emit(slot_index, normalized_species)
	loadout_changed.emit(get_equipped_slots())
	return true


func clear_slot(slot_index: int) -> bool:
	last_equip_error = ""
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	if equipped_slots[slot_index].is_empty():
		return false

	equipped_slots[slot_index] = ""
	slot_changed.emit(slot_index, "")
	loadout_changed.emit(get_equipped_slots())
	return true


func get_charge(species_id: String) -> int:
	match species_id.strip_edges().to_lower():
		SPECIES_GOBLIN:
			return goblin_charges
		SPECIES_ORC:
			return orc_charges
		SPECIES_SKELETON:
			return skeleton_charges
	return 0


func has_charge(species_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	return get_charge(species_id) >= amount


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
	total_vestige = maxi(total_vestige - amount, 0)
	total_changed.emit(total_vestige, -amount)
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
	total_vestige = maxi(total_vestige - amount, 0)
	total_changed.emit(total_vestige, -amount)
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
	total_vestige = maxi(total_vestige - amount, 0)
	total_changed.emit(total_vestige, -amount)
	skeleton_charge_changed.emit(skeleton_charges, -amount)
	return true


func consume_charge(species_id: String, amount: int = 1) -> bool:
	match species_id.strip_edges().to_lower():
		SPECIES_GOBLIN:
			return consume_goblin_charge(amount)
		SPECIES_ORC:
			return consume_orc_charge(amount)
		SPECIES_SKELETON:
			return consume_skeleton_charge(amount)
	return false


func reset() -> void:
	last_equip_error = ""
	total_vestige = 0
	total_changed.emit(total_vestige, 0)
	goblin_charges = 0
	goblin_charge_changed.emit(goblin_charges, 0)
	orc_charges = 0
	orc_charge_changed.emit(orc_charges, 0)
	skeleton_charges = 0
	skeleton_charge_changed.emit(skeleton_charges, 0)
	equipped_slots = ["", "", "", ""]
	loadout_changed.emit(get_equipped_slots())


func _is_supported_species(species_id: String) -> bool:
	return species_id == SPECIES_GOBLIN \
		or species_id == SPECIES_ORC \
		or species_id == SPECIES_SKELETON


func _is_species_equipped_in_other_slot(species_id: String, target_slot_index: int) -> bool:
	for slot_index in range(equipped_slots.size()):
		if slot_index == target_slot_index:
			continue
		if equipped_slots[slot_index] == species_id:
			return true
	return false


func _display_name(species_id: String) -> String:
	match species_id:
		SPECIES_GOBLIN:
			return "Goblin"
		SPECIES_ORC:
			return "Orc"
		SPECIES_SKELETON:
			return "Skeleton"
		_:
			return "Unknown"
