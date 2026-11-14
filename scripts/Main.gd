extends Node2D

@onready var player_castle: Node2D = $PlayerCastle
@onready var enemy_castle: Node2D = $EnemyCastle
@onready var multiplier_gate: Area2D = $MultiplierGate
@onready var enemy_hp_bar: ProgressBar = $UI/HUD/EnemyHPBar
@onready var status_label: Label = $UI/HUD/StatusLabel
@onready var victory_panel: Panel = $UI/VictoryPanel

var terrain_polygon: PackedVector2Array = []

func _ready() -> void:
	enemy_castle.connect("health_changed", _on_enemy_health_changed)
	enemy_castle.connect("castle_destroyed", _on_castle_destroyed)
	$UI/HUD/RestartBtn.pressed.connect(_on_restart_pressed)
	$UI/VictoryPanel/PlayAgainBtn.pressed.connect(_on_restart_pressed)
	
	victory_panel.visible = false
	_generate_terrain()

func _generate_terrain() -> void:
	# Define a smooth 2D valley terrain
	terrain_polygon = PackedVector2Array([
		Vector2(0, 560),
		Vector2(320, 560),
		Vector2(500, 630),
		Vector2(740, 630),
		Vector2(920, 560),
		Vector2(1280, 560),
		Vector2(1280, 720),
		Vector2(0, 720)
	])
	$Terrain/CollisionPolygon2D.polygon = terrain_polygon
	queue_redraw()

func _draw() -> void:
	# 1. Sky Gradient / Background already cleared by environment
	# 2. Draw Rolling Green Hills
	if terrain_polygon.size() > 0:
		draw_colored_polygon(terrain_polygon, Color(0.32, 0.65, 0.28)) # Vibrant grass
		
		# Draw top grass highlight line
		for i in range(5):
			draw_line(terrain_polygon[i], terrain_polygon[i+1], Color(0.45, 0.82, 0.35), 6.0)

func _on_enemy_health_changed(current_hp: float, max_hp: float) -> void:
	var ratio = current_hp / max_hp
	enemy_hp_bar.value = ratio * 100.0
	status_label.text = "Enemy Fortress HP: %d / %d" % [int(current_hp), int(max_hp)]

func _on_castle_destroyed() -> void:
	victory_panel.visible = true
	status_label.text = "🎉 VICTORY! Enemy Fortress Completely Obliterated!"

func _on_restart_pressed() -> void:
	# Clean up any leftover projectiles
	for child in get_children():
		if child is RigidBody2D and "has_multiplied" in child:
			child.queue_free()
	
	enemy_castle.reset()
	victory_panel.visible = false
	status_label.text = "Drag left to aim through the x15 gate!"

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == KEY_R:
		_on_restart_pressed()
