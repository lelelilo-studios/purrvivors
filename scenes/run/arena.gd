class_name Arena
extends Node2D
## One run: owns the player, the horde (via EnemyDirector), snacks,
## projectiles, FX, HUD and the level-up / pause / game-over screens.
## Everything spawnable is pooled.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const SNACK_SCENE := preload("res://scenes/snacks/snack.tscn")
const POOF_SCENE := preload("res://scenes/fx/poof.tscn")
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")

const POOF_ENEMY_COLOR := Color(0.72, 0.6, 0.47)
const POOF_EAT_COLOR := Color(0.98, 0.83, 0.4)

var enemy_grid := SpatialGrid.new()
var active_enemies: Array[Enemy] = []
var active_snacks: Array[Snack] = []
var run_over := false

var _pending_level_ups := 0
var _showing_level_up := false
var _hitstopping := false

@onready var player: Player = $World/Player
@onready var camera: GameCamera = $GameCamera
@onready var director: EnemyDirector = $Director
@onready var snack_container: Node2D = $Snacks
@onready var enemy_container: Node2D = $World/Enemies
@onready var projectile_container: Node2D = $Projectiles
@onready var fx_container: Node2D = $FX
@onready var level_up_screen: Control = $ScreenLayer/LevelUpScreen
@onready var pause_screen: Control = $ScreenLayer/PauseScreen
@onready var game_over_screen: Control = $ScreenLayer/GameOverScreen


func _ready() -> void:
	randomize()
	GameData.start_run(GameData.meta.selected_cat)
	player.setup(GameData.meta.selected_cat, self)
	player.died.connect(_on_player_died)
	director.setup(self)
	GameData.leveled_up.connect(_on_leveled_up)
	InputRouter.app_focus_lost.connect(_on_focus_lost)
	level_up_screen.option_chosen.connect(_on_upgrade_chosen)
	ObjectPool.prewarm(ENEMY_SCENE, 160)
	ObjectPool.prewarm(SNACK_SCENE, 80)
	ObjectPool.prewarm(POOF_SCENE, 16)
	ObjectPool.prewarm(PROJECTILE_SCENE, 40)
	camera.position = player.position
	camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	if run_over:
		return
	GameData.add_run_time(delta)
	camera.position = player.position
	director.update(delta)
	_update_snacks(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not run_over and not _showing_level_up:
		_toggle_pause()


# -------------------------------- enemies ----------------------------------

func spawn_enemy(type: String, pos: Vector2, elite := false) -> void:
	var def: Dictionary = Balance.ENEMIES[type]
	var enemy: Enemy = ObjectPool.acquire(ENEMY_SCENE)
	enemy_container.add_child(enemy)
	enemy.setup(type, def, pos, elite, Balance.difficulty_scalar(GameData.run_time))
	enemy.dead = false
	active_enemies.append(enemy)


func damage_enemy(enemy: Enemy, amount: float, knockback := Vector2.ZERO) -> void:
	if enemy.dead:
		return
	AudioManager.play_sfx("enemy_hit", 0.14, -6.0)
	if enemy.take_damage(amount, knockback):
		_kill_enemy(enemy)


func _kill_enemy(enemy: Enemy) -> void:
	enemy.dead = true
	var pos := enemy.position
	var def := enemy.def
	_poof(pos, POOF_ENEMY_COLOR, 12 if not enemy.is_elite else 22)
	AudioManager.play_sfx("enemy_die", 0.12)

	# Every kill drops its snack where the critter fell (the core loop).
	spawn_snack(enemy.drop, pos)
	if randf() < Balance.DROP_MILK_CHANCE:
		spawn_snack("milk", pos + _scatter())
	if randf() < Balance.DROP_COIN_CHANCE:
		spawn_snack("coin", pos + _scatter())
	if randf() < Balance.DROP_GOLDEN_COOKIE_CHANCE:
		spawn_snack("golden_cookie", pos + _scatter())
	if randf() < Balance.DROP_VACUUM_CHANCE:
		spawn_snack("vacuum", pos + _scatter())

	if def.has("split_into"):
		var count: int = randi_range(int(def.split_count[0]), int(def.split_count[1]))
		for i in count:
			spawn_enemy(def.split_into, pos + _scatter(), false)

	GameData.add_kill(enemy.coins, enemy.score_value)
	if enemy.is_elite:
		camera.add_trauma(0.3)
		hitstop(0.09, 0.15)
	active_enemies.erase(enemy)
	ObjectPool.release(enemy)


# --------------------------------- snacks ----------------------------------

func spawn_snack(type: String, pos: Vector2) -> void:
	var snack: Snack = ObjectPool.acquire(SNACK_SCENE)
	snack_container.add_child(snack)
	snack.setup(type, pos)
	active_snacks.append(snack)


func _update_snacks(delta: float) -> void:
	var ppos := player.position
	var pickup_r := player.eff_pickup_radius
	var i := active_snacks.size() - 1
	while i >= 0:
		var snack := active_snacks[i]
		var dist := snack.position.distance_to(ppos)
		if snack.magnetized or dist < pickup_r:
			snack.magnetized = true
			snack.position = snack.position.move_toward(ppos, Balance.SNACK_MAGNET_SPEED * delta)
			if dist < Balance.SNACK_EAT_RADIUS:
				_eat_snack(snack)
				active_snacks.remove_at(i)
		i -= 1


func _eat_snack(snack: Snack) -> void:
	match snack.snack_type:
		"milk":
			player.heal(Balance.MILK_HEAL)
			AudioManager.play_sfx("heal")
		"coin":
			GameData.add_run_coins(Balance.COIN_SNACK_VALUE)
			AudioManager.play_sfx("coin", 0.1)
		"vacuum":
			for other: Snack in active_snacks:
				other.magnetized = true
			AudioManager.play_sfx("vacuum")
		_:
			GameData.gain_xp(int(Balance.SNACK_XP.get(snack.snack_type, 1)))
			AudioManager.play_sfx("nom", 0.18)
	_poof(snack.position, POOF_EAT_COLOR, 6, 2.0, 30.0)
	ObjectPool.release(snack)


# ----------------------------------- juice ---------------------------------

func _poof(pos: Vector2, color: Color, count := 10, size := 3.0, vel := 55.0) -> void:
	var poof: Poof = ObjectPool.acquire(POOF_SCENE)
	fx_container.add_child(poof)
	poof.burst(pos, color, count, size, vel)


func hitstop(duration := 0.05, time_scale := 0.1) -> void:
	if _hitstopping:
		return
	_hitstopping = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstopping = false


func on_player_hurt() -> void:
	camera.add_trauma(0.45)
	hitstop(0.05)


func on_player_revived() -> void:
	_poof(player.position, Color(1.0, 0.9, 0.5), 26, 4.0, 90.0)
	camera.add_trauma(0.3)


# ------------------------------ level-up flow ------------------------------

func _on_leveled_up(_new_level: int) -> void:
	if run_over:
		return
	_pending_level_ups += 1
	if not _showing_level_up:
		_present_level_up()


func _present_level_up() -> void:
	_showing_level_up = true
	AudioManager.play_sfx("level_up")
	level_up_screen.present(UpgradePool.roll(player))


func _on_upgrade_chosen(option: Dictionary) -> void:
	UpgradePool.apply(player, option)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_present_level_up()
	else:
		_showing_level_up = false


# ------------------------------ pause & death ------------------------------

func _toggle_pause() -> void:
	if pause_screen.visible:
		pause_screen.close()
	else:
		pause_screen.open()


func _on_focus_lost() -> void:
	if not run_over and not _showing_level_up and not pause_screen.visible:
		pause_screen.open()


func _on_player_died() -> void:
	run_over = true
	camera.add_trauma(0.7)
	_poof(player.position, Color(0.9, 0.9, 0.95), 30, 4.0, 100.0)
	player.hide()
	AudioManager.play_sfx("defeat")
	var summary := GameData.end_run(GameData.run_time)
	game_over_screen.show_summary(summary)


func _scatter() -> Vector2:
	return Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
