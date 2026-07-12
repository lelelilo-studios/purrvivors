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
	if ResourceLoader.exists(LOGO_PATH):
		logo_image.texture = load(LOGO_PATH)
		logo_text.hide()
	else:
		logo_image.hide()
	_start_logo_bob()


func refresh() -> void:
	coins_label.text = "%d Fish Coins in the jar" % GameData.meta.coins


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
