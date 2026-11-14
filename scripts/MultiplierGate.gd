extends Area2D

@export var multiplier_factor: int = 15
@export var gate_color: Color = Color(1.0, 0.85, 0.2, 0.9)
@export var float_speed: float = 2.0
@export var float_amplitude: float = 15.0

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")
var initial_pos_y: float = 0.0
var time_elapsed: float = 0.0
var pulse_scale: float = 1.0

func _ready() -> void:
	initial_pos_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_elapsed += delta
	# Floating gently in the sky
	position.y = initial_pos_y + sin(time_elapsed * float_speed) * float_amplitude
	
	if pulse_scale > 1.0:
		pulse_scale = move_toward(pulse_scale, 1.0, delta * 3.0)
	
	queue_redraw()

func _draw() -> void:
	var width: float = 24.0 * pulse_scale
	var height: float = 120.0 * pulse_scale
	var rect = Rect2(-width * 0.5, -height * 0.5, width, height)
	
	# Outer glow
	draw_rect(rect.grow(8.0), Color(gate_color.r, gate_color.g, gate_color.b, 0.25), false, 4.0)
	# Inner glowing barrier
	draw_rect(rect, Color(gate_color.r, gate_color.g, gate_color.b, 0.35), true)
	draw_rect(rect, gate_color, false, 3.0)
	
	# Display Multiplier text
	var text: String = "x" + str(multiplier_factor)
	var font = ThemeDB.fallback_font
	var font_size = int(28 * pulse_scale)
	draw_string(font, Vector2(-22, 10), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if "has_multiplied" in body and not body.has_multiplied:
		body.has_multiplied = true
		pulse_scale = 1.4
		_multiply_projectiles(body)

func _multiply_projectiles(source: Node2D) -> void:
	var original_velocity: Vector2 = source.linear_velocity if "linear_velocity" in source else Vector2(400, -200)
	var spawn_pos: Vector2 = source.global_position
	var base_damage: float = source.damage if "damage" in source else 30.0
	
	# Spawn multiplied swarm projectiles
	for i in range(multiplier_factor - 1):
		var child = projectile_scene.instantiate()
		child.set("is_child_swarm", true)
		child.set("has_multiplied", true)
		child.set("damage", base_damage * 0.8)
		
		# Slight spread in angle and velocity for natural swarm feel
		var angle_offset = deg_to_rad(randf_range(-14.0, 14.0))
		var speed_scale = randf_range(0.92, 1.08)
		var spread_velocity = original_velocity.rotated(angle_offset) * speed_scale
		
		# Add to scene
		get_parent().call_deferred("add_child", child)
		child.set_deferred("global_position", spawn_pos + Vector2(randf_range(-8, 8), randf_range(-12, 12)))
		child.set_deferred("linear_velocity", spread_velocity)
