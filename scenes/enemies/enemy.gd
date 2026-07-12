class_name Enemy
extends Node2D
## One pooled, physics-free horde critter. The EnemyDirector moves every
## enemy in a single loop (see enemy_director.gd); this script is the data
## container plus per-enemy reactions (flash, damage, elite styling).

const DIRECTIONS := [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east",
]

static var _frames_cache: Dictionary = {}

# Behavior enum - the horde loop must never string-compare per frame.
enum Behavior { SWARMER, SWARMER_WAVE, CHASER, CHASER_ERRATIC, TANK, DASHER, RANGED }
const BEHAVIOR_IDS := {
	"swarmer": Behavior.SWARMER, "swarmer_wave": Behavior.SWARMER_WAVE,
	"chaser": Behavior.CHASER, "chaser_erratic": Behavior.CHASER_ERRATIC,
	"tank": Behavior.TANK, "dasher": Behavior.DASHER, "ranged": Behavior.RANGED,
}

var type_key := ""
var behavior_id := Behavior.CHASER
var max_hp := 1.0
var hp := 1.0
var speed := 50.0
var damage := 1
var contact_radius := 10.0
var coins := 0
var score_value := 0
var drop := "cookie"
var is_elite := false
var dead := false
var def: Dictionary = {}

var velocity := Vector2.ZERO
var knockback := Vector2.ZERO
var cached_push := Vector2.ZERO
var move_vec := Vector2.ZERO      # steering result, recomputed on parity frames
# dasher/ranged tuning pulled out of `def` at setup (no dict hits in the loop)
var dash_speed := 0.0
var dash_windup := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var keep_distance := 0.0
var shoot_interval := 0.0
var projectile_damage := 0
var projectile_speed := 0.0
var contact_cooldown := 0.0
var facing_index := 2          # south
var anim_name := "walk"
# dasher / ranged behavior state (see enemy_director.gd)
var state := 0
var state_timer := 0.0
var wave_phase := 0.0
var shoot_timer := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite

var _flash_tween: Tween


func _ready() -> void:
	sprite.material = sprite.material.duplicate()


func setup(key: String, enemy_def: Dictionary, pos: Vector2, elite: bool, scalar: float) -> void:
	type_key = key
	def = enemy_def
	behavior_id = BEHAVIOR_IDS[def.behavior]
	dash_speed = float(def.get("dash_speed", 0.0))
	dash_windup = float(def.get("dash_windup", 0.0))
	dash_time = float(def.get("dash_time", 0.0))
	dash_cooldown = float(def.get("dash_cooldown", 0.0))
	keep_distance = float(def.get("keep_distance", 0.0))
	shoot_interval = float(def.get("shoot_interval", 0.0))
	projectile_damage = int(def.get("projectile_damage", 0))
	projectile_speed = float(def.get("projectile_speed", 0.0))
	move_vec = Vector2.ZERO
	cached_push = Vector2.ZERO
	max_hp = float(def.hp) * scalar * (Balance.ELITE_HP_MULT if elite else 1.0)
	hp = max_hp
	speed = float(def.speed)
	damage = int(ceilf(float(def.damage) * scalar * (Balance.ELITE_DAMAGE_MULT if elite else 1.0)))
	contact_radius = float(def.contact_radius)
	coins = int(def.coins) + (Balance.ELITE_COIN_BONUS if elite else 0)
	score_value = int(float(def.score) * (Balance.ELITE_SCORE_MULT if elite else 1.0))
	drop = def.drop
	is_elite = elite
	position = pos
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	contact_cooldown = 0.0
	state = 0
	state_timer = 0.0
	wave_phase = randf() * TAU
	shoot_timer = randf_range(0.5, float(def.get("shoot_interval", 2.0)))

	sprite.sprite_frames = _frames_for(def.sprite_dir)
	var base_scale := float(def.get("sprite_scale", 1.0))
	scale = Vector2.ONE * base_scale * (Balance.ELITE_SCALE if elite else 1.0)
	modulate = Balance.ELITE_TINT if elite else Color.WHITE
	facing_index = 2
	anim_name = "walk"
	_play_anim()
	show()


func take_damage(amount: float, kb: Vector2 = Vector2.ZERO) -> bool:
	hp -= amount
	knockback += kb
	_flash()
	return hp <= 0.0


func face_towards(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var idx := wrapi(roundi(dir.angle() / (TAU / 8.0)), 0, 8)
	if idx != facing_index:
		facing_index = idx
		_play_anim()


func _play_anim() -> void:
	var full := StringName("%s_%s" % [anim_name, DIRECTIONS[facing_index]])
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(full):
		sprite.play(full)


func _flash() -> void:
	var mat: ShaderMaterial = sprite.material
	mat.set_shader_parameter(&"flash", 0.85)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(mat, "shader_parameter/flash", 0.0, 0.16)


func _pool_reset() -> void:
	show()


func _pool_sleep() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
		_flash_tween = null
	if sprite != null and sprite.material != null:
		sprite.material.set_shader_parameter(&"flash", 0.0)


static func _frames_for(dir: String) -> SpriteFrames:
	if not _frames_cache.has(dir):
		var path := "%s/frames.tres" % dir
		_frames_cache[dir] = load(path) if ResourceLoader.exists(path) else null
	return _frames_cache[dir]
