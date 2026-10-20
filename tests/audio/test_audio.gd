extends SceneTree
const Recipes = preload("res://tools/audio/score_recipes.gd")
const Director = preload("res://scripts/progression/audio_director.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var folder := "res://.godot/audio_validation/repeat"
	var recipes := Recipes.new()
	var generated := recipes.generate(folder)
	var baked: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/audio/manifest.json"))
	check(FileAccess.get_file_as_bytes(folder + "/manifest.json") == FileAccess.get_file_as_bytes("res://assets/generated/audio/manifest.json"), "deterministic manifest")
	for group: String in ["tracks", "effects"]:
		for id: String in generated[group]:
			var bytes := FileAccess.get_file_as_bytes(folder + "/" + id + ".wav")
			check(bytes == FileAccess.get_file_as_bytes("res://assets/generated/audio/" + id + ".wav"), "byte repeat " + id)
			var wave: AudioStreamWAV = load("res://assets/generated/audio/" + id + ".wav")
			check(wave.stereo and wave.mix_rate == 22050 and wave.format == AudioStreamWAV.FORMAT_16_BITS, "stereo PCM " + id)
			var meta: Dictionary = baked[group][id]
			check(absf(wave.get_length() - float(meta.seconds)) < 0.001, "duration " + id)
			check(float(meta.rms) > 0.025 and float(meta.rms) < 0.3, "RMS headroom " + id)
			var pcm := wave.data
			var peak := 0
			var difference := 0.0
			var max_jump := 0
			var previous := pcm.decode_s16(pcm.size() - 4)
			var silent := 0
			var longest_silent := 0
			for i in range(0, pcm.size(), 4):
				var l := pcm.decode_s16(i)
				var r := pcm.decode_s16(i + 2)
				peak = maxi(peak, maxi(absi(l), absi(r)))
				difference += absf(l - r)
				max_jump = maxi(max_jump, absi(l - previous))
				previous = l
				silent = silent + 1 if absi(l) + absi(r) < 20 else 0
				longest_silent = maxi(longest_silent, silent)
			check(peak > 19000 and peak < 21000, "normalized no clipping " + id)
			if group == "tracks":
				check(wave.get_length() >= 26.0 and wave.get_length() <= 49.0, "long-form arrangement " + id)
				check(difference / (pcm.size() / 4) > 100.0, "real stereo " + id)
				var seam := absi(pcm.decode_s16(0) - pcm.decode_s16(pcm.size() - 4))
				check(seam <= max_jump and seam < 2500, "bounded loop seam " + id)
				check(longest_silent < 2205, "no silent holes " + id)
	var mixer := Director.new()
	root.add_child(mixer)
	mixer.set_process(false)
	mixer.play_theme("forest")
	mixer.advance(0.8)
	check(mixer.weights.forest == 1.0, "fade in")
	mixer.advance(6.0)
	var position: float = mixer.positions.forest
	mixer.play_theme("battle")
	mixer.advance(0.4)
	check(is_equal_approx(mixer.weights.forest, 0.5) and is_equal_approx(mixer.weights.battle, 0.5), "overlapping fade")
	mixer.advance(0.4)
	check(mixer.weights.forest == 0.0 and mixer.weights.battle == 1.0, "fade completes")
	var saved: float = mixer.positions.forest
	mixer.play_theme("forest")
	mixer.advance(0.8)
	check(mixer.positions.forest > saved and saved > position, "resume exploration after battle")
	var before: float = mixer.positions.forest
	mixer.play_theme("forest")
	check(mixer.positions.forest == before, "same theme idempotent")
	mixer.apply({"music": 0, "sfx": 2})
	mixer.advance(3.0)
	check(mixer.positions.forest == before and mixer.players.forest.volume_linear == 0.0, "mute freezes playback")
	mixer.cue("victory")
	var jingle: AudioStream = mixer.outcome.stream
	mixer.cue("confirm")
	check(mixer.outcome.stream == jingle and mixer.ui.stream != jingle, "UI cannot steal jingle")
	mixer.advance(0.1)
	check(mixer.duck_gain < 1.0, "outcome ducks music")
	mixer.apply({"music": 2, "sfx": 0})
	mixer.advance(1.0)
	check(mixer.duck_gain == 1.0 and mixer.positions.forest > before, "unmute resume and silent effects release duck")
	for id: String in Director.THEMES:
		mixer.play_theme(id)
		mixer.advance(0.1)
	mixer.advance(0.8)
	var sum := 0.0
	for value: float in mixer.weights.values(): sum += value
	check(is_equal_approx(sum, 1.0) and mixer.weights.guardian == 1.0, "rapid transitions settle without stuck voices")
	for player: AudioStreamPlayer in mixer.players.values():
		check(player.stream.loop_end == player.stream.data.size() / 4, "stereo loop frame bounds")
	mixer.free()
	print("AUDIO TESTS: %s assertions, %s failures" % [checks, failures])
	quit(1 if failures else 0)
