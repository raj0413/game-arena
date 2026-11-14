extends RigidBody2D

signal block_damaged(amount: float)
signal block_destroyed(block: Node)

@export var max_health: float = 70.0
@export var block_size: Vector2 = Vector2(64, 32)
@export var block_color: Color = Color(0.48, 0.48, 0.52) # Stone grey

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
		queue_redraw()

func _draw() -> void:
	var rect = Rect2(-block_size * 0.5, block_size)
	var fill_color = block_color
	
	# Damage tint
	var health_ratio = current_health / max_health
	if flash_timer > 0.0:
		fill_color = Color(1.0, 0.3, 0.3) # Flash red
	else:
		fill_color = block_color.lerp(Color(0.3, 0.2, 0.2), 1.0 - health_ratio)
	
	# Draw main brick
	draw_rect(rect, fill_color, true)
	# Draw border / bevel
	draw_rect(rect, Color(0.25, 0.25, 0.28), false, 2.0)
	
	# Draw internal brick mortar line
	draw_line(Vector2(-block_size.x * 0.5, 0), Vector2(block_size.x * 0.5, 0), Color(0.3, 0.3, 0.35), 1.5)
	draw_line(Vector2(0, -block_size.y * 0.5), Vector2(0, 0), Color(0.3, 0.3, 0.35), 1.5)

func take_damage(amount: float) -> void:
	current_health -= amount
	flash_timer = 0.15
	block_damaged.emit(amount)
	queue_redraw()
	
	if current_health <= 0:
		block_destroyed.emit(self)
		queue_free()
