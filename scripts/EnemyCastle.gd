extends Node2D

signal health_changed(current_hp: float, max_hp: float)
signal castle_destroyed()
signal ai_shot_fired()

@export var max_health: float = 600.0
var current_health: float = 600.0

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")
var broken_arm_scene: PackedScene = preload("res://prefabs/BrokenArmDebris.tscn")

@onready var mech_sprite: Sprite2D = $MechSprite
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var spark_particles: CPUParticles2D = $SparkParticles

var base_pos_y: float = 0.0
var flash_timer: float = 0.0

var arm_broken: bool = false
var leg_crippled: bool = false

func _ready() -> void:
	current_health = max_health
	base_pos_y = position.y
	muzzle_flash.visible = false
	spark_particles.emitting = false
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

func execute_ai_turn(gate_pos: Vector2, player_pos: Vector2) -> void:
	await get_tree().create_timer(0.6).timeout
	
	muzzle_flash.visible = true
	flash_timer = 0.15
	
	var projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + Vector2(-65, -55)
	
	# Aim curve through the x5 gate towards player
	var target = gate_pos + Vector2(randf_range(-12, 12), randf_range(-10, 10))
	var aim_dir = (target - spawn_pos).normalized()
	aim_dir.y -= 0.28
	aim_dir = aim_dir.normalized()
	
	var power = randf_range(680.0, 750.0)
	var velocity = aim_dir * power
	
	projectile.set("is_enemy_shot", true)
	projectile.add_collision_exception_with(self) # PREVENT SELF COLLISION
	
	get_parent().add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.linear_velocity = velocity
	
	ai_shot_fired.emit()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	mech_sprite.modulate = Color(1.0, 0.25, 0.25)
	await get_tree().create_timer(0.18).timeout
	mech_sprite.modulate = Color(1.0, 1.0, 1.0)
	
	# Dismemberment
	if current_health <= max_health * 0.7 and not arm_broken:
		arm_broken = true
		_dismember_arm()
		
	if current_health <= max_health * 0.4 and not leg_crippled:
		leg_crippled = true
		_cripple_leg()
		
	if current_health <= 0:
		castle_destroyed.emit()

func _dismember_arm() -> void:
	spark_particles.emitting = true
	var debris = broken_arm_scene.instantiate()
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector2(20, -50)
	debris.linear_velocity = Vector2(180, -260)
	debris.angular_velocity = 12.0
	
	var main = get_tree().current_scene
	if main and main.has_method("trigger_shake"):
		main.trigger_shake(8.0)

func _cripple_leg() -> void:
	# Enemy mech drops to one knee and tilts backward!
	var tween = create_tween()
	tween.tween_property(self, "position:y", base_pos_y + 16.0, 0.4).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(mech_sprite, "rotation_degrees", -12.0, 0.4)

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	arm_broken = false
	leg_crippled = false
	spark_particles.emitting = false
	position.y = base_pos_y
	mech_sprite.rotation_degrees = 0.0
	mech_sprite.modulate = Color(1.0, 1.0, 1.0)
