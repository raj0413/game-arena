extends Area2D

@export var multiplier_factor: int = 20
@export var float_speed: float = 2.2
@export var float_amplitude: float = 16.0

var projectile_scene: PackedScene = preload("res://prefabs/Cannonball.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var initial_pos_y: float = 0.0
var time_elapsed: float = 0.0
var target_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	initial_pos_y = position.y
	body_entered.connect(_on_body_entered)
	label.text = "x" + str(multiplier_factor)

func _process(delta: float) -> void:
	time_elapsed += delta
	position.y = initial_pos_y + sin(time_elapsed * float_speed) * float_amplitude
	sprite.rotation = sin(time_elapsed * 1.5) * 0.04
	scale = scale.lerp(target_scale, delta * 4.0)

func _on_body_entered(body: Node2D) -> void:
	if "has_multiplied" in body and not body.has_multiplied:
		body.has_multiplied = true
		scale = Vector2(1.35, 1.35)
		
		# Play chime sound via Main
		var main = get_tree().current_scene
		if main and main.has_method("play_sound"):
			main.play_sound("gate")
			
		_multiply_projectiles(body)

func _multiply_projectiles(source: Node2D) -> void:
	var original_velocity: Vector2 = source.linear_velocity if "linear_velocity" in source else Vector2(400, -200)
	var spawn_pos: Vector2 = source.global_position
	var base_damage: float = source.damage if "damage" in source else 30.0
	var is_enemy: bool = source.get("is_enemy_shot") == true
	
	for i in range(multiplier_factor - 1):
		var child = projectile_scene.instantiate()
		child.set("is_child_swarm", true)
		child.set("has_multiplied", true)
		child.set("is_enemy_shot", is_enemy)
		child.set("damage", base_damage * 0.85)
		
		var angle_offset = deg_to_rad(randf_range(-14.0, 14.0))
		var speed_scale = randf_range(0.92, 1.08)
		var spread_velocity = original_velocity.rotated(angle_offset) * speed_scale
		
		get_parent().call_deferred("add_child", child)
		child.set_deferred("global_position", spawn_pos + Vector2(randf_range(-12, 12), randf_range(-16, 16)))
		child.set_deferred("linear_velocity", spread_velocity)
