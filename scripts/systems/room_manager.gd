extends Node2D
class_name RoomManager

signal room_cleared

const SPECIES_GOBLIN: String = "goblin"
const SPECIES_ORC: String = "orc"
const SPECIES_SKIRMISHER: String = "species_skirmisher"
const SPECIES_SKELETON: String = "skeleton"
const SPECIES_CONTROLLER: String = "species_controller"

const ROLE_DUELIST: String = "duelist"
const ROLE_BRUISER: String = "bruiser"
const ROLE_SKIRMISHER: String = "skirmisher"
const ROLE_ARTILLERY: String = "artillery"
const ROLE_CONTROLLER: String = "controller"

const ROLE_TO_SPECIES := {
	ROLE_DUELIST: SPECIES_GOBLIN,
	ROLE_BRUISER: SPECIES_ORC,
	ROLE_SKIRMISHER: SPECIES_SKIRMISHER,
	ROLE_ARTILLERY: SPECIES_SKELETON,
	ROLE_CONTROLLER: SPECIES_CONTROLLER,
}

const SPECIES_TO_DEFAULT_ROLE := {
	SPECIES_GOBLIN: ROLE_DUELIST,
	SPECIES_ORC: ROLE_BRUISER,
	SPECIES_SKIRMISHER: ROLE_SKIRMISHER,
	SPECIES_SKELETON: ROLE_ARTILLERY,
	SPECIES_CONTROLLER: ROLE_CONTROLLER,
}

@export var goblin_scene: PackedScene = preload("res://scenes/enemies/goblin.tscn")
@export var orc_scene: PackedScene = preload("res://scenes/enemies/orc.tscn")
@export var species_skirmisher_scene: PackedScene = preload("res://scenes/enemies/species_skirmisher.tscn")
@export var skeleton_scene: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
@export var species_controller_scene: PackedScene = preload("res://scenes/enemies/species_controller.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@export var player_heart_hud_scene: PackedScene = preload("res://scenes/ui/player_heart_hud.tscn")
@export var enemies_per_wave: int = 3
@export_enum("early", "mid", "pressure") var wave_profile: String = "early"
@export var auto_spawn_on_ready: bool = true

var spawned_enemies: Array[Node] = []
var is_room_cleared: bool = false


func _ready() -> void:
	_ensure_player_exists()
	_ensure_player_heart_hud()
	if auto_spawn_on_ready:
		spawn_wave()


func _process(_delta: float) -> void:
	if is_room_cleared:
		return

	_prune_dead_enemies()
	if not spawned_enemies.is_empty():
		return

	is_room_cleared = true
	room_cleared.emit()
	print("ROOM CLEAR")


func spawn_wave() -> void:
	if not _has_complete_species_roster():
		push_warning("RoomManager species roster scene is missing")
		return

	is_room_cleared = false
	spawned_enemies.clear()

	var spawn_points := _collect_spawn_points()
	if spawn_points.is_empty():
		spawn_points = [
			global_position + Vector2(72, 0),
			global_position + Vector2(-72, 0),
		]

	var wave_roles: Array[String] = _build_wave_roles(enemies_per_wave)
	for i in wave_roles.size():
		var role: String = wave_roles[i]
		var species_id: String = _species_for_role(role)
		var selected_scene := _scene_for_species(species_id)
		if selected_scene == null:
			continue

		var enemy_instance: Node = selected_scene.instantiate()
		if enemy_instance == null:
			continue

		var default_role: String = _default_role_for_species(species_id)
		enemy_instance.set_meta("species_id", species_id)
		if role != default_role:
			enemy_instance.set_meta("role_override", role)

		if enemy_instance is Enemy:
			var enemy := enemy_instance as Enemy
			enemy.species_id = species_id
			enemy.role_id = ""
			if role != default_role:
				enemy.role_id = role
		if enemy_instance is Node2D:
			var enemy_node := enemy_instance as Node2D
			enemy_node.global_position = spawn_points[i % spawn_points.size()]
		add_child(enemy_instance)
		spawned_enemies.append(enemy_instance)


func _has_complete_species_roster() -> bool:
	return goblin_scene != null \
		and orc_scene != null \
		and species_skirmisher_scene != null \
		and skeleton_scene != null \
		and species_controller_scene != null


func _build_wave_roles(target_count: int) -> Array[String]:
	var template := _template_for_profile()
	if template.is_empty():
		template = [ROLE_DUELIST, ROLE_BRUISER, ROLE_ARTILLERY]

	template.shuffle()
	var roles: Array[String] = []
	for i in target_count:
		roles.append(template[i % template.size()])
	return roles


func _template_for_profile() -> Array[String]:
	match wave_profile:
		"early":
			return [ROLE_DUELIST, ROLE_DUELIST, ROLE_BRUISER]
		"mid":
			return [ROLE_DUELIST, ROLE_ARTILLERY, ROLE_SKIRMISHER]
		"pressure":
			return [ROLE_BRUISER, ROLE_CONTROLLER, ROLE_SKIRMISHER]
	return [ROLE_DUELIST, ROLE_BRUISER, ROLE_ARTILLERY]


func _species_for_role(role: String) -> String:
	var species_variant: Variant = ROLE_TO_SPECIES.get(role, SPECIES_GOBLIN)
	if species_variant is String:
		return species_variant as String
	return SPECIES_GOBLIN


func _default_role_for_species(species_id: String) -> String:
	var role_variant: Variant = SPECIES_TO_DEFAULT_ROLE.get(species_id, ROLE_DUELIST)
	if role_variant is String:
		return role_variant as String
	return ROLE_DUELIST


func _scene_for_species(species_id: String) -> PackedScene:
	match species_id:
		SPECIES_GOBLIN:
			return goblin_scene
		SPECIES_ORC:
			return orc_scene
		SPECIES_SKIRMISHER:
			return species_skirmisher_scene
		SPECIES_SKELETON:
			return skeleton_scene
		SPECIES_CONTROLLER:
			return species_controller_scene
	return goblin_scene


func _collect_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child in get_children():
		if not child is Marker2D:
			continue
		var marker := child as Marker2D
		if marker.name.begins_with("SpawnPoint"):
			points.append(marker.global_position)
	return points


func _ensure_player_exists() -> void:
	if not get_tree().get_nodes_in_group("player").is_empty():
		return
	if player_scene == null:
		return

	var player_instance := player_scene.instantiate()
	if player_instance == null:
		return
	if player_instance is Node2D:
		var spawn_marker := get_node_or_null("PlayerSpawn")
		if spawn_marker is Marker2D:
			(player_instance as Node2D).global_position = (spawn_marker as Marker2D).global_position
	add_child(player_instance)


func _ensure_player_heart_hud() -> void:
	if player_heart_hud_scene == null:
		return
	if get_node_or_null("PlayerHeartHUD") != null:
		return

	var heart_hud_instance := player_heart_hud_scene.instantiate()
	if heart_hud_instance == null:
		return

	heart_hud_instance.name = "PlayerHeartHUD"
	add_child(heart_hud_instance)


func _prune_dead_enemies() -> void:
	var alive_enemies: Array[Node] = []
	for enemy in spawned_enemies:
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		alive_enemies.append(enemy)
	spawned_enemies = alive_enemies
