extends Node
var music := AudioStreamPlayer.new()
var effect := AudioStreamPlayer.new()
var theme: String = ""
var settings: Dictionary = {"music": 2, "sfx": 2}
var last_event: String = ""
func _ready() -> void:
	add_child(music)
	add_child(effect)
func apply(next: Dictionary) -> void:
	settings = next.duplicate()
	music.volume_db = [-80.0, -24.0, -18.0, -12.0][int(settings.music)]
	effect.volume_db = [-80.0, -18.0, -12.0, -6.0][int(settings.sfx)]
	music.stream_paused = settings.music == 0
func play_theme(id: String) -> void:
	if theme == id: return
	theme = id
	music.stream = load("res://assets/generated/m6/" + id + ".wav")
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream.loop_begin = 0
	music.stream.loop_end = music.stream.data.size() / 2
	if DisplayServer.get_name() != "headless": music.play()
	music.stream_paused = settings.music == 0
func cue(id: String) -> void:
	if settings.sfx == 0: return
	effect.stream = load("res://assets/generated/m6/" + id + ".wav")
	if DisplayServer.get_name() != "headless": effect.play()

func _exit_tree() -> void:
	music.stop()
	effect.stop()
	music.stream = null
	effect.stream = null
