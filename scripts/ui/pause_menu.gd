extends CanvasLayer

# Audio volume constants
const MIN_DB: float = -80.0
const MAX_DB: float = 3.0
const SFX_UI_CLICK: AudioStream = preload("res://assets/audio/sfx/UiClick.mp3")

# Track previous window size for fullscreen toggle
var _prev_window_size: Vector2i = Vector2i(320, 180)
var _ui_click_player: AudioStreamPlayer

# Node references
@onready var panel: Panel = $Panel
@onready var main_buttons: VBoxContainer = $Panel/VBoxContainer/MainButtons
@onready var settings_menu: VBoxContainer = $Panel/VBoxContainer/SettingsMenu
@onready var video_menu: VBoxContainer = $Panel/VBoxContainer/VideoMenu
@onready var audio_menu: VBoxContainer = $Panel/VBoxContainer/AudioMenu

@onready var resume_button: Button = $Panel/VBoxContainer/MainButtons/ResumeButton
@onready var settings_button: Button = $Panel/VBoxContainer/MainButtons/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/MainButtons/QuitButton
@onready var video_button: Button = $Panel/VBoxContainer/SettingsMenu/VideoButton
@onready var audio_button: Button = $Panel/VBoxContainer/SettingsMenu/AudioButton
@onready var back_button: Button = $Panel/VBoxContainer/SettingsMenu/BackButton
@onready var back_button_video: Button = $Panel/VBoxContainer/VideoMenu/BackButton2
@onready var back_button_audio: Button = $Panel/VBoxContainer/AudioMenu/BackButton3

@onready var resolution_option: OptionButton = $Panel/VBoxContainer/VideoMenu/ResolutionOption
@onready var fullscreen_toggle: CheckButton = $Panel/VBoxContainer/VideoMenu/FullscreenContainer/FullscreenToggle

@onready var volume_slider: HSlider = $Panel/VBoxContainer/AudioMenu/VolumeSlider
@onready var volume_value_label: Label = $Panel/VBoxContainer/AudioMenu/VolumeValue
@onready var mute_toggle: CheckButton = $Panel/VBoxContainer/AudioMenu/MuteContainer/MuteToggle


func _ready() -> void:
	# Initialize previous window size
	_prev_window_size = DisplayServer.window_get_size()
	_ensure_ui_click_player()
	_connect_runtime_signals()
	
	# Keep pause panel centered across window resize/fullscreen changes
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_center_panel")
	
	# Subscribe to pause manager signals
	if not PauseManager.pause_toggled.is_connected(_on_pause_toggled):
		PauseManager.pause_toggled.connect(_on_pause_toggled)
	
	# Initially hidden
	visible = false
	
	# Initialize volume slider and settings
	_initialize_settings()


func _connect_runtime_signals() -> void:
	# Connect runtime in code to keep scene editable without brittle hard-coded connections.
	if not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

	if not video_button.pressed.is_connected(_on_video_pressed):
		video_button.pressed.connect(_on_video_pressed)
	if not audio_button.pressed.is_connected(_on_audio_pressed):
		audio_button.pressed.connect(_on_audio_pressed)
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if not resolution_option.item_selected.is_connected(_on_resolutions_item_selected):
		resolution_option.item_selected.connect(_on_resolutions_item_selected)
	if not fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if not back_button_video.pressed.is_connected(_on_back_to_settings_pressed):
		back_button_video.pressed.connect(_on_back_to_settings_pressed)

	if not volume_slider.value_changed.is_connected(_on_volume_value_changed):
		volume_slider.value_changed.connect(_on_volume_value_changed)
	if not mute_toggle.toggled.is_connected(_on_mute_toggled):
		mute_toggle.toggled.connect(_on_mute_toggled)
	if not back_button_audio.pressed.is_connected(_on_back_to_settings_pressed):
		back_button_audio.pressed.connect(_on_back_to_settings_pressed)

func _initialize_settings() -> void:
	# Set initial volume from audio bus
	var bus_db = AudioServer.get_bus_volume_db(0)
	var volume_percent = _db_to_percent(bus_db)
	volume_slider.value = volume_percent
	volume_value_label.text = "%d%%" % int(volume_percent)
	
	# Set initial fullscreen state
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.button_pressed = is_fullscreen
	
	# Set initial mute state
	var is_muted = AudioServer.is_bus_mute(0)
	mute_toggle.button_pressed = is_muted


func _ensure_ui_click_player() -> void:
	if _ui_click_player != null:
		return

	_ui_click_player = AudioStreamPlayer.new()
	_ui_click_player.name = "UiClickPlayer"
	_ui_click_player.stream = SFX_UI_CLICK
	_ui_click_player.bus = "Master"
	add_child(_ui_click_player)


func _play_ui_click() -> void:
	if _ui_click_player == null:
		return
	# Restart the click so rapid menu navigation still gives audible feedback.
	_ui_click_player.stop()
	_ui_click_player.play()


# Main buttons handlers
func _on_resume_pressed() -> void:
	_play_ui_click()
	PauseManager.resume()


func _on_settings_pressed() -> void:
	_play_ui_click()
	main_buttons.visible = false
	settings_menu.visible = true
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	_play_ui_click()
	PauseManager.resume()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/core/main.tscn")


# Settings menu handlers
func _on_back_pressed() -> void:
	_play_ui_click()
	settings_menu.visible = false
	main_buttons.visible = true
	settings_button.grab_focus()


func _on_video_pressed() -> void:
	_play_ui_click()
	settings_menu.visible = false
	video_menu.visible = true


func _on_audio_pressed() -> void:
	_play_ui_click()
	settings_menu.visible = false
	audio_menu.visible = true


func _on_back_to_settings_pressed() -> void:
	_play_ui_click()
	video_menu.visible = false
	audio_menu.visible = false
	settings_menu.visible = true


# Video menu handlers
func _on_resolutions_item_selected(index: int) -> void:
	_play_ui_click()
	# Compute chosen size from selected index
	var chosen_size: Vector2i = Vector2i(320, 180)
	match index:
		0:
			chosen_size = Vector2i(320, 180)
		1:
			chosen_size = Vector2i(640, 360)
		2:
			chosen_size = Vector2i(1280, 720)
		3:
			chosen_size = Vector2i(1920, 1080)
	
	# If fullscreen, remember size; if windowed, apply now
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		_prev_window_size = chosen_size
	else:
		DisplayServer.window_set_size(chosen_size)
		_prev_window_size = chosen_size


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	_play_ui_click()
	if toggled_on:
		# Store current window size then go fullscreen
		_prev_window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Return to windowed mode and restore previous size
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_prev_window_size)


# Audio menu handlers
func _on_volume_value_changed(value: float) -> void:
	var db: float = 0.0
	if value <= 50.0:
		var t_low: float = clamp(value / 50.0, 0.0, 1.0)
		db = lerp(MIN_DB, 0.0, t_low)
	else:
		var t_high: float = clamp((value - 50.0) / 50.0, 0.0, 1.0)
		db = lerp(0.0, MAX_DB, t_high)
	
	AudioServer.set_bus_volume_db(0, db)
	volume_value_label.text = "%d%%" % int(value)


func _on_mute_toggled(toggled_on: bool) -> void:
	_play_ui_click()
	AudioServer.set_bus_mute(0, toggled_on)


# Pause manager callback
func _on_pause_toggled(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		_center_panel()
		_reset_to_main_buttons()
		# Reinitialize settings when showing pause menu
		_initialize_settings()
		resume_button.grab_focus()


func _on_viewport_size_changed() -> void:
	_center_panel()


func _center_panel() -> void:
	# Ensure the panel is always centered in the current viewport.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.position = (viewport_size - panel.size) * 0.5


# Reset UI to main buttons view
func _reset_to_main_buttons() -> void:
	main_buttons.visible = true
	settings_menu.visible = false
	video_menu.visible = false
	audio_menu.visible = false


# Helper to convert dB to percentage
func _db_to_percent(db: float) -> float:
	if db <= -80.0:
		return 0.0
	elif db <= 0.0:
		var t_low: float = (db - MIN_DB) / (0.0 - MIN_DB)
		return t_low * 50.0
	else:
		var t_high: float = db / MAX_DB
		return 50.0 + (t_high * 50.0)
