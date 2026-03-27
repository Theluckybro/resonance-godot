extends CharacterBody2D
class_name Player

signal player_damaged(current_health: int, damage_taken: int)
signal player_died()
signal vestige_collected(total_vestige: int, amount: int)

@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@export_group("Dash")
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.75
@export var dash_iframe_duration: float = -1.0
@export var dash_trail_interval: float = 0.03
@export var dash_trail_lifetime: float = 0.12
@export var dash_trail_tint: Color = Color(0.75, 0.9, 1.0, 0.65)
@export var dash_trail_scale_end: float = 0.7
@export var dash_trail_offset: Vector2 = Vector2.ZERO

var dash_trail_spawn_left: float = 0.0

@export_group("Combat")
@export var attack_damage: int = 5
@export var attack_cooldown: float = 0.65
@export var max_health: int = 10
@export var damage_invulnerability_duration: float = 0.2
@export var hit_knockback_impulse: float = 130.0
@export var debug_print_health: bool = true

const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_DASH: StringName = &"dash"
const ANIM_ATTACK: StringName = &"attack"
const ANIM_DEATH: StringName = &"death"

const STATE_IDLE: StringName = &"idle"
const STATE_RUN: StringName = &"run"
const STATE_DASH: StringName = &"dash"
const STATE_ATTACK: StringName = &"attack"
const STATE_DEAD: StringName = &"dead"

const ATTACK_ANIM_LEFT: StringName = &"attack_left"
const ATTACK_ANIM_RIGHT: StringName = &"attack_right"
const ATTACK_ANIM_LEGACY: StringName = &"attack"
const HP_PER_HEART: int = 2
const GOBLIN_SPECIES_ID: String = "goblin"
const ORC_SPECIES_ID: String = "orc"
const SKELETON_SPECIES_ID: String = "skeleton"
const GOBLIN_SCENE: PackedScene = preload("res://scenes/enemies/goblin.tscn")
const ORC_SCENE: PackedScene = preload("res://scenes/enemies/orc.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/enemies/skeleton.tscn")
const ORC_SLAM_RING_VFX_SCRIPT: Script = preload("res://scripts/enemies/vfx/orc_slam_ring_vfx.gd")
const VESTIGE_BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/vestige_bone_projectile.tscn")
const SFX_SLASH_VARIANTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/Slash1.wav"),
	preload("res://assets/audio/sfx/Slash2.wav"),
	preload("res://assets/audio/sfx/Slash3.wav"),
	preload("res://assets/audio/sfx/Slash4.wav"),
	preload("res://assets/audio/sfx/Slash5.wav"),
	preload("res://assets/audio/sfx/Slash6.wav"),
	preload("res://assets/audio/sfx/Slash7.wav"),
]
const SFX_HIT_VARIANTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/Hit1.mp3"),
	preload("res://assets/audio/sfx/Hit2.mp3"),
	preload("res://assets/audio/sfx/Hit3.mp3"),
]
const SFX_VESTIGE_SUMMON: AudioStream = preload("res://assets/audio/sfx/VestigeSummon.mp3")
const SFX_DASH_START: AudioStream = preload("res://assets/audio/sfx/DashStart.mp3")
const SFX_GAME_OVER: AudioStream = preload("res://assets/audio/sfx/GameOver.mp3")

# Animation reference
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword: Sprite2D = $Sword
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox
@onready var sword_hitbox_shape: CollisionShape2D = $Sword/SwordHitbox/CollisionShape2D
@onready var sfx_player: AudioStreamPlayer2D = get_node_or_null("SfxPlayer")

var input_vector: Vector2 = Vector2.ZERO
var last_nonzero_direction: Vector2 = Vector2.DOWN
var dash_direction: Vector2 = Vector2.ZERO
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var attack_cooldown_left: float = 0.0
var is_attack_facing_locked: bool = false
var attack_facing_left: bool = false
var hit_targets_this_attack: Dictionary = {}

var current_dash_speed: float = 0.0
var current_health: int = 0
var current_vestige: int = 0
var goblin_vestige_charges: int = 0
var orc_vestige_charges: int = 0
var skeleton_vestige_charges: int = 0
var damage_invulnerability_left: float = 0.0
var dash_invulnerability_left: float = 0.0
var goblin_vestige_cooldown_left: float = 0.0
var orc_vestige_cooldown_left: float = 0.0
var skeleton_vestige_cooldown_left: float = 0.0
var goblin_vestige_instance: CharacterBody2D
var goblin_vestige_sprite: AnimatedSprite2D
var goblin_vestige_target: Node2D
var goblin_vestige_no_target_left: float = 0.0
var goblin_vestige_attack_left: float = 0.0
var goblin_vestige_attack_applied: bool = false
var orc_vestige_instance: CharacterBody2D
var orc_vestige_sprite: AnimatedSprite2D
var orc_vestige_target: Node2D
var orc_vestige_no_target_left: float = 0.0
var orc_vestige_attack_left: float = 0.0
var orc_vestige_attack_applied: bool = false
var skeleton_vestige_instance: CharacterBody2D
var skeleton_vestige_sprite: AnimatedSprite2D
var skeleton_vestige_target: Node2D
var skeleton_vestige_no_target_left: float = 0.0
var skeleton_vestige_attack_cooldown_left: float = 0.0
var skeleton_vestige_has_fired: bool = false

@export_group("Vestige: Goblin")
@export var goblin_vestige_damage: int = 6
@export var goblin_vestige_cooldown: float = 0.28
@export var goblin_vestige_spawn_offset: float = 16.0
@export var goblin_vestige_chase_speed: float = 220.0
@export var goblin_vestige_attack_range: float = 16.0
@export var goblin_vestige_no_target_timeout: float = 2.0
@export var goblin_vestige_attack_duration: float = 0.35
@export var goblin_vestige_attack_hit_time: float = 0.15
@export var goblin_vestige_move_stretch_scale: Vector2 = Vector2(1.3, 0.9)

@export_group("Vestige: Orc")
@export var orc_vestige_damage: int = 12
@export var orc_vestige_cooldown: float = 0.55
@export var orc_vestige_spawn_offset: float = 18.0
@export var orc_vestige_chase_speed: float = 170.0
@export var orc_vestige_attack_range: float = 18.0
@export var orc_vestige_no_target_timeout: float = 2.0
@export var orc_vestige_attack_duration: float = 0.52
@export var orc_vestige_attack_hit_time: float = 0.26
@export var orc_vestige_aoe_radius: float = 18.0
@export var orc_vestige_slam_vfx_duration: float = 0.22
@export var orc_vestige_slam_vfx_color: Color = Color(1.0, 0.64, 0.32, 0.95)
@export var orc_vestige_slam_vfx_thickness_px: float = 2.4
@export var orc_vestige_move_stretch_scale: Vector2 = Vector2(1.2, 0.92)

@export_group("Vestige: Skeleton")
@export var skeleton_vestige_damage: int = 15
@export var skeleton_vestige_cooldown: float = 0.45
@export var skeleton_vestige_spawn_offset: float = 18.0
@export var skeleton_vestige_chase_speed: float = 145.0
@export var skeleton_vestige_preferred_range: float = 96.0
@export var skeleton_vestige_no_target_timeout: float = 2.0
@export var skeleton_vestige_attack_cooldown: float = 0.42
@export var skeleton_vestige_projectile_speed: float = 190.0
@export var skeleton_vestige_projectile_lifetime: float = 1.35
@export var skeleton_vestige_projectile_spawn_offset: float = 10.0
@export var skeleton_vestige_move_stretch_scale: Vector2 = Vector2(1.18, 0.94)


func _ready() -> void:
	_ensure_sfx_player()
	add_to_group("player")
	current_dash_speed = dash_speed
	max_health = maxi(max_health, HP_PER_HEART)
	# Keep full-heart representation valid for HUD by using even max HP.
	if (max_health % HP_PER_HEART) != 0:
		max_health += 1
	current_health = max_health
	if has_node("/root/VestigeInventory"):
		current_vestige = VestigeInventory.get_total()
		goblin_vestige_charges = VestigeInventory.get_goblin_charges()
		orc_vestige_charges = VestigeInventory.get_orc_charges()
		skeleton_vestige_charges = VestigeInventory.get_skeleton_charges()
	_log_health_debug("spawn")

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
	if attack_cooldown_left > 0.0:
		attack_cooldown_left = max(attack_cooldown_left - delta, 0.0)
	if goblin_vestige_cooldown_left > 0.0:
		goblin_vestige_cooldown_left = maxf(goblin_vestige_cooldown_left - delta, 0.0)
	if orc_vestige_cooldown_left > 0.0:
		orc_vestige_cooldown_left = maxf(orc_vestige_cooldown_left - delta, 0.0)
	if skeleton_vestige_cooldown_left > 0.0:
		skeleton_vestige_cooldown_left = maxf(skeleton_vestige_cooldown_left - delta, 0.0)
	if damage_invulnerability_left > 0.0:
		damage_invulnerability_left = maxf(damage_invulnerability_left - delta, 0.0)
	if dash_invulnerability_left > 0.0:
		dash_invulnerability_left = maxf(dash_invulnerability_left - delta, 0.0)

	if state_machine:
		state_machine.physics_step(delta)

	_tick_goblin_vestige_summon(delta)
	_tick_orc_vestige_summon(delta)
	_tick_skeleton_vestige_summon(delta)

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

	if current_state_name != STATE_DEAD:
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

	var required_animations: Array[StringName] = [ANIM_IDLE, ANIM_RUN, ANIM_DASH, ANIM_ATTACK, ANIM_DEATH]
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


func is_vestige_primary_pressed() -> bool:
	return GameInput.is_vestige_primary_pressed()


func is_vestige_secondary_pressed() -> bool:
	return GameInput.is_vestige_secondary_pressed()


func is_vestige_tertiary_pressed() -> bool:
	return GameInput.is_vestige_tertiary_pressed()


func is_vestige_quaternary_pressed() -> bool:
	return GameInput.is_vestige_quaternary_pressed()


func is_vestige_inventory_open() -> bool:
	if has_node("/root/VestigeInventoryFlow"):
		return VestigeInventoryFlow.is_open()
	return false


func can_start_dash() -> bool:
	if is_dead():
		return false
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
	dash_invulnerability_left = _resolve_dash_iframe_duration()
	velocity = dash_direction * current_dash_speed
	_play_sfx(SFX_DASH_START)
	
	_start_dash_trail()


func tick_dash(delta: float) -> void:
	dash_time_left = max(dash_time_left - delta, 0.0)
	velocity = dash_direction * current_dash_speed


func is_dash_finished() -> bool:
	return dash_time_left <= 0.0


func finish_dash() -> void:
	dash_time_left = 0.0
	dash_cooldown_left = dash_cooldown
	dash_invulnerability_left = 0.0

	_stop_dash_trail()


func _resolve_dash_iframe_duration() -> float:
	if dash_iframe_duration > 0.0:
		return dash_iframe_duration
	return dash_duration


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
	if is_dead():
		return
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
	play_required_animation(ANIM_ATTACK)
	hit_targets_this_attack.clear()
	_set_sword_active(true)
	attack_cooldown_left = attack_cooldown
	_play_random_sfx(SFX_SLASH_VARIANTS)
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
	if is_dead():
		return false
	if attack_cooldown_left > 0.0:
		return false
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
		sword_hitbox.set_deferred("monitoring", is_active)
		sword_hitbox.set_deferred("monitorable", is_active)

	if sword_hitbox_shape:
		sword_hitbox_shape.set_deferred("disabled", not is_active)


func is_dead() -> bool:
	return current_health <= 0


func get_current_health() -> int:
	return current_health


func get_max_health() -> int:
	return max_health


func get_current_vestige() -> int:
	return current_vestige


func collect_vestige(amount: int = 1, source_species: String = "") -> void:
	if amount <= 0:
		return

	var normalized_species := source_species.strip_edges().to_lower()

	if has_node("/root/VestigeInventory"):
		current_vestige = VestigeInventory.add_vestige(amount)
		if normalized_species == GOBLIN_SPECIES_ID:
			goblin_vestige_charges = VestigeInventory.add_goblin_charge(amount)
		elif normalized_species == ORC_SPECIES_ID:
			orc_vestige_charges = VestigeInventory.add_orc_charge(amount)
		elif normalized_species == SKELETON_SPECIES_ID:
			skeleton_vestige_charges = VestigeInventory.add_skeleton_charge(amount)
	else:
		current_vestige += amount
		if normalized_species == GOBLIN_SPECIES_ID:
			goblin_vestige_charges += amount
		elif normalized_species == ORC_SPECIES_ID:
			orc_vestige_charges += amount
		elif normalized_species == SKELETON_SPECIES_ID:
			skeleton_vestige_charges += amount

	vestige_collected.emit(current_vestige, amount)
	print("[DEBUG][Vestige] species=%s | collected=%d | total=%d | goblin_charge=%d | orc_charge=%d | skeleton_charge=%d" % [normalized_species, amount, current_vestige, goblin_vestige_charges, orc_vestige_charges, skeleton_vestige_charges])


func can_use_vestige_slot(slot_index: int) -> bool:
	if is_dead():
		return false
	if slot_index < 0 or slot_index >= 4:
		return false
	if is_vestige_inventory_open():
		return false

	var species_id := _resolve_equipped_species_for_slot(slot_index)
	if species_id.is_empty():
		return false
	if _get_species_charge_count(species_id) <= 0:
		return false
	return _get_species_cooldown_left(species_id) <= 0.0


func try_use_vestige_slot(slot_index: int) -> bool:
	if not can_use_vestige_slot(slot_index):
		return false
	var selected_species := _resolve_equipped_species_for_slot(slot_index)
	return _try_cast_vestige_species(selected_species)


func can_use_goblin_vestige() -> bool:
	return can_use_vestige_slot(0)


func try_use_goblin_vestige() -> bool:
	return try_use_vestige_slot(0)


func _try_cast_vestige_species(selected_species: String) -> bool:
	if selected_species.is_empty():
		return false

	if selected_species == ORC_SPECIES_ID:
		if has_node("/root/VestigeInventory"):
			if not VestigeInventory.consume_charge(ORC_SPECIES_ID, 1):
				_sync_local_vestige_counts_from_inventory()
				return false
			_sync_local_vestige_counts_from_inventory()
		else:
			orc_vestige_charges -= 1

		orc_vestige_cooldown_left = orc_vestige_cooldown
		_start_orc_vestige_summon()
		print("[DEBUG][VestigeOrc] cast | charge=%d | cooldown=%.2f" % [orc_vestige_charges, orc_vestige_cooldown_left])
		return true

	if selected_species == SKELETON_SPECIES_ID:
		if has_node("/root/VestigeInventory"):
			if not VestigeInventory.consume_charge(SKELETON_SPECIES_ID, 1):
				_sync_local_vestige_counts_from_inventory()
				return false
			_sync_local_vestige_counts_from_inventory()
		else:
			skeleton_vestige_charges -= 1

		skeleton_vestige_cooldown_left = skeleton_vestige_cooldown
		_start_skeleton_vestige_summon()
		print("[DEBUG][VestigeSkeleton] cast | charge=%d | cooldown=%.2f" % [skeleton_vestige_charges, skeleton_vestige_cooldown_left])
		return true

	if has_node("/root/VestigeInventory"):
		if not VestigeInventory.consume_charge(GOBLIN_SPECIES_ID, 1):
			_sync_local_vestige_counts_from_inventory()
			return false
		_sync_local_vestige_counts_from_inventory()
	else:
		goblin_vestige_charges -= 1

	goblin_vestige_cooldown_left = goblin_vestige_cooldown
	_start_goblin_vestige_summon()
	print("[DEBUG][VestigeGoblin] cast | charge=%d | cooldown=%.2f" % [goblin_vestige_charges, goblin_vestige_cooldown_left])
	return true


func _start_goblin_vestige_summon() -> void:
	_despawn_goblin_vestige(true)
	_play_sfx(SFX_VESTIGE_SUMMON)

	var summon_variant: Variant = GOBLIN_SCENE.instantiate()
	if not (summon_variant is CharacterBody2D):
		return

	goblin_vestige_instance = summon_variant as CharacterBody2D
	goblin_vestige_instance.remove_from_group("enemy")
	goblin_vestige_instance.set_physics_process(false)
	goblin_vestige_instance.set_process(false)
	_disable_summoned_enemy_ai(goblin_vestige_instance)
	goblin_vestige_instance.collision_layer = 0
	goblin_vestige_instance.collision_mask = 0

	var collision_shape := goblin_vestige_instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape:
		collision_shape.disabled = true

	goblin_vestige_sprite = goblin_vestige_instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		goblin_vestige_instance.free()
		goblin_vestige_instance = null
		return

	goblin_vestige_instance.set_meta("is_vestige_ally", true)
	host.add_child(goblin_vestige_instance)
	goblin_vestige_instance.remove_from_group("enemy")
	var facing_direction := _resolve_facing_direction_vector().normalized()
	if facing_direction == Vector2.ZERO:
		facing_direction = Vector2.RIGHT
	goblin_vestige_instance.global_position = global_position + (facing_direction * goblin_vestige_spawn_offset)

	goblin_vestige_target = null
	goblin_vestige_no_target_left = goblin_vestige_no_target_timeout
	goblin_vestige_attack_left = 0.0
	goblin_vestige_attack_applied = false

	_play_goblin_vestige_move_anim(facing_direction)
	print("[DEBUG][VestigeGoblin] spawn")


func _tick_goblin_vestige_summon(delta: float) -> void:
	if goblin_vestige_instance == null or not is_instance_valid(goblin_vestige_instance):
		return

	if goblin_vestige_attack_left > 0.0:
		goblin_vestige_attack_left = maxf(goblin_vestige_attack_left - delta, 0.0)
		if not goblin_vestige_attack_applied and goblin_vestige_attack_left <= (goblin_vestige_attack_duration - goblin_vestige_attack_hit_time):
			if goblin_vestige_target and is_instance_valid(goblin_vestige_target) and goblin_vestige_target.has_method("receive_hit"):
				goblin_vestige_target.call("receive_hit", goblin_vestige_damage, goblin_vestige_instance.global_position)
				print("[DEBUG][VestigeGoblin] attack_hit=%s" % goblin_vestige_target.name)
			goblin_vestige_attack_applied = true
		if goblin_vestige_attack_left <= 0.0:
			_despawn_goblin_vestige(true)
			print("[DEBUG][VestigeGoblin] despawn_after_attack")
		return

	if not _is_vestige_enemy_target_valid(goblin_vestige_target, goblin_vestige_instance):
		goblin_vestige_target = null

	if goblin_vestige_target == null:
		goblin_vestige_target = _find_nearest_enemy_for_vestige(goblin_vestige_instance.global_position, goblin_vestige_instance)
		if goblin_vestige_target:
			print("[DEBUG][VestigeGoblin] target_acquired=%s" % goblin_vestige_target.name)

	if goblin_vestige_target == null:
		goblin_vestige_no_target_left = maxf(goblin_vestige_no_target_left - delta, 0.0)
		_play_goblin_vestige_idle_anim()
		if goblin_vestige_no_target_left <= 0.0:
			_despawn_goblin_vestige(true)
			print("[DEBUG][VestigeGoblin] despawn_timeout")
		return

	var target_position := goblin_vestige_target.global_position
	var to_target := target_position - goblin_vestige_instance.global_position
	var distance_to_target := to_target.length()
	if distance_to_target <= goblin_vestige_attack_range:
		_play_goblin_vestige_attack_anim(to_target)
		goblin_vestige_attack_left = goblin_vestige_attack_duration
		goblin_vestige_attack_applied = false
		return

	var move_direction := to_target / maxf(distance_to_target, 0.001)
	goblin_vestige_instance.global_position += move_direction * goblin_vestige_chase_speed * delta
	_play_goblin_vestige_move_anim(move_direction)


func _find_nearest_enemy_for_vestige(origin: Vector2, vestige_self: Node) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance_sq := INF

	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		if not _is_vestige_enemy_target_valid(enemy_node, vestige_self):
			continue

		var enemy := enemy_node as Node2D

		var dist_sq := origin.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_distance_sq:
			nearest_distance_sq = dist_sq
			nearest_enemy = enemy

	return nearest_enemy


func _is_vestige_enemy_target_valid(enemy_node: Node, vestige_self: Node) -> bool:
	if enemy_node == null:
		return false
	if not (enemy_node is Node2D):
		return false
	if not is_instance_valid(enemy_node):
		return false
	if enemy_node == vestige_self:
		return false
	if not enemy_node.has_method("receive_hit"):
		return false
	if enemy_node.has_meta("is_vestige_ally") and bool(enemy_node.get_meta("is_vestige_ally")):
		return false
	if enemy_node.has_method("is_dead_state") and bool(enemy_node.call("is_dead_state")):
		return false
	return true


func _disable_summoned_enemy_ai(summoned_enemy: Node) -> void:
	if summoned_enemy == null:
		return
	var summoned_state_machine := summoned_enemy.get_node_or_null("StateMachine")
	if summoned_state_machine == null:
		return
	summoned_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	summoned_state_machine.set_process(false)
	summoned_state_machine.set_physics_process(false)


func _play_goblin_vestige_idle_anim() -> void:
	if goblin_vestige_sprite == null:
		return
	if goblin_vestige_sprite.sprite_frames and goblin_vestige_sprite.sprite_frames.has_animation(&"idle"):
		if goblin_vestige_sprite.animation != &"idle" or not goblin_vestige_sprite.is_playing():
			goblin_vestige_sprite.play(&"idle")
	goblin_vestige_sprite.scale = Vector2(1.0, 1.0)


func _play_goblin_vestige_move_anim(direction: Vector2) -> void:
	if goblin_vestige_sprite == null:
		return
	if goblin_vestige_sprite.sprite_frames and goblin_vestige_sprite.sprite_frames.has_animation(&"move"):
		if goblin_vestige_sprite.animation != &"move" or not goblin_vestige_sprite.is_playing():
			goblin_vestige_sprite.play(&"move")

	if absf(direction.x) > 0.0001:
		goblin_vestige_sprite.flip_h = direction.x < 0.0

	goblin_vestige_sprite.scale = Vector2(
		-absf(goblin_vestige_move_stretch_scale.x) if goblin_vestige_sprite.flip_h else absf(goblin_vestige_move_stretch_scale.x),
		goblin_vestige_move_stretch_scale.y
	)


func _play_goblin_vestige_attack_anim(direction: Vector2) -> void:
	if goblin_vestige_sprite == null:
		return
	if absf(direction.x) > 0.0001:
		goblin_vestige_sprite.flip_h = direction.x < 0.0
	if goblin_vestige_sprite.sprite_frames and goblin_vestige_sprite.sprite_frames.has_animation(&"attack"):
		goblin_vestige_sprite.play(&"attack")
	goblin_vestige_sprite.scale = Vector2(
		-1.0 if goblin_vestige_sprite.flip_h else 1.0,
		1.0
	)


func _despawn_goblin_vestige(should_clear_state: bool = true) -> void:
	if goblin_vestige_instance and is_instance_valid(goblin_vestige_instance):
		goblin_vestige_instance.queue_free()
	if should_clear_state:
		goblin_vestige_instance = null
		goblin_vestige_sprite = null
		goblin_vestige_target = null
		goblin_vestige_no_target_left = 0.0
		goblin_vestige_attack_left = 0.0
		goblin_vestige_attack_applied = false


func _start_orc_vestige_summon() -> void:
	_despawn_orc_vestige(true)
	_play_sfx(SFX_VESTIGE_SUMMON)

	var summon_variant: Variant = ORC_SCENE.instantiate()
	if not (summon_variant is CharacterBody2D):
		return

	orc_vestige_instance = summon_variant as CharacterBody2D
	orc_vestige_instance.remove_from_group("enemy")
	orc_vestige_instance.set_physics_process(false)
	orc_vestige_instance.set_process(false)
	_disable_summoned_enemy_ai(orc_vestige_instance)
	orc_vestige_instance.collision_layer = 0
	orc_vestige_instance.collision_mask = 0

	var collision_shape := orc_vestige_instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape:
		collision_shape.disabled = true

	orc_vestige_sprite = orc_vestige_instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		orc_vestige_instance.free()
		orc_vestige_instance = null
		return

	orc_vestige_instance.set_meta("is_vestige_ally", true)
	host.add_child(orc_vestige_instance)
	orc_vestige_instance.remove_from_group("enemy")

	var facing_direction := _resolve_facing_direction_vector().normalized()
	if facing_direction == Vector2.ZERO:
		facing_direction = Vector2.RIGHT
	orc_vestige_instance.global_position = global_position + (facing_direction * orc_vestige_spawn_offset)

	orc_vestige_target = null
	orc_vestige_no_target_left = orc_vestige_no_target_timeout
	orc_vestige_attack_left = 0.0
	orc_vestige_attack_applied = false

	_play_orc_vestige_move_anim(facing_direction)
	print("[DEBUG][VestigeOrc] spawn")


func _tick_orc_vestige_summon(delta: float) -> void:
	if orc_vestige_instance == null or not is_instance_valid(orc_vestige_instance):
		return

	if orc_vestige_attack_left > 0.0:
		if not _is_vestige_enemy_target_valid(orc_vestige_target, orc_vestige_instance):
			orc_vestige_target = _find_nearest_enemy_for_vestige(orc_vestige_instance.global_position, orc_vestige_instance)
			if orc_vestige_target == null:
				_despawn_orc_vestige(true)
				print("[DEBUG][VestigeOrc] despawn_no_target_during_attack")
				return

		orc_vestige_attack_left = maxf(orc_vestige_attack_left - delta, 0.0)
		if not orc_vestige_attack_applied and orc_vestige_attack_left <= (orc_vestige_attack_duration - orc_vestige_attack_hit_time):
			_perform_orc_vestige_ground_slam(orc_vestige_instance.global_position)
			orc_vestige_attack_applied = true
		if orc_vestige_attack_left <= 0.0:
			_despawn_orc_vestige(true)
			print("[DEBUG][VestigeOrc] despawn_after_slam")
		return

	if not _is_vestige_enemy_target_valid(orc_vestige_target, orc_vestige_instance):
		orc_vestige_target = null

	if orc_vestige_target == null:
		orc_vestige_target = _find_nearest_enemy_for_vestige(orc_vestige_instance.global_position, orc_vestige_instance)
		if orc_vestige_target:
			print("[DEBUG][VestigeOrc] target_acquired=%s" % orc_vestige_target.name)

	if orc_vestige_target == null:
		orc_vestige_no_target_left = maxf(orc_vestige_no_target_left - delta, 0.0)
		_play_orc_vestige_idle_anim()
		if orc_vestige_no_target_left <= 0.0:
			_despawn_orc_vestige(true)
			print("[DEBUG][VestigeOrc] despawn_timeout")
		return

	var to_target := orc_vestige_target.global_position - orc_vestige_instance.global_position
	var distance_to_target := to_target.length()
	if distance_to_target <= orc_vestige_attack_range:
		_play_orc_vestige_attack_anim(to_target)
		orc_vestige_attack_left = orc_vestige_attack_duration
		orc_vestige_attack_applied = false
		return

	var move_direction := to_target / maxf(distance_to_target, 0.001)
	orc_vestige_instance.global_position += move_direction * orc_vestige_chase_speed * delta
	_play_orc_vestige_move_anim(move_direction)


func _perform_orc_vestige_ground_slam(origin: Vector2) -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		if not _is_vestige_enemy_target_valid(enemy_node, orc_vestige_instance):
			continue

		var enemy := enemy_node as Node2D
		if origin.distance_to(enemy.global_position) > orc_vestige_aoe_radius:
			continue

		enemy.call("receive_hit", orc_vestige_damage, origin)

	_spawn_orc_vestige_slam_vfx(origin)
	print("[DEBUG][VestigeOrc] slam")


func _spawn_orc_vestige_slam_vfx(origin: Vector2) -> void:
	if orc_vestige_instance and is_instance_valid(orc_vestige_instance):
		var embedded_vfx := orc_vestige_instance.get_node_or_null("GroundSlamVfx")
		if embedded_vfx != null:
			if embedded_vfx.has_method("configure"):
				embedded_vfx.call(
					"configure",
					orc_vestige_aoe_radius,
					orc_vestige_slam_vfx_duration,
					orc_vestige_slam_vfx_color,
					orc_vestige_slam_vfx_thickness_px
				)
			if embedded_vfx.has_method("play_once"):
				embedded_vfx.call("play_once")
			return

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	var vfx_variant: Variant = ORC_SLAM_RING_VFX_SCRIPT.new()
	if not (vfx_variant is Node2D):
		return

	var vfx := vfx_variant as Node2D
	vfx.global_position = origin
	if vfx.has_method("configure"):
		vfx.call(
			"configure",
			orc_vestige_aoe_radius,
			orc_vestige_slam_vfx_duration,
			orc_vestige_slam_vfx_color,
			orc_vestige_slam_vfx_thickness_px
		)
	host.add_child(vfx)


func _play_orc_vestige_idle_anim() -> void:
	if orc_vestige_sprite == null:
		return
	if orc_vestige_sprite.sprite_frames and orc_vestige_sprite.sprite_frames.has_animation(&"idle"):
		if orc_vestige_sprite.animation != &"idle" or not orc_vestige_sprite.is_playing():
			orc_vestige_sprite.play(&"idle")
	orc_vestige_sprite.scale = Vector2(1.0, 1.0)


func _play_orc_vestige_move_anim(direction: Vector2) -> void:
	if orc_vestige_sprite == null:
		return
	if orc_vestige_sprite.sprite_frames and orc_vestige_sprite.sprite_frames.has_animation(&"move"):
		if orc_vestige_sprite.animation != &"move" or not orc_vestige_sprite.is_playing():
			orc_vestige_sprite.play(&"move")

	if absf(direction.x) > 0.0001:
		orc_vestige_sprite.flip_h = direction.x < 0.0

	orc_vestige_sprite.scale = Vector2(
		-absf(orc_vestige_move_stretch_scale.x) if orc_vestige_sprite.flip_h else absf(orc_vestige_move_stretch_scale.x),
		orc_vestige_move_stretch_scale.y
	)


func _play_orc_vestige_attack_anim(direction: Vector2) -> void:
	if orc_vestige_sprite == null:
		return
	if absf(direction.x) > 0.0001:
		orc_vestige_sprite.flip_h = direction.x < 0.0
	if orc_vestige_sprite.sprite_frames and orc_vestige_sprite.sprite_frames.has_animation(&"attack"):
		orc_vestige_sprite.play(&"attack")
	orc_vestige_sprite.scale = Vector2(
		-1.0 if orc_vestige_sprite.flip_h else 1.0,
		1.0
	)


func _despawn_orc_vestige(should_clear_state: bool = true) -> void:
	if orc_vestige_instance and is_instance_valid(orc_vestige_instance):
		orc_vestige_instance.queue_free()
	if should_clear_state:
		orc_vestige_instance = null
		orc_vestige_sprite = null
		orc_vestige_target = null
		orc_vestige_no_target_left = 0.0
		orc_vestige_attack_left = 0.0
		orc_vestige_attack_applied = false


func _start_skeleton_vestige_summon() -> void:
	_despawn_skeleton_vestige(true)
	_play_sfx(SFX_VESTIGE_SUMMON)

	var summon_variant: Variant = SKELETON_SCENE.instantiate()
	if not (summon_variant is CharacterBody2D):
		return

	skeleton_vestige_instance = summon_variant as CharacterBody2D
	skeleton_vestige_instance.remove_from_group("enemy")
	skeleton_vestige_instance.set_physics_process(false)
	skeleton_vestige_instance.set_process(false)
	_disable_summoned_enemy_ai(skeleton_vestige_instance)
	skeleton_vestige_instance.collision_layer = 0
	skeleton_vestige_instance.collision_mask = 0

	var collision_shape := skeleton_vestige_instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape:
		collision_shape.disabled = true

	skeleton_vestige_sprite = skeleton_vestige_instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		skeleton_vestige_instance.free()
		skeleton_vestige_instance = null
		return

	skeleton_vestige_instance.set_meta("is_vestige_ally", true)
	host.add_child(skeleton_vestige_instance)
	skeleton_vestige_instance.remove_from_group("enemy")

	var facing_direction := _resolve_facing_direction_vector().normalized()
	if facing_direction == Vector2.ZERO:
		facing_direction = Vector2.RIGHT
	skeleton_vestige_instance.global_position = global_position + (facing_direction * skeleton_vestige_spawn_offset)

	skeleton_vestige_target = null
	skeleton_vestige_no_target_left = skeleton_vestige_no_target_timeout
	skeleton_vestige_attack_cooldown_left = 0.0
	skeleton_vestige_has_fired = false

	_play_skeleton_vestige_move_anim(facing_direction)
	print("[DEBUG][VestigeSkeleton] spawn")


func _tick_skeleton_vestige_summon(delta: float) -> void:
	if skeleton_vestige_instance == null or not is_instance_valid(skeleton_vestige_instance):
		return

	if not _is_vestige_enemy_target_valid(skeleton_vestige_target, skeleton_vestige_instance):
		skeleton_vestige_target = null

	if skeleton_vestige_target == null:
		skeleton_vestige_target = _find_nearest_enemy_for_vestige(skeleton_vestige_instance.global_position, skeleton_vestige_instance)
		if skeleton_vestige_target:
			print("[DEBUG][VestigeSkeleton] target_acquired=%s" % skeleton_vestige_target.name)

	if skeleton_vestige_target == null:
		skeleton_vestige_no_target_left = maxf(skeleton_vestige_no_target_left - delta, 0.0)
		_play_skeleton_vestige_idle_anim()
		if skeleton_vestige_no_target_left <= 0.0:
			_despawn_skeleton_vestige(true)
			print("[DEBUG][VestigeSkeleton] despawn_timeout")
		return

	if skeleton_vestige_attack_cooldown_left > 0.0:
		skeleton_vestige_attack_cooldown_left = maxf(skeleton_vestige_attack_cooldown_left - delta, 0.0)

	var to_target := skeleton_vestige_target.global_position - skeleton_vestige_instance.global_position
	var distance_to_target := to_target.length()
	if distance_to_target > skeleton_vestige_preferred_range:
		var move_direction := to_target / maxf(distance_to_target, 0.001)
		skeleton_vestige_instance.global_position += move_direction * skeleton_vestige_chase_speed * delta
		_play_skeleton_vestige_move_anim(move_direction)
		return

	_play_skeleton_vestige_attack_anim(to_target)
	if skeleton_vestige_attack_cooldown_left <= 0.0:
		_throw_skeleton_vestige_bone(to_target)
		skeleton_vestige_attack_cooldown_left = skeleton_vestige_attack_cooldown
		skeleton_vestige_has_fired = true
		print("[DEBUG][VestigeSkeleton] throw_bone")
		_despawn_skeleton_vestige(true)
		print("[DEBUG][VestigeSkeleton] despawn_after_throw")


func _throw_skeleton_vestige_bone(direction_to_target: Vector2) -> void:
	if skeleton_vestige_instance == null or not is_instance_valid(skeleton_vestige_instance):
		return

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	var projectile_variant: Variant = VESTIGE_BONE_PROJECTILE_SCENE.instantiate()
	if not (projectile_variant is Area2D):
		return

	var projectile := projectile_variant as Area2D
	var fire_direction := direction_to_target.normalized() if direction_to_target.length_squared() > 0.0 else Vector2.RIGHT
	projectile.global_position = skeleton_vestige_instance.global_position + (fire_direction * skeleton_vestige_projectile_spawn_offset)
	host.add_child(projectile)

	if projectile.has_method("configure"):
		projectile.call(
			"configure",
			skeleton_vestige_instance,
			fire_direction,
			skeleton_vestige_projectile_speed,
			skeleton_vestige_projectile_lifetime,
			skeleton_vestige_damage,
			5.0
		)


func _play_skeleton_vestige_idle_anim() -> void:
	if skeleton_vestige_sprite == null:
		return
	if skeleton_vestige_sprite.sprite_frames and skeleton_vestige_sprite.sprite_frames.has_animation(&"idle"):
		if skeleton_vestige_sprite.animation != &"idle" or not skeleton_vestige_sprite.is_playing():
			skeleton_vestige_sprite.play(&"idle")
	skeleton_vestige_sprite.scale = Vector2(1.0, 1.0)


func _play_skeleton_vestige_move_anim(direction: Vector2) -> void:
	if skeleton_vestige_sprite == null:
		return
	if skeleton_vestige_sprite.sprite_frames and skeleton_vestige_sprite.sprite_frames.has_animation(&"move"):
		if skeleton_vestige_sprite.animation != &"move" or not skeleton_vestige_sprite.is_playing():
			skeleton_vestige_sprite.play(&"move")

	if absf(direction.x) > 0.0001:
		skeleton_vestige_sprite.flip_h = direction.x < 0.0

	skeleton_vestige_sprite.scale = Vector2(
		-absf(skeleton_vestige_move_stretch_scale.x) if skeleton_vestige_sprite.flip_h else absf(skeleton_vestige_move_stretch_scale.x),
		skeleton_vestige_move_stretch_scale.y
	)


func _play_skeleton_vestige_attack_anim(direction: Vector2) -> void:
	if skeleton_vestige_sprite == null:
		return
	if absf(direction.x) > 0.0001:
		skeleton_vestige_sprite.flip_h = direction.x < 0.0
	if skeleton_vestige_sprite.sprite_frames and skeleton_vestige_sprite.sprite_frames.has_animation(&"attack"):
		skeleton_vestige_sprite.play(&"attack")
	skeleton_vestige_sprite.scale = Vector2(
		-1.0 if skeleton_vestige_sprite.flip_h else 1.0,
		1.0
	)


func _despawn_skeleton_vestige(should_clear_state: bool = true) -> void:
	if skeleton_vestige_instance and is_instance_valid(skeleton_vestige_instance):
		skeleton_vestige_instance.queue_free()
	if should_clear_state:
		skeleton_vestige_instance = null
		skeleton_vestige_sprite = null
		skeleton_vestige_target = null
		skeleton_vestige_no_target_left = 0.0
		skeleton_vestige_attack_cooldown_left = 0.0
		skeleton_vestige_has_fired = false


func _resolve_equipped_species_for_slot(slot_index: int) -> String:
	if not has_node("/root/VestigeInventory"):
		return ""
	return VestigeInventory.get_equipped_species(slot_index)


func _get_species_charge_count(species_id: String) -> int:
	match species_id:
		GOBLIN_SPECIES_ID:
			return goblin_vestige_charges
		ORC_SPECIES_ID:
			return orc_vestige_charges
		SKELETON_SPECIES_ID:
			return skeleton_vestige_charges
	return 0


func _get_species_cooldown_left(species_id: String) -> float:
	match species_id:
		GOBLIN_SPECIES_ID:
			return goblin_vestige_cooldown_left
		ORC_SPECIES_ID:
			return orc_vestige_cooldown_left
		SKELETON_SPECIES_ID:
			return skeleton_vestige_cooldown_left
	return 9999.0


func _sync_local_vestige_counts_from_inventory() -> void:
	if not has_node("/root/VestigeInventory"):
		return
	current_vestige = VestigeInventory.get_total()
	goblin_vestige_charges = VestigeInventory.get_goblin_charges()
	orc_vestige_charges = VestigeInventory.get_orc_charges()
	skeleton_vestige_charges = VestigeInventory.get_skeleton_charges()


func _resolve_facing_direction_vector() -> Vector2:
	if _resolve_attack_facing_from_mouse():
		return Vector2.LEFT
	return Vector2.RIGHT


func get_heart_slot_count() -> int:
	return maxi(1, int(float(max_health + HP_PER_HEART - 1) / HP_PER_HEART))


func get_heart_fill_state(heart_index: int) -> int:
	if heart_index < 0:
		return 0

	var heart_hp := clampi(current_health - (heart_index * HP_PER_HEART), 0, HP_PER_HEART)
	if heart_hp >= HP_PER_HEART:
		return 2
	if heart_hp == (HP_PER_HEART - 1):
		return 1
	return 0


func start_death() -> void:
	is_attack_facing_locked = false
	dash_time_left = 0.0
	dash_invulnerability_left = 0.0
	dash_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_play_sfx(SFX_GAME_OVER)
	_despawn_goblin_vestige(true)
	_despawn_orc_vestige(true)
	_despawn_skeleton_vestige(true)
	_set_sword_active(false)

	if animation_player and animation_player.is_playing():
		animation_player.stop()

	play_required_animation(ANIM_DEATH)


func receive_hit(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if damage <= 0:
		return
	if current_health <= 0:
		return
	if dash_invulnerability_left > 0.0:
		_log_health_debug("hit_ignored_dash_iframe", damage)
		return
	if damage_invulnerability_left > 0.0:
		_log_health_debug("hit_ignored_invulnerability", damage)
		return

	current_health = max(current_health - damage, 0)
	damage_invulnerability_left = damage_invulnerability_duration
	_play_random_sfx(SFX_HIT_VARIANTS)

	if source_position != Vector2.ZERO:
		var knockback_direction := (global_position - source_position).normalized()
		velocity += knockback_direction * hit_knockback_impulse

	player_damaged.emit(current_health, damage)
	_log_health_debug("damaged", damage)
	if current_health == 0:
		_log_health_debug("dead")
		if state_machine != null and state_machine.has_state(STATE_DEAD):
			state_machine.request_transition(STATE_DEAD)
		player_died.emit()


func _log_health_debug(event_name: String, damage_amount: int = 0) -> void:
	if not debug_print_health:
		return

	var heart_text := "%.1f/%d" % [float(current_health) / float(HP_PER_HEART), get_heart_slot_count()]

	if damage_amount > 0:
		print("[DEBUG][PlayerHP] %s | HP: %d/%d | Hearts: %s | Damage: %d" % [event_name, current_health, max_health, heart_text, damage_amount])
		return

	print("[DEBUG][PlayerHP] %s | HP: %d/%d | Hearts: %s" % [event_name, current_health, max_health, heart_text])


func _ensure_sfx_player() -> void:
	if sfx_player == null:
		var created_player := AudioStreamPlayer2D.new()
		created_player.name = "SfxPlayer"
		created_player.max_polyphony = 3
		add_child(created_player)
		sfx_player = created_player

	sfx_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


func _play_random_sfx(streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return

	var random_index := randi_range(0, streams.size() - 1)
	var selected_stream := streams[random_index]
	_play_sfx(selected_stream)


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	if sfx_player == null:
		return

	sfx_player.stream = stream
	sfx_player.play()
