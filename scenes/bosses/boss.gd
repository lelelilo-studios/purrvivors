class_name Boss
extends CharacterBody2D
## Milestone bosses. One script, three personalities (from Balance.BOSSES):
##  boss_bulldog - Big Chompus: telegraphed charge bruiser
##  boss_vacuum  - VAC-U-TRON 9000: summons roombas, sucks in the cat AND
##                 steals nearby snacks (rude)
##  boss_fatcat  - The Fatriarch: charging final boss, enrages at half HP
## A boss persists until killed; only kills raise the win tier.

const DIRECTIONS := [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east",
]

enum State { CHASE, WINDUP, CHARGE, SUCK }

var boss_id := ""
var def: Dictionary = {}
var max_hp := 100.0
var hp := 100.0
var damage := 1
var speed := 40.0
var contact_radius := 26.0
var dead := false
var enraged := false

var arena: Node2D
var state := State.CHASE
var state_timer := 0.0
var charge_dir := Vector2.ZERO
var summon_timer := 0.0
var suck_timer := 0.0
var contact_cooldown := 0.0
var facing_index := 2

@onready var sprite: AnimatedSprite2D = $Sprite

var _flash_tween: Tween


func setup(id: String, arena_ref: Node2D, pos: Vector2) -> void:
	boss_id = id
	arena = arena_ref
	def = Balance.BOSSES[id]
	max_hp = float(def.hp) * Balance.BOSS_HP_META_SCALE
	hp = max_hp
	damage = int(def.damage)
	speed = float(def.speed)
	contact_radius = float(def.contact_radius)
	dead = false
	enraged = false
	state = State.CHASE
	state_timer = 2.0
	summon_timer = float(def.get("summon_interval", 0.0))
	suck_timer = float(def.get("suck_interval", 0.0))
	position = pos
	var frames_path := "%s/frames.tres" % def.sprite_dir
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path)
	sprite.material = sprite.material.duplicate()
	_play_anim("walk")
	show()


func _physics_process(delta: float) -> void:
	if dead or arena == null or arena.run_over:
		return
	var player: Player = arena.player
	var to_player := player.position - position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)
	state_timer -= delta

	match state:
		State.CHASE:
			velocity = dir * speed * (1.4 if enraged else 1.0)
			_face(dir)
			if def.has("charge_speed") and state_timer <= 0.0 and dist < 240.0:
				state = State.WINDUP
				state_timer = float(def.charge_windup)
				charge_dir = dir
			if def.has("suck_interval"):
				suck_timer -= delta
				if suck_timer <= 0.0:
					state = State.SUCK
					state_timer = float(def.suck_duration)
					AudioManager.play_sfx("vacuum_suck")
		State.WINDUP:
			velocity = Vector2.ZERO
			# Telegraph hard: quiver + red pulse. Readability first.
			sprite.offset.x = sin(state_timer * 50.0) * 2.0
			sprite.modulate = Color.WHITE.lerp(Color(1.7, 0.6, 0.6),
				0.5 + 0.5 * sin(state_timer * 25.0))
			charge_dir = (player.position - position).normalized()
			if state_timer <= 0.0:
				state = State.CHARGE
				state_timer = float(def.charge_time)
				sprite.modulate = Color.WHITE
				sprite.offset.x = 0.0
				arena.camera.add_trauma(0.25)
				AudioManager.play_sfx("boss_charge")
		State.CHARGE:
			velocity = charge_dir * float(def.charge_speed) * (1.25 if enraged else 1.0)
			if state_timer <= 0.0:
				state = State.CHASE
				state_timer = float(def.charge_cooldown)
		State.SUCK:
			velocity = Vector2.ZERO
			_suck(delta, player, dir, dist)
			if state_timer <= 0.0:
				state = State.CHASE
				suck_timer = float(def.suck_interval)

	move_and_slide()

	if def.has("summon_interval") and state != State.SUCK:
		summon_timer -= delta
		if summon_timer <= 0.0:
			summon_timer = float(def.summon_interval)
			_summon(def.get("summon_type", "roomba"), int(def.get("summon_count", 1)))

	contact_cooldown -= delta
	if contact_cooldown <= 0.0 and dist < contact_radius + Balance.PLAYER_CONTACT_RADIUS:
		player.take_hit(damage, position)
		contact_cooldown = 1.0


func take_damage(amount: float, _kb := Vector2.ZERO) -> bool:
	if dead:
		return false
	hp -= amount
	_flash()
	queue_redraw()
	if not enraged and def.has("phase2_hp_frac") and hp <= max_hp * float(def.phase2_hp_frac):
		_enrage()
	return hp <= 0.0


func _enrage() -> void:
	enraged = true
	speed *= float(def.get("phase2_speed_mult", 1.0))
	modulate = Color(1.15, 0.9, 0.9)
	arena.camera.add_trauma(0.4)
	arena.hud.announce("%s is FURIOUS!" % def.display_name)
	AudioManager.play_sfx("boss_roar")
	if def.has("phase2_summon"):
		_summon(def.phase2_summon, 3)


func _suck(delta: float, player: Player, dir: Vector2, dist: float) -> void:
	# Drag the cat in... (dir points boss -> player, so subtract)
	if dist > contact_radius:
		player.position -= dir * float(def.suck_pull) * delta
	# ...and steal loose snacks. Genuinely evil.
	var i: int = arena.active_snacks.size() - 1
	while i >= 0:
		var snack = arena.active_snacks[i]
		snack.position = snack.position.move_toward(position, float(def.suck_pull) * 1.5 * delta)
		if snack.position.distance_to(position) < contact_radius:
			arena.active_snacks.remove_at(i)
			ObjectPool.release(snack)
		i -= 1


func _summon(type: String, count: int) -> void:
	for i in count:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(30.0, 60.0)
		arena.spawn_enemy(type, position + offset, false)
	AudioManager.play_sfx("boss_summon")


func _face(dir: Vector2) -> void:
	var idx := wrapi(roundi(dir.angle() / (TAU / 8.0)), 0, 8)
	if idx != facing_index:
		facing_index = idx
		_play_anim("walk")


func _play_anim(base: String) -> void:
	var name := StringName("%s_%s" % [base, DIRECTIONS[facing_index]])
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(name):
		sprite.play(name)


func _flash() -> void:
	var mat: ShaderMaterial = sprite.material
	mat.set_shader_parameter(&"flash", 0.7)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(mat, "shader_parameter/flash", 0.0, 0.14)


func _draw() -> void:
	# Chunky HP bar floating above the boss.
	if dead:
		return
	# Drawn below the boss: parent draw commands render under the child
	# sprite, so above-head placement would be hidden by the head.
	var w := 56.0
	var y := contact_radius * 1.9
	draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 7), Color(0.29, 0.2, 0.15))
	draw_rect(Rect2(-w * 0.5, y, w * (hp / max_hp), 5), Color(0.9, 0.3, 0.25))


func _process(_delta: float) -> void:
	queue_redraw()
