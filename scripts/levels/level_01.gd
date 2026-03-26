extends RoomManager

@export_group("Level 01 Map")
@export var fallback_map_width_tiles: int = 30
@export var fallback_map_height_tiles: int = 18
@export var fallback_tile_size: Vector2i = Vector2i(16, 16)

@onready var map_floor: TileMapLayer = get_node_or_null("MapFloor") as TileMapLayer
@onready var map_walls: TileMapLayer = get_node_or_null("YSortWorld/MapWalls") as TileMapLayer
@onready var wave_notification: WaveNotification = get_node_or_null("WaveNotification/WaveNotification") as WaveNotification

var level_camera: Camera2D
var tracked_player: Node2D
var _is_paused: bool = false

func _ready() -> void:
	_configure_render_layers()
	_build_world_bounds()
	super._ready()
	_setup_level_camera()
	_setup_wave_notifications()
	_setup_pause_system()


func _process(delta: float) -> void:
	super._process(delta)
	_update_camera_tracking()


func _configure_render_layers() -> void:
	if map_floor != null:
		map_floor.z_index = -1
	if map_walls != null:
		map_walls.z_index = 0
		map_walls.y_sort_enabled = true


func _setup_level_camera() -> void:
	if level_camera == null:
		level_camera = Camera2D.new()
		level_camera.name = "LevelCamera"
		level_camera.position_smoothing_enabled = true
		level_camera.position_smoothing_speed = 8.0
		add_child(level_camera)

	level_camera.make_current()
	var map_rect_px := _calculate_map_rect_px()
	level_camera.limit_left = int(map_rect_px.position.x)
	level_camera.limit_top = int(map_rect_px.position.y)
	level_camera.limit_right = int(map_rect_px.end.x)
	level_camera.limit_bottom = int(map_rect_px.end.y)

	tracked_player = get_tree().get_first_node_in_group("player") as Node2D
	_update_camera_tracking()


func _build_world_bounds() -> void:
	var existing := get_node_or_null("WorldBounds")
	if existing != null:
		existing.queue_free()

	var world_bounds := Node2D.new()
	world_bounds.name = "WorldBounds"
	add_child(world_bounds)

	var map_rect_px := _calculate_map_rect_px()
	var map_left := map_rect_px.position.x
	var map_top := map_rect_px.position.y
	var map_right := map_rect_px.end.x
	var map_bottom := map_rect_px.end.y
	var map_width_px := map_rect_px.size.x
	var map_height_px := map_rect_px.size.y
	var thickness := float(_resolve_tile_size().x)

	_add_bound_body(world_bounds, "BoundLeft", Vector2(map_left - thickness * 0.5, map_top + map_height_px * 0.5), Vector2(thickness, map_height_px + thickness * 2.0))
	_add_bound_body(world_bounds, "BoundRight", Vector2(map_right + thickness * 0.5, map_top + map_height_px * 0.5), Vector2(thickness, map_height_px + thickness * 2.0))
	_add_bound_body(world_bounds, "BoundTop", Vector2(map_left + map_width_px * 0.5, map_top - thickness * 0.5), Vector2(map_width_px + thickness * 2.0, thickness))
	_add_bound_body(world_bounds, "BoundBottom", Vector2(map_left + map_width_px * 0.5, map_bottom + thickness * 0.5), Vector2(map_width_px + thickness * 2.0, thickness))


func _calculate_map_rect_px() -> Rect2:
	var all_cells: Array[Vector2i] = []
	if map_floor != null:
		all_cells.append_array(map_floor.get_used_cells())
	if map_walls != null:
		all_cells.append_array(map_walls.get_used_cells())

	var tile_size_px := _resolve_tile_size()
	if all_cells.is_empty():
		return Rect2(
			Vector2.ZERO,
			Vector2(fallback_map_width_tiles * tile_size_px.x, fallback_map_height_tiles * tile_size_px.y)
		)

	var min_cell := all_cells[0]
	var max_cell := all_cells[0]
	for cell in all_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	var origin := Vector2(min_cell.x * tile_size_px.x, min_cell.y * tile_size_px.y)
	var size := Vector2((max_cell.x - min_cell.x + 1) * tile_size_px.x, (max_cell.y - min_cell.y + 1) * tile_size_px.y)
	return Rect2(origin, size)


func _resolve_tile_size() -> Vector2i:
	if map_floor != null and map_floor.tile_set != null:
		return map_floor.tile_set.tile_size
	if map_walls != null and map_walls.tile_set != null:
		return map_walls.tile_set.tile_size
	return fallback_tile_size


func _add_bound_body(parent: Node2D, body_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = PhysicsLayers.ENVIRONMENT_AND_TRIGGER
	body.collision_mask = 0
	body.position = center

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)

	parent.add_child(body)


func _update_camera_tracking() -> void:
	if level_camera == null:
		return
	if tracked_player == null or not is_instance_valid(tracked_player):
		tracked_player = get_tree().get_first_node_in_group("player") as Node2D
	if tracked_player == null:
		return

	level_camera.global_position = tracked_player.global_position


func _setup_wave_notifications() -> void:
	if wave_notification == null:
		return
	
	wave_started.connect(func(wave_number: int) -> void:
		wave_notification.show_notification("Wave %d" % wave_number)
	)
	room_cleared.connect(func() -> void:
		wave_notification.show_notification("Room Clear")
	)


func _setup_pause_system() -> void:
	# Register the level as pausable
	if PauseManager:
		# Register player node
		var player = get_tree().get_first_node_in_group("player")
		if player:
			PauseManager.register_pausable_node(player)
		
		# Register enemy spawner (this)
		PauseManager.register_pausable_node(self)
		
		# Subscribe to pause events
		PauseManager.pause_toggled.connect(_on_pause_toggled)


func _on_pause_toggled(is_paused: bool) -> void:
	_is_paused = is_paused
	# Pause/unpause all spawned enemies
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(!is_paused)
			enemy.set_process(!is_paused)
