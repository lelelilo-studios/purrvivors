class_name Arena
extends Node2D

signal run_finished(action: String)   # "again" | "shop" | "menu"
## One run: owns the player, the horde (via EnemyDirector), snacks,
## projectiles, FX, HUD and the level-up / pause / game-over screens.
## Everything spawnable is pooled.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const SNACK_SCENE := preload("res://scenes/snacks/snack.tscn")
const POOF_SCENE := preload("res://scenes/fx/poof.tscn")
const PROJECTILE_SCENE := preload("res://scenes/weapons/projectile.tscn")
const BOSS_SCENE := preload("res://scenes/bosses/boss.tscn")
const BOSS_IDS := ["boss_bulldog", "boss_vacuum", "boss_fatcat"]

const POOF_ENEMY_COLOR := Color(0.72, 0.6, 0.47)
const POOF_EAT_COLOR := Color(0.98, 0.83, 0.4)

var enemy_grid := SpatialGrid.new()
var active_enemies: Array[Enemy] = []
var active_snacks: Array[Snack] = []
var active_bosses: Array[Boss] = []
var next_boss_index := 0
var run_over := false

var _pending_level_ups := 0
var _showing_level_up := false
var _hitstopping := false

# perf instrumentation (read by DevTools --perf-log)
var perf_director_us := 0
var perf_snacks_us := 0

@onready var ground: Ground = $Ground
@onready var player: Player = $World/Player
@onready var camera: GameCamera = $GameCamera
@onready var director: EnemyDirector = $Director
@onready var snack_container: Node2D = $Snacks
@onready var enemy_container: Node2D = $World/Enemies
@onready var projectile_container: Node2D = $Projectiles
@onready var fx_container: Node2D = $FX
@onready var hud: Control = $HUDLayer/HUD
@onready var level_up_screen: Control = $ScreenLayer/LevelUpScreen
@onready var pause_screen: Control = $ScreenLayer/PauseScreen
@onready var game_over_screen: Control = $ScreenLayer/GameOverScreen


func _ready() -> void:
	randomize()
	add_to_group(&"arena")
	GameData.start_run(GameData.meta.selected_cat)
	var biome: String = Ground.BIOMES[int(GameData.meta.get("runs", 0)) % Ground.BIOMES.size()]
	ground.setup(biome, randi())
	ground.update_around(Vector2.ZERO)
	player.setup(GameData.meta.selected_cat, self)
	player.died.connect(_on_player_died)
	director.setup(self)
	GameData.leveled_up.connect(_on_leveled_up)
	InputRouter.app_focus_lost.connect(_on_focus_lost)
	level_up_screen.option_chosen.connect(_on_upgrade_chosen)
	game_over_screen.action.connect(_finish_run)
	pause_screen.restart_requested.connect(_finish_run.bind("again"))
	pause_screen.quit_requested.connect(_finish_run.bind("menu"))
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
	ground.update_around(player.position)
	var t0 := Time.get_ticks_usec()
	director.update(delta)
	var t1 := Time.get_ticks_usec()
	_update_snacks(delta)
	perf_snacks_us = Time.get_ticks_usec() - t1
	perf_director_us = t1 - t0
	_check_boss_milestones()


# --------------------------------- bosses ----------------------------------

func _check_boss_milestones() -> void:
	if next_boss_index >= Balance.BOSS_TIMES_SEC.size():
		return
	if GameData.run_time >= Balance.BOSS_TIMES_SEC[next_boss_index]:
		spawn_boss(next_boss_index)
		next_boss_index += 1


func spawn_boss(index: int) -> void:
	var boss_id: String = BOSS_IDS[index]
	var def: Dictionary = Balance.BOSSES[boss_id]
	var boss: Boss = BOSS_SCENE.instantiate()
	enemy_container.add_child(boss)
	var angle := randf() * TAU
	boss.setup(boss_id, self, player.position
		+ Vector2.from_angle(angle) * (camera.offscreen_radius() + 40.0))
	active_bosses.append(boss)
	hud.announce("%s  -  %s" % [def.display_name, def.intro_line])
	camera.add_trauma(0.5)
	AudioManager.play_sfx("boss_roar")


func damage_boss(boss: Boss, amount: float) -> void:
	if boss.take_damage(amount):
		_kill_boss(boss)


func _kill_boss(boss: Boss) -> void:
	boss.dead = true
	var def := boss.def
	for snack_type: String in def.snacks:
		spawn_snack(snack_type, boss.position + _scatter())
	for i in 3:
		spawn_snack("coin", boss.position + _scatter())
	_poof(boss.position, Color(1.0, 0.85, 0.4), 34, 5.0, 120.0)
	camera.add_trauma(0.7)
	hitstop(0.22, 0.08)
	AudioManager.play_sfx("boss_defeat")
	GameData.notify_boss_defeated(boss.boss_id)
	hud.announce("%s defeated!" % def.display_name)
	active_bosses.erase(boss)
	boss.queue_free()
	if boss.boss_id == "boss_fatcat":
		_full_clear()


func _full_clear() -> void:
	run_over = true
	AudioManager.play_sfx("fanfare")
	var summary := GameData.end_run(GameData.run_time)
	game_over_screen.show_summary(summary)


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


func damage_enemy(target: Node2D, amount: float, knockback := Vector2.ZERO) -> void:
	if target.dead:
		return
	if target is Boss:
		AudioManager.play_sfx("enemy_hit", 0.14, -4.0)
		damage_boss(target, amount)
		return
	AudioManager.play_sfx("enemy_hit", 0.14, -6.0)
	if target.take_damage(amount, knockback):
		_kill_enemy(target)


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


func _finish_run(action: String) -> void:
	# If the run is being abandoned mid-fight, still bank coins + progress.
	if not run_over:
		run_over = true
		GameData.end_run(GameData.run_time)
	get_tree().paused = false
	run_finished.emit(action)


func _scatter() -> Vector2:
	return Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
