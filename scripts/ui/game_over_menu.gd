extends CanvasLayer

signal retry_requested()
signal main_menu_requested()

@export var show_delay: float = 2.0

@onready var color_rect: ColorRect = $ColorRect
@onready var panel: Panel = $Panel
@onready var retry_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/RetryButton
@onready var main_menu_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/MainMenuButton

var _show_timer: float = 0.0
var _is_ready_to_show: bool = false

func _ready() -> void:
	visible = false
	# Signals are already connected in scene file, no need to connect here

func _process(delta: float) -> void:
	if not _is_ready_to_show:
		return
	
	_show_timer -= delta
	if _show_timer <= 0.0:
		_show_game_over()

func show_game_over() -> void:
	_is_ready_to_show = true
	_show_timer = show_delay

func _show_game_over() -> void:
	_is_ready_to_show = false
	visible = true
	
	# Block game input like pause menu
	
func hide_game_over() -> void:
	visible = false
	_is_ready_to_show = false
	_show_timer = 0.0

func _on_retry_button_pressed() -> void:
	print("Retry button pressed")
	retry_requested.emit()
	# Resume game before hiding to ensure smooth transition
	hide_game_over()

func _on_main_menu_button_pressed() -> void:
	print("Main menu button pressed")
	main_menu_requested.emit()
	# Resume game before hiding to ensure smooth transition
	hide_game_over()
