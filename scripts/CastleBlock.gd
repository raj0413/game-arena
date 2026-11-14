extends RigidBody2D

signal block_damaged(amount: float)
signal block_destroyed(block: Node)

@export var max_health: float = 75.0

@onready var sprite: Sprite2D = $Sprite2D

var current_health: float
var flash_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	mass = 3.5
	var mat = PhysicsMaterial.new()
	mat.friction = 0.85
	physics_material_override = mat

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			var health_ratio = current_health / max_health
			sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.45, 0.35, 0.35), 1.0 - health_ratio)

func take_damage(amount: float) -> void:
	current_health -= amount
	flash_timer = 0.18
	sprite.modulate = Color(1.0, 0.25, 0.25) # Flash bright red on impact
	block_damaged.emit(amount)
	
	if current_health <= 0:
		block_destroyed.emit(self)
		queue_free()
