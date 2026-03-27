extends CharacterBody2D
class_name Enemy

signal enemy_died(enemy: Enemy)

const SPECIES_GOBLIN: String = "goblin"
const SPECIES_ORC: String = "orc"
const SPECIES_SKIRMISHER: String = "species_skirmisher"
const SPECIES_SKELETON: String = "skeleton"
const SPECIES_CONTROLLER: String = "species_controller"

const ROLE_DUELIST: String = "duelist"
const ROLE_BRUISER: String = "bruiser"
const ROLE_SKIRMISHER: String = "skirmisher"
const ROLE_ARTILLERY: String = "artillery"
const ROLE_CONTROLLER: String = "controller"
const PRESET_FILE_PATH: String = "res://data/enemies/EnemyArchetypePresets.json"
const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/bone_projectile.tscn")
const VESTIGE_PICKUP_SCENE: PackedScene = preload("res://scenes/core/vestige_pickup.tscn")
const ORC_SLAM_RING_VFX_SCRIPT: Script = preload("res://scripts/enemies/vfx/orc_slam_ring_vfx.gd")
const VESTIGE_ORB_GOBLIN: Texture2D = preload("res://assets/Sprites/Vestige/OrbGoblin.png")
const VESTIGE_ORB_ORC: Texture2D = preload("res://assets/Sprites/Vestige/OrbOrc.png")
const VESTIGE_ORB_SKELETON: Texture2D = preload("res://assets/Sprites/Vestige/OrbSkeleton.png")
const SFX_GOBLIN_ATTACK: AudioStream = preload("res://assets/audio/sfx/GoblinAttack.mp3")
const SFX_ORC_ATTACK: AudioStream = preload("res://assets/audio/sfx/OrcAttack.mp3")
const SFX_SKELETON_ATTACK: AudioStream = preload("res://assets/audio/sfx/SkeletonAttack.mp3")
const SFX_GOBLIN_DEATH: AudioStream = preload("res://assets/audio/sfx/GoblinDeath.mp3")
const SFX_HIT_VARIANTS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/Hit1.mp3"),
	preload("res://assets/audio/sfx/Hit2.mp3"),
	preload("res://assets/audio/sfx/Hit3.mp3"),
]

const DEFAULT_SPECIES_TO_ROLE := {
	SPECIES_GOBLIN: ROLE_DUELIST,
	SPECIES_ORC: ROLE_BRUISER,
	SPECIES_SKIRMISHER: ROLE_SKIRMISHER,
	SPECIES_SKELETON: ROLE_ARTILLERY,
	SPECIES_CONTROLLER: ROLE_CONTROLLER,
}

const SPECIES_TO_VESTIGE_ORB := {
	SPECIES_GOBLIN: VESTIGE_ORB_GOBLIN,
	SPECIES_ORC: VESTIGE_ORB_ORC,
	SPECIES_SKELETON: VESTIGE_ORB_SKELETON,
}

const LEGACY_ARCHETYPE_TO_ROLE := {
	"Duelist": ROLE_DUELIST,
	"Bruiser": ROLE_BRUISER,
	"Skirmisher": ROLE_SKIRMISHER,
	"Artillery": ROLE_ARTILLERY,
	"Controller": ROLE_CONTROLLER,
	"MeleeCepat": ROLE_DUELIST,
	"MeleeBeratTelegraphed": ROLE_BRUISER,
	"RangedZoning": ROLE_ARTILLERY,
}

static var _preset_cache_loaded: bool = false
static var _preset_species_cache: Dictionary = {}
static var _preset_roles_cache: Dictionary = {}

@export var max_health: int = 8
@export var move_speed: float = 70.0
@export var acceleration: float = 420.0
@export var aggro_range: float = 170.0
@export_enum("goblin", "orc", "species_skirmisher", "skeleton", "species_controller") var species_id: String = SPECIES_GOBLIN
@export var role_id: String = ""
@export var hit_flash_duration: float = 0.1
@export var hit_stun_duration: float = 0.08
@export var hit_freeze_duration: float = 0.035
@export var knockback_impulse: float = 110.0
@export_range(0.0, 1.0, 0.01) var vestige_drop_chance: float = 0.5
@export var vestige_drop_amount: int = 1
@export var hit_spark_particle_count: int = 20
@export var hit_spark_radius: float = 16.0
@export var hit_spark_lifetime: float = 0.4
@export var hit_spark_color: Color = Color(1.0, 0.27, 0.0, 1.0)
@export var ground_slam_vfx_duration: float = 0.22
@export var ground_slam_vfx_color: Color = Color(1.0, 0.64, 0.32, 0.95)
@export var ground_slam_vfx_thickness_px: float = 2.4

@onready var body_visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var state_machine: StateMachine = $StateMachine
@onready var sfx_player: AudioStreamPlayer2D = get_node_or_null("SfxPlayer")

const STATE_IDLE: StringName = &"idle"
const STATE_CHASE: StringName = &"chase"
const STATE_ATTACK: StringName = &"attack"
const STATE_HIT_STUN: StringName = &"hit_stun"
const STATE_DEAD: StringName = &"dead"

const ANIM_IDLE: StringName = &"idle"
const ANIM_MOVE: StringName = &"move"
const ANIM_ATTACK: StringName = &"attack"
const FACING_DEADZONE_X: float = 0.25

var current_state_name: StringName = &""
var current_health: int = 0
var hit_stun_left: float = 0.0
var hit_flash_left: float = 0.0
var local_freeze_left: float = 0.0
var visual_time: float = 0.0
var target_player: Node2D
var base_modulate: Color = Color.WHITE
var active_role_id: String = ROLE_DUELIST
var artillery_attack_cooldown: float = 1.1
var artillery_attack_cooldown_left: float = 0.0
var artillery_min_range: float = 64.0
var artillery_preferred_range: float = 108.0
var artillery_max_range: float = 156.0
var artillery_strafe_speed: float = 42.0
var artillery_retreat_speed: float = 72.0
var artillery_sidestep_interval: float = 1.1
var artillery_strafe_switch_left: float = 0.0
var artillery_strafe_sign: float = 1.0
var artillery_projectile_speed: float = 170.0
var artillery_projectile_lifetime: float = 1.25
var artillery_projectile_damage: int = 10
var artillery_projectile_radius: float = 4.0
var melee_attack_range: float = 14.0
var melee_aoe_radius: float = 14.0
var melee_attack_damage: int = 9
var melee_attack_cooldown: float = 0.5
var melee_attack_cooldown_left: float = 0.0
var melee_windup_sec: float = 0.13
var melee_active_sec: float = 0.08
var melee_recover_sec: float = 0.16
var melee_lunge_px: float = 8.0
var melee_has_hit_in_cycle: bool = false


func _ready() -> void:
	_ensure_sfx_player()
	_apply_species_and_role_from_runtime()
	add_to_group("enemy")
	collision_layer = PhysicsLayers.ENEMY
	collision_mask = PhysicsLayers.MASK_ENEMY_BODY
	current_health = max_health

	if body_visual:
		base_modulate = body_visual.modulate

	_refresh_player_target()
	_update_facing_direction()

	if state_machine == null:
		push_error("Enemy is missing StateMachine node.")
		return

	state_machine.set_context(self)
	state_machine.start()
	_update_visual_state(0.0)


func _apply_species_and_role_from_runtime() -> void:
	var runtime_species: String = _resolve_runtime_species_id()
	species_id = runtime_species

	var runtime_role: String = _resolve_runtime_role_id(runtime_species)
	active_role_id = runtime_role
	var default_role: String = _get_species_default_role(runtime_species)
	role_id = runtime_role if runtime_role != default_role else ""

	var preset: Dictionary = _get_role_preset(runtime_role)
	if preset.is_empty():
		push_warning("Enemy preset for role '%s' is missing." % runtime_role)
		_initialize_role_runtime()
		return

	_apply_preset_values(preset)
	_initialize_role_runtime()


func _resolve_runtime_species_id() -> String:
	var resolved_species: String = species_id.strip_edges().to_lower()
	if has_meta("species_id"):
		var meta_species: Variant = get_meta("species_id")
		if meta_species is StringName or meta_species is String:
			resolved_species = String(meta_species).strip_edges().to_lower()

	if resolved_species.is_empty():
		return SPECIES_GOBLIN
	return resolved_species


func _resolve_runtime_role_id(runtime_species: String) -> String:
	if has_meta("role_override"):
		var meta_role_override: Variant = get_meta("role_override")
		var override_role: String = _extract_role_from_variant(meta_role_override)
		if not override_role.is_empty():
			return override_role

	# Backward compatibility for older spawn metadata.
	if has_meta("enemy_role"):
		var legacy_meta_role: Variant = get_meta("enemy_role")
		var legacy_role: String = _extract_role_from_variant(legacy_meta_role)
		if not legacy_role.is_empty():
			return legacy_role

	var scene_role_override: String = role_id.strip_edges().to_lower()
	if not scene_role_override.is_empty():
		return scene_role_override

	return _get_species_default_role(runtime_species)


func _extract_role_from_variant(value: Variant) -> String:
	if value is StringName or value is String:
		return String(value).strip_edges().to_lower()
	return ""


func _get_species_default_role(species: String) -> String:
	_ensure_preset_cache_loaded()

	var species_variant: Variant = _preset_species_cache.get(species, {})
	if species_variant is Dictionary:
		var species_dict := species_variant as Dictionary
		var default_role_variant: Variant = species_dict.get("default_role", "")
		var default_role: String = _extract_role_from_variant(default_role_variant)
		if not default_role.is_empty():
			return default_role

	var fallback_role_variant: Variant = DEFAULT_SPECIES_TO_ROLE.get(species, ROLE_DUELIST)
	if fallback_role_variant is String:
		return fallback_role_variant as String
	return ROLE_DUELIST


func _get_role_preset(role: String) -> Dictionary:
	_ensure_preset_cache_loaded()

	var normalized_role: String = role.strip_edges().to_lower()
	var preset_variant: Variant = _preset_roles_cache.get(normalized_role, {})
	if preset_variant is Dictionary:
		return (preset_variant as Dictionary).duplicate(true)
	return {}


func _ensure_preset_cache_loaded() -> void:
	if _preset_cache_loaded:
		return
	_preset_cache_loaded = true

	if not FileAccess.file_exists(PRESET_FILE_PATH):
		push_warning("Enemy preset file not found: %s" % PRESET_FILE_PATH)
		return

	var raw_text := FileAccess.get_file_as_string(PRESET_FILE_PATH)
	if raw_text.is_empty():
		push_warning("Enemy preset file is empty: %s" % PRESET_FILE_PATH)
		return

	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("Enemy preset file has invalid JSON structure.")
		return

	var root := parsed as Dictionary

	var species_value: Variant = root.get("species", {})
	if species_value is Dictionary:
		var species_dict := species_value as Dictionary
		for species_key_variant in species_dict.keys():
			var normalized_species: String = String(species_key_variant).to_lower()
			var species_entry_variant: Variant = species_dict[species_key_variant]
			if species_entry_variant is Dictionary:
				_preset_species_cache[normalized_species] = (species_entry_variant as Dictionary).duplicate(true)

	var roles_value: Variant = root.get("roles", {})
	if roles_value is Dictionary:
		var roles_dict := roles_value as Dictionary
		for role_key_variant in roles_dict.keys():
			var normalized_role: String = String(role_key_variant).to_lower()
			var role_entry_variant: Variant = roles_dict[role_key_variant]
			if role_entry_variant is Dictionary:
				_preset_roles_cache[normalized_role] = (role_entry_variant as Dictionary).duplicate(true)

	# Backward compatibility for previous files that still store presets in "archetypes".
	var archetypes_value: Variant = root.get("archetypes", {})
	if archetypes_value is Dictionary:
		var archetypes_dict := archetypes_value as Dictionary
		for archetype_key_variant in archetypes_dict.keys():
			var mapped_role: String = _map_legacy_archetype_key_to_role(String(archetype_key_variant))
			if mapped_role.is_empty() or _preset_roles_cache.has(mapped_role):
				continue

			var archetype_entry_variant: Variant = archetypes_dict[archetype_key_variant]
			if archetype_entry_variant is Dictionary:
				_preset_roles_cache[mapped_role] = (archetype_entry_variant as Dictionary).duplicate(true)


func _map_legacy_archetype_key_to_role(archetype_key: String) -> String:
	var mapped_variant: Variant = LEGACY_ARCHETYPE_TO_ROLE.get(archetype_key, "")
	if mapped_variant is String:
		return (mapped_variant as String).to_lower()
	return archetype_key.to_lower()


func _apply_preset_values(preset: Dictionary) -> void:
	max_health = int(preset.get("hp", max_health))
	move_speed = float(preset.get("move_speed", move_speed))
	acceleration = float(preset.get("accel", acceleration))
	aggro_range = float(preset.get("aggro_range", aggro_range))
	hit_stun_duration = float(preset.get("hit_stun_sec", hit_stun_duration))
	hit_flash_duration = float(preset.get("hit_flash_sec", hit_flash_duration))

	if preset.has("knockback_resist"):
		var knockback_resist := clampf(float(preset.get("knockback_resist", 0.0)), 0.0, 0.95)
		knockback_impulse = knockback_impulse * (1.0 - knockback_resist)

	artillery_attack_cooldown = maxf(float(preset.get("cooldown_sec", artillery_attack_cooldown)), 0.05)
	artillery_min_range = maxf(float(preset.get("min_range", artillery_min_range)), 8.0)
	artillery_preferred_range = maxf(float(preset.get("preferred_range", artillery_preferred_range)), artillery_min_range + 1.0)
	artillery_max_range = maxf(float(preset.get("max_range", artillery_max_range)), artillery_preferred_range + 1.0)
	artillery_strafe_speed = maxf(float(preset.get("strafe_speed", artillery_strafe_speed)), 0.0)
	artillery_retreat_speed = maxf(float(preset.get("retreat_speed", artillery_retreat_speed)), 0.0)
	artillery_sidestep_interval = maxf(float(preset.get("sidestep_interval_sec", artillery_sidestep_interval)), 0.1)
	artillery_projectile_speed = maxf(float(preset.get("projectile_speed", artillery_projectile_speed)), 1.0)
	artillery_projectile_lifetime = maxf(float(preset.get("projectile_lifetime_sec", artillery_projectile_lifetime)), 0.1)
	artillery_projectile_damage = max(int(preset.get("projectile_damage", artillery_projectile_damage)), 1)
	artillery_projectile_radius = maxf(float(preset.get("projectile_radius_px", artillery_projectile_radius)), 1.0)

	melee_attack_range = maxf(float(preset.get("attack_range", melee_attack_range)), 1.0)
	melee_aoe_radius = maxf(float(preset.get("aoe_radius_px", melee_attack_range)), 1.0)
	melee_attack_damage = max(int(preset.get("damage", melee_attack_damage)), 1)
	melee_attack_cooldown = maxf(float(preset.get("cooldown_sec", melee_attack_cooldown)), 0.05)
	melee_windup_sec = maxf(float(preset.get("windup_sec", melee_windup_sec)), 0.01)
	melee_active_sec = maxf(float(preset.get("active_sec", melee_active_sec)), 0.01)
	melee_recover_sec = maxf(float(preset.get("recover_sec", melee_recover_sec)), 0.01)
	melee_lunge_px = maxf(float(preset.get("lunge_px", melee_lunge_px)), 0.0)


func _initialize_role_runtime() -> void:
	if is_melee_role():
		melee_attack_cooldown_left = randf_range(0.0, melee_attack_cooldown)
		melee_has_hit_in_cycle = false

	if active_role_id != ROLE_ARTILLERY:
		return

	artillery_attack_cooldown_left = randf_range(0.0, artillery_attack_cooldown)
	artillery_strafe_switch_left = randf_range(0.0, artillery_sidestep_interval)
	artillery_strafe_sign = -1.0 if (randi() % 2) == 0 else 1.0


func _physics_process(delta: float) -> void:
	if is_dead_state():
		return
	visual_time += delta
	_update_timers(delta)

	if not has_valid_target_player():
		_refresh_player_target()
	_update_facing_direction()

	if local_freeze_left > 0.0:
		_update_visual_state(delta)
		return

	if state_machine:
		state_machine.physics_step(delta)

	_try_fire_artillery_projectile()

	move_and_slide()
	_update_visual_state(delta)


func _update_timers(delta: float) -> void:
	if hit_flash_left > 0.0:
		hit_flash_left = max(hit_flash_left - delta, 0.0)
	if local_freeze_left > 0.0:
		local_freeze_left = max(local_freeze_left - delta, 0.0)
	if is_melee_role():
		melee_attack_cooldown_left = maxf(melee_attack_cooldown_left - delta, 0.0)
	if active_role_id == ROLE_ARTILLERY:
		artillery_attack_cooldown_left = maxf(artillery_attack_cooldown_left - delta, 0.0)
		artillery_strafe_switch_left = maxf(artillery_strafe_switch_left - delta, 0.0)


func receive_hit(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead_state():
		return
	if damage <= 0:
		return

	current_health = max(current_health - damage, 0)
	hit_flash_left = hit_flash_duration
	_play_random_sfx(SFX_HIT_VARIANTS)
	if body_visual:
		body_visual.modulate = Color.WHITE

	if source_position != Vector2.ZERO:
		var knockback_direction := (global_position - source_position).normalized()
		velocity += knockback_direction * knockback_impulse

	local_freeze_left = maxf(local_freeze_left, hit_freeze_duration)
	hit_stun_left = hit_stun_duration
	_spawn_hit_spark()

	if current_health == 0:
		request_state(STATE_DEAD)
		return

	request_state(STATE_HIT_STUN)


func _spawn_hit_spark() -> void:
	_spawn_feedback_burst(hit_spark_color, hit_spark_particle_count, hit_spark_radius, hit_spark_lifetime)


func on_enter_dead_state() -> void:
	collision_layer = 0
	collision_mask = 0
	_play_sfx(_resolve_death_sfx())
	_spawn_feedback_burst(Color(1.0, 0.45, 0.45, 0.9), 16, 24.0, 0.26)
	_try_spawn_vestige_pickup()
	enemy_died.emit(self)

	if body_visual:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 0.35)

	var vanish_tween := create_tween()
	vanish_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	vanish_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	vanish_tween.tween_callback(queue_free)


func _try_spawn_vestige_pickup() -> void:
	if vestige_drop_amount <= 0:
		return

	if randf() > clampf(vestige_drop_chance, 0.0, 1.0):
		return

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	var drop_position := global_position + Vector2(randf_range(-4.0, 4.0), -3.0)
	var pickup := _create_vestige_pickup(drop_position, vestige_drop_amount, species_id)
	if pickup == null:
		return
	host.call_deferred("add_child", pickup)


func _create_vestige_pickup(spawn_position: Vector2, amount: int, source_species: String) -> Area2D:
	var pickup_variant: Variant = VESTIGE_PICKUP_SCENE.instantiate()
	if not (pickup_variant is Area2D):
		return null

	var pickup := pickup_variant as Area2D
	pickup.global_position = spawn_position

	if pickup.has_method("set_vestige_amount"):
		pickup.call("set_vestige_amount", amount)
	if pickup.has_method("set_source_species"):
		pickup.call("set_source_species", source_species)

	var orb_texture_variant: Variant = SPECIES_TO_VESTIGE_ORB.get(source_species, null)
	if orb_texture_variant is Texture2D and pickup.has_method("set_orb_texture"):
		pickup.call("set_orb_texture", orb_texture_variant)

	return pickup


func _refresh_player_target() -> void:
	if _is_vestige_ally_instance():
		target_player = null
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		target_player = null
		return

	if players[0] is Node2D:
		target_player = players[0] as Node2D


func has_valid_target_player() -> bool:
	if _is_vestige_ally_instance():
		return false
	return target_player != null and is_instance_valid(target_player)


func _update_facing_direction() -> void:
	if body_visual == null:
		return
	if not has_valid_target_player():
		return

	var horizontal_delta := target_player.global_position.x - global_position.x
	if absf(horizontal_delta) <= FACING_DEADZONE_X:
		return

	body_visual.flip_h = horizontal_delta < 0.0


func is_player_in_aggro_range() -> bool:
	if _is_vestige_ally_instance():
		return false
	if not has_valid_target_player():
		return false
	return global_position.distance_to(target_player.global_position) <= aggro_range


func is_melee_role() -> bool:
	return active_role_id == ROLE_DUELIST or active_role_id == ROLE_BRUISER


func uses_ground_slam_attack() -> bool:
	return active_role_id == ROLE_BRUISER


func can_start_melee_attack() -> bool:
	if _is_vestige_ally_instance():
		return false
	if not is_melee_role():
		return false
	if current_state_name != STATE_CHASE:
		return false
	if melee_attack_cooldown_left > 0.0:
		return false
	if not has_valid_target_player():
		return false

	var distance_to_player := global_position.distance_to(target_player.global_position)
	if uses_ground_slam_attack():
		return distance_to_player <= melee_aoe_radius
	return distance_to_player <= melee_attack_range


func reset_melee_attack_cycle() -> void:
	melee_has_hit_in_cycle = false


func begin_melee_attack_cooldown() -> void:
	melee_attack_cooldown_left = melee_attack_cooldown


func try_apply_melee_hit() -> bool:
	if _is_vestige_ally_instance():
		return false
	if melee_has_hit_in_cycle:
		return false
	if not has_valid_target_player():
		return false

	var distance_to_player := global_position.distance_to(target_player.global_position)
	if distance_to_player > melee_attack_range:
		return false
	if not target_player.has_method("receive_hit"):
		return false

	target_player.call("receive_hit", melee_attack_damage, global_position)
	melee_has_hit_in_cycle = true
	return true


func try_apply_melee_ground_slam_hit() -> bool:
	if _is_vestige_ally_instance():
		return false
	if melee_has_hit_in_cycle:
		return false

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false

	var has_hit_target := false
	for player_variant in players:
		if not (player_variant is Node2D):
			continue

		var player := player_variant as Node2D
		if not is_instance_valid(player):
			continue
		if global_position.distance_to(player.global_position) > melee_aoe_radius:
			continue
		if not player.has_method("receive_hit"):
			continue

		player.call("receive_hit", melee_attack_damage, global_position)
		has_hit_target = true

	if has_hit_target:
		melee_has_hit_in_cycle = true

	return has_hit_target


func perform_melee_ground_slam() -> bool:
	_spawn_ground_slam_vfx()
	return try_apply_melee_ground_slam_hit()


func _spawn_ground_slam_vfx() -> void:
	var embedded_vfx := get_node_or_null("GroundSlamVfx")
	if embedded_vfx != null:
		if embedded_vfx.has_method("configure"):
			embedded_vfx.call(
				"configure",
				melee_aoe_radius,
				ground_slam_vfx_duration,
				ground_slam_vfx_color,
				ground_slam_vfx_thickness_px
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
	vfx.global_position = global_position

	if vfx.has_method("configure"):
		vfx.call(
			"configure",
			melee_aoe_radius,
			ground_slam_vfx_duration,
			ground_slam_vfx_color,
			ground_slam_vfx_thickness_px
		)

	host.add_child(vfx)


func apply_melee_lunge_motion(delta: float) -> void:
	if not has_valid_target_player():
		apply_idle_motion(delta)
		return

	var to_player := target_player.global_position - global_position
	if to_player.length_squared() <= 0.001:
		apply_idle_motion(delta)
		return

	var lunge_speed := maxf(move_speed, melee_lunge_px / maxf(melee_active_sec, 0.01))
	var desired_velocity := to_player.normalized() * lunge_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * 1.4 * delta)


func apply_idle_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)


func apply_chase_motion(delta: float) -> void:
	if not has_valid_target_player():
		apply_idle_motion(delta)
		return

	if active_role_id == ROLE_ARTILLERY:
		_apply_artillery_kiting_motion(delta)
		return

	var desired_velocity := (target_player.global_position - global_position).normalized() * move_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)


func _apply_artillery_kiting_motion(delta: float) -> void:
	if not has_valid_target_player():
		apply_idle_motion(delta)
		return

	var to_player: Vector2 = target_player.global_position - global_position
	var distance_to_player: float = to_player.length()
	if distance_to_player <= 0.001:
		apply_idle_motion(delta)
		return

	var direction_to_player: Vector2 = to_player / distance_to_player
	var desired_velocity := Vector2.ZERO

	if distance_to_player < artillery_min_range:
		desired_velocity = -direction_to_player * artillery_retreat_speed
	elif distance_to_player > artillery_preferred_range:
		desired_velocity = direction_to_player * move_speed
	else:
		if artillery_strafe_switch_left <= 0.0:
			artillery_strafe_sign *= -1.0
			artillery_strafe_switch_left = artillery_sidestep_interval

		var perpendicular := Vector2(-direction_to_player.y, direction_to_player.x) * artillery_strafe_sign
		desired_velocity = perpendicular * artillery_strafe_speed

	velocity = velocity.move_toward(desired_velocity, acceleration * delta)


func _try_fire_artillery_projectile() -> void:
	if _is_vestige_ally_instance():
		return
	if active_role_id != ROLE_ARTILLERY:
		return
	if current_state_name != STATE_CHASE:
		return
	if artillery_attack_cooldown_left > 0.0:
		return
	if not has_valid_target_player():
		return

	var to_player: Vector2 = target_player.global_position - global_position
	var distance_to_player: float = to_player.length()
	if distance_to_player <= 0.001:
		return
	if distance_to_player > artillery_max_range:
		return

	var fire_direction: Vector2 = to_player / distance_to_player
	_spawn_artillery_projectile(fire_direction)
	artillery_attack_cooldown_left = artillery_attack_cooldown


func _spawn_artillery_projectile(fire_direction: Vector2) -> void:
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	# Use bone projectile for skeleton artillery, generic projectile for others
	var projectile_scene = BONE_PROJECTILE_SCENE if species_id == SPECIES_SKELETON else ENEMY_PROJECTILE_SCENE
	_play_sfx(_resolve_attack_sfx())
	var projectile_variant: Variant = projectile_scene.instantiate()
	if not (projectile_variant is Area2D):
		return

	var projectile := projectile_variant as Area2D
	projectile.global_position = global_position + fire_direction * (artillery_projectile_radius + 8.0)
	host.add_child(projectile)

	if projectile.has_method("configure"):
		projectile.call(
			"configure",
			self,
			fire_direction,
			artillery_projectile_speed,
			artillery_projectile_lifetime,
			artillery_projectile_damage,
			artillery_projectile_radius
		)


func update_hit_stun_motion(delta: float) -> void:
	hit_stun_left = max(hit_stun_left - delta, 0.0)
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * 1.6 * delta)


func is_hit_stun_finished() -> bool:
	return hit_stun_left <= 0.0


func _is_vestige_ally_instance() -> bool:
	return has_meta("is_vestige_ally") and bool(get_meta("is_vestige_ally"))


func request_state(state_name: StringName) -> void:
	if state_machine == null:
		return
	state_machine.request_transition(state_name)


func set_visual_state(state_name: StringName) -> void:
	current_state_name = state_name
	_sync_visual_animation()


func is_dead_state() -> bool:
	return current_state_name == STATE_DEAD


func _sync_visual_animation() -> void:
	if body_visual == null:
		return
	if body_visual.sprite_frames == null:
		return

	var target_animation := ANIM_IDLE
	if current_state_name == STATE_CHASE:
		target_animation = ANIM_MOVE
	elif current_state_name == STATE_ATTACK:
		target_animation = ANIM_ATTACK

	if not body_visual.sprite_frames.has_animation(target_animation):
		if body_visual.sprite_frames.has_animation(ANIM_IDLE):
			target_animation = ANIM_IDLE
		elif body_visual.sprite_frames.has_animation(ANIM_MOVE):
			target_animation = ANIM_MOVE
		else:
			return

	if body_visual.animation != target_animation or not body_visual.is_playing():
		body_visual.play(target_animation)


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
		STATE_ATTACK:
			var attack_pulse := 0.5 + 0.5 * sin(visual_time * 14.0)
			target_scale = Vector2(1.08 + attack_pulse * 0.10, 0.92 - attack_pulse * 0.05)
		STATE_HIT_STUN:
			target_scale = Vector2(1.12, 0.88)
			target_modulate = Color.WHITE
		STATE_DEAD:
			target_scale = Vector2(0.75, 0.75)
			target_modulate = Color(1.0, 1.0, 1.0, 0.35)

	if hit_flash_left > 0.0 and current_state_name != STATE_DEAD:
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


func play_attack_sfx() -> void:
	_play_sfx(_resolve_attack_sfx())


func _ensure_sfx_player() -> void:
	if sfx_player == null:
		var created_player := AudioStreamPlayer2D.new()
		created_player.name = "SfxPlayer"
		created_player.max_polyphony = 2
		add_child(created_player)
		sfx_player = created_player

	sfx_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"


func _resolve_attack_sfx() -> AudioStream:
	if species_id == SPECIES_ORC:
		return SFX_ORC_ATTACK
	if species_id == SPECIES_SKELETON:
		return SFX_SKELETON_ATTACK
	return SFX_GOBLIN_ATTACK


func _resolve_death_sfx() -> AudioStream:
	if species_id == SPECIES_GOBLIN:
		return SFX_GOBLIN_DEATH
	return null


func _play_random_sfx(streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return

	var random_index := randi_range(0, streams.size() - 1)
	_play_sfx(streams[random_index])


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	if sfx_player == null:
		return

	sfx_player.stream = stream
	sfx_player.play()
