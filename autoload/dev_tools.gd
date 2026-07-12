extends Node
## DevTools - the debug/balance mode the spec requires, plus a headless
## screenshot hook for automated visual checks.
##
## CLI:  godot -- --screenshot=/abs/path.png [--shot-delay=3.0]
## Keys (debug builds only):
##   F1 god mode  |  F2 +60s run time  |  F3 kill all on screen
##   F4 +200 Fish Coins  |  F5 +1 level  |  F6 spawn next boss (phase 7)

var god_mode := false
var auto_pick := false

var _screenshot_path := ""


func _ready() -> void:
	var delay := 2.5
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-delay="):
			delay = float(arg.get_slice("=", 1))
		elif arg == "--god":
			god_mode = true
		elif arg == "--auto-pick":
			auto_pick = true
		elif arg == "--perf-log":
			var timer := Timer.new()
			timer.wait_time = 5.0
			timer.autostart = true
			timer.timeout.connect(func() -> void:
				var arena := get_tree().get_first_node_in_group(&"arena") as Arena
				if arena == null:
					return
				print("[perf] fps=%d enemies=%d snacks=%d director_us=%d snacks_us=%d fx=%d proj=%d" % [
					Engine.get_frames_per_second(), arena.active_enemies.size(),
					arena.active_snacks.size(), arena.perf_director_us,
					arena.perf_snacks_us, arena.fx_container.get_child_count(),
					arena.projectile_container.get_child_count()]))
			add_child(timer)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
			get_tree().create_timer(delay, true, false, true).timeout.connect(_take_screenshot)
		elif arg.begins_with("--start-time="):
			# Fires after --quick-start's arena spawn (which resets run_time).
			var t := float(arg.get_slice("=", 1))
			get_tree().create_timer(1.4).timeout.connect(
				func() -> void: GameData.run_time = t)
		elif arg.begins_with("--grant-xp="):
			var xp := int(arg.get_slice("=", 1))
			get_tree().create_timer(1.5).timeout.connect(
				func() -> void: GameData.gain_xp(xp))
		elif arg == "--quick-start":
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				var main := get_tree().current_scene as Main
				if main != null:
					main._start_run(GameData.meta.selected_cat))
		elif arg.begins_with("--boss="):
			var idx := int(arg.get_slice("=", 1))
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				var arena := get_tree().get_first_node_in_group(&"arena") as Arena
				if arena != null:
					arena.spawn_boss(idx)
					arena.next_boss_index = idx + 1)
		elif arg.begins_with("--all-weapons="):
			var lvl := int(arg.get_slice("=", 1))
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				var arena := get_tree().get_first_node_in_group(&"arena") as Arena
				if arena == null:
					return
				for id: String in Balance.WEAPONS:
					arena.player.weapons.add_weapon(id)
					for i in lvl - 1:
						arena.player.weapons.level_up_weapon(id)
				print("[dev] all weapons at level ", lvl))


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				god_mode = not god_mode
				print("[dev] god mode: ", god_mode)
			KEY_F2:
				GameData.run_time += 60.0
				print("[dev] run time -> %.0fs" % GameData.run_time)
			KEY_F3:
				_kill_all()
			KEY_F4:
				GameData.add_run_coins(200)
			KEY_F5:
				GameData.gain_xp(Balance.xp_to_next(GameData.level))
			KEY_F6:
				var arena := get_tree().get_first_node_in_group(&"arena") as Arena
				if arena != null and arena.next_boss_index < 3:
					arena.spawn_boss(arena.next_boss_index)
					arena.next_boss_index += 1


func _kill_all() -> void:
	var arena := get_tree().get_first_node_in_group(&"arena") as Arena
	if arena == null:
		return
	for enemy: Enemy in arena.active_enemies.duplicate():
		arena.damage_enemy(enemy, 99999.0)


func _take_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_screenshot_path)
	var arena := get_tree().get_first_node_in_group(&"arena") as Arena
	var enemies := arena.active_enemies.size() if arena != null else -1
	print("screenshot -> %s (err=%d) fps=%d enemies=%d" % [
		_screenshot_path, err, Engine.get_frames_per_second(), enemies])
	get_tree().quit()
