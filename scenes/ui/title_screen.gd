extends Control
## Title screen. The illustrated background + logo art land in the UI asset
## pass; until then the text logo carries the identity.

signal play_pressed
signal shop_pressed

const BG_PATH := "res://assets/sprites/ui/title_background.png"
const LOGO_PATH := "res://assets/sprites/ui/logo.png"

@onready var background: TextureRect = %Background
@onready var logo_image: TextureRect = %LogoImage
@onready var logo_text: Label = %LogoText
@onready var coins_label: Label = %CoinsLabel

var _logo_tween: Tween


func _ready() -> void:
	%PlayButton.pressed.connect(func() -> void: play_pressed.emit())
	%ShopButton.pressed.connect(func() -> void: shop_pressed.emit())
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())
	if OS.has_feature("web"):
		%QuitButton.hide()   # browsers do not appreciate quit()
	if ResourceLoader.exists(BG_PATH):
		background.texture = load(BG_PATH)
		_add_secret_cat_pet()
	if ResourceLoader.exists(LOGO_PATH):
		logo_image.texture = load(LOGO_PATH)
		logo_text.hide()
	else:
		logo_image.hide()
	_start_logo_bob()


func refresh() -> void:
	coins_label.text = "%d Fish Coins in the jar" % GameData.meta.coins


## Small delight: pet the title cat, get a meow. Nobody needs to know.
func _add_secret_cat_pet() -> void:
	var pet_zone := Button.new()
	pet_zone.flat = true
	pet_zone.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	pet_zone.add_theme_stylebox_override(&"hover", StyleBoxEmpty.new())
	pet_zone.add_theme_stylebox_override(&"pressed", StyleBoxEmpty.new())
	pet_zone.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	pet_zone.set_anchors_preset(Control.PRESET_CENTER)
	pet_zone.custom_minimum_size = Vector2(220, 280)
	pet_zone.position = Vector2(-110, -140)
	pet_zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pet_zone.pressed.connect(func() -> void:
		AudioManager.play_sfx("meow", 0.2)
		var t := create_tween()
		background.pivot_offset = background.size / 2.0
		t.tween_property(background, "scale", Vector2.ONE * 1.01, 0.08)
		t.tween_property(background, "scale", Vector2.ONE, 0.12))
	add_child(pet_zone)
	move_child(pet_zone, background.get_index() + 1)


func _start_logo_bob() -> void:
	# Gentle breathing pulse - the menu should never feel frozen.
	# (Scale, not position: these live in containers that own their layout.)
	var target: Control = logo_image if logo_image.texture != null else logo_text
	await get_tree().process_frame
	target.pivot_offset = target.size / 2.0
	_logo_tween = create_tween().set_loops()
	_logo_tween.tween_property(target, "scale", Vector2.ONE * 1.035, 1.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_logo_tween.tween_property(target, "scale", Vector2.ONE, 1.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
