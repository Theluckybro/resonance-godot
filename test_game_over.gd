extends Node

# Simple test script to verify Game Over functionality
# Attach this to any node in a scene to test

func _ready() -> void:
	print("Game Over Test Ready - Press 'T' to trigger player death and test Game Over UI")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			_trigger_game_over_test()

func _trigger_game_over_test() -> void:
	print("Triggering Game Over test...")
	
	# Find the player in the scene
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player found, triggering death...")
		# Set player health to 0 to trigger death
		player.current_health = 0
		player.receive_hit(1)  # This should trigger the death sequence
	else:
		print("No player found in scene!")
