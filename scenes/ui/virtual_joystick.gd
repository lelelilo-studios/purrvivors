extends Control
## Floating virtual joystick: appears where the thumb lands on the lower-left
## half of the screen, feeds InputRouter. Only visible in touch mode.
## Drawn procedurally in palette colors until the UI art pass replaces it.

const RADIUS := 46.0
const DEAD_ZONE := 0.12

var _touch_index := -1
var _origin := Vector2.ZERO
var _vector := Vector2.ZERO


func _ready() -> void:
	visible = InputRouter.touch_mode
	InputRouter.touch_mode_changed.connect(func(on: bool) -> void: visible = on)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_vector = Vector2.ZERO
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var raw: Vector2 = (event.position - _origin) / RADIUS
		_vector = raw.limit_length(1.0)
		if _vector.length() < DEAD_ZONE:
			_vector = Vector2.ZERO
		InputRouter.joystick_vector = _vector
		accept_event()
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_vector = Vector2.ZERO
	InputRouter.joystick_vector = Vector2.ZERO


func _draw() -> void:
	if _touch_index == -1:
		return
	var base := _origin
	draw_circle(base, RADIUS, Color(1.0, 0.96, 0.89, 0.25))
	draw_arc(base, RADIUS, 0, TAU, 40, Color(0.29, 0.2, 0.15, 0.7), 3.0)
	var thumb := base + _vector * RADIUS * 0.7
	draw_circle(thumb, 20.0, Color(0.94, 0.56, 0.29, 0.85))
	draw_arc(thumb, 20.0, 0, TAU, 24, Color(0.29, 0.2, 0.15, 0.9), 3.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_release()
