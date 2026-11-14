extends RigidBody2D

func _ready() -> void:
	# Lifetime cleanup
	get_tree().create_timer(6.0).timeout.connect(queue_free)
