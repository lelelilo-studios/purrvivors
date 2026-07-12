class_name Snack
extends Node2D
## A dropped treat (pooled). Spawned ONLY by dying enemies - never randomly.
## The SnackSystem in the arena moves it (magnet) and feeds it to the cat.

static var _texture_cache: Dictionary = {}

var snack_type := "cookie"
var magnetized := false

@onready var sprite: Sprite2D = $Sprite


func setup(type: String, pos: Vector2) -> void:
	snack_type = type
	position = pos
	magnetized = false
	sprite.texture = _texture_for(type)
	# Snacks pop out of the fallen enemy with a little hop.
	# (0.75 base scale: 32px snack art sits better against 48px cats.)
	scale = Vector2.ONE * 0.2
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale", Vector2.ONE * 0.75, 0.25)
	show()


func _pool_sleep() -> void:
	magnetized = false


## The magnet-all pickup is drawn as a yarn ball (cuter than a vacuum).
const TEXTURE_ALIASES := {"vacuum": "yarn_ball"}


static func _texture_for(type: String) -> Texture2D:
	if not _texture_cache.has(type):
		var file: String = TEXTURE_ALIASES.get(type, type)
		var path := "res://assets/sprites/snacks/%s.png" % file
		_texture_cache[type] = load(path) if ResourceLoader.exists(path) else null
	return _texture_cache[type]
