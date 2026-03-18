extends "res://scripts/systems/fsm/state.gd"
class_name PlayerState

# Preload Player class to ensure type recognition
const Player = preload("res://scripts/player/player.gd")


func get_player() -> Player:
	return context as Player
