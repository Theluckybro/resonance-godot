extends CharacterBody2D
class_name EnemyMeleeFast

signal enemy_died(enemy: EnemyMeleeFast)

@export var max_health: int = 8
@export var move_speed: float = 70.0
@export var acceleration: float = 420.0
@export var aggro_range: float = 170.0
@export var hit_flash_duration: float = 0.1
@export var hit_stun_duration: float = 0.08
@export var hit_freeze_duration: float = 0.035
@export var knockback_impulse: float = 110.0

@onready var body_visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var state_machine: StateMachine = $StateMachine

const STATE_IDLE: StringName = &"idle"
const STATE_CHASE: StringName = &"chase"
const STATE_HIT_STUN: StringName = &"hit_stun"
const STATE_DEAD: StringName = &"dead"

var current_state_name: StringName = &""
var current_health: int = 0
var hit_stun_left: float = 0.0
var hit_flash_left: float = 0.0
var local_freeze_left: float = 0.0
var visual_time: float = 0.0
var target_player: Node2D
var base_modulate: Color = Color.WHITE


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = PhysicsLayers.ENEMY
	collision_mask = PhysicsLayers.MASK_ENEMY_BODY
	current_health = max_health

	if body_visual:
		base_modulate = body_visual.modulate

	_refresh_player_target()

	if state_machine == null:
		push_error("EnemyMeleeFast is missing StateMachine node.")
		return

	state_machine.set_context(self)
	state_machine.start()
	_update_visual_state(0.0)


func _physics_process(delta: float) -> void:
	if is_dead_state():
		return
	visual_time += delta
	_update_timers(delta)

	if local_freeze_left > 0.0:
		_update_visual_state(delta)
		return

	if not has_valid_target_player():
		_refresh_player_target()

	if state_machine:
		state_machine.physics_step(delta)

	move_and_slide()
	_update_visual_state(delta)


func _update_timers(delta: float) -> void:
	if hit_flash_left > 0.0:
		hit_flash_left = max(hit_flash_left - delta, 0.0)
	if local_freeze_left > 0.0:
		local_freeze_left = max(local_freeze_left - delta, 0.0)


func receive_hit(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead_state():
		return
	if damage <= 0:
		return

	current_health = max(current_health - damage, 0)
	hit_flash_left = hit_flash_duration
	if body_visual:
		body_visual.modulate = Color.WHITE

	if source_position != Vector2.ZERO:
		var knockback_direction := (global_position - source_position).normalized()
		velocity += knockback_direction * knockback_impulse

	local_freeze_left = maxf(local_freeze_left, hit_freeze_duration)
	hit_stun_left = hit_stun_duration
	_spawn_feedback_burst(Color(1.0, 0.92, 0.92, 0.95), 8, 16.0, 0.16)

	if current_health == 0:
		request_state(STATE_DEAD)
		return

	request_state(STATE_HIT_STUN)


func on_enter_dead_state() -> void:
	collision_layer = 0
	collision_mask = 0
	_spawn_feedback_burst(Color(1.0, 0.45, 0.45, 0.9), 16, 24.0, 0.26)
	enemy_died.emit(self)

	if body_visual:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 0.35)

	var vanish_tween := create_tween()
	vanish_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	vanish_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	vanish_tween.tween_callback(queue_free)


func _refresh_player_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		target_player = null
		return

	if players[0] is Node2D:
		target_player = players[0] as Node2D


func has_valid_target_player() -> bool:
	return target_player != null and is_instance_valid(target_player)


func is_player_in_aggro_range() -> bool:
	if not has_valid_target_player():
		return false
	return global_position.distance_to(target_player.global_position) <= aggro_range


func apply_idle_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)


func apply_chase_motion(delta: float) -> void:
	if not has_valid_target_player():
		apply_idle_motion(delta)
		return

	var desired_velocity := (target_player.global_position - global_position).normalized() * move_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)


func update_hit_stun_motion(delta: float) -> void:
	hit_stun_left = max(hit_stun_left - delta, 0.0)
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * 1.6 * delta)


func is_hit_stun_finished() -> bool:
	return hit_stun_left <= 0.0


func request_state(state_name: StringName) -> void:
	if state_machine == null:
		return
	state_machine.request_transition(state_name)


func set_visual_state(state_name: StringName) -> void:
	current_state_name = state_name


func is_dead_state() -> bool:
	return current_state_name == STATE_DEAD


func _update_visual_state(delta: float) -> void:
	if body_visual == null:
		return

	var target_scale := Vector2.ONE
	var target_rotation := 0.0
	var target_modulate := base_modulate

	match current_state_name:
		STATE_IDLE:
			var idle_pulse := 0.5 + 0.5 * sin(visual_time * 3.0)
			target_scale = Vector2.ONE * (0.95 + idle_pulse * 0.06)
			target_rotation = sin(visual_time * 2.6) * 0.02
		STATE_CHASE:
			var chase_pulse := 0.5 + 0.5 * sin(visual_time * 10.0)
			target_scale = Vector2(1.04 + chase_pulse * 0.08, 0.96 - chase_pulse * 0.04)
			if velocity.length() > 0.1:
				target_rotation = clamp(velocity.normalized().x * 0.16, -0.16, 0.16)
		STATE_HIT_STUN:
			target_scale = Vector2(1.12, 0.88)
			target_modulate = Color.WHITE
		STATE_DEAD:
			target_scale = Vector2(0.75, 0.75)
			target_modulate = Color(1.0, 1.0, 1.0, 0.35)

	if hit_flash_left > 0.0 and current_state != State.DEAD:
		target_modulate = Color.WHITE

	var blend_speed := clampf(delta * 18.0, 0.0, 1.0)
	body_visual.scale = body_visual.scale.lerp(target_scale, blend_speed)
	body_visual.rotation = lerpf(body_visual.rotation, target_rotation, blend_speed)
	body_visual.modulate = body_visual.modulate.lerp(target_modulate, clampf(delta * 20.0, 0.0, 1.0))


func _spawn_feedback_burst(color: Color, particle_count: int, radius: float, lifetime: float) -> void:
	if particle_count <= 0:
		return

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	for _index in particle_count:
		var fragment := Polygon2D.new()
		fragment.polygon = PackedVector2Array([
			Vector2(0, -1),
			Vector2(1, 0),
			Vector2(0, 1),
			Vector2(-1, 0),
		])
		fragment.color = color
		fragment.global_position = global_position
		fragment.scale = Vector2.ONE * randf_range(0.7, 1.4)
		host.add_child(fragment)

		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var distance := randf_range(radius * 0.4, radius)
		var target_position := fragment.global_position + direction * distance

		var tween := fragment.create_tween()
		tween.tween_property(fragment, "global_position", target_position, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(fragment, "scale", Vector2.ZERO, lifetime)
		var faded_modulate := fragment.modulate
		faded_modulate.a = 0.0
		tween.parallel().tween_property(fragment, "modulate", faded_modulate, lifetime)
		tween.finished.connect(fragment.queue_free)
