extends RigidBody2D

@export var damage: float = 35.0
var has_multiplied: bool = false
var is_child_swarm: bool = false
var is_enemy_shot: bool = false
var lifetime: float = 7.0

var explosion_scene: PackedScene = preload("res://prefabs/ExplosionEffect.tscn")
var popup_scene: PackedScene = preload("res://prefabs/DamagePopup.tscn")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	
	if is_child_swarm:
		scale = Vector2(0.85, 0.85)
		
	if is_enemy_shot:
		sprite.modulate = Color(1.0, 0.35, 0.6)
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	if linear_velocity.length_squared() > 10.0:
		rotation = linear_velocity.angle()

func _on_body_entered(body: Node) -> void:
	_spawn_impact_fx()
	
	var can_damage: bool = false
	if is_enemy_shot and body.name == "PlayerCastle":
		can_damage = true
	elif not is_enemy_shot and (body.name == "EnemyCastle" or body.has_method("take_damage")):
		can_damage = true
		
	if can_damage and body.has_method("take_damage"):
		var is_crit: bool = randf() < 0.25
		var actual_dmg: float = damage * (1.5 if is_crit else 1.0)
		body.take_damage(actual_dmg)
		_spawn_damage_popup(actual_dmg, is_crit)
		queue_free()
	elif body is StaticBody2D:
		await get_tree().create_timer(0.35).timeout
		queue_free()

func _spawn_impact_fx() -> void:
	var explosion = explosion_scene.instantiate()
	get_parent().call_deferred("add_child", explosion)
	explosion.set_deferred("global_position", global_position)
	
	var main = get_tree().current_scene
	if main:
		if main.has_method("trigger_shake"):
			main.trigger_shake(3.5 if is_child_swarm else 7.5)
		if main.has_method("play_sound"):
			main.play_sound("explosion")

func _spawn_damage_popup(amount: float, is_crit: bool) -> void:
	var popup = popup_scene.instantiate()
	get_parent().call_deferred("add_child", popup)
	popup.set_deferred("global_position", global_position + Vector2(randf_range(-15, 15), -20))
	popup.call_deferred("setup", amount, is_crit)
