extends CanvasLayer

class_name MainMenu

const SFX_UI_CLICK: AudioStream = preload("res://assets/audio/sfx/UiClick.mp3")
const BGM_MAIN_MENU: AudioStream = preload("res://assets/audio/music/BGM_Little Slime's Adventure.mp3")
const _GameConfigType = preload("res://scripts/autoload/game_config.gd")

var _ui_click_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
var _bgm_bus_index: int = -1
var _sfx_bus_index: int = -1

# Node references
@onready var panel: Panel = $Panel
@onready var main_buttons: VBoxContainer = $Panel/ContentScroll/VBoxContainer/MainButtons
@onready var difficulty_panel: VBoxContainer = $Panel/ContentScroll/VBoxContainer/DifficultyPanel
@onready var settings_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/SettingsMenu
@onready var video_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/VideoMenu
@onready var audio_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/AudioMenu

@onready var play_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/PlayButton
@onready var settings_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/SettingsButton
@onready var quit_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/QuitButton

@onready var easy_button: Button = $Panel/ContentScroll/VBoxContainer/DifficultyPanel/EasyButton
@onready var normal_button: Button = $Panel/ContentScroll/VBoxContainer/DifficultyPanel/NormalButton
@onready var hard_button: Button = $Panel/ContentScroll/VBoxContainer/DifficultyPanel/HardButton
@onready var difficulty_back_button: Button = $Panel/ContentScroll/VBoxContainer/DifficultyPanel/BackButton

@onready var video_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/VideoButton
@onready var audio_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/AudioButton
@onready var settings_back_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/BackButton

@onready var resolution_option: OptionButton = $Panel/ContentScroll/VBoxContainer/VideoMenu/ResolutionOption
@onready var fullscreen_toggle: CheckButton = $Panel/ContentScroll/VBoxContainer/VideoMenu/FullscreenContainer/FullscreenToggle
@onready var video_back_button: Button = $Panel/ContentScroll/VBoxContainer/VideoMenu/BackButton

@onready var volume_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/VolumeContainer/VolumeSlider
@onready var volume_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/VolumeContainer/VolumeValue
@onready var mute_toggle: CheckButton = $Panel/ContentScroll/VBoxContainer/AudioMenu/MuteContainer/MuteToggle
@onready var bgm_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/BgmSlider
@onready var bgm_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/BgmValue
@onready var sfx_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/SfxSlider
@onready var sfx_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/SfxValue
@onready var audio_back_button: Button = $Panel/ContentScroll/VBoxContainer/AudioMenu/BackButton

const MIN_DB: float = -80.0
const MAX_DB: float = 3.0
const MAIN_SCENE_PATH := "res://scenes/core/main.tscn"

var _prev_window_size: Vector2i = Vector2i(320, 180)


func _ready() -> void:
	_prev_window_size = DisplayServer.window_get_size()
	_ensure_ui_click_player()
	_ensure_bgm_player()
	_resolve_audio_bus_indexes()
	_play_bgm(BGM_MAIN_MENU)
	_connect_runtime_signals()

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_center_panel")

	_initialize_settings()


func _connect_runtime_signals() -> void:
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

	if not easy_button.pressed.is_connected(_on_easy_pressed):
		easy_button.pressed.connect(_on_easy_pressed)
	if not normal_button.pressed.is_connected(_on_normal_pressed):
		normal_button.pressed.connect(_on_normal_pressed)
	if not hard_button.pressed.is_connected(_on_hard_pressed):
		hard_button.pressed.connect(_on_hard_pressed)
	if not difficulty_back_button.pressed.is_connected(_on_difficulty_back_pressed):
		difficulty_back_button.pressed.connect(_on_difficulty_back_pressed)

	if not video_button.pressed.is_connected(_on_video_pressed):
		video_button.pressed.connect(_on_video_pressed)
	if not audio_button.pressed.is_connected(_on_audio_pressed):
		audio_button.pressed.connect(_on_audio_pressed)
	if not settings_back_button.pressed.is_connected(_on_settings_back_pressed):
		settings_back_button.pressed.connect(_on_settings_back_pressed)

	if not resolution_option.item_selected.is_connected(_on_resolutions_item_selected):
		resolution_option.item_selected.connect(_on_resolutions_item_selected)
	if not fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if not video_back_button.pressed.is_connected(_on_video_back_pressed):
		video_back_button.pressed.connect(_on_video_back_pressed)

	if not volume_slider.value_changed.is_connected(_on_volume_value_changed):
		volume_slider.value_changed.connect(_on_volume_value_changed)
	if not bgm_slider.value_changed.is_connected(_on_bgm_volume_value_changed):
		bgm_slider.value_changed.connect(_on_bgm_volume_value_changed)
	if not sfx_slider.value_changed.is_connected(_on_sfx_volume_value_changed):
		sfx_slider.value_changed.connect(_on_sfx_volume_value_changed)
	if not mute_toggle.toggled.is_connected(_on_mute_toggled):
		mute_toggle.toggled.connect(_on_mute_toggled)
	if not audio_back_button.pressed.is_connected(_on_audio_back_pressed):
		audio_back_button.pressed.connect(_on_audio_back_pressed)


func _resolve_audio_bus_indexes() -> void:
	_bgm_bus_index = AudioServer.get_bus_index("BGM")
	_sfx_bus_index = AudioServer.get_bus_index("SFX")

	if _bgm_bus_index == -1:
		push_warning("MainMenu: BGM bus not found.")
	if _sfx_bus_index == -1:
		push_warning("MainMenu: SFX bus not found.")


func _ensure_ui_click_player() -> void:
	if _ui_click_player == null:
		_ui_click_player = AudioStreamPlayer.new()
		_ui_click_player.name = "UiClickPlayer"
		_ui_click_player.stream = SFX_UI_CLICK
		add_child(_ui_click_player)

	_ui_click_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


func _ensure_bgm_player() -> void:
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.name = "BgmPlayer"
		_bgm_player.autoplay = false
		_bgm_player.stream_paused = false
		add_child(_bgm_player)

	_bgm_player.bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"


func _play_bgm(stream: AudioStream) -> void:
	if stream == null:
		return
	if _bgm_player == null:
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return

	_bgm_player.stream = stream
	_bgm_player.volume_db = 0.0
	_bgm_player.play()


func _play_ui_click() -> void:
	if _ui_click_player == null:
		return
	_ui_click_player.stop()
	_ui_click_player.play()


func _initialize_settings() -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	var bus_db: float = 0.0
	if master_bus_index != -1:
		bus_db = AudioServer.get_bus_volume_db(master_bus_index)
	var volume_percent = _db_to_percent(bus_db)
	volume_slider.value = volume_percent
	volume_value_label.text = "%d%%" % int(volume_percent)

	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.button_pressed = is_fullscreen

	var is_muted = AudioServer.is_bus_mute(0)
	mute_toggle.button_pressed = is_muted

	_initialize_bgm_sfx_settings()


func _initialize_bgm_sfx_settings() -> void:
	if _bgm_bus_index == -1:
		bgm_slider.editable = false
		bgm_value_label.text = "N/A"
	else:
		bgm_slider.editable = true
		var bgm_db: float = AudioServer.get_bus_volume_db(_bgm_bus_index)
		var bgm_percent: float = _db_to_percent(bgm_db)
		bgm_slider.value = bgm_percent
		bgm_value_label.text = "%d%%" % int(bgm_percent)

	if _sfx_bus_index == -1:
		sfx_slider.editable = false
		sfx_value_label.text = "N/A"
	else:
		sfx_slider.editable = true
		var sfx_db: float = AudioServer.get_bus_volume_db(_sfx_bus_index)
		var sfx_percent: float = _db_to_percent(sfx_db)
		sfx_slider.value = sfx_percent
		sfx_value_label.text = "%d%%" % int(sfx_percent)


func _db_to_percent(db: float) -> float:
	if db <= 0.0:
		return (db - MIN_DB) / (0.0 - MIN_DB) * 50.0
	return 50.0 + (db / MAX_DB) * 50.0


func _load_game_level(difficulty: _GameConfigType.Difficulty) -> void:
	var game_config := get_node_or_null("/root/GameConfig")
	if game_config != null:
		game_config.set_selected_difficulty(difficulty)

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


# Main Menu Handlers
func _on_play_pressed() -> void:
	_play_ui_click()
	main_buttons.visible = false
	difficulty_panel.visible = true
	normal_button.grab_focus()


func _on_settings_pressed() -> void:
	_play_ui_click()
	main_buttons.visible = false
	settings_menu.visible = true
	video_button.grab_focus()


func _on_quit_pressed() -> void:
	_play_ui_click()
	get_tree().quit()


# Difficulty Selection Handlers
func _on_easy_pressed() -> void:
	_play_ui_click()
	_load_game_level(_GameConfigType.Difficulty.EASY)


func _on_normal_pressed() -> void:
	_play_ui_click()
	_load_game_level(_GameConfigType.Difficulty.NORMAL)


func _on_hard_pressed() -> void:
	_play_ui_click()
	_load_game_level(_GameConfigType.Difficulty.HARD)


func _on_difficulty_back_pressed() -> void:
	_play_ui_click()
	difficulty_panel.visible = false
	main_buttons.visible = true
	play_button.grab_focus()


# Settings Menu Handlers
func _on_settings_back_pressed() -> void:
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


# Video Menu Handlers
func _on_resolutions_item_selected(index: int) -> void:
	_play_ui_click()
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

	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		_prev_window_size = chosen_size
	else:
		DisplayServer.window_set_size(chosen_size)
		_prev_window_size = chosen_size


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	_play_ui_click()
	if toggled_on:
		_prev_window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_prev_window_size)


func _on_video_back_pressed() -> void:
	_play_ui_click()
	video_menu.visible = false
	settings_menu.visible = true


# Audio Menu Handlers
func _on_volume_value_changed(value: float) -> void:
	var db: float = _percent_to_db(value)
	var master_bus_index := AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, db)
	volume_value_label.text = "%d%%" % int(value)


func _on_bgm_volume_value_changed(value: float) -> void:
	if _bgm_bus_index == -1:
		return

	AudioServer.set_bus_volume_db(_bgm_bus_index, _percent_to_db(value))
	bgm_value_label.text = "%d%%" % int(value)


func _on_sfx_volume_value_changed(value: float) -> void:
	if _sfx_bus_index == -1:
		return

	AudioServer.set_bus_volume_db(_sfx_bus_index, _percent_to_db(value))
	sfx_value_label.text = "%d%%" % int(value)


func _on_mute_toggled(toggled_on: bool) -> void:
	_play_ui_click()
	AudioServer.set_bus_mute(0, toggled_on)


func _on_audio_back_pressed() -> void:
	_play_ui_click()
	audio_menu.visible = false
	settings_menu.visible = true


func _on_viewport_size_changed() -> void:
	_center_panel()


func _center_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.position = (viewport_size - panel.size) * 0.5


func _percent_to_db(value: float) -> float:
	if value <= 50.0:
		var t_low: float = clamp(value / 50.0, 0.0, 1.0)
		return lerp(MIN_DB, 0.0, t_low)

	var t_high: float = clamp((value - 50.0) / 50.0, 0.0, 1.0)
	return lerp(0.0, MAX_DB, t_high)
