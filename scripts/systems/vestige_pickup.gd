extends Area2D

const MIN_VESTIGE_CHARGE_PER_ORB: int = 3
const SFX_VESTIGE_PICKUP: AudioStream = preload("res://assets/audio/sfx/VestigePickUp.mp3")
const VESTIGE_CHARGES_CONFIG_PATH: String = "res://data/vestiges/VestigeCharges.json"

@export var vestige_amount: int = MIN_VESTIGE_CHARGE_PER_ORB
@export var auto_pickup_radius: float = 0

@onready var orb_sprite: Sprite2D = get_node_or_null("OrbSprite")
@onready var orb_glow: Sprite2D = get_node_or_null("OrbGlow")
@onready var sfx_player: AudioStreamPlayer2D = get_node_or_null("SfxPlayer")

var is_consumed: bool = false
var pending_orb_texture: Texture2D
var source_species_id: String = ""
var _vestige_charges_config: Dictionary = {}


func _ready() -> void:
	_ensure_sfx_player()
	_load_vestige_charges_config()
	monitoring = true
	monitorable = true
	collision_layer = PhysicsLayers.PICKUP
	collision_mask = PhysicsLayers.MASK_PICKUP
	_apply_orb_texture_if_ready()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func set_vestige_amount(amount: int) -> void:
	vestige_amount = maxi(MIN_VESTIGE_CHARGE_PER_ORB, amount)


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
	
	# Hide visuals immediately so Y sorting doesn't render the collected orb
	if orb_sprite:
		orb_sprite.visible = false
	if orb_glow:
		orb_glow.visible = false

	if player_node.has_method("collect_vestige"):
		var grant_amount := _get_charge_for_species(source_species_id)
		player_node.call("collect_vestige", grant_amount, source_species_id)
		_play_pickup_sfx_then_free()
		return

	queue_free()


func _physics_process(_delta: float) -> void:
	if is_consumed:
		return
	var player_variant := get_tree().get_first_node_in_group("player")
	if not (player_variant is Node2D):
		return

	var player := player_variant as Node2D
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > auto_pickup_radius:
		return

	_try_collect(player)


func _resolve_player_node(collider: Node) -> Node:
	var current: Node = collider
	while current != null:
		if current.is_in_group("player") and current.has_method("collect_vestige"):
			return current
		current = current.get_parent()
	return null


func _ensure_sfx_player() -> void:
	if sfx_player == null:
		var created_player := AudioStreamPlayer2D.new()
		created_player.name = "SfxPlayer"
		created_player.max_polyphony = 1
		add_child(created_player)
		sfx_player = created_player

	sfx_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


func _play_pickup_sfx_then_free() -> void:
	if sfx_player == null or SFX_VESTIGE_PICKUP == null:
		queue_free()
		return

	sfx_player.stream = SFX_VESTIGE_PICKUP
	sfx_player.play()

	var stream_length := SFX_VESTIGE_PICKUP.get_length()
	if stream_length <= 0.0:
		queue_free()
		return

	var timer := get_tree().create_timer(stream_length)
	await timer.timeout
	queue_free()


func _load_vestige_charges_config() -> void:
	var file := FileAccess.open(VESTIGE_CHARGES_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to load vestige charges config from: %s" % VESTIGE_CHARGES_CONFIG_PATH)
		return
	
	var json_string := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Failed to parse vestige charges config: %s" % json.get_error_message())
		return
	
	_vestige_charges_config = json.get_data() as Dictionary


func _get_charge_for_species(species_id: String) -> int:
	if _vestige_charges_config.is_empty():
		return maxi(MIN_VESTIGE_CHARGE_PER_ORB, vestige_amount)
	
	var species_charges := _vestige_charges_config.get("species_charges", {}) as Dictionary
	var species_key := species_id.to_lower()
	
	if species_charges.has(species_key):
		return species_charges[species_key] as int
	
	# Fallback to default charge from config or use vestige_amount
	var default_charge: int = _vestige_charges_config.get("default_charge", MIN_VESTIGE_CHARGE_PER_ORB) as int
	return maxi(MIN_VESTIGE_CHARGE_PER_ORB, default_charge)
