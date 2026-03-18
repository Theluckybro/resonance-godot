extends Node2D
class_name RoomManager

signal room_cleared

@export var enemy_scene: PackedScene = preload("res://scenes/enemies/melee_fast.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@export var enemies_per_wave: int = 2
@export var auto_spawn_on_ready: bool = true

var spawned_enemies: Array[Node] = []
var is_room_cleared: bool = false


func _ready() -> void:
	_ensure_player_exists()
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
	if enemy_scene == null:
		push_warning("RoomManager enemy_scene is missing")
		return

	is_room_cleared = false
	spawned_enemies.clear()

	var spawn_points := _collect_spawn_points()
	if spawn_points.is_empty():
		spawn_points = [
			global_position + Vector2(72, 0),
			global_position + Vector2(-72, 0),
		]

	for i in enemies_per_wave:
		var enemy_instance := enemy_scene.instantiate()
		if enemy_instance == null:
			continue
		if enemy_instance is Node2D:
			var enemy_node := enemy_instance as Node2D
			enemy_node.global_position = spawn_points[i % spawn_points.size()]
		add_child(enemy_instance)
		spawned_enemies.append(enemy_instance)


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


func _prune_dead_enemies() -> void:
	var alive_enemies: Array[Node] = []
	for enemy in spawned_enemies:
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		alive_enemies.append(enemy)
	spawned_enemies = alive_enemies
