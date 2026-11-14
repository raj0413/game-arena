extends Node2D

signal health_changed(current_hp: float, max_hp: float)
signal castle_destroyed()
signal ai_shot_fired()

@export var max_health: float = 550.0
var current_health: float = 550.0

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")

@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var cannon_pivot: Node2D = $CannonPivot
@onready var barrel_sprite: Sprite2D = $CannonPivot/BarrelSprite
@onready var muzzle_flash: Sprite2D = $CannonPivot/MuzzleFlash

var base_pivot_x: float = -15.0
var flash_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	cannon_pivot.position = Vector2(base_pivot_x, -45)
	cannon_pivot.rotation = -2.6 # ~30 deg up facing left
	muzzle_flash.visible = false
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	# Recoil recovery
	if cannon_pivot.position.x > base_pivot_x:
		cannon_pivot.position.x = move_toward(cannon_pivot.position.x, base_pivot_x, delta * 45.0)
		
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

func execute_ai_turn(gate_pos: Vector2, player_pos: Vector2) -> void:
	# Calculate aim angle towards the multiplier gate with slight random variation
	var target_spot = gate_pos + Vector2(randf_range(-15, 15), randf_range(-20, 20))
	var aim_dir = (target_spot - cannon_pivot.global_position).normalized()
	var target_angle = clamp(aim_dir.angle(), -2.9, -1.8)
	
	# Smoothly rotate cannon barrel over 1.0s to simulate AI aiming
	var tween = create_tween()
	tween.tween_property(cannon_pivot, "rotation", target_angle, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Pause 0.3s before firing
	await get_tree().create_timer(0.3).timeout
	_fire_ai_cannon(target_angle)

func _fire_ai_cannon(angle: float) -> void:
	cannon_pivot.position.x = base_pivot_x + 14.0 # Recoil backward
	muzzle_flash.visible = true
	flash_timer = 0.14
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = cannon_pivot.global_position + Vector2(cos(angle), sin(angle)) * 55.0
	var power = randf_range(680.0, 780.0)
	var velocity = Vector2(cos(angle), sin(angle)) * power
	
	projectile.set("is_enemy_shot", true)
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	ai_shot_fired.emit()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	chassis_sprite.modulate = Color(1.0, 0.25, 0.25)
	await get_tree().create_timer(0.18).timeout
	chassis_sprite.modulate = Color(1.0, 1.0, 1.0)
	
	if current_health <= 0:
		castle_destroyed.emit()

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	chassis_sprite.modulate = Color(1.0, 1.0, 1.0)
	cannon_pivot.rotation = -2.6
