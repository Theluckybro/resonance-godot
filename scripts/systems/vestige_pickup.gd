extends Area2D

@export var vestige_amount: int = 1

@onready var orb_sprite: Sprite2D = get_node_or_null("OrbSprite")
@onready var orb_glow: Sprite2D = get_node_or_null("OrbGlow")

var is_consumed: bool = false
var pending_orb_texture: Texture2D
var source_species_id: String = ""


func _ready() -> void:
	collision_layer = PhysicsLayers.PICKUP
	collision_mask = PhysicsLayers.MASK_PICKUP
	_apply_orb_texture_if_ready()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func set_vestige_amount(amount: int) -> void:
	vestige_amount = maxi(1, amount)


func set_orb_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	pending_orb_texture = texture
	_apply_orb_texture_if_ready()


func set_source_species(species_id: String) -> void:
	source_species_id = species_id.strip_edges().to_lower()


func _apply_orb_texture_if_ready() -> void:
	if pending_orb_texture == null:
		return
	if orb_sprite:
		orb_sprite.texture = pending_orb_texture
	if orb_glow:
		orb_glow.texture = pending_orb_texture


func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	_try_collect(area)


func _try_collect(collider: Node) -> void:
	if is_consumed:
		return

	var player_node := _resolve_player_node(collider)
	if player_node == null:
		return

	is_consumed = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0

	if player_node.has_method("collect_vestige"):
		player_node.call("collect_vestige", vestige_amount, source_species_id)

	queue_free()


func _resolve_player_node(collider: Node) -> Node:
	var current: Node = collider
	while current != null:
		if current.is_in_group("player") and current.has_method("collect_vestige"):
			return current
		current = current.get_parent()
	return null
