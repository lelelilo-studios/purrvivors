extends Control
## Cat select: one card per cat, locked cats show their price and unlock in
## place. Best win tier per cat shows off progress.

signal cat_chosen(cat_id: String)
signal back_pressed

@onready var cards_box: HBoxContainer = %Cards
@onready var coins_label: Label = %CoinsLabel


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void: back_pressed.emit())


func refresh() -> void:
	coins_label.text = "%d Fish Coins" % GameData.meta.coins
	for child in cards_box.get_children():
		child.queue_free()
	for cat_id: String in Balance.CATS:
		cards_box.add_child(_build_card(cat_id))


func _build_card(cat_id: String) -> Button:
	var def: Dictionary = Balance.CATS[cat_id]
	var unlocked := GameData.is_cat_unlocked(cat_id)
	var card := Button.new()
	card.theme_type_variation = &"Card"
	card.custom_minimum_size = Vector2(200, 300)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override(&"separation", 4)
	margin.add_child(vbox)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0, 110)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var portrait_path := "%s/south.png" % def.sprite_dir
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	if not unlocked:
		portrait.modulate = Color(0.25, 0.2, 0.18)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(portrait)

	_add_label(vbox, def.display_name if unlocked else "???", 32, 1.0)
	_add_label(vbox, def.tagline, 16, 0.75)
	_add_label(vbox, "HP %d   speed %d" % [def.max_hp, def.move_speed], 16, 0.9)
	_add_label(vbox, "starts with %s" % Balance.WEAPONS[def.starting_weapon].display_name, 16, 0.9)

	var best: Dictionary = GameData.meta.best.get(cat_id, {})
	if not best.is_empty() and int(best.tier) > 0:
		_add_label(vbox, "best: %s" % Balance.WIN_TIER_NAMES[int(best.tier)], 16, 0.9)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	if unlocked:
		card.pressed.connect(func() -> void:
			AudioManager.play_sfx("card_pick")
			cat_chosen.emit(cat_id))
	else:
		var cost := int(def.unlock_cost)
		var afford: bool = GameData.meta.coins >= cost
		_add_label(vbox, "unlock: %d coins" % cost, 16, 1.0 if afford else 0.5)
		card.pressed.connect(func() -> void:
			if GameData.buy_cat(cat_id):
				AudioManager.play_sfx("coin")
				refresh())
	return card


func _add_label(parent: Control, text: String, size: int, alpha: float) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", size)
	label.modulate.a = alpha
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
