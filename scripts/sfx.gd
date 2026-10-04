extends Node
## Ses efektleri ve müzik. Sesler tools/make_sounds.py ile üretilir.

const NAMES := ["tap", "good", "bad", "win", "levelup", "coin", "stir", "meow", "whoosh",
		"step", "moo", "cluck", "quack", "woof", "ses_a", "ses_e", "ses_i", "ses_o", "ses_u"]
const POOL := 6

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var music: AudioStreamPlayer
var sound_on := true
var music_on := true


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	for n in NAMES:
		_streams[n] = load("res://assets/sounds/%s.wav" % n)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	music = AudioStreamPlayer.new()
	var m: AudioStreamWAV = load("res://assets/sounds/muzik.wav")
	m.loop_mode = AudioStreamWAV.LOOP_FORWARD
	m.loop_begin = 0
	m.loop_end = int(m.get_length() * m.mix_rate)
	music.stream = m
	music.volume_db = -9.0
	add_child(music)
	sound_on = GameState.settings["sound"]
	music_on = GameState.settings["music"]


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not sound_on or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## Ayara göre müziği başlatır ya da durdurur.
func set_music(on: bool) -> void:
	music_on = on
	if on and not music.playing:
		music.play()
	elif not on:
		music.stop()
