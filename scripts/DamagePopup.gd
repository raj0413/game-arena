extends Node2D

@onready var label: Label = $Label

var velocity: Vector2 = Vector2(0, -60)
var lifetime: float = 0.8
var time_alive: float = 0.0

func setup(amount: float, is_crit: bool = false) -> void:
	if is_crit:
		label.text = "CRIT! -%d" % int(amount)
		label.modulate = Color(1.0, 0.2, 0.2)
		scale = Vector2(1.3, 1.3)
	else:
		label.text = "-%d" % int(amount)
		label.modulate = Color(1.0, 0.85, 0.2)

func _process(delta: float) -> void:
	time_alive += delta
	position += velocity * delta
	velocity.y *= 0.95 # Slow down
	
	var alpha = 1.0 - (time_alive / lifetime)
	modulate.a = max(0.0, alpha)
	
	if time_alive >= lifetime:
		queue_free()
