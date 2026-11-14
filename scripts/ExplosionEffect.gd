extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var lifetime: float = 0.35
var time_alive: float = 0.0

func _ready() -> void:
	scale = Vector2(0.4, 0.4)
	rotation = randf_range(0, TAU)

func _process(delta: float) -> void:
	time_alive += delta
	var progress = time_alive / lifetime
	
	scale = Vector2.ONE * lerp(0.4, 1.4, progress)
	modulate.a = lerp(1.0, 0.0, progress)
	
	if time_alive >= lifetime:
		queue_free()
