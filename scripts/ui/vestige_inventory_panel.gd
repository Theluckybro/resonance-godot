extends CanvasLayer
class_name VestigeInventoryPanel

const SPECIES_GOBLIN: String = "goblin"
const SPECIES_ORC: String = "orc"
const SPECIES_SKELETON: String = "skeleton"
const VESTIGE_DATA_PATH: String = "res://data/vestiges/VestigeData.json"
const SLOT_LABELS: Array[String] = ["Q", "E", "R", "Shift"]
const COLOR_GOBLIN: Color = Color(0.8, 1.0, 0.6)
const COLOR_ORC: Color = Color(0.9, 0.6, 0.4)
const COLOR_SKELETON: Color = Color(0.7, 0.8, 1.0)
const COLOR_EMPTY: Color = Color(0.5, 0.5, 0.5)
const COLOR_NEUTRAL: Color = Color(1.0, 1.0, 1.0)

@onready var inventory_grid: GridContainer = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/LeftColumnMargin/VBoxContainer/InventoryGrid")
@onready var item_name_label: Label = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/DetailAreaMargin/DetailVBox/ItemNameLabel")
@onready var item_desc_label: RichTextLabel = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/DetailAreaMargin/DetailVBox/ItemDescLabel")

@onready var icon_q_panel: Panel = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/EquipAreaVBox/EquippedSkillVBox/QER_Row/SlotQ_Box/Icon_Q")
@onready var icon_e_panel: Panel = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/EquipAreaVBox/EquippedSkillVBox/QER_Row/SlotE_Box/Icon_E")
@onready var icon_r_panel: Panel = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/EquipAreaVBox/EquippedSkillVBox/QER_Row/SlotR_Box/Icon_R")
@onready var icon_shift_panel: Panel = get_node_or_null("BackgroundPanel/MarginContainer/MainVBox/BodyHBox/RightColumnVBox/EquipAreaVBox/EquippedSkillVBox/Shift_Row/CenterContainer/Icon_Shift")

var selected_species: String = ""
var inventory_cell_panels: Array[Panel] = []
var vestige_data_by_species: Dictionary = {}


func _has_inventory_singleton() -> bool:
	var tree := get_tree()
	return tree != null and tree.root != null and tree.root.has_node("VestigeInventory")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	set_process_unhandled_input(true)
	visible = false
	_load_vestige_data()
	_collect_inventory_cells()
	_connect_ui_signals()
	_connect_inventory_signals()
	_refresh_all()


func open_panel() -> void:
	visible = true
	_refresh_all()


func close_panel() -> void:
	visible = false


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func is_open() -> bool:
	return visible


func _collect_inventory_cells() -> void:
	inventory_cell_panels.clear()
	if inventory_grid == null:
		return

	for i in range(24):
		var panel_name := "Panel" if i == 0 else "Panel%d" % (i + 1)
		var panel := inventory_grid.get_node_or_null(panel_name)
		if panel is Panel:
			inventory_cell_panels.append(panel as Panel)


func _connect_ui_signals() -> void:
	for i in range(inventory_cell_panels.size()):
		var panel := inventory_cell_panels[i]
		if panel != null and not panel.gui_input.is_connected(_on_inventory_cell_clicked):
			panel.gui_input.connect(_on_inventory_cell_clicked.bind(i))

	var slot_panels: Array[Panel] = [icon_q_panel, icon_e_panel, icon_r_panel, icon_shift_panel]
	for slot_index in range(slot_panels.size()):
		var slot_panel := slot_panels[slot_index]
		if slot_panel != null and not slot_panel.gui_input.is_connected(_on_slot_icon_clicked):
			slot_panel.gui_input.connect(_on_slot_icon_clicked.bind(slot_index))


func _connect_inventory_signals() -> void:
	if not _has_inventory_singleton():
		return

	if not VestigeInventory.goblin_charge_changed.is_connected(_on_inventory_changed):
		VestigeInventory.goblin_charge_changed.connect(_on_inventory_changed)
	if not VestigeInventory.orc_charge_changed.is_connected(_on_inventory_changed):
		VestigeInventory.orc_charge_changed.connect(_on_inventory_changed)
	if not VestigeInventory.skeleton_charge_changed.is_connected(_on_inventory_changed):
		VestigeInventory.skeleton_charge_changed.connect(_on_inventory_changed)
	if not VestigeInventory.loadout_changed.is_connected(_on_loadout_changed):
		VestigeInventory.loadout_changed.connect(_on_loadout_changed)


func _on_inventory_changed(_new_total: int, _delta: int) -> void:
	_refresh_all()


func _on_loadout_changed(_slots: Array[String]) -> void:
	_refresh_all()


func _on_inventory_cell_clicked(event: InputEvent, cell_index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var species_at_cell := _get_cell_species(cell_index)
	if species_at_cell.is_empty():
		return

	_select_species(species_at_cell)
	get_viewport().set_input_as_handled()


func _on_slot_icon_clicked(event: InputEvent, slot_index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	_try_equip_to_slot(slot_index)
	get_viewport().set_input_as_handled()


func _get_cell_species(cell_index: int) -> String:
	if not _has_inventory_singleton():
		return ""
	if cell_index < 0 or cell_index >= 24:
		return ""

	var goblin_count := VestigeInventory.get_charge(SPECIES_GOBLIN)
	var orc_count := VestigeInventory.get_charge(SPECIES_ORC)
	var skeleton_count := VestigeInventory.get_charge(SPECIES_SKELETON)

	if cell_index < goblin_count:
		return SPECIES_GOBLIN
	if cell_index < goblin_count + orc_count:
		return SPECIES_ORC
	if cell_index < goblin_count + orc_count + skeleton_count:
		return SPECIES_SKELETON
	return ""


func _select_species(species_id: String) -> void:
	if not _has_inventory_singleton():
		return

	selected_species = species_id
	_refresh_inventory_tints()
	_refresh_detail_panel("")


func _try_equip_to_slot(slot_index: int) -> void:
	if selected_species.is_empty():
		_refresh_detail_panel("Klik vestige di inventory dulu.")
		return
	if not _has_inventory_singleton():
		return
	if VestigeInventory.get_charge(selected_species) <= 0:
		_refresh_detail_panel("%s belum punya charge." % _display_name(selected_species))
		return

	if VestigeInventory.equip_vestige_to_slot(selected_species, slot_index):
		_refresh_detail_panel("%s dipasang ke slot %s." % [_display_name(selected_species), SLOT_LABELS[slot_index]])
		_refresh_all()
	else:
		var reason := VestigeInventory.get_last_equip_error()
		_refresh_detail_panel(reason if not reason.is_empty() else "Gagal equip vestige ke slot.")


func _refresh_all() -> void:
	_refresh_inventory_tints()
	_refresh_slot_tints()
	_refresh_detail_panel("")


func _refresh_inventory_tints() -> void:
	for i in range(inventory_cell_panels.size()):
		var panel := inventory_cell_panels[i]
		if panel == null:
			continue

		var species := _get_cell_species(i)
		var tint_color := COLOR_NEUTRAL

		if species == SPECIES_GOBLIN:
			tint_color = COLOR_GOBLIN
		elif species == SPECIES_ORC:
			tint_color = COLOR_ORC
		elif species == SPECIES_SKELETON:
			tint_color = COLOR_SKELETON
		elif species.is_empty():
			tint_color = COLOR_EMPTY

		if species == selected_species and not species.is_empty():
			tint_color = tint_color.lightened(0.2)

		panel.modulate = tint_color


func _refresh_slot_tints() -> void:
	if not _has_inventory_singleton():
		return

	var slots := VestigeInventory.get_equipped_slots()
	var slot_panels: Array[Panel] = [icon_q_panel, icon_e_panel, icon_r_panel, icon_shift_panel]

	for slot_index in range(slot_panels.size()):
		var panel := slot_panels[slot_index]
		if panel == null:
			continue

		var equipped_species := _slot_species(slots, slot_index)
		var tint_color := COLOR_EMPTY
		if equipped_species == SPECIES_GOBLIN:
			tint_color = COLOR_GOBLIN
		elif equipped_species == SPECIES_ORC:
			tint_color = COLOR_ORC
		elif equipped_species == SPECIES_SKELETON:
			tint_color = COLOR_SKELETON

		panel.modulate = tint_color


func _refresh_detail_panel(message: String) -> void:
	if not _has_inventory_singleton():
		if item_name_label:
			item_name_label.text = "Nama: -"
		if item_desc_label:
			item_desc_label.clear()
			item_desc_label.append_text(message if not message.is_empty() else "Klik vestige di inventory untuk melihat detail.")
		return

	if selected_species.is_empty():
		if item_name_label:
			item_name_label.text = "Nama: -"
		if item_desc_label:
			item_desc_label.clear()
			item_desc_label.append_text(message if not message.is_empty() else "Klik vestige di inventory untuk melihat detail.")
		return

	var charge := VestigeInventory.get_charge(selected_species)
	if item_name_label:
		item_name_label.text = "Nama: %s" % _display_name(selected_species)

	var detail_text := "Deskripsi: %s\nEfek: %s\n\nCharge: %d" % [_description_for(selected_species), _effect_for(selected_species), charge]
	if not message.is_empty():
		detail_text = "%s\n\n%s" % [detail_text, message]

	if item_desc_label:
		item_desc_label.clear()
		item_desc_label.append_text(detail_text)


func _slot_species(slots: Array[String], slot_index: int) -> String:
	if slot_index < 0 or slot_index >= slots.size():
		return ""
	return slots[slot_index]


func _load_vestige_data() -> void:
	vestige_data_by_species.clear()
	if not FileAccess.file_exists(VESTIGE_DATA_PATH):
		push_warning("Vestige data file tidak ditemukan: %s" % VESTIGE_DATA_PATH)
		return

	var file := FileAccess.open(VESTIGE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Gagal membuka vestige data file: %s" % VESTIGE_DATA_PATH)
		return

	var raw_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("Format JSON vestige tidak valid (harus Dictionary).")
		return

	var root_dict: Dictionary = parsed as Dictionary
	var vestiges: Variant = root_dict.get("vestiges", {})
	if vestiges is Dictionary:
		vestige_data_by_species = vestiges as Dictionary
	else:
		push_warning("Key 'vestiges' tidak ditemukan atau bukan Dictionary.")


func _description_for(species_id: String) -> String:
	var entry := _get_vestige_entry(species_id)
	if entry.has("description"):
		return str(entry.get("description", ""))
	return "Tidak ada detail vestige."


func _effect_for(species_id: String) -> String:
	var entry := _get_vestige_entry(species_id)
	if entry.has("effect"):
		return str(entry.get("effect", ""))
	return "Tidak ada efek vestige."


func _display_name(species_id: String) -> String:
	var entry := _get_vestige_entry(species_id)
	if entry.has("name"):
		return str(entry.get("name", "-"))
	return "-"


func _get_vestige_entry(species_id: String) -> Dictionary:
	var species_key := species_id.strip_edges().to_lower()
	if not vestige_data_by_species.has(species_key):
		return {}

	var entry: Variant = vestige_data_by_species.get(species_key, {})
	if entry is Dictionary:
		return entry as Dictionary
	return {}
