extends Node2D

signal shot_fired()

@export var max_power: float = 850.0
@export var min_power: float = 250.0
@export var power_scale: float = 3.5

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")

var is_aiming: bool = false
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var aim_angle: float = -0.55 # Radians (~30 degrees up)
var current_power: float = 0.0

var barrel_length: float = 45.0
var barrel_origin: Vector2 = Vector2(10, -35)

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start aim if clicked in left side of screen
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
	# 1. Draw Castle Tank Base & Treads
	# Treads
	draw_rect(Rect2(-45, -8, 90, 16), Color(0.2, 0.2, 0.22), true)
	# Wheels inside treads
	for wx in [-30, -10, 10, 30]:
		draw_circle(Vector2(wx, 0), 6.0, Color(0.4, 0.4, 0.45))
	
	# Castle stone body
	draw_rect(Rect2(-38, -48, 76, 40), Color(0.45, 0.45, 0.5), true)
	draw_rect(Rect2(-38, -48, 76, 40), Color(0.25, 0.25, 0.3), false, 2.5)
	
	# Parapet crenels on top
	draw_rect(Rect2(-38, -58, 18, 10), Color(0.4, 0.4, 0.45), true)
	draw_rect(Rect2(20, -58, 18, 10), Color(0.4, 0.4, 0.45), true)
	
	# 2. Draw Cannon Barrel
	var barrel_end = barrel_origin + Vector2(cos(aim_angle), sin(aim_angle)) * barrel_length
	draw_line(barrel_origin, barrel_end, Color(0.18, 0.18, 0.22), 12.0)
	draw_circle(barrel_origin, 10.0, Color(0.3, 0.3, 0.35))
	
	# 3. Draw Trajectory Prediction Arc when aiming
	if is_aiming and current_power > min_power:
		_draw_trajectory(barrel_end)

func _draw_trajectory(start_pos: Vector2) -> void:
	var gravity = Vector2(0, 980) # Project gravity
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	var time_step = 0.04
	
	var points_count = 22
	for i in range(points_count):
		var t = i * time_step
		var next_pos = start_pos + velocity * t + 0.5 * gravity * t * t
		var alpha = 1.0 - (float(i) / points_count) * 0.85
		draw_circle(next_pos, 3.5, Color(1.0, 0.85, 0.2, alpha))

func _fire_cannon() -> void:
	if current_power < min_power:
		return
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + barrel_origin + Vector2(cos(aim_angle), sin(aim_angle)) * (barrel_length + 8.0)
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	shot_fired.emit()
