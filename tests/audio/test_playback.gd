extends SceneTree
const Director = preload("res://scripts/progression/audio_director.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Playback test needs graphical/audio session")
		quit(1)
		return
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	var mixer := Director.new()
	root.add_child(mixer)
	for id: String in Director.THEMES:
		mixer.play_theme(id)
		await create_timer(0.9).timeout
		check(mixer.players[id].playing, "actual playback " + id)
		# Cross the actual stereo loop boundary, rather than waiting 40 seconds per track.
		mixer.players[id].seek(mixer.players[id].stream.get_length() - 0.2)
		await create_timer(0.45).timeout
		check(mixer.players[id].playing and mixer.players[id].get_playback_position() < 1.0, "actual loop wrap " + id)
	mixer.cue("capture")
	mixer.cue("navigate")
	check(mixer.outcome.playing and mixer.ui.playing, "concurrent jingle and UI")
	await create_timer(0.25).timeout
	mixer.apply({"music": 0, "sfx": 0})
	var paused: float = mixer.players.guardian.get_playback_position()
	await create_timer(0.3).timeout
	check(mixer.players.guardian.stream_paused and absf(mixer.players.guardian.get_playback_position() - paused) < 0.02, "real mute pause")
	mixer.apply({"music": 2, "sfx": 2})
	await create_timer(0.35).timeout
	check(mixer.players.guardian.playing and mixer.players.guardian.get_playback_position() > paused, "real unmute resume")
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	DirAccess.make_dir_recursive_absolute("res://.godot/audio_validation")
	check(recording.save_to_wav("res://.godot/audio_validation/mix_preview.wav") == OK, "record actual output")
	var pcm := recording.data
	var peak := 0
	for i in range(0, pcm.size(), 2): peak = maxi(peak, absi(pcm.decode_s16(i)))
	check(recording.get_length() > 7.0 and peak > 100 and peak < 30000, "non silent unclipped output")
	mixer.free()
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	await process_frame
	print("AUDIO PLAYBACK: %s assertions, %s failures; .godot/audio_validation/mix_preview.wav" % [checks, failures])
	quit(1 if failures else 0)
