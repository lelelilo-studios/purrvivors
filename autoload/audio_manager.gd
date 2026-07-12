extends Node
## AudioManager - one cohesive audio path: SFX + Music buses, a small
## round-robin player pool with pitch variation (same sample never sounds
## twice-identical), and music crossfade. Missing files fail silently so
## gameplay code can call play_sfx() before the audio phase lands assets.

const SFX_DIR := "res://assets/audio/sfx"
const SFX_PLAYERS := 10

var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_player: AudioStreamPlayer
var _music_fade_tween: Tween


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)
	# Every Button in the game gets click + hover sounds automatically.
	# Skip flat buttons (invisible hotspots) and Cards (they voice themselves).
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Button and not node.flat and node.theme_type_variation != &"Card":
		node.pressed.connect(play_sfx.bind("click", 0.1, -6.0))
		node.mouse_entered.connect(play_sfx.bind("hover", 0.1, -14.0))


func play_sfx(name: String, pitch_variation := 0.08, volume_db := 0.0) -> void:
	var stream := _stream_for(name)
	if stream == null:
		return
	var p := _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	p.stream = stream
	p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	p.volume_db = volume_db
	p.play()


func play_music(path: String, fade_sec := 0.8) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if _music_player.stream == stream and _music_player.playing:
		return
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null
	if _music_player.playing:
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_sec)
		_music_fade_tween.tween_callback(_swap_music.bind(stream, fade_sec))
	else:
		_swap_music(stream, fade_sec)


func stop_music(fade_sec := 0.8) -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_sec)
	_music_fade_tween.tween_callback(_music_player.stop)


func _swap_music(stream: AudioStream, fade_sec: float) -> void:
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var t := create_tween()
	t.tween_property(_music_player, "volume_db", 0.0, fade_sec)


func _stream_for(name: String) -> AudioStream:
	if _sfx_streams.has(name):
		return _sfx_streams[name]
	var stream: AudioStream = null
	for ext in ["wav", "ogg"]:
		var path := "%s/%s.%s" % [SFX_DIR, name, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_sfx_streams[name] = stream   # cache nulls too: missing stays quiet
	return stream


func _ensure_bus(name: String) -> void:
	if AudioServer.get_bus_index(name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
