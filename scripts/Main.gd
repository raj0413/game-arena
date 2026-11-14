extends Node2D

@onready var player_castle: Node2D = $PlayerCastle
@onready var enemy_castle: Node2D = $EnemyCastle
@onready var multiplier_gate: Area2D = $MultiplierGate
@onready var enemy_hp_bar: ProgressBar = $UI/HUD/TopPanel/EnemyHPBar
@onready var status_label: Label = $UI/HUD/TopPanel/StatusLabel
@onready var victory_panel: Panel = $UI/VictoryPanel
@onready var camera: Camera2D = $Camera2D

var shake_intensity: float = 0.0

func _ready() -> void:
	enemy_castle.connect("health_changed", _on_enemy_health_changed)
	enemy_castle.connect("castle_destroyed", _on_castle_destroyed)
	$UI/HUD/RestartBtn.pressed.connect(_on_restart_pressed)
	$UI/VictoryPanel/PlayAgainBtn.pressed.connect(_on_restart_pressed)
	$UI/VictoryPanel/WatchAdBtn.pressed.connect(_on_watch_ad_pressed)
	
	victory_panel.visible = false
	_setup_terrain_collision()

func _process(delta: float) -> void:
	# Camera Screen Shake
	if shake_intensity > 0.0:
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 20.0)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

func trigger_shake(amount: float) -> void:
	shake_intensity = clamp(shake_intensity + amount, 0.0, 16.0)

func _setup_terrain_collision() -> void:
	# Invisible physics boundary matching the green rolling hills in background.png
	var hill_points = PackedVector2Array([
		Vector2(0, 580),
		Vector2(260, 580),
		Vector2(480, 630),
		Vector2(780, 630),
		Vector2(960, 580),
		Vector2(1280, 580),
		Vector2(1280, 750),
		Vector2(0, 750)
	])
	$Terrain/CollisionPolygon2D.polygon = hill_points

func _on_enemy_health_changed(current_hp: float, max_hp: float) -> void:
	var ratio = current_hp / max_hp
	enemy_hp_bar.value = ratio * 100.0
	status_label.text = "Enemy Fortress: %d / %d HP" % [int(current_hp), int(max_hp)]

func _on_castle_destroyed() -> void:
	trigger_shake(15.0)
	victory_panel.visible = true
	status_label.text = "🎉 VICTORY! Enemy Fortress Completely Obliterated!"

func _on_restart_pressed() -> void:
	for child in get_children():
		if child is RigidBody2D and "has_multiplied" in child:
			child.queue_free()
	
	enemy_castle.reset()
	victory_panel.visible = false
	status_label.text = "🎯 Pull back & aim through the x15 gate!"

func _on_watch_ad_pressed() -> void:
	# Simulate Rewarded Ad watch
	$UI/VictoryPanel/AdStatus.text = "🎁 Rewarded Ad Played! 500 Coins Collected!"
	trigger_shake(8.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == KEY_R:
		_on_restart_pressed()
