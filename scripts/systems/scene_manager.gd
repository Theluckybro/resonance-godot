extends Node

class_name SceneManager

# Preload GameConfig script for type hints
const _GameConfigType = preload("res://scripts/autoload/game_config.gd")
const GAME_CONFIG_PATH := "/root/GameConfig"

func load_game_level(difficulty: _GameConfigType.Difficulty) -> void:
	var game_config := get_node_or_null(GAME_CONFIG_PATH)
	if game_config != null:
		game_config.set_selected_difficulty(difficulty)
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/core/main.tscn")
