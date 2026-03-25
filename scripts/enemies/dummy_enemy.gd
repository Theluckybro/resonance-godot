extends CharacterBody2D
class_name DummyEnemy

@export var log_hits: bool = true
@export var show_hit_flash: bool = true
@export var hit_flash_duration: float = 0.08

@onready var body_visual: CanvasItem = get_node_or_null("BodyVisual") as CanvasItem

var hit_flash_left: float = 0.0
var total_damage_taken: int = 0
var hit_count: int = 0


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = PhysicsLayers.ENEMY
	collision_mask = PhysicsLayers.ENVIRONMENT_AND_TRIGGER


func _physics_process(delta: float) -> void:
	if not show_hit_flash or body_visual == null:
		return
	if hit_flash_left > 0.0:
		hit_flash_left = maxf(hit_flash_left - delta, 0.0)
		if hit_flash_left <= 0.0:
			body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func receive_hit(damage: int, _source_position: Vector2 = Vector2.ZERO) -> void:
	if damage <= 0:
		return

	hit_count += 1
	total_damage_taken += damage

	if show_hit_flash and body_visual != null:
		body_visual.modulate = Color(1.0, 0.45, 0.45, 1.0)
		hit_flash_left = hit_flash_duration

	if log_hits:
		print("[DEBUG][DummyEnemy] hit_count=%d | damage=%d | total_damage=%d" % [hit_count, damage, total_damage_taken])
