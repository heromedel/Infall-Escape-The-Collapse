## Sound effects, synthesized when the game starts so no audio files are needed.
## Call Sounds.play("laser"). Each sound is a short 16-bit mono clip built from simple waves and noise.
extends Node

const MIX_RATE := 22050
const VOICES := 10

var _clips := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _noise_seed := 12345


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_build_clips()


func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if Settings.value("sound") == "Off" or not _clips.has(sound_name):
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _clips[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _build_clips() -> void:
	_clips.click = _make(0.05, func(t, _p): return _square(t, 1400.0) * _fade(t, 0.05) * 0.25)
	_clips.hover = _make(0.03, func(t, _p): return sin(TAU * 2200.0 * t) * _fade(t, 0.03) * 0.12)
	_clips.draw = _make(0.18, func(t, _p): return _noise() * _swell(t, 0.18) * 0.35 * (1.0 - t / 0.18))
	_clips.play = _make(0.22, func(t, _p): return (_noise() * 0.5 + sin(TAU * lerpf(220.0, 90.0, t / 0.22) * t)) * _fade(t, 0.22) * 0.5)
	_clips.power = _make(0.35, func(t, _p): return (sin(TAU * lerpf(300.0, 900.0, t / 0.35) * t) * 0.6 + _square(t, lerpf(150.0, 450.0, t / 0.35)) * 0.15) * _swell(t, 0.35) * 0.45)
	_clips.laser = _make(0.22, func(t, _p): return _square(t, lerpf(1800.0, 300.0, pow(t / 0.22, 0.5))) * _fade(t, 0.22) * 0.32)
	_clips.heavy = _make(0.4, func(t, _p): return (_saw(t, lerpf(500.0, 80.0, t / 0.4)) * 0.5 + _noise() * 0.3) * _fade(t, 0.4) * 0.5)
	_clips.ion = _make(0.45, func(t, _p): return sin(TAU * (600.0 + 300.0 * sin(TAU * 30.0 * t)) * t) * _fade(t, 0.45) * 0.4 + _noise() * 0.08 * _fade(t, 0.45))
	_clips.missile = _make(0.6, func(t, _p): return (_noise() * 0.6 + sin(TAU * lerpf(120.0, 60.0, t / 0.6) * t) * 0.4) * _swell(t, 0.6) * 0.45)
	_clips.beam = _make(0.7, func(t, _p): return (_saw(t, 220.0 + 15.0 * sin(TAU * 8.0 * t)) * 0.35 + sin(TAU * 440.0 * t) * 0.25) * _swell(t, 0.7) * 0.5)
	_clips.explosion = _make(0.7, func(t, _p): return (_brown() * 1.6 + sin(TAU * lerpf(90.0, 30.0, t / 0.7) * t) * 0.6) * _fade(t, 0.7) * 0.6)
	_clips.hull_hit = _make(0.35, func(t, _p): return (_brown() * 1.4 + _square(t, 70.0) * 0.3) * _fade(t, 0.35) * 0.6)
	_clips.shield_hit = _make(0.45, func(t, _p): return (sin(TAU * 880.0 * t) * 0.4 + sin(TAU * 1320.0 * t) * 0.25 + _noise() * 0.15) * _fade(t, 0.45) * 0.45)
	_clips.shield_up = _make(0.5, func(t, _p): return (sin(TAU * lerpf(400.0, 800.0, t / 0.5) * t) * 0.5 + sin(TAU * lerpf(600.0, 1200.0, t / 0.5) * t) * 0.3) * _swell(t, 0.5) * 0.4)
	_clips.miss = _make(0.3, func(t, _p): return _noise() * sin(PI * t / 0.3) * 0.25)
	_clips.repair = _make(0.35, func(t, _p): return _square(t, 520.0 if fmod(t, 0.1) < 0.05 else 780.0) * _fade(t, 0.35) * 0.2)
	_clips.fire = _make(0.6, func(t, _p): return _brown() * (0.6 + 0.4 * sin(TAU * 11.0 * t)) * _swell(t, 0.6) * 0.8)
	_clips.wound = _make(0.2, func(t, _p): return _square(t, lerpf(300.0, 150.0, t / 0.2)) * _fade(t, 0.2) * 0.25)
	_clips.death = _make(0.8, func(t, _p): return sin(TAU * lerpf(500.0, 100.0, t / 0.8) * t) * _fade(t, 0.8) * 0.4)
	_clips.turn = _make(0.4, func(t, _p): return (sin(TAU * 660.0 * t) * (1.0 if t < 0.15 else 0.0) + sin(TAU * 990.0 * t) * (1.0 if t >= 0.15 else 0.0)) * _fade(t, 0.4) * 0.3)
	_clips.error = _make(0.2, func(t, _p): return _square(t, 140.0) * _fade(t, 0.2) * 0.25)
	_clips.cloak = _make(0.7, func(t, _p): return sin(TAU * lerpf(900.0, 200.0, t / 0.7) * t) * _swell(t, 0.7) * 0.35 + _noise() * 0.05)
	_clips.teleport = _make(0.6, func(t, _p): return sin(TAU * (400.0 + 1200.0 * fmod(t * 6.0, 1.0)) * t) * _swell(t, 0.6) * 0.3)
	_clips.hack = _make(0.5, func(t, _p): return _square(t, [440.0, 660.0, 330.0, 880.0][int(t * 16.0) % 4]) * _fade(t, 0.5) * 0.2)
	_clips.jump = _make(1.2, func(t, _p): return sin(TAU * lerpf(80.0, 1400.0, pow(t / 1.2, 2.0)) * t) * _swell(t, 1.2) * 0.45)
	_clips.victory = _make(1.4, func(t, _p): return _chord(t, [523.25, 659.25, 783.99, 1046.5], 1.4))
	_clips.defeat = _make(1.6, func(t, _p): return _chord(t, [392.0, 311.13, 261.63, 196.0], 1.6))


## Builds a clip by sampling the generator function at every sample time.
func _make(seconds: float, generator: Callable) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var value := clampf(generator.call(t, float(i) / count), -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _fade(t: float, length: float) -> float:
	return pow(maxf(0.0, 1.0 - t / length), 2.0)


func _swell(t: float, length: float) -> float:
	var attack := minf(1.0, t / (length * 0.15))
	return attack * _fade(t, length) * 1.6


func _square(t: float, frequency: float) -> float:
	return 1.0 if fmod(t * frequency, 1.0) < 0.5 else -1.0


func _saw(t: float, frequency: float) -> float:
	return fmod(t * frequency, 1.0) * 2.0 - 1.0


func _noise() -> float:
	_noise_seed = (_noise_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_noise_seed) / 0x3fffffff - 1.0


var _brown_value := 0.0
func _brown() -> float:
	_brown_value = clampf(_brown_value + _noise() * 0.12, -1.0, 1.0)
	return _brown_value


## A rising arpeggio that rings into a chord.
func _chord(t: float, notes: Array, length: float) -> float:
	var value := 0.0
	for i in notes.size():
		var start := i * 0.12
		if t >= start:
			var local := t - start
			value += sin(TAU * notes[i] * local) * exp(-local * 2.2) * 0.22
	return value * minf(1.0, (length - t) * 4.0)
