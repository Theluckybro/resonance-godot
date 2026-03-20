extends CanvasLayer
class_name PlayerHeartHUD

const HEART_HP_STEP: int = 2

@export var full_heart_texture: Texture2D = preload("res://assets/Reference/Packs/0x72_DungeonTilesetII_v1.7/frames/ui_heart_full.png")
@export var half_heart_texture: Texture2D = preload("res://assets/Reference/Packs/0x72_DungeonTilesetII_v1.7/frames/ui_heart_half.png")
@export var empty_heart_texture: Texture2D = preload("res://assets/Reference/Packs/0x72_DungeonTilesetII_v1.7/frames/ui_heart_empty.png")

@onready var hearts_container: HBoxContainer = $MarginContainer/Hearts

var tracked_player: Player
var heart_nodes: Array[TextureRect] = []


func _ready() -> void:
	_connect_to_player()


func _process(_delta: float) -> void:
	if tracked_player == null or not is_instance_valid(tracked_player):
		_connect_to_player()


func _connect_to_player() -> void:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		return

	var candidate := player_nodes[0]
	if not (candidate is Player):
		return
	var candidate_player := candidate as Player

	if tracked_player == candidate_player:
		return

	if tracked_player != null:
		if tracked_player.player_damaged.is_connected(_on_player_damaged):
			tracked_player.player_damaged.disconnect(_on_player_damaged)
		if tracked_player.player_died.is_connected(_on_player_died):
			tracked_player.player_died.disconnect(_on_player_died)

	tracked_player = candidate_player

	if not tracked_player.player_damaged.is_connected(_on_player_damaged):
		tracked_player.player_damaged.connect(_on_player_damaged)
	if not tracked_player.player_died.is_connected(_on_player_died):
		tracked_player.player_died.connect(_on_player_died)

	_refresh_hearts(tracked_player.get_current_health(), tracked_player.get_max_health())


func _on_player_damaged(current_health: int, _damage_taken: int) -> void:
	if tracked_player == null:
		return
	_refresh_hearts(current_health, tracked_player.get_max_health())


func _on_player_died() -> void:
	if tracked_player == null:
		return
	_refresh_hearts(0, tracked_player.get_max_health())


func _refresh_hearts(current_hp: int, max_hp: int) -> void:
	var required_slots := maxi(1, int(ceili(float(max_hp) / float(HEART_HP_STEP))))
	if required_slots != heart_nodes.size():
		_rebuild_heart_nodes(required_slots)

	for i in heart_nodes.size():
		var fill_hp := clampi(current_hp - (i * HEART_HP_STEP), 0, HEART_HP_STEP)
		var target_texture := empty_heart_texture
		if fill_hp >= HEART_HP_STEP:
			target_texture = full_heart_texture
		elif fill_hp == (HEART_HP_STEP - 1):
			target_texture = half_heart_texture
		heart_nodes[i].texture = target_texture


func _rebuild_heart_nodes(required_slots: int) -> void:
	for child in hearts_container.get_children():
		child.queue_free()
	heart_nodes.clear()

	for _i in required_slots:
		var heart_rect := TextureRect.new()
		heart_rect.custom_minimum_size = Vector2(16.0, 16.0)
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP
		heart_rect.texture = empty_heart_texture
		heart_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hearts_container.add_child(heart_rect)
		heart_nodes.append(heart_rect)
