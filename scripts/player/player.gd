extends CharacterBody2D
class_name Player

# Movement parameters
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Dash parameters
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.75

const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_DASH: StringName = &"dash"

const STATE_IDLE: StringName = &"idle"
const STATE_RUN: StringName = &"run"
const STATE_DASH: StringName = &"dash"
const STATE_ATTACK: StringName = &"attack"

const ATTACK_ANIM_LEFT: StringName = &"attack_left"
const ATTACK_ANIM_RIGHT: StringName = &"attack_right"
const ATTACK_ANIM_LEGACY: StringName = &"attack"

# Animation reference
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword: Sprite2D = $Sword
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox
@onready var sword_hitbox_shape: CollisionShape2D = $Sword/SwordHitbox/CollisionShape2D

var input_vector: Vector2 = Vector2.ZERO
var last_nonzero_direction: Vector2 = Vector2.DOWN
var dash_direction: Vector2 = Vector2.ZERO
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var is_attack_facing_locked: bool = false
var attack_facing_left: bool = false

var current_dash_speed: float = 0.0


func _ready() -> void:
	add_to_group("player")
	current_dash_speed = dash_speed

	# Setup collision layer dan mask
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.MASK_PLAYER_BODY

	_validate_required_animations()

	# Debug: verifikasi Input Map setup
	if not GameInput.is_setup_valid():
		var missing_actions := ", ".join(GameInput.get_missing_actions())
		push_warning("GameInput action setup incomplete. Missing actions: %s" % missing_actions)

	if state_machine == null:
		push_error("Player is missing StateMachine node.")
		return

	_set_sword_active(false)

	state_machine.set_context(self)
	state_machine.start()


func _physics_process(delta: float) -> void:
	# Read input
	input_vector = GameInput.movement_vector()
	if input_vector != Vector2.ZERO:
		last_nonzero_direction = input_vector.normalized()

	if dash_cooldown_left > 0.0:
		dash_cooldown_left = max(dash_cooldown_left - delta, 0.0)

	if state_machine:
		state_machine.physics_step(delta)

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if not animated_sprite:
		return

	var visual_direction := input_vector
	var current_state_name := StringName()
	if state_machine:
		current_state_name = state_machine.get_current_state_name()

	if current_state_name == STATE_DASH and dash_direction != Vector2.ZERO:
		visual_direction = dash_direction
	elif visual_direction == Vector2.ZERO:
		visual_direction = last_nonzero_direction

	if current_state_name == STATE_ATTACK and is_attack_facing_locked:
		animated_sprite.flip_h = attack_facing_left
	elif not is_zero_approx(visual_direction.x):
		animated_sprite.flip_h = visual_direction.x < 0.0

	if sword:
		var facing_left := animated_sprite.flip_h
		var sword_scale := sword.scale
		sword_scale.x = -absf(sword_scale.x) if facing_left else absf(sword_scale.x)
		sword.scale = sword_scale

		var sword_position := sword.position
		sword_position.x = -absf(sword_position.x) if facing_left else absf(sword_position.x)
		sword.position = sword_position


func _validate_required_animations() -> void:
	if animated_sprite == null:
		push_error("Player AnimatedSprite2D node is missing.")
		return
	if animated_sprite.sprite_frames == null:
		push_error("Player AnimatedSprite2D has no SpriteFrames resource.")
		return

	var required_animations: Array[StringName] = [ANIM_IDLE, ANIM_RUN, ANIM_DASH]
	for animation_name in required_animations:
		if not animated_sprite.sprite_frames.has_animation(animation_name):
			push_error("Player is missing required animation: %s" % animation_name)


func has_move_input() -> bool:
	return input_vector != Vector2.ZERO


func is_dash_input_pressed() -> bool:
	return GameInput.is_dash_pressed()


func is_attack_pressed() -> bool:
	return GameInput.is_attack_pressed()


func can_start_dash() -> bool:
	return dash_cooldown_left <= 0.0 and dash_time_left <= 0.0


func start_dash() -> void:
	var requested_direction := input_vector
	if requested_direction == Vector2.ZERO:
		requested_direction = last_nonzero_direction
	if requested_direction == Vector2.ZERO:
		requested_direction = Vector2.DOWN

	dash_direction = requested_direction.normalized()
	current_dash_speed = dash_speed
	dash_time_left = dash_duration
	velocity = dash_direction * current_dash_speed


func tick_dash(delta: float) -> void:
	dash_time_left = max(dash_time_left - delta, 0.0)
	velocity = dash_direction * current_dash_speed


func is_dash_finished() -> bool:
	return dash_time_left <= 0.0


func finish_dash() -> void:
	dash_time_left = 0.0
	dash_cooldown_left = dash_cooldown


func apply_idle_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func apply_run_motion(delta: float) -> void:
	velocity = velocity.move_toward(input_vector * speed, acceleration * delta)


func lock_attack_motion() -> void:
	velocity = Vector2.ZERO


func play_required_animation(animation_name: StringName) -> bool:
	if animated_sprite == null:
		push_error("Player AnimatedSprite2D node is missing.")
		return false
	if animated_sprite.sprite_frames == null:
		push_error("Player AnimatedSprite2D has no SpriteFrames resource.")
		return false
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_error("Player attempted to play missing animation: %s" % animation_name)
		return false

	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)
	return true
	
	
func start_attack() -> void:
	if animation_player == null:
		push_error("Player AnimationPlayer node is missing.")
		return

	if not is_zero_approx(input_vector.x):
		attack_facing_left = input_vector.x < 0.0
	elif not is_zero_approx(last_nonzero_direction.x):
		attack_facing_left = last_nonzero_direction.x < 0.0
	elif animated_sprite:
		attack_facing_left = animated_sprite.flip_h

	var attack_animation_name := _resolve_attack_animation_name()
	if attack_animation_name == StringName():
		push_error("Player AnimationPlayer is missing attack animation. Expected attack_left / attack_right.")
		return

	is_attack_facing_locked = true
	lock_attack_motion()
	_set_sword_active(true)
	animation_player.play(attack_animation_name)


func finish_attack() -> void:
	is_attack_facing_locked = false
	_set_sword_active(false)
	if animation_player == null:
		return

	if animation_player.has_animation("RESET"):
		animation_player.play("RESET")
		animation_player.seek(0.0, true)
		animation_player.stop()
		return

	if animation_player.is_playing() and _is_attack_animation_name(animation_player.current_animation):
		animation_player.stop()


func get_animation_player() -> AnimationPlayer:
	return animation_player


func can_start_attack() -> bool:
	# Attack can be started if not already attacking
	if animation_player == null:
		return false

	var has_any_attack_animation := animation_player.has_animation(ATTACK_ANIM_LEFT)
	has_any_attack_animation = has_any_attack_animation or animation_player.has_animation(ATTACK_ANIM_RIGHT)
	has_any_attack_animation = has_any_attack_animation or animation_player.has_animation(ATTACK_ANIM_LEGACY)
	if not has_any_attack_animation:
		return false

	if not animation_player.is_playing():
		return true

	return not _is_attack_animation_name(animation_player.current_animation)


func _resolve_attack_animation_name() -> StringName:
	if animation_player == null:
		return StringName()

	var directional_animation := ATTACK_ANIM_LEFT if attack_facing_left else ATTACK_ANIM_RIGHT
	if animation_player.has_animation(directional_animation):
		return directional_animation

	if animation_player.has_animation(ATTACK_ANIM_LEGACY):
		return ATTACK_ANIM_LEGACY

	return StringName()


func _is_attack_animation_name(animation_name: StringName) -> bool:
	return animation_name == ATTACK_ANIM_LEFT \
		or animation_name == ATTACK_ANIM_RIGHT \
		or animation_name == ATTACK_ANIM_LEGACY


func _set_sword_active(is_active: bool) -> void:
	if sword:
		sword.visible = is_active

	if sword_hitbox:
		sword_hitbox.monitoring = is_active
		sword_hitbox.monitorable = is_active

	if sword_hitbox_shape:
		sword_hitbox_shape.disabled = not is_active
