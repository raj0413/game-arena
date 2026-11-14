extends RigidBody2D

@export var damage: float = 35.0
var has_multiplied: bool = false
var is_child_swarm: bool = false
var lifetime: float = 7.0

var trail_positions: Array[Vector2] = []
var max_trail_length: int = 8

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	
	# Self cleanup after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	# Keep track of recent positions for fiery smoke trail
	trail_positions.push_front(global_position)
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_back()
	queue_redraw()

func _draw() -> void:
	# Draw projectile core
	var radius: float = 6.0 if is_child_swarm else 8.5
	var outer_color: Color = Color(1.0, 0.45, 0.1, 0.9) if not is_child_swarm else Color(1.0, 0.75, 0.2, 0.9)
	var inner_color: Color = Color(1.0, 0.95, 0.6, 1.0)
	
	# Outer fiery glow
	draw_circle(Vector2.ZERO, radius + 2.0, Color(1.0, 0.3, 0.0, 0.4))
	# Main body
	draw_circle(Vector2.ZERO, radius, outer_color)
	# Glowing core
	draw_circle(Vector2.ZERO, radius * 0.5, inner_color)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		# Hit the ground
		await get_tree().create_timer(1.2).timeout
		queue_free()
