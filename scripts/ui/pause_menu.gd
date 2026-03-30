extends CanvasLayer

# Audio volume constants
const MIN_DB: float = -80.0
const MAX_DB: float = 3.0
const SFX_UI_CLICK: AudioStream = preload("res://assets/audio/sfx/UiClick.mp3")

# Track previous window size for fullscreen toggle
var _prev_window_size: Vector2i = Vector2i(320, 180)
var _ui_click_player: AudioStreamPlayer
var _bgm_bus_index: int = -1
var _sfx_bus_index: int = -1

# Node references
@onready var panel: Panel = $Panel
@onready var main_buttons: VBoxContainer = $Panel/ContentScroll/VBoxContainer/MainButtons
@onready var settings_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/SettingsMenu
@onready var video_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/VideoMenu
@onready var audio_menu: VBoxContainer = $Panel/ContentScroll/VBoxContainer/AudioMenu

@onready var resume_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/ResumeButton
@onready var settings_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/SettingsButton
@onready var quit_button: Button = $Panel/ContentScroll/VBoxContainer/MainButtons/QuitButton
@onready var video_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/VideoButton
@onready var audio_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/AudioButton
@onready var back_button: Button = $Panel/ContentScroll/VBoxContainer/SettingsMenu/BackButton
@onready var back_button_video: Button = $Panel/ContentScroll/VBoxContainer/VideoMenu/BackButton2
@onready var back_button_audio: Button = $Panel/ContentScroll/VBoxContainer/AudioMenu/BackButton3

@onready var resolution_option: OptionButton = $Panel/ContentScroll/VBoxContainer/VideoMenu/ResolutionOption
@onready var fullscreen_toggle: CheckButton = $Panel/ContentScroll/VBoxContainer/VideoMenu/FullscreenContainer/FullscreenToggle

@onready var volume_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/VolumeSlider
@onready var volume_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/VolumeValue
@onready var mute_toggle: CheckButton = $Panel/ContentScroll/VBoxContainer/AudioMenu/MuteContainer/MuteToggle
@onready var bgm_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/BgmSlider
@onready var bgm_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/BgmValue
@onready var sfx_slider: HSlider = $Panel/ContentScroll/VBoxContainer/AudioMenu/SfxSlider
@onready var sfx_value_label: Label = $Panel/ContentScroll/VBoxContainer/AudioMenu/SfxValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	add_to_group("pause_menu_ui")
	# Initialize previous window size
	_prev_window_size = DisplayServer.window_get_size()
	_ensure_ui_click_player()
	_resolve_audio_bus_indexes()
	
	# Keep pause panel centered across window resize/fullscreen changes
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_center_panel")
	
	# Initially hidden
	visible = false
	if not PauseManager.pause_toggled.is_connected(_on_pause_toggled):
		PauseManager.pause_toggled.connect(_on_pause_toggled)
	if not is_connected("visibility_changed", Callable(self, "_on_visibility_changed")):
		connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	
	# Initialize volume slider and settings
	_initialize_settings()


func _input(event: InputEvent) -> void:
	if not (event is InputEventAction):
		return
	if not event.is_pressed() or event.is_echo():
		return
	if not visible:
		return

	if event.is_action_pressed("ui_pause") or event.is_action_pressed("ui_cancel"):
		PauseManager.resume()
		get_viewport().set_input_as_handled()



func _resolve_audio_bus_indexes() -> void:
	_bgm_bus_index = AudioServer.get_bus_index("BGM")
	_sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# Debug output for troubleshooting audio bus setup
	if _bgm_bus_index == -1:
		push_warning("PauseMenu: BGM bus not found. Available buses: %s" % str(AudioServer.get_bus_count()))
	if _sfx_bus_index == -1:
		push_warning("PauseMenu: SFX bus not found. Available buses: %s" % str(AudioServer.get_bus_count()))

func _initialize_settings() -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	var bus_db: float = 0.0
	if master_bus_index != -1:
		bus_db = AudioServer.get_bus_volume_db(master_bus_index)
	var volume_percent = _db_to_percent(bus_db)
	volume_slider.value = volume_percent
	volume_value_label.text = "%d%%" % int(volume_percent)
	
	# Set initial fullscreen state
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.button_pressed = is_fullscreen
	
	# Set initial mute state
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


func _ensure_ui_click_player() -> void:
	if _ui_click_player == null:
		_ui_click_player = AudioStreamPlayer.new()
		_ui_click_player.name = "UiClickPlayer"
		_ui_click_player.stream = SFX_UI_CLICK
		add_child(_ui_click_player)

	_ui_click_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


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
	var scene_result: Error = get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	if scene_result != OK:
		push_error("PauseMenu: Failed to change to main menu scene. Error code: %d" % int(scene_result))


func _open_pause_menu(request_pause: bool = true) -> void:
	if request_pause:
		PauseManager.pause_menu()
	visible = true
	_center_panel()
	_reset_to_main_buttons()
	_initialize_settings()
	resume_button.grab_focus()


func _close_pause_menu(request_resume: bool = true) -> void:
	visible = false
	if request_resume:
		PauseManager.resume()


func _on_pause_toggled(is_paused: bool, context: StringName) -> void:
	if context == PauseManager.PAUSE_CONTEXT_MENU:
		visible = is_paused
		if is_paused:
			_center_panel()
			_reset_to_main_buttons()
			_initialize_settings()
			resume_button.grab_focus()
		return

	if not is_paused:
		visible = false


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


func _on_viewport_size_changed() -> void:
	_center_panel()


func _on_visibility_changed() -> void:
	if visible:
		_center_panel()
		_reset_to_main_buttons()


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


func _percent_to_db(value: float) -> float:
	if value <= 50.0:
		var t_low: float = clamp(value / 50.0, 0.0, 1.0)
		return lerp(MIN_DB, 0.0, t_low)

	var t_high: float = clamp((value - 50.0) / 50.0, 0.0, 1.0)
	return lerp(0.0, MAX_DB, t_high)
