extends Node2D

signal health_changed(current_hp: float, max_hp: float)
signal castle_destroyed()
signal ai_shot_fired()

@export var max_health: float = 600.0
var current_health: float = 600.0

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")

@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var muzzle_flash: Sprite2D = $MuzzleFlash

var base_pos_x: float = 0.0
var flash_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	base_pos_x = position.x
	muzzle_flash.visible = false
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	# Recoil recovery
	if position.x > base_pos_x:
		position.x = move_toward(position.x, base_pos_x, delta * 35.0)
		
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

func execute_ai_turn(gate_pos: Vector2, player_pos: Vector2) -> void:
	# AI targeting towards the multiplier gate
	await get_tree().create_timer(0.6).timeout
	
	# Recoil kick backward (to the right)
	position.x = base_pos_x + 14.0
	muzzle_flash.visible = true
	flash_timer = 0.15
	
	var projectile = projectile_scene.instantiate()
	# Muzzle tip position on the enemy boss tank
	var spawn_pos = global_position + Vector2(-80, -58)
	
	# Aim vector through the floating multiplier gate
	var target = gate_pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	var aim_dir = (target - spawn_pos).normalized()
	# Give it a nice upward parabolic arc
	aim_dir.y -= 0.28
	aim_dir = aim_dir.normalized()
	
	var power = randf_range(680.0, 760.0)
	var velocity = aim_dir * power
	
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
	position.x = base_pos_x
