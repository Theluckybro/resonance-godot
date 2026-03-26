extends Control
class_name WaveNotification

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Make sure we start invisible
	modulate.a = 0.0


func show_notification(text: String) -> void:
	label.text = text
	# Reset animation and play fade-in then fade-out
	animation_player.stop()
	animation_player.play("fade_in_out")
