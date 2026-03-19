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
@export var dash_trail_interval: float = 0.03
@export var dash_trail_lifetime: float = 0.12
@export var dash_trail_tint: Color = Color(0.75, 0.9, 1.0, 0.65)
@export var dash_trail_scale_end: float = 0.7
@export var dash_trail_offset: Vector2 = Vector2.ZERO

var dash_trail_spawn_left: float = 0.0

# Attack parameters
@export var attack_damage: int = 1

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
var hit_targets_this_attack: Dictionary = {}

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

	_setup_sword_hitbox()

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

	if state_machine and state_machine.get_current_state_name() == STATE_DASH:
		_tick_dash_trail(delta)


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


func _setup_sword_hitbox() -> void:
	if sword_hitbox == null:
		push_error("Player is missing SwordHitbox node.")
		return

	sword_hitbox.collision_layer = PhysicsLayers.HITBOX
	sword_hitbox.collision_mask = PhysicsLayers.MASK_HITBOX_PLAYER

	if not sword_hitbox.body_entered.is_connected(_on_sword_hitbox_body_entered):
		sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	if not sword_hitbox.area_entered.is_connected(_on_sword_hitbox_area_entered):
		sword_hitbox.area_entered.connect(_on_sword_hitbox_area_entered)


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
	
	_start_dash_trail()


func tick_dash(delta: float) -> void:
	dash_time_left = max(dash_time_left - delta, 0.0)
	velocity = dash_direction * current_dash_speed


func is_dash_finished() -> bool:
	return dash_time_left <= 0.0


func finish_dash() -> void:
	dash_time_left = 0.0
	dash_cooldown_left = dash_cooldown

	_stop_dash_trail()


func _start_dash_trail() -> void:
	dash_trail_spawn_left = 0.0


func _tick_dash_trail(delta: float) -> void:
	if dash_trail_interval <= 0.0:
		_spawn_dash_trail()
		return

	dash_trail_spawn_left -= delta
	while dash_trail_spawn_left <= 0.0:
		_spawn_dash_trail()
		dash_trail_spawn_left += dash_trail_interval


func _stop_dash_trail() -> void:
	dash_trail_spawn_left = 0.0


func _spawn_dash_trail() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	if parent_node == null:
		return

	if animated_sprite.animation == StringName():
		return

	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = animated_sprite.sprite_frames
	ghost.animation = animated_sprite.animation
	ghost.stop()
	ghost.frame = animated_sprite.frame
	ghost.frame_progress = animated_sprite.frame_progress
	ghost.flip_h = animated_sprite.flip_h
	ghost.flip_v = animated_sprite.flip_v
	ghost.centered = animated_sprite.centered
	ghost.offset = animated_sprite.offset
	ghost.global_transform = animated_sprite.global_transform
	ghost.z_index = animated_sprite.z_index - 1
	ghost.z_as_relative = animated_sprite.z_as_relative
	ghost.modulate = dash_trail_tint

	var trail_offset := dash_trail_offset
	if ghost.flip_h:
		trail_offset.x = -trail_offset.x
	ghost.global_position += trail_offset

	parent_node.add_child(ghost)

	var target_scale := ghost.scale * dash_trail_scale_end
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, dash_trail_lifetime)
	tw.parallel().tween_property(ghost, "scale", target_scale, dash_trail_lifetime)
	tw.finished.connect(ghost.queue_free)


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

	attack_facing_left = _resolve_attack_facing_from_mouse()

	var attack_animation_name := _resolve_attack_animation_name()
	if attack_animation_name == StringName():
		push_error("Player AnimationPlayer is missing attack animation. Expected attack_left / attack_right.")
		return

	is_attack_facing_locked = true
	lock_attack_motion()
	hit_targets_this_attack.clear()
	_set_sword_active(true)
	call_deferred("_apply_damage_to_current_overlaps")
	animation_player.play(attack_animation_name)


func finish_attack() -> void:
	is_attack_facing_locked = false
	hit_targets_this_attack.clear()
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


func _resolve_attack_facing_from_mouse() -> bool:
	var reference_x := global_position.x
	if animated_sprite:
		reference_x = animated_sprite.global_position.x

	var mouse_position := get_global_mouse_position()
	if mouse_position.x < reference_x:
		return true
	if mouse_position.x > reference_x:
		return false

	# If click is exactly on center line, keep current facing.
	if animated_sprite:
		return animated_sprite.flip_h
	return attack_facing_left


func _is_attack_animation_name(animation_name: StringName) -> bool:
	return animation_name == ATTACK_ANIM_LEFT \
		or animation_name == ATTACK_ANIM_RIGHT \
		or animation_name == ATTACK_ANIM_LEGACY


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	_try_apply_attack_damage(body)


func _on_sword_hitbox_area_entered(area: Area2D) -> void:
	if area == null or area == sword_hitbox:
		return
	_try_apply_attack_damage(area)


func _apply_damage_to_current_overlaps() -> void:
	if sword_hitbox == null:
		return

	for overlapping_body in sword_hitbox.get_overlapping_bodies():
		if overlapping_body is Node:
			_try_apply_attack_damage(overlapping_body)

	for overlapping_area in sword_hitbox.get_overlapping_areas():
		if overlapping_area is Area2D and overlapping_area != sword_hitbox:
			_try_apply_attack_damage(overlapping_area)


func _try_apply_attack_damage(collider: Node) -> void:
	if collider == null:
		return
	if sword_hitbox == null or not sword_hitbox.monitoring:
		return

	var target := _resolve_damage_target(collider)
	if target == null:
		return

	var target_id := target.get_instance_id()
	if hit_targets_this_attack.has(target_id):
		return
	hit_targets_this_attack[target_id] = true

	var hit_source_position := sword.global_position if sword else global_position
	target.call("receive_hit", attack_damage, hit_source_position)


func _resolve_damage_target(collider: Node) -> Node:
	var current: Node = collider
	while current != null:
		if current == self:
			return null
		if current.has_method("receive_hit"):
			return current
		current = current.get_parent()

	return null


func _set_sword_active(is_active: bool) -> void:
	if sword:
		sword.visible = is_active

	if sword_hitbox:
		sword_hitbox.monitoring = is_active
		sword_hitbox.monitorable = is_active

	if sword_hitbox_shape:
		sword_hitbox_shape.disabled = not is_active
