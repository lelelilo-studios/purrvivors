class_name EnemyDirector
extends Node
## The horde conductor. Spawns escalating waves (rate, pack size, tier mix,
## elites, surges, pincers - all from Balance) and updates every enemy in
## ONE loop with no physics bodies.
##
## Perf scheme (300+ enemies on weak hardware): enemies alternate between a
## "steering" frame (full AI: target dir, separation, facing, contact) and
## an "integrate" frame (position += cached move). The spatial grid rebuilds
## every other frame. AI timers tick with 2x delta to stay real-time.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

const SEPARATION_RADIUS := 14.0
const SEPARATION_PUSH := 34.0
const KNOCKBACK_DECAY := 6.0

# Dasher states
const ROAM := 0
const WINDUP := 1
const DASH := 2
const RECOVER := 3

var arena: Node2D
var frame_parity := 0
var spawn_timer := 1.0
var surge_timer := Balance.SURGE_INTERVAL_SEC
var surge_left := 0.0
var pincer := false
var pincer_angle := 0.0
## tier letter -> weight table filtered down to types whose art exists,
## so the roster grows automatically as sprites land.
var _available_weights: Dictionary = {}


func setup(arena_ref: Node2D) -> void:
	arena = arena_ref
	for tier: String in Balance.SPAWN_WEIGHTS:
		var filtered := {}
		for type: String in Balance.SPAWN_WEIGHTS[tier]:
			var dir: String = Balance.ENEMIES[type].sprite_dir
			if ResourceLoader.exists("%s/frames.tres" % dir):
				filtered[type] = Balance.SPAWN_WEIGHTS[tier][type]
		_available_weights[tier] = filtered


func update(delta: float) -> void:
	var t: float = GameData.run_time
	_update_surge(delta)
	_update_spawning(delta, t)
	_update_enemies(delta)


# -------------------------------- spawning ---------------------------------

func _update_spawning(delta: float, t: float) -> void:
	var interval: float = Balance.spawn_interval(t)
	if surge_left > 0.0:
		interval /= Balance.SURGE_RATE_MULT
	spawn_timer -= delta
	while spawn_timer <= 0.0:
		spawn_timer += interval
		if arena.active_enemies.size() >= Balance.max_alive(t):
			continue
		_spawn_pack(t)


func _update_surge(delta: float) -> void:
	if surge_left > 0.0:
		surge_left -= delta
		return
	surge_timer -= delta
	if surge_timer <= 0.0:
		surge_timer = Balance.SURGE_INTERVAL_SEC * randf_range(0.8, 1.2)
		surge_left = Balance.SURGE_DURATION_SEC
		pincer = randf() < Balance.PINCER_CHANCE
		pincer_angle = randf() * TAU


func _spawn_pack(t: float) -> void:
	var weights := _current_weights(t)
	if weights.is_empty():
		return
	for i in Balance.pack_size(t):
		var type := _pick_weighted(weights)
		var pos := _spawn_position()
		var elite := randf() < Balance.elite_chance(t)
		arena.spawn_enemy(type, pos, elite)


func _current_weights(t: float) -> Dictionary:
	var best := "A"
	for tier: String in Balance.TIER_UNLOCK:
		if t >= float(Balance.TIER_UNLOCK[tier]) and tier > best:
			best = tier
	return _available_weights.get(best, {})


func _pick_weighted(weights: Dictionary) -> String:
	var total := 0.0
	for w in weights.values():
		total += w
	var roll := randf() * total
	for type: String in weights:
		roll -= weights[type]
		if roll <= 0.0:
			return type
	return weights.keys()[0]


func _spawn_position() -> Vector2:
	var angle: float
	if surge_left > 0.0 and pincer:
		# Pincer: squeeze from two opposite arcs.
		angle = pincer_angle + (PI if randf() < 0.5 else 0.0) + randf_range(-0.5, 0.5)
	else:
		angle = randf() * TAU
	var radius: float = arena.camera.offscreen_radius() + Balance.SPAWN_MARGIN
	return arena.player.position + Vector2.from_angle(angle) * radius


# ----------------------------- the horde loop ------------------------------

func _update_enemies(delta: float) -> void:
	frame_parity = 1 - frame_parity
	var grid: SpatialGrid = arena.enemy_grid
	if frame_parity == 0:
		grid.clear()
		for e: Enemy in arena.active_enemies:
			grid.insert(e, e.position)

	var player: Player = arena.player
	var player_pos := player.position
	var dt2 := delta * 2.0   # AI timers tick on alternate frames

	for i in arena.active_enemies.size():
		var e: Enemy = arena.active_enemies[i]

		if (i & 1) == frame_parity:
			# ---- steering frame: full AI ----
			var to_player := player_pos - e.position
			var dist := to_player.length()
			var dir := to_player / maxf(dist, 0.001)

			match e.behavior_id:
				Enemy.Behavior.SWARMER, Enemy.Behavior.CHASER, Enemy.Behavior.TANK:
					e.move_vec = dir * e.speed
				Enemy.Behavior.SWARMER_WAVE:
					e.wave_phase += dt2 * 6.0
					var side := Vector2(-dir.y, dir.x) * sin(e.wave_phase) * 0.6
					e.move_vec = (dir + side).normalized() * e.speed
				Enemy.Behavior.CHASER_ERRATIC:
					e.wave_phase += dt2 * 2.2
					var wobble := Vector2.from_angle(e.wave_phase * 2.7) * 0.45
					e.move_vec = (dir + wobble).normalized() * e.speed
				Enemy.Behavior.DASHER:
					e.move_vec = _dasher_move(e, dir, dist, dt2)
				Enemy.Behavior.RANGED:
					e.move_vec = _ranged_move(e, dir, dist, dt2)

			e.cached_push = grid.separation_push(e, e.position, SEPARATION_RADIUS)
			if e.state != WINDUP:
				var face := dir
				if e.behavior_id == Enemy.Behavior.RANGED and dist < e.keep_distance:
					face = -dir
				e.face_towards(face)

			# Contact damage with per-enemy cooldown.
			e.contact_cooldown -= dt2
			if e.contact_cooldown <= 0.0 and dist < e.contact_radius + Balance.PLAYER_CONTACT_RADIUS:
				player.take_hit(e.damage, e.position)
				e.contact_cooldown = 0.8

		# ---- every frame: integrate ----
		e.position += (e.move_vec + e.cached_push * SEPARATION_PUSH + e.knockback) * delta
		e.knockback = e.knockback.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)


func _dasher_move(e: Enemy, dir: Vector2, dist: float, dt: float) -> Vector2:
	e.state_timer -= dt
	match e.state:
		ROAM:
			if dist < 150.0 and e.state_timer <= 0.0:
				e.state = WINDUP
				e.state_timer = e.dash_windup
				e.velocity = dir   # lock aim at windup start
				return Vector2.ZERO
			return dir * e.speed
		WINDUP:
			# Telegraph: quiver in place, pulse warning tint.
			e.sprite.modulate = (Balance.ELITE_TINT if e.is_elite else Color.WHITE).lerp(
				Color(1.6, 0.7, 0.7), 0.5 + 0.5 * sin(e.state_timer * 30.0))
			if e.state_timer <= 0.0:
				e.state = DASH
				e.state_timer = e.dash_time
				e.velocity = (arena.player.position - e.position).normalized()
				e.sprite.modulate = Color.WHITE
				AudioManager.play_sfx("dash", 0.15)
			return Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
		DASH:
			if e.state_timer <= 0.0:
				e.state = RECOVER
				e.state_timer = e.dash_cooldown
			return e.velocity * e.dash_speed
		RECOVER:
			if e.state_timer <= 0.0:
				e.state = ROAM
				e.state_timer = 0.4
			return dir * e.speed * 0.5
	return Vector2.ZERO


func _ranged_move(e: Enemy, dir: Vector2, dist: float, dt: float) -> Vector2:
	e.shoot_timer -= dt
	if e.shoot_timer <= 0.0 and dist < e.keep_distance * 1.6:
		e.shoot_timer = e.shoot_interval
		var projectile: Node2D = ObjectPool.acquire(ENEMY_PROJECTILE_SCENE)
		arena.projectile_container.add_child(projectile)
		projectile.launch(arena, e.position, dir * e.projectile_speed, e.projectile_damage)
	if dist > e.keep_distance * 1.15:
		return dir * e.speed
	if dist < e.keep_distance * 0.85:
		return -dir * e.speed
	return Vector2.ZERO
