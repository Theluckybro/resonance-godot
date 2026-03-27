extends Control
class_name WaveNotification

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const ANIMATION_LIBRARY_KEY := "wave_notification"
const ANIMATION_NAME := "fade_in_out"


func _ready() -> void:
	# Make sure we start invisible
	modulate.a = 0.0
	
	# Create and add the fade animation if it doesn't exist
	_setup_animation()
	
	# Log initialization
	print("WaveNotification initialized at path: ", get_path())


func _setup_animation() -> void:
	# Ensure our dedicated animation library exists before reading it.
	if not animation_player.has_animation_library(ANIMATION_LIBRARY_KEY):
		var created_lib := AnimationLibrary.new()
		var add_err := animation_player.add_animation_library(ANIMATION_LIBRARY_KEY, created_lib)
		if add_err != OK:
			push_error("WaveNotification: Failed to add AnimationLibrary '%s'. Error code: %d" % [ANIMATION_LIBRARY_KEY, add_err])
			return

	var lib = animation_player.get_animation_library(ANIMATION_LIBRARY_KEY)
	if lib == null:
		push_error("WaveNotification: AnimationLibrary '%s' is missing after creation." % ANIMATION_LIBRARY_KEY)
		return
	
	# Only create animation if it doesn't exist
	if not lib.has_animation(ANIMATION_NAME):
		var anim = Animation.new()
		anim.length = 3.0
		
		# Create the modulate alpha track
		var track_idx = anim.add_track(Animation.TrackType.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(".:modulate"))
		anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
		
		# Add keyframes: fade in (0-0.3s), stay (0.3-2.7s), fade out (2.7-3s)
		anim.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 0))
		anim.track_insert_key(track_idx, 0.3, Color(1, 1, 1, 1))
		anim.track_insert_key(track_idx, 2.7, Color(1, 1, 1, 1))
		anim.track_insert_key(track_idx, 3.0, Color(1, 1, 1, 0))
		
		# Add animation to library
		lib.add_animation(ANIMATION_NAME, anim)
		
		# Debug print to confirm animation was added
		print("WaveNotification: Animation '%s/%s' created successfully" % [ANIMATION_LIBRARY_KEY, ANIMATION_NAME])
	else:
		print("WaveNotification: Animation '%s/%s' already exists" % [ANIMATION_LIBRARY_KEY, ANIMATION_NAME])


func show_notification(text: String) -> void:
	if label == null:
		push_error("WaveNotification: Label node not found!")
		return
	if animation_player == null:
		push_error("WaveNotification: AnimationPlayer node not found!")
		return

	var animation_path := "%s/%s" % [ANIMATION_LIBRARY_KEY, ANIMATION_NAME]
	if not animation_player.has_animation(animation_path):
		_setup_animation()
		if not animation_player.has_animation(animation_path):
			push_error("WaveNotification: Animation '%s' is unavailable." % animation_path)
			return
	
	print("WaveNotification: Displaying text: '%s'" % text)
	label.text = text
	# Reset animation and play fade-in then fade-out
	animation_player.stop()
	animation_player.play(animation_path)
