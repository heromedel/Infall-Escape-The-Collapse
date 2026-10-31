extends Node
## Sfx (autoload): plays the game's sound effects by name from audio/, a few at a time, with a little pitch
## variation so repeated shots don't sound identical; and the music, cross-fading between tracks. All the
## sounds are made by tools/make_audio.py.

const VOICES := 12
const MUSIC_FADE := 2.0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_a := AudioStreamPlayer.new()
var _music_b := AudioStreamPlayer.new()
var _music_track := ""
var _last_played: Dictionary = {}    # name -> time, so a burst of the same sound doesn't stack into noise


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	add_child(_music_a)
	add_child(_music_b)
	_music_a.volume_db = -80.0
	_music_b.volume_db = -80.0
	apply_volumes()


func _stream(sound: String) -> AudioStream:
	if _streams.has(sound):
		return _streams[sound]
	var stream: AudioStream = null
	for extension in [".wav", ".ogg"]:
		var path: String = "res://audio/" + sound + extension
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_streams[sound] = stream
	return stream


func play(sound: String, volume_db: float = 0.0) -> void:
	var stream := _stream(sound)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -1000)) < 35:
		return
	_last_played[sound] = now
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db + _effects_db()
	player.pitch_scale = randf_range(0.94, 1.06) if sound not in ["click", "select", "pause", "unpause"] else 1.0
	player.play()


func play_music(track: String) -> void:
	if track == _music_track:
		return
	_music_track = track
	var stream := _stream("music_" + track)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var incoming := _music_b if _music_a.playing and _music_a.volume_db > -60.0 else _music_a
	var outgoing := _music_a if incoming == _music_b else _music_b
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", _music_db(), MUSIC_FADE)
	tween.tween_property(outgoing, "volume_db", -80.0, MUSIC_FADE)
	tween.chain().tween_callback(outgoing.stop)


func _effects_db() -> float:
	return linear_to_db(maxf(0.001, float(Settings.get_value("effects_volume", 0.8)))) - 4.0


func _music_db() -> float:
	return linear_to_db(maxf(0.001, float(Settings.get_value("music_volume", 0.6)))) - 8.0


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(Settings.get_value("master_volume", 0.8)))))
	for player in [_music_a, _music_b]:
		if player.playing and player.volume_db > -60.0:
			player.volume_db = _music_db()
