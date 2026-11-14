extends Node2D

signal health_changed(current_hp: float, max_hp: float)
signal castle_destroyed()

@export var max_health: float = 560.0
var current_health: float

var block_scene: PackedScene = preload("res://prefabs/CastleBlock.tscn")
var active_blocks: Array[Node] = []

func _ready() -> void:
	current_health = max_health
	_build_castle()

func _build_castle() -> void:
	# Clear any previous children
	for child in get_children():
		child.queue_free()
	active_blocks.clear()
	
	# Layout: 4 layers of stone blocks
	# Layer 0 (Base): 2 blocks
	# Layer 1: 2 blocks
	# Layer 2: 2 blocks
	# Layer 3 (Rooftop crenels): 2 blocks
	var block_w: float = 64.0
	var block_h: float = 32.0
	
	for row in range(4):
		for col in [-0.5, 0.5]:
			var block = block_scene.instantiate()
			block.position = Vector2(col * (block_w + 2.0), -row * (block_h + 2.0) - (block_h * 0.5))
			block.connect("block_damaged", _on_block_damaged)
			block.connect("block_destroyed", _on_block_destroyed)
			add_child(block)
			active_blocks.append(block)
	
	current_health = active_blocks.size() * 70.0
	max_health = current_health
	health_changed.emit(current_health, max_health)

func _on_block_damaged(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)

func _on_block_destroyed(block: Node) -> void:
	active_blocks.erase(block)
	if active_blocks.is_empty() or current_health <= 0:
		castle_destroyed.emit()

func reset() -> void:
	_build_castle()
