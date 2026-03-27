extends Node

enum Difficulty { EASY, NORMAL, HARD }

var selected_difficulty: Difficulty = Difficulty.NORMAL


func set_selected_difficulty(difficulty: Difficulty) -> void:
	selected_difficulty = difficulty


func get_selected_difficulty() -> Difficulty:
	return selected_difficulty
