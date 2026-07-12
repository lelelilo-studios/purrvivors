extends WeaponBase
## Red Dot of Doom - dots orbit the cat and zap whatever they touch.
## Unaimed, dependable, hypnotic.

const TEXTURE_PATH := "res://assets/sprites/fx/laser_dot.png"

var _dots: Array[Sprite2D] = []
var _orbit_angle := 0.0
var _tick_left := 0.0


func _on_refresh() -> void:
	var s := stats()
	var count := int(s.count)
	while _dots.size() < count:
		var dot := Sprite2D.new()
		if ResourceLoader.exists(TEXTURE_PATH):
			dot.texture = load(TEXTURE_PATH)
		add_child(dot)
		_dots.append(dot)
	while _dots.size() > count:
		_dots.pop_back().queue_free()


func _process(delta: float) -> void:
	var s := stats()
	_orbit_angle += float(s.orbit_speed) * delta
	var count := _dots.size()
	for i in count:
		var angle := _orbit_angle + TAU * i / count
		_dots[i].position = Vector2.from_angle(angle) * float(s.orbit_radius)
		# A little pulse keeps the dot alive-looking.
		_dots[i].scale = Vector2.ONE * (0.85 + 0.15 * sin(_orbit_angle * 5.0 + i))

	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = float(s.tick)
	var zapped := false
	for dot in _dots:
		for enemy in arena().enemy_grid.query_radius(dot.global_position, float(s.dot_radius)):
			arena().damage_enemy(enemy, damage(), Vector2.ZERO)
			zapped = true
	if zapped:
		AudioManager.play_sfx("laser", 0.2, -10.0)
