extends Node2D

signal shot_fired()
signal health_changed(current_hp: float, max_hp: float)
signal player_defeated()

@export var max_health: float = 500.0
@export var max_power: float = 880.0
@export var min_power: float = 280.0
@export var power_scale: float = 3.6

var current_health: float = 500.0
var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")
var broken_arm_scene: PackedScene = preload("res://prefabs/BrokenArmDebris.tscn")

var is_aiming: bool = false
var can_aim: bool = true
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var aim_angle: float = -0.55
var current_power: float = 0.0

@onready var mech_sprite: Sprite2D = $MechSprite
@onready var cannon_pivot: Node2D = $CannonPivot
@onready var muzzle_flash: Sprite2D = $CannonPivot/MuzzleFlash
@onready var spark_particles: CPUParticles2D = $SparkParticles

var base_pos_y: float = 0.0
var flash_timer: float = 0.0

# Dismemberment flags
var arm_broken: bool = false
var leg_crippled: bool = false

func _ready() -> void:
	current_health = max_health
	base_pos_y = position.y
	cannon_pivot.position = Vector2(25, -60)
	cannon_pivot.rotation = aim_angle
	muzzle_flash.visible = false
	spark_particles.emitting = false

func _process(delta: float) -> void:
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
			aim_angle = clamp(drag_vector.angle(), -1.45, 0.05)
			current_power = clamp(drag_vector.length() * power_scale, min_power, max_power)
			cannon_pivot.rotation = aim_angle
		queue_redraw()

func _draw() -> void:
	if is_aiming and current_power > min_power:
		var muzzle_global = cannon_pivot.global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 60.0
		var muzzle_local = to_local(muzzle_global)
		_draw_trajectory(muzzle_local)

func _draw_trajectory(start_pos: Vector2) -> void:
	var gravity = Vector2(0, 980)
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	var time_step = 0.038
	
	var points_count = 24
	for i in range(points_count):
		var t = i * time_step
		var next_pos = start_pos + velocity * t + 0.5 * gravity * t * t
		var alpha = 1.0 - (float(i) / points_count) * 0.75
		var radius = lerp(5.0, 2.0, float(i) / points_count)
		draw_circle(next_pos, radius, Color(0.3, 0.9, 1.0, alpha)) # Cyan laser arc

func _fire_cannon() -> void:
	if current_power < min_power:
		return
	
	muzzle_flash.visible = true
	flash_timer = 0.12
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = cannon_pivot.global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 65.0
	var velocity = Vector2(cos(aim_angle), sin(aim_angle)) * current_power
	
	projectile.set("is_enemy_shot", false)
	projectile.add_collision_exception_with(self) # PREVENT SELF COLLISION
	
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	shot_fired.emit()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Damage flash
	mech_sprite.modulate = Color(1.0, 0.25, 0.25)
	await get_tree().create_timer(0.18).timeout
	mech_sprite.modulate = Color(1.0, 1.0, 1.0)
	
	# Check Dismemberment:
	# 1. Break Arm if HP <= 70%
	if current_health <= max_health * 0.7 and not arm_broken:
		arm_broken = true
		_dismember_arm()
		
	# 2. Break Leg / Limp if HP <= 40%
	if current_health <= max_health * 0.4 and not leg_crippled:
		leg_crippled = true
		_cripple_leg()
		
	if current_health <= 0:
		player_defeated.emit()

func _dismember_arm() -> void:
	spark_particles.emitting = true
	var debris = broken_arm_scene.instantiate()
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector2(-20, -50)
	debris.linear_velocity = Vector2(-180, -260)
	debris.angular_velocity = -12.0
	
	var main = get_tree().current_scene
	if main and main.has_method("trigger_shake"):
		main.trigger_shake(8.0)

func _cripple_leg() -> void:
	# Robot drops to one knee and limps with forward tilt!
	var tween = create_tween()
	tween.tween_property(self, "position:y", base_pos_y + 16.0, 0.4).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(mech_sprite, "rotation_degrees", 12.0, 0.4)

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	arm_broken = false
	leg_crippled = false
	spark_particles.emitting = false
	position.y = base_pos_y
	mech_sprite.rotation_degrees = 0.0
	mech_sprite.modulate = Color(1.0, 1.0, 1.0)
	cannon_pivot.rotation = -0.55
