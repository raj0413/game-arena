extends Node2D

enum TurnState {
	PLAYER_AIM,
	PLAYER_FIRING,
	AI_AIM,
	AI_FIRING,
	GAME_OVER
}

var current_state: TurnState = TurnState.PLAYER_AIM

@onready var player_castle = $PlayerCastle
@onready var enemy_castle = $EnemyCastle
@onready var multiplier_gate: Area2D = $MultiplierGate
@onready var camera: Camera2D = $Camera2D

@onready var player_hp_bar: ProgressBar = $UI/HUD/TopPanel/PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = $UI/HUD/TopPanel/EnemyHPBar
@onready var status_label: Label = $UI/HUD/TopPanel/StatusLabel
@onready var turn_indicator: Label = $UI/HUD/TopPanel/TurnIndicator

@onready var victory_panel: Panel = $UI/VictoryPanel
@onready var defeat_panel: Panel = $UI/DefeatPanel

@onready var sfx_cannon: AudioStreamPlayer = $Audio/SfxCannon
@onready var sfx_gate: AudioStreamPlayer = $Audio/SfxGate
@onready var sfx_explosion: AudioStreamPlayer = $Audio/SfxExplosion
@onready var sfx_victory: AudioStreamPlayer = $Audio/SfxVictory

var shake_intensity: float = 0.0
var sfx_explosion_cooldown: float = 0.0

func _ready() -> void:
	player_castle.connect("shot_fired", _on_player_shot_fired)
	player_castle.connect("health_changed", _on_player_health_changed)
	player_castle.connect("player_defeated", _on_player_defeated)
	
	enemy_castle.connect("ai_shot_fired", _on_ai_shot_fired)
	enemy_castle.connect("health_changed", _on_enemy_health_changed)
	enemy_castle.connect("castle_destroyed", _on_enemy_defeated)
	
	$UI/HUD/RestartBtn.pressed.connect(_on_restart_pressed)
	$UI/VictoryPanel/PlayAgainBtn.pressed.connect(_on_restart_pressed)
	$UI/VictoryPanel/WatchAdBtn.pressed.connect(_on_victory_ad_pressed)
	$UI/DefeatPanel/ReviveAdBtn.pressed.connect(_on_revive_ad_pressed)
	$UI/DefeatPanel/RestartBtn.pressed.connect(_on_restart_pressed)
	
	victory_panel.visible = false
	defeat_panel.visible = false
	
	_setup_terrain_collision()
	_set_turn(TurnState.PLAYER_AIM)

func _process(delta: float) -> void:
	# Camera Screen Shake
	if shake_intensity > 0.0:
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 20.0)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO
		
	if sfx_explosion_cooldown > 0.0:
		sfx_explosion_cooldown -= delta
		
	# Check projectile flying completion
	if current_state == TurnState.PLAYER_FIRING:
		if _get_active_projectiles_count() == 0:
			_set_turn(TurnState.AI_AIM)
	elif current_state == TurnState.AI_FIRING:
		if _get_active_projectiles_count() == 0:
			_set_turn(TurnState.PLAYER_AIM)

func trigger_shake(amount: float) -> void:
	shake_intensity = clamp(shake_intensity + amount, 0.0, 16.0)

func play_sound(sfx_name: String) -> void:
	match sfx_name:
		"cannon":
			if sfx_cannon: sfx_cannon.play()
		"gate":
			if sfx_gate: sfx_gate.play()
		"explosion":
			if sfx_explosion and sfx_explosion_cooldown <= 0.0:
				sfx_explosion.play()
				sfx_explosion_cooldown = 0.08 # prevent audio overload
		"victory":
			if sfx_victory: sfx_victory.play()

func _setup_terrain_collision() -> void:
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

func _set_turn(new_state: TurnState) -> void:
	if current_state == TurnState.GAME_OVER:
		return
		
	current_state = new_state
	
	match current_state:
		TurnState.PLAYER_AIM:
			player_castle.can_aim = true
			turn_indicator.text = "🟢 YOUR TURN"
			turn_indicator.modulate = Color(0.3, 1.0, 0.4)
			status_label.text = "🎯 Drag & aim through the x20 gate!"
			
		TurnState.PLAYER_FIRING:
			player_castle.can_aim = false
			turn_indicator.text = "🚀 BARRAGE INCOMING!"
			turn_indicator.modulate = Color(1.0, 0.8, 0.2)
			status_label.text = "Watch the destruction!"
			
		TurnState.AI_AIM:
			player_castle.can_aim = false
			turn_indicator.text = "🔴 ENEMY AI TURN"
			turn_indicator.modulate = Color(1.0, 0.3, 0.3)
			status_label.text = "🤖 Enemy AI is calculating trajectory..."
			await get_tree().create_timer(0.9).timeout
			if current_state == TurnState.AI_AIM:
				enemy_castle.execute_ai_turn(multiplier_gate.global_position, player_castle.global_position)
				
		TurnState.AI_FIRING:
			turn_indicator.text = "⚠️ INCOMING ENEMY SWARM!"
			turn_indicator.modulate = Color(1.0, 0.2, 0.2)
			status_label.text = "Brace for impact!"

func _on_player_shot_fired() -> void:
	play_sound("cannon")
	trigger_shake(5.0)
	await get_tree().create_timer(0.25).timeout
	current_state = TurnState.PLAYER_FIRING

func _on_ai_shot_fired() -> void:
	play_sound("cannon")
	trigger_shake(5.0)
	await get_tree().create_timer(0.25).timeout
	current_state = TurnState.AI_FIRING

func _get_active_projectiles_count() -> int:
	var count = 0
	for child in get_children():
		if child is RigidBody2D and "has_multiplied" in child:
			count += 1
	return count

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	player_hp_bar.value = (current_hp / max_hp) * 100.0

func _on_enemy_health_changed(current_hp: float, max_hp: float) -> void:
	enemy_hp_bar.value = (current_hp / max_hp) * 100.0

func _on_enemy_defeated() -> void:
	current_state = TurnState.GAME_OVER
	play_sound("victory")
	trigger_shake(16.0)
	victory_panel.visible = true
	turn_indicator.text = "👑 VICTORY!"

func _on_player_defeated() -> void:
	current_state = TurnState.GAME_OVER
	trigger_shake(16.0)
	defeat_panel.visible = true
	turn_indicator.text = "💀 DEFEAT!"

func _on_victory_ad_pressed() -> void:
	$UI/VictoryPanel/AdStatus.text = "🎁 Ad Completed! +500 Gold Added to Wallet!"
	trigger_shake(8.0)

func _on_revive_ad_pressed() -> void:
	defeat_panel.visible = false
	player_castle.current_health = player_castle.max_health * 0.5
	player_castle.health_changed.emit(player_castle.current_health, player_castle.max_health)
	trigger_shake(10.0)
	_set_turn(TurnState.PLAYER_AIM)

func _on_restart_pressed() -> void:
	for child in get_children():
		if child is RigidBody2D and "has_multiplied" in child:
			child.queue_free()
			
	player_castle.reset()
	enemy_castle.reset()
	victory_panel.visible = false
	defeat_panel.visible = false
	_set_turn(TurnState.PLAYER_AIM)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == KEY_R:
		_on_restart_pressed()
