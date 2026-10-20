extends Node
# Scene-local mixer; presentation state never enters saves or gameplay RNG.
const THEMES := ["hub", "forest", "camp", "battle", "guardian"]
const OUTCOMES := ["capture", "victory", "growth", "defeat"]
const FADE_SECONDS := 0.8
var players: Dictionary = {}
var weights: Dictionary = {}
var positions: Dictionary = {}
var ui := AudioStreamPlayer.new()
var action := AudioStreamPlayer.new()
var outcome := AudioStreamPlayer.new()
var theme: String = ""
var settings: Dictionary = {"music": 2, "sfx": 2}
var last_event: String = ""
var duck_remaining := 0.0
var duck_gain := 1.0
var audible := false

func _ready() -> void:
	audible = DisplayServer.get_name() != "headless"
	for id: String in THEMES:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/generated/audio/" + id + ".wav")
		player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		player.stream.loop_begin = 0
		# Stereo 16-bit frames, not the number of individual channel samples.
		player.stream.loop_end = player.stream.data.size() / 4
		add_child(player)
		players[id] = player
		weights[id] = 0.0
		positions[id] = 0.0
	for player: AudioStreamPlayer in [ui, action, outcome]: add_child(player)
	apply(settings)

func apply(next: Dictionary) -> void:
	settings = {"music": clampi(int(next.get("music", 2)), 0, 3), "sfx": clampi(int(next.get("sfx", 2)), 0, 3)}
	for player: AudioStreamPlayer in players.values(): player.stream_paused = settings.music == 0
	for player: AudioStreamPlayer in [ui, action, outcome]:
		player.volume_db = [-80.0, -22.0, -16.0, -10.0][settings.sfx]
		if settings.sfx == 0: player.stop()
	if settings.sfx == 0: duck_remaining = 0.0
	update_mix()

func play_theme(id: String) -> void:
	if not players.has(id) or theme == id: return
	theme = id
	var player: AudioStreamPlayer = players[id]
	if audible and not player.playing:
		player.play(float(positions[id]))
		player.stream_paused = settings.music == 0

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	duck_remaining = maxf(0.0, duck_remaining - delta)
	duck_gain = move_toward(duck_gain, 0.42 if duck_remaining > 0.0 else 1.0, delta * 3.0)
	if settings.music != 0:
		for id: String in THEMES:
			var player: AudioStreamPlayer = players[id]
			var previous: float = weights[id]
			weights[id] = move_toward(previous, 1.0 if id == theme else 0.0, delta / FADE_SECONDS)
			if previous > 0.0 or id == theme:
				positions[id] = fmod(float(positions[id]) + delta, player.stream.get_length())
			if id != theme and weights[id] == 0.0 and player.playing:
				positions[id] = player.get_playback_position()
				player.stop()
	update_mix()

func update_mix() -> void:
	for id: String in players:
		players[id].volume_linear = [0.0, 0.20, 0.36, 0.60][settings.music] * float(weights[id]) * duck_gain

func cue(id: String) -> void:
	if settings.sfx == 0 or not id in ["navigate", "back", "confirm", "hit", "capture", "victory", "growth", "defeat"]: return
	var player := outcome if id in OUTCOMES else action if id == "hit" else ui
	player.stream = load("res://assets/generated/audio/" + id + ".wav")
	if id in OUTCOMES: duck_remaining = player.stream.get_length()
	if audible: player.play()

func _exit_tree() -> void:
	for player: AudioStreamPlayer in players.values() + [ui, action, outcome]:
		player.stop()
		player.stream = null
