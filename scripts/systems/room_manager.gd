extends Node2D
class_name RoomManager

signal room_cleared
signal wave_started(wave_number: int)

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
const SFX_WAVE_START: AudioStream = preload("res://assets/audio/sfx/WaveStart.mp3")
const SFX_ROOM_CLEAR: AudioStream = preload("res://assets/audio/sfx/RoomClear.mp3")
const BGM_INGAME: AudioStream = preload("res://assets/audio/music/BGM_不条理モード.mp3")

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
@export var y_sort_container_path: NodePath = ^"YSortWorld"
@export var enemies_per_wave: int = 3
@export_enum("early", "mid", "pressure") var wave_profile: String = "early"
@export var auto_spawn_on_ready: bool = true
@export var debug_force_goblin_drop_100_in_this_room: bool = false
@export var debug_force_goblin_drop_debug_build_only: bool = true
@export var debug_force_orc_drop_100_in_this_room: bool = false
@export var debug_force_orc_drop_debug_build_only: bool = true

var spawned_enemies: Array[Node] = []
var is_room_cleared: bool = false
var current_wave: int = 0
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_sfx_player()
	_ensure_bgm_player()
	_play_bgm(BGM_INGAME)
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
	_play_sfx(SFX_ROOM_CLEAR)
	print("ROOM CLEAR")


func spawn_wave() -> void:
	if not _has_complete_species_roster():
		push_warning("RoomManager species roster scene is missing")
		return

	current_wave += 1
	is_room_cleared = false
	spawned_enemies.clear()
	wave_started.emit(current_wave)
	_play_sfx(SFX_WAVE_START)

	var spawn_points := _collect_spawn_points()
	if spawn_points.is_empty():
		spawn_points = [
			global_position + Vector2(72, 0),
			global_position + Vector2(-72, 0),
		]

	var wave_roles: Array[String] = _build_wave_roles(enemies_per_wave)
	var entity_parent := _get_entity_parent()
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
			if _should_force_goblin_drop_100(species_id):
				enemy.vestige_drop_chance = 1.0
			if _should_force_orc_drop_100(species_id):
				enemy.vestige_drop_chance = 1.0
		if enemy_instance is Node2D:
			var enemy_node := enemy_instance as Node2D
			enemy_node.global_position = spawn_points[i % spawn_points.size()]
		entity_parent.add_child(enemy_instance)
		spawned_enemies.append(enemy_instance)


func _ensure_sfx_player() -> void:
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer"
		add_child(sfx_player)

	sfx_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


func _ensure_bgm_player() -> void:
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BgmPlayer"
		add_child(bgm_player)

	# Keep BGM audible while SceneTree is paused; pause effect is handled via bus attenuation.
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.stream_paused = false
	bgm_player.bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"


func _play_bgm(stream: AudioStream) -> void:
	if stream == null:
		return
	if bgm_player == null:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return

	bgm_player.stream = stream
	bgm_player.volume_db = 0.0
	bgm_player.play()


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	if sfx_player == null:
		return

	sfx_player.stream = stream
	sfx_player.play()


func _should_force_goblin_drop_100(species_id: String) -> bool:
	if species_id != SPECIES_GOBLIN:
		return false
	if not debug_force_goblin_drop_100_in_this_room:
		return false
	if debug_force_goblin_drop_debug_build_only and not OS.is_debug_build():
		return false
	return true


func _should_force_orc_drop_100(species_id: String) -> bool:
	if species_id != SPECIES_ORC:
		return false
	if not debug_force_orc_drop_100_in_this_room:
		return false
	if debug_force_orc_drop_debug_build_only and not OS.is_debug_build():
		return false
	return true


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
	var markers := find_children("SpawnPoint*", "Marker2D", true, false)
	for marker_node in markers:
		if not marker_node is Marker2D:
			continue
		var marker := marker_node as Marker2D
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
		var spawn_marker := _find_marker("PlayerSpawn")
		if spawn_marker is Marker2D:
			(player_instance as Node2D).global_position = (spawn_marker as Marker2D).global_position
	_get_entity_parent().add_child(player_instance)


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


func _get_entity_parent() -> Node:
	if y_sort_container_path.is_empty():
		return self

	var candidate := get_node_or_null(y_sort_container_path)
	if candidate == null:
		return self
	return candidate


func _find_marker(marker_name: String) -> Marker2D:
	var markers := find_children(marker_name, "Marker2D", true, false)
	if markers.is_empty():
		return null
	if markers[0] is Marker2D:
		return markers[0] as Marker2D
	return null
