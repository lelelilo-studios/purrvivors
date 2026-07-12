class_name Player
extends CharacterBody2D
## The cat. CharacterBody2D (player + bosses only get physics bodies).
## Steering comes from InputRouter (keyboard or touch joystick); attacks are
## automatic via the WeaponManager child.

signal died

const DIRECTIONS := [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east",
]

var cat_id := "tabby"
var max_hp := 6
var hp := 6
var revives := 0
var luck := 0.0
var arena: Node2D

# Effective stats (recomputed when passives/meta change).
var eff_speed := 85.0
var eff_pickup_radius := 30.0
var eff_damage_mult := 1.0

var facing_index := 2   # south
var iframes := 0.0
var _base_speed := 85.0
var _base_pickup := 30.0
var _meta: Dictionary = {}
var _milk_timer := 0.0
var _flash_tween: Tween

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var weapons: WeaponManager = $Weapons


func setup(cat: String, arena_ref: Node2D) -> void:
	arena = arena_ref
	cat_id = cat
	var def: Dictionary = Balance.CATS[cat]
	_meta = GameData.meta_effects()
	max_hp = int(def.max_hp) + int(_meta.max_hp)
	hp = max_hp
	_base_speed = float(def.move_speed)
	_base_pickup = float(def.pickup_radius)
	luck = float(_meta.luck)
	revives = int(_meta.revive)
	sprite.sprite_frames = load("%s/frames.tres" % def.sprite_dir)
	sprite.material = sprite.material.duplicate()
	weapons.setup(self)
	weapons.add_weapon(def.starting_weapon)
	for i in int(_meta.starting_weapon_level):
		weapons.level_up_weapon(def.starting_weapon)
	recompute_stats()
	GameData.report_player_hp(hp, max_hp)
	_play_anim("idle")


## Called by WeaponManager whenever a passive changes.
func recompute_stats() -> void:
	eff_speed = _base_speed * (1.0 + float(_meta.move_speed_mult)) \
		* (1.0 + weapons.passive_level("collar") * Balance.PASSIVES["collar"].speed_mult_per_level)
	eff_pickup_radius = _base_pickup * (1.0 + float(_meta.pickup_mult)) \
		* (1.0 + weapons.passive_level("bigger_bowl") * Balance.PASSIVES["bigger_bowl"].pickup_mult_per_level)
	eff_damage_mult = (1.0 + float(_meta.damage_mult)) \
		* (1.0 + weapons.passive_level("catnip") * Balance.PASSIVES["catnip"].damage_mult_per_level)
	if weapons.passive_level("nine_lives") > 0 and not weapons.nine_lives_consumed:
		revives = maxi(revives, int(_meta.revive) + 1)
	luck = float(_meta.luck) + weapons.passive_level("lucky_paw") * Balance.PASSIVES["lucky_paw"].luck_per_level


func _physics_process(delta: float) -> void:
	if hp <= 0:
		return   # fallen - the death tween owns the sprite now
	if iframes > 0.0:
		iframes -= delta
		sprite.visible = fmod(iframes, 0.16) < 0.10   # classic invuln blink
		if iframes <= 0.0:
			sprite.visible = true

	var move := InputRouter.get_move_vector()
	velocity = move * eff_speed
	move_and_slide()

	if move != Vector2.ZERO:
		var idx := wrapi(roundi(move.angle() / (TAU / 8.0)), 0, 8)
		if idx != facing_index:
			facing_index = idx
		_play_anim("walk")
	else:
		_play_anim("idle")

	_milk_regen(delta)


func take_hit(amount: int, from_pos: Vector2) -> void:
	if iframes > 0.0 or hp <= 0 or DevTools.god_mode:
		return
	hp = maxi(0, hp - amount)
	iframes = Balance.PLAYER_IFRAMES_SEC
	GameData.report_player_hp(hp, max_hp)
	AudioManager.play_sfx("player_hit")
	_flash()
	# A shove away from the hit sells the impact.
	var push := (position - from_pos).normalized() * 26.0
	position += push
	if arena != null:
		arena.on_player_hurt()
	if hp <= 0:
		_die()


func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(max_hp, hp + amount)
	GameData.report_player_hp(hp, max_hp)


func _die() -> void:
	if revives > 0:
		revives -= 1
		weapons.nine_lives_consumed = true
		hp = maxi(1, max_hp / 2)
		iframes = 2.0
		GameData.report_player_hp(hp, max_hp)
		AudioManager.play_sfx("revive")
		if arena != null:
			arena.on_player_revived()
		return
	died.emit()


func _milk_regen(delta: float) -> void:
	var milk_level := weapons.passive_level("milk")
	if milk_level <= 0 or hp >= max_hp or hp <= 0:
		return
	_milk_timer += delta
	var interval: float = Balance.PASSIVES["milk"].heal_interval[milk_level - 1]
	if _milk_timer >= interval:
		_milk_timer = 0.0
		heal(1)


func _play_anim(base: String) -> void:
	var name := StringName("%s_%s" % [base, DIRECTIONS[facing_index]])
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(name) \
			and sprite.animation != name:
		sprite.play(name)


func _flash() -> void:
	var mat: ShaderMaterial = sprite.material
	mat.set_shader_parameter(&"flash", 0.85)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(mat, "shader_parameter/flash", 0.0, 0.2)
