extends Node2D

signal shot_fired()
signal health_changed(current_hp: float, max_hp: float)
signal player_defeated()

@export var max_health: float = 500.0
@export var max_power: float = 880.0
@export var min_power: float = 260.0
@export var power_scale: float = 3.6

var current_health: float = 500.0
var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")
var muzzle_flash_tex: Texture2D = preload("res://assets/textures/muzzle_flash.png")

var is_aiming: bool = false
var can_aim: bool = true
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var aim_angle: float = -0.55 # ~30 degrees upward
var current_power: float = 0.0

@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var cannon_pivot: Node2D = $CannonPivot
@onready var barrel_sprite: Sprite2D = $CannonPivot/BarrelSprite
@onready var muzzle_flash: Sprite2D = $CannonPivot/MuzzleFlash

var base_pivot_x: float = 12.0
var flash_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	cannon_pivot.position = Vector2(base_pivot_x, -52)
	cannon_pivot.rotation = aim_angle
	muzzle_flash.visible = false

func _process(delta: float) -> void:
	# Smooth cannon recoil recovery
	if cannon_pivot.position.x < base_pivot_x:
		cannon_pivot.position.x = move_toward(cannon_pivot.position.x, base_pivot_x, delta * 45.0)
	
	# Muzzle flash fade
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not can_aim:
		return
		
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
			# Clamp aiming between -80 deg and 5 deg
			aim_angle = clamp(drag_vector.angle(), -1.4, 0.1)
			current_power = clamp(drag_vector.length() * power_scale, min_power, max_power)
			cannon_pivot.rotation = aim_angle
		queue_redraw()

func _draw() -> void:
	# Draw Trajectory Prediction Arc originating from the barrel muzzle
	if is_aiming and current_power > min_power:
		var muzzle_global = cannon_pivot.global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 52.0
		var muzzle_local = to_local(muzzle_global)
		_draw_trajectory(muzzle_local)

func _draw_trajectory(start_pos: Vector2) -> void:
	var gravity = Vector2(0, 980)
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	var time_step = 0.038
	
	var points_count = 22
	for i in range(points_count):
		var t = i * time_step
		var next_pos = start_pos + velocity * t + 0.5 * gravity * t * t
		var alpha = 1.0 - (float(i) / points_count) * 0.75
		var radius = lerp(4.5, 2.0, float(i) / points_count)
		draw_circle(next_pos, radius, Color(1.0, 0.85, 0.2, alpha))

func _fire_cannon() -> void:
	if current_power < min_power:
		return
	
	# Recoil animation
	cannon_pivot.position.x = base_pivot_x - 14.0
	
	# Show Muzzle Flash
	muzzle_flash.visible = true
	flash_timer = 0.12
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = cannon_pivot.global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 55.0
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	
	projectile.set("is_enemy_shot", false)
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	shot_fired.emit()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Damage flash
	chassis_sprite.modulate = Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(0.18).timeout
	chassis_sprite.modulate = Color(1.0, 1.0, 1.0)
	
	if current_health <= 0:
		player_defeated.emit()

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	chassis_sprite.modulate = Color(1.0, 1.0, 1.0)
	cannon_pivot.rotation = -0.55
