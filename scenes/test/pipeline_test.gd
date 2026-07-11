extends Node2D
## Asset-pipeline test scene (build-order step 2).
## Proves the full PixelLab -> Godot chain before the big asset batch:
## crisp nearest-neighbor import, 8-direction sprite mapping, the global
## theme + pixel font, and viewport-driven integer camera zoom.
## WASD / arrows walk Tabby around. The button cycles zoom to eyeball
## crispness at 1x / 2x / 3x.
##
## Run `godot -- --screenshot=/abs/path.png` to auto-capture and quit.

const BASE_VIEW := Vector2(640.0, 360.0)  # target visible world slice
const CAT_SPEED := 90.0
const DOG_TURN_INTERVAL := 0.6

# Index = round(angle / 45 deg); Godot 2D angles: 0 = east, positive = clockwise (south).
const DIR_NAMES: Array[String] = [
	"east", "south-east", "south", "south-west",
	"west", "north-west", "north", "north-east",
]

const CAT_TEXTURES := {
	"south": preload("res://assets/sprites/cats/tabby/south.png"),
	"south-east": preload("res://assets/sprites/cats/tabby/south-east.png"),
	"east": preload("res://assets/sprites/cats/tabby/east.png"),
	"north-east": preload("res://assets/sprites/cats/tabby/north-east.png"),
	"north": preload("res://assets/sprites/cats/tabby/north.png"),
	"north-west": preload("res://assets/sprites/cats/tabby/north-west.png"),
	"west": preload("res://assets/sprites/cats/tabby/west.png"),
	"south-west": preload("res://assets/sprites/cats/tabby/south-west.png"),
}

const DOG_TEXTURES := {
	"south": preload("res://assets/sprites/enemies/dog/south.png"),
	"south-east": preload("res://assets/sprites/enemies/dog/south-east.png"),
	"east": preload("res://assets/sprites/enemies/dog/east.png"),
	"north-east": preload("res://assets/sprites/enemies/dog/north-east.png"),
	"north": preload("res://assets/sprites/enemies/dog/north.png"),
	"north-west": preload("res://assets/sprites/enemies/dog/north-west.png"),
	"west": preload("res://assets/sprites/enemies/dog/west.png"),
	"south-west": preload("res://assets/sprites/enemies/dog/south-west.png"),
}

const COOKIE_TEXTURE := preload("res://assets/sprites/snacks/cookie.png")

@onready var _camera: Camera2D = $Camera
@onready var _cat: Sprite2D = $Cat
@onready var _dog: Sprite2D = $Dog
@onready var _cookie: Sprite2D = $Cookie
@onready var _info: Label = $UI/Margin/Panel/VBox/Info
@onready var _zoom_button: Button = $UI/Margin/Panel/VBox/ZoomButton

var _zoom_override := 0  # 0 = auto, otherwise fixed 1x/2x/3x
var _dog_dir_index := 2  # south
var _dog_turn_timer := 0.0
var _screenshot_path := ""


func _ready() -> void:
	_cat.texture = CAT_TEXTURES["south"]
	_dog.texture = DOG_TEXTURES["south"]
	_cookie.texture = COOKIE_TEXTURE
	_zoom_button.pressed.connect(_on_zoom_button_pressed)
	get_viewport().size_changed.connect(_update_zoom)
	_update_zoom()

	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
			get_tree().create_timer(1.0).timeout.connect(_take_screenshot)
		elif arg == "--fonttest":
			_build_font_test()


## Renders a ladder of font sizes so we can pick ones that sit cleanly on
## Pixelify Sans's native pixel grid (wrong sizes garble glyphs).
func _build_font_test() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	for size: int in [8, 9, 10, 11, 12, 16, 18, 20, 22, 24, 27, 32]:
		var label := Label.new()
		label.text = "%d: Purrvivors 0123456789 zoom 2x vw" % size
		label.add_theme_font_size_override(&"font_size", size)
		vbox.add_child(label)
	$UI.add_child(panel)


func _process(delta: float) -> void:
	# Cat: steer with the adaptive input actions, face movement direction.
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move != Vector2.ZERO:
		_cat.position += move * CAT_SPEED * delta
		_cat.texture = CAT_TEXTURES[_direction_name(move)]

	# Dog: idly show off all 8 rotations.
	_dog_turn_timer += delta
	if _dog_turn_timer >= DOG_TURN_INTERVAL:
		_dog_turn_timer = 0.0
		_dog_dir_index = (_dog_dir_index + 1) % DIR_NAMES.size()
		_dog.texture = DOG_TEXTURES[DIR_NAMES[_dog_dir_index]]

	var vp := get_viewport_rect().size
	_info.text = "viewport %d x %d  |  zoom %dx  |  %d fps" % [
		int(vp.x), int(vp.y), int(_camera.zoom.x), Engine.get_frames_per_second(),
	]


func _direction_name(velocity: Vector2) -> String:
	var index := wrapi(roundi(velocity.angle() / (TAU / 8.0)), 0, 8)
	return DIR_NAMES[index]


func _update_zoom() -> void:
	# Integer zoom keeps pixels square and crisp; auto mode picks the largest
	# integer that still shows at least BASE_VIEW of the world.
	var z: int
	if _zoom_override > 0:
		z = _zoom_override
	else:
		var vp := get_viewport_rect().size
		z = maxi(1, floori(minf(vp.x / BASE_VIEW.x, vp.y / BASE_VIEW.y)))
	_camera.zoom = Vector2(z, z)


func _on_zoom_button_pressed() -> void:
	_zoom_override = (_zoom_override + 1) % 4
	_update_zoom()
	var label := "auto" if _zoom_override == 0 else "%dx fixed" % _zoom_override
	_zoom_button.text = "Zoom: %s" % label


func _take_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_screenshot_path)
	print("screenshot -> %s (err=%d)" % [_screenshot_path, err])
	get_tree().quit()
