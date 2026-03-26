extends Node

## Signal emitted when pause state changes
signal pause_toggled(is_paused: bool)

## Whether the game is currently paused
var _is_paused: bool = false

## Nodes that should be paused (player, enemies, projectiles, etc.)
var _pausable_nodes: Array[Node] = []

## Audio bus for muffling effect
var _master_bus_index: int = -1

## Input debounce flag
var _input_consumed: bool = false


func _ready() -> void:
	# Verify input actions are set up
	var missing = GameInput.get_missing_actions()
	if missing.size() > 0:
		push_error("PauseManager: Missing input actions: ", missing)
	
	# Find master audio bus for muffling
	_master_bus_index = AudioServer.get_bus_index("Master")
	if _master_bus_index == -1:
		push_warning("PauseManager: Master audio bus not found")
	
	print("PauseManager initialized successfully")


func _process(_delta: float) -> void:
	# Check for pause input with debounce
	if GameInput.is_pause_pressed():
		if not _input_consumed:
			print("PauseManager: Pause input detected, toggling pause")
			toggle_pause()
			_input_consumed = true
	else:
		_input_consumed = false


## Toggle pause state (pause -> unpause or unpause -> pause)
func toggle_pause() -> void:
	if _is_paused:
		resume()
	else:
		pause()


## Pause the game
func pause() -> void:
	if _is_paused:
		return
	
	_is_paused = true
	_disable_game_nodes()
	_apply_audio_muffling(true)
	pause_toggled.emit(true)


## Resume the game
func resume() -> void:
	if not _is_paused:
		return
	
	_is_paused = false
	_enable_game_nodes()
	_apply_audio_muffling(false)
	pause_toggled.emit(false)


## Returns whether the game is paused
func is_paused() -> bool:
	return _is_paused


## Register a node to be paused/resumed
func register_pausable_node(node: Node) -> void:
	if node and not node in _pausable_nodes:
		_pausable_nodes.append(node)


## Unregister a node from pause control
func unregister_pausable_node(node: Node) -> void:
	if node in _pausable_nodes:
		_pausable_nodes.erase(node)


## Disable physics and process on all pausable nodes
func _disable_game_nodes() -> void:
	for node in _pausable_nodes:
		if is_instance_valid(node):
			node.set_physics_process(false)
			node.set_process(false)
			# Also disable any AnimationPlayer children
			_disable_animations(node)


## Enable physics and process on all pausable nodes
func _enable_game_nodes() -> void:
	for node in _pausable_nodes:
		if is_instance_valid(node):
			node.set_physics_process(true)
			node.set_process(true)
			# Re-enable any AnimationPlayer children
			_enable_animations(node)


## Recursively disable AnimationPlayers
func _disable_animations(node: Node) -> void:
	if node is AnimationPlayer:
		node.pause()
	
	for child in node.get_children():
		_disable_animations(child)


## Recursively enable AnimationPlayers
func _enable_animations(node: Node) -> void:
	if node is AnimationPlayer:
		var anim_player := node as AnimationPlayer
		var current_anim: StringName = anim_player.current_animation
		if current_anim != &"" and anim_player.has_animation(current_anim):
			anim_player.play(current_anim)
	
	for child in node.get_children():
		_enable_animations(child)


## Apply or remove audio muffling effect
func _apply_audio_muffling(muffled: bool) -> void:
	if _master_bus_index == -1:
		return
	
	if muffled:
		# Reduce volume to 0.3x (roughly -10dB)
		var volume_db = linear_to_db(0.3)
		AudioServer.set_bus_volume_db(_master_bus_index, volume_db)
	else:
		# Restore normal volume (0dB)
		AudioServer.set_bus_volume_db(_master_bus_index, 0.0)


## Clean up pause state when switching scenes
func _on_scene_changed() -> void:
	if _is_paused:
		resume()
