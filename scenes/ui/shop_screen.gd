extends Control
## The Cat Café - permanent upgrades bought with Fish Coins. Costs escalate
## per tier (Balance.shop_cost); pips show owned tiers.

signal back_pressed

@onready var grid: GridContainer = %Grid
@onready var coins_label: Label = %CoinsLabel


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void: back_pressed.emit())


func refresh() -> void:
	coins_label.text = "%d Fish Coins" % GameData.meta.coins
	for child in grid.get_children():
		child.queue_free()
	for upgrade_id: String in Balance.SHOP_UPGRADES:
		grid.add_child(_build_item(upgrade_id))


func _build_item(upgrade_id: String) -> PanelContainer:
	var def: Dictionary = Balance.SHOP_UPGRADES[upgrade_id]
	var tier := GameData.upgrade_tier(upgrade_id)
	var maxed := tier >= int(def.max_tiers)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 4)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 8)
	vbox.add_child(header)
	if def.has("icon") and ResourceLoader.exists(def.icon):
		var icon := TextureRect.new()
		icon.texture = load(def.icon)
		icon.custom_minimum_size = Vector2(28, 28)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		header.add_child(icon)
	var title := Label.new()
	title.text = def.display_name
	header.add_child(title)

	var flavor := Label.new()
	flavor.text = def.flavor
	flavor.modulate.a = 0.65
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(flavor)

	var pips := Label.new()
	var filled := ""
	for i in int(def.max_tiers):
		filled += "#" if i < tier else "-"
	pips.text = filled
	pips.modulate.a = 0.85
	vbox.add_child(pips)

	var buy := Button.new()
	if maxed:
		buy.text = "MAXED. Magnificent."
		buy.disabled = true
	else:
		var cost := Balance.shop_cost(upgrade_id, tier)
		buy.text = "Buy - %d coins" % cost
		buy.disabled = not GameData.can_afford_upgrade(upgrade_id)
		buy.pressed.connect(func() -> void:
			if GameData.buy_upgrade(upgrade_id):
				AudioManager.play_sfx("coin")
				refresh())
	vbox.add_child(buy)
	return panel
