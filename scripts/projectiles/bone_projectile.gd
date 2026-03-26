extends Area2D
class_name BoneProjectile
## Bone projectile variant for skeleton artillery enemies.

const SFX_PROJECTILE_IMPACT: AudioStream = preload("res://assets/audio/sfx/ProjectileImpact.mp3")

@export var speed: float = 170.0
@export var lifetime_sec: float = 1.25
@export var damage: int = 10
@export var rotation_speed: float = 360.0  # degrees per second

var direction: Vector2 = Vector2.RIGHT
var source_enemy: Node2D
var life_left: float = 0.0


func _ready() -> void:
	collision_layer = PhysicsLayers.PROJECTILE_ENEMY
	collision_mask = PhysicsLayers.MASK_PROJECTILE_ENEMY
	monitoring = true
	monitorable = true
	life_left = lifetime_sec

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func configure(
	owner_enemy: Node2D,
	fire_direction: Vector2,
	projectile_speed: float,
	projectile_lifetime: float,
	projectile_damage: int,
	_projectile_radius: float = 5.0
) -> void:
	source_enemy = owner_enemy
	direction = fire_direction.normalized() if fire_direction.length_squared() > 0.0 else Vector2.RIGHT
	speed = maxf(projectile_speed, 1.0)
	lifetime_sec = maxf(projectile_lifetime, 0.1)
	life_left = lifetime_sec
	damage = max(projectile_damage, 1)
	# Note: bone projectile ignores radius, uses fixed size for visual consistency


func _physics_process(delta: float) -> void:
	life_left = maxf(life_left - delta, 0.0)
	if life_left <= 0.0:
		queue_free()
		return

	rotation += deg_to_rad(rotation_speed * delta)
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	_handle_collider(body)


func _on_area_entered(area: Area2D) -> void:
	if area == self:
		return
	_handle_collider(area)


func _handle_collider(collider: Node) -> void:
	if collider == null:
		return

	var target := _resolve_damage_target(collider)
	if target != null:
		target.call("receive_hit", damage, global_position)
		_play_impact_sfx()
		queue_free()
		return

	if _should_block_projectile(collider):
		_play_impact_sfx()
		queue_free()


func _resolve_damage_target(collider: Node) -> Node:
	var current: Node = collider
	while current != null:
		if current == self:
			return null
		if source_enemy != null and (current == source_enemy or source_enemy.is_ancestor_of(current)):
			return null
		if current.is_in_group("enemy"):
			return null
		if current.has_method("receive_hit"):
			return current
		current = current.get_parent()
	return null


func _should_block_projectile(collider: Node) -> bool:
	if source_enemy != null and (collider == source_enemy or source_enemy.is_ancestor_of(collider)):
		return false
	if collider.is_in_group("enemy"):
		return false
	return true


func _play_impact_sfx() -> void:
	if SFX_PROJECTILE_IMPACT == null:
		return

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	var sfx := AudioStreamPlayer2D.new()
	sfx.stream = SFX_PROJECTILE_IMPACT
	sfx.bus = &"Master"
	sfx.global_position = global_position
	host.add_child(sfx)
	sfx.play()

	var timer := get_tree().create_timer(maxf(SFX_PROJECTILE_IMPACT.get_length(), 0.05))
	await timer.timeout
	if is_instance_valid(sfx):
		sfx.queue_free()
