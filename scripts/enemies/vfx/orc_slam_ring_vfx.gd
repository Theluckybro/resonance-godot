extends Node2D
class_name OrcSlamRingVfx

var duration_sec: float = 0.22
var max_radius: float = 18.0
var ring_color: Color = Color(1.0, 0.64, 0.32, 0.95)
var thickness_px: float = 2.4

var debris_color: Color = Color(0.42, 0.31, 0.20, 0.92)
var dust_color: Color = Color(0.60, 0.49, 0.34, 0.35)

var _elapsed_sec: float = 0.0
var _cleanup_sec: float = 0.0
var _is_embedded_mode: bool = false
var _is_playing: bool = false

var _ring_particles: GPUParticles2D
var _dust_particles: GPUParticles2D
var _debris_particles: GPUParticles2D


func configure(radius: float, lifetime: float, color: Color, thickness: float) -> void:
	max_radius = maxf(radius, 1.0)
	duration_sec = maxf(lifetime, 0.03)
	ring_color = color
	thickness_px = maxf(thickness, 0.5)
	_cleanup_sec = duration_sec + 0.28
	_configure_particles()


func play_once() -> void:
	_elapsed_sec = 0.0
	_is_playing = true
	_emit_once()
	queue_redraw()
	set_process(true)


func _ready() -> void:
	_ring_particles = get_node_or_null("RingParticles") as GPUParticles2D
	_dust_particles = get_node_or_null("DustParticles") as GPUParticles2D
	_debris_particles = get_node_or_null("DebrisParticles") as GPUParticles2D
	_is_embedded_mode = _ring_particles != null and _dust_particles != null and _debris_particles != null

	if _ring_particles == null:
		_ring_particles = _create_particles_node("RingParticles")
		add_child(_ring_particles)
	if _dust_particles == null:
		_dust_particles = _create_particles_node("DustParticles")
		add_child(_dust_particles)
	if _debris_particles == null:
		_debris_particles = _create_particles_node("DebrisParticles")
		add_child(_debris_particles)

	_configure_particles()

	if _is_embedded_mode:
		set_process(false)
	else:
		# Runtime fallback mode: temporary node that cleans itself up.
		top_level = true
		z_index = 40
		_is_playing = true
		_emit_once()
		queue_redraw()
		set_process(true)


func _process(delta: float) -> void:
	_elapsed_sec += delta
	queue_redraw()
	if _elapsed_sec >= _cleanup_sec:
		_is_playing = false
		queue_redraw()
		if _is_embedded_mode:
			_stop_emission()
			set_process(false)
		else:
			queue_free()


func _draw() -> void:
	if not _is_playing:
		return

	var normalized_t := clampf(_elapsed_sec / maxf(duration_sec, 0.001), 0.0, 1.0)
	var fade := 1.0 - normalized_t
	var pulse_radius := max_radius * lerpf(0.9, 1.02, normalized_t)
	var outline_width := maxf(thickness_px * 2.2, 2.0)

	var fill_color := ring_color
	fill_color.a *= 0.14 * fade

	var outer_color := ring_color
	outer_color.a *= 0.95 * fade

	var inner_color := ring_color
	inner_color.a *= 0.45 * fade

	draw_circle(Vector2.ZERO, pulse_radius, fill_color)
	draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 96, outer_color, outline_width, true)
	draw_arc(Vector2.ZERO, maxf(pulse_radius - outline_width * 0.85, 0.5), 0.0, TAU, 96, inner_color, maxf(outline_width * 0.5, 1.0), true)


func _create_particles_node(node_name: String) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = node_name
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	return particles


func _emit_once() -> void:
	if _ring_particles:
		_ring_particles.restart()
		_ring_particles.emitting = true
	if _dust_particles:
		_dust_particles.restart()
		_dust_particles.emitting = true
	if _debris_particles:
		_debris_particles.restart()
		_debris_particles.emitting = true


func _stop_emission() -> void:
	if _ring_particles:
		_ring_particles.emitting = false
	if _dust_particles:
		_dust_particles.emitting = false
	if _debris_particles:
		_debris_particles.emitting = false


func _configure_particles() -> void:
	if _ring_particles == null or _dust_particles == null or _debris_particles == null:
		return

	_configure_ring_particles()
	_configure_dust_particles()
	_configure_debris_particles()


func _configure_ring_particles() -> void:
	var ring := _ring_particles
	var mat := ParticleProcessMaterial.new()

	var ring_count := int(clampf(round(max_radius * 1.6), 20.0, 96.0))
	ring.amount = ring_count
	ring.lifetime = maxf(duration_sec * 0.72, 0.03)
	ring.preprocess = 0.0
	ring.speed_scale = 1.0

	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = maxf(max_radius * 0.05, 0.8)
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 180.0
	mat.flatness = 1.0
	mat.initial_velocity_min = maxf(max_radius * 2.8, 8.0)
	mat.initial_velocity_max = maxf(max_radius * 4.2, 12.0)
	mat.scale_min = maxf(thickness_px * 0.12, 0.18)
	mat.scale_max = maxf(thickness_px * 0.22, 0.28)
	mat.damping_min = 10.0
	mat.damping_max = 16.0
	mat.gravity = Vector3.ZERO

	var ring_gradient := Gradient.new()
	var start_color := ring_color
	start_color.a = ring_color.a
	var end_color := ring_color
	end_color.a = 0.0
	ring_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	ring_gradient.colors = PackedColorArray([start_color, end_color])
	var ring_ramp := GradientTexture1D.new()
	ring_ramp.gradient = ring_gradient
	mat.color_ramp = ring_ramp

	ring.process_material = mat


func _configure_dust_particles() -> void:
	var dust := _dust_particles
	var mat := ParticleProcessMaterial.new()

	var dust_count := int(clampf(round(max_radius * 1.2), 14.0, 80.0))
	dust.amount = dust_count
	dust.lifetime = maxf(duration_sec * 1.1, 0.05)
	dust.preprocess = 0.0
	dust.speed_scale = 1.0

	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = maxf(max_radius * 0.2, 1.0)
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 180.0
	mat.flatness = 1.0
	mat.initial_velocity_min = maxf(max_radius * 0.95, 4.0)
	mat.initial_velocity_max = maxf(max_radius * 1.85, 7.0)
	mat.scale_min = 2
	mat.scale_max = 4
	mat.damping_min = 2.2
	mat.damping_max = 4.0
	mat.gravity = Vector3(0.0, 35.0, 0.0)

	var dust_gradient := Gradient.new()
	var dust_start := dust_color
	dust_start.a *= 1.05
	var dust_end := dust_color
	dust_end.a = 0.0
	dust_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	dust_gradient.colors = PackedColorArray([dust_start, dust_end])
	var dust_ramp := GradientTexture1D.new()
	dust_ramp.gradient = dust_gradient
	mat.color_ramp = dust_ramp

	dust.process_material = mat


func _configure_debris_particles() -> void:
	var debris := _debris_particles
	var mat := ParticleProcessMaterial.new()

	var debris_count := int(clampf(round(max_radius * 0.95), 8.0, 44.0))
	debris.amount = debris_count
	debris.lifetime = maxf(duration_sec * 0.96, 0.05)
	debris.preprocess = 0.0
	debris.speed_scale = 1.0

	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = maxf(max_radius * 0.18, 1.0)
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 180.0
	mat.flatness = 1.0
	mat.initial_velocity_min = maxf(max_radius * 2.1, 8.0)
	mat.initial_velocity_max = maxf(max_radius * 4.0, 12.0)
	mat.scale_min = 1
	mat.scale_max = 2
	mat.damping_min = 5.0
	mat.damping_max = 9.0
	mat.gravity = Vector3(0.0, 90.0, 0.0)

	var debris_gradient := Gradient.new()
	var debris_start := debris_color
	var debris_end := debris_color
	debris_end.a = 0.0
	debris_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	debris_gradient.colors = PackedColorArray([debris_start, debris_end])
	var debris_ramp := GradientTexture1D.new()
	debris_ramp.gradient = debris_gradient
	mat.color_ramp = debris_ramp

	debris.process_material = mat
