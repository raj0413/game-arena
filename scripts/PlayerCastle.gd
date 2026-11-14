extends Node2D

signal shot_fired()

@export var max_power: float = 880.0
@export var min_power: float = 260.0
@export var power_scale: float = 3.6

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")
var tank_texture: Texture2D = preload("res://assets/textures/player_tank.png")

var is_aiming: bool = false
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var aim_angle: float = -0.55 # Radians (~30 degrees up)
var current_power: float = 0.0

var barrel_origin: Vector2 = Vector2(40, -50)
var barrel_length: float = 40.0
var base_position_x: float = 0.0

func _ready() -> void:
	base_position_x = position.x

func _process(delta: float) -> void:
	# Recoil recovery
	if position.x < base_position_x:
		position.x = move_toward(position.x, base_position_x, delta * 35.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.position.x < 650:
					is_aiming = true
					drag_start = event.position
					current_drag = event.position
			else:
				if is_aiming:
					is_aiming = false
					_fire_cannon()
					queue_redraw()
	
	elif event is InputEventMouseMotion and is_aiming:
		current_drag = event.position
		var drag_vector = drag_start - current_drag
		if drag_vector.length() > 10.0:
			aim_angle = drag_vector.angle()
			current_power = clamp(drag_vector.length() * power_scale, min_power, max_power)
		queue_redraw()

func _draw() -> void:
	# 1. Draw Player Castle Tank HD Sprite
	if tank_texture:
		var tex_size = tank_texture.get_size()
		# Draw centered horizontally, sitting on ground
		draw_texture(tank_texture, Vector2(-tex_size.x * 0.5, -tex_size.y + 10))
	
	# 2. Draw Cannon Barrel with Recoil
	var barrel_end = barrel_origin + Vector2(cos(aim_angle), sin(aim_angle)) * barrel_length
	draw_line(barrel_origin, barrel_end, Color(0.2, 0.2, 0.24), 10.0)
	draw_circle(barrel_origin, 8.0, Color(0.3, 0.3, 0.35))
	
	# 3. Draw Trajectory Prediction Arc when aiming
	if is_aiming and current_power > min_power:
		_draw_trajectory(barrel_end)

func _draw_trajectory(start_pos: Vector2) -> void:
	var gravity = Vector2(0, 980)
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	var time_step = 0.038
	
	var points_count = 24
	for i in range(points_count):
		var t = i * time_step
		var next_pos = start_pos + velocity * t + 0.5 * gravity * t * t
		var alpha = 1.0 - (float(i) / points_count) * 0.8
		var radius = lerp(4.5, 2.0, float(i) / points_count)
		draw_circle(next_pos, radius, Color(1.0, 0.85, 0.2, alpha))

func _fire_cannon() -> void:
	if current_power < min_power:
		return
	
	# Visual Recoil
	position.x -= 12.0
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + barrel_origin + Vector2(cos(aim_angle), sin(aim_angle)) * (barrel_length + 8.0)
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	shot_fired.emit()
