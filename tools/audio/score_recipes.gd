extends RefCounted
# Original Lanternwild score. All oscillators and percussion are synthesized offline.
const RATE := 22050
const THEMES := {
	"hub": {"bpm": 96, "root": 60, "chords": [0,5,9,7,0,5,2,7,9,5,0,7,5,7,0,0], "voice": 0},
	"forest": {"bpm": 108, "root": 57, "chords": [0,5,3,7,0,5,10,7,3,10,5,7,0,5,7,0], "voice": 1},
	"camp": {"bpm": 80, "root": 60, "chords": [0,9,5,7,0,5,7,0,9,5,0,7,5,7,0,0], "voice": 2},
	"battle": {"bpm": 132, "root": 57, "chords": [0,0,5,7,0,3,10,7,5,5,0,7,3,10,7,7], "voice": 0},
	"guardian": {"bpm": 144, "root": 50, "chords": [0,0,8,7,0,3,8,7,5,8,0,7,8,5,7,7], "voice": 0}}
const EFFECTS := {"navigate": [76], "back": [67,60], "confirm": [72,79], "capture": [60,64,67,72,79], "victory": [60,64,67,72,76,79,84], "hit": [43,36], "growth": [60,62,64,67,72,76,79], "defeat": [60,55,52,48]}
var left := PackedFloat32Array()
var right := PackedFloat32Array()
var noise := PackedFloat32Array()

func prepare(seconds: float) -> void:
	left.resize(int(round(seconds * RATE)))
	right.resize(left.size())
	left.fill(0.0)
	right.fill(0.0)
	noise.resize(4096)
	var rng := RandomNumberGenerator.new()
	rng.seed = 842032
	for i in range(noise.size()): noise[i] = rng.randf_range(-1.0, 1.0)

func note(at: float, duration: float, pitch: int, gain: float, pan: float, voice: int) -> void:
	var start := int(round(at * RATE))
	var count := int(duration * RATE)
	var frequency := 440.0 * pow(2.0, (pitch - 69.0) / 12.0)
	var table := PackedFloat32Array()
	table.resize(1024)
	for i in range(1024):
		var p := TAU * i / 1024.0
		match voice:
			0: table[i] = (sin(p) + 0.22 * sin(p * 3.0) + 0.08 * sin(p * 5.0)) / 1.3
			1: table[i] = sin(p) * 0.82 + sin(p * 2.0) * 0.14 + sin(p * 3.0) * 0.04
			2: table[i] = sin(p) * 0.72 + sin(p * 3.0) * 0.2 + sin(p * 6.0) * 0.08
			3: table[i] = sin(p) * 0.9 + sin(p * 3.0) * 0.1
	var attack := 0.012 if voice != 1 else 0.035
	for i in range(count):
		var t := float(i) / RATE
		var envelope := minf(t / attack, 1.0) * minf((duration - t) / 0.06, 1.0)
		if voice == 2: envelope *= exp(-4.0 * t / duration)
		var value := table[int(t * frequency * 1024.0) % 1024] * envelope * gain
		var index := (start + i) % left.size()
		left[index] += value * (1.0 - pan * 0.55)
		right[index] += value * (1.0 + pan * 0.55)
		# A quiet wraparound stereo echo, part of the seamless loop render.
		var echo := (index + int(RATE * 0.1875)) % left.size()
		left[echo] += value * 0.08 * (1.0 + pan)
		right[echo] += value * 0.08 * (1.0 - pan)

func drum(at: float, kind: int, gain: float) -> void:
	var duration := 0.15 if kind == 0 else 0.09
	var start := int(round(at * RATE))
	for i in range(int(duration * RATE)):
		var t := float(i) / RATE
		var decay := exp(-t * (28.0 if kind == 0 else 55.0))
		var value := sin(TAU * (65.0 * t + 1.2 * (1.0 - exp(-t * 35.0)))) if kind == 0 else noise[i % noise.size()] - noise[(i + 1) % noise.size()] * 0.65
		var sample_value := value * gain * decay * minf(t / 0.002, 1.0)
		left[(start + i) % left.size()] += sample_value * (0.85 if kind == 2 else 1.0)
		right[(start + i) % left.size()] += sample_value * (1.0 if kind == 2 else 0.9)

func save_wave(path: String, looped: bool) -> Dictionary:
	var peak := 0.0
	for i in range(left.size()): peak = maxf(peak, maxf(absf(left[i]), absf(right[i])))
	var scale := 0.62 / maxf(peak, 0.001)
	var bytes := PackedByteArray()
	bytes.resize(left.size() * 4)
	var square := 0.0
	for i in range(left.size()):
		var l := left[i] * scale
		var r := right[i] * scale
		bytes.encode_s16(i * 4, int(round(l * 32767.0)))
		bytes.encode_s16(i * 4 + 2, int(round(r * 32767.0)))
		square += (l * l + r * r) * 0.5
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.stereo = true
	wave.mix_rate = RATE
	wave.data = bytes
	if looped:
		wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wave.loop_end = left.size()
	assert(wave.save_to_wav(path) == OK)
	return {"frames": left.size(), "rate": RATE, "channels": 2, "seconds": float(left.size()) / RATE, "peak": 0.62, "rms": sqrt(square / left.size()), "loop": looped, "sha256": digest(bytes)}

func theme(id: String, path: String) -> Dictionary:
	var song: Dictionary = THEMES[id]
	var beat := 60.0 / float(song.bpm)
	prepare(64.0 * beat)
	var active := id in ["battle", "guardian"]
	var minor := id != "hub" and id != "camp"
	var motif := [0,7,4,2,0,4,7,9] if not minor else [0,7,3,2,0,3,7,10]
	for bar in range(16):
		var root_note := int(song.root) + int(song.chords[bar])
		var offset := int(song.chords[bar])
		var third := (4 if offset in [3, 8, 10] else 3) if minor else (3 if offset in [2, 9] else 4)
		var chord := [root_note, root_note + third, root_note + 7]
		for step in range(8):
			var time := (bar * 4.0 + step * 0.5) * beat
			note(time, beat * 0.7, int(chord[(step + bar % 2) % 3]) + 12, 0.035 if id == "camp" else 0.048, -0.65, 2)
		for step in range(4):
			note((bar * 4.0 + step) * beat, beat * 0.82, root_note - 24 + (7 if step == 2 else 0), 0.12, 0.0, 3)
			if id != "camp":
				drum((bar * 4.0 + step) * beat, 0 if step % 2 == 0 else 1, 0.1 if active else 0.035)
				drum((bar * 4.0 + step + 0.5) * beat, 2, 0.025 if active else 0.012)
		# Four related phrases: call, answer, lifted bridge, resolved return.
		var phrase := bar / 4
		var offsets := [0.0, 1.5, 2.0, 3.0] if not active else [0.0, 0.75, 1.5, 2.5, 3.0]
		for index in range(offsets.size()):
			if bar % 4 == 3 and index > 1: continue
			var pitch := int(song.root) + 12 + int(motif[(bar * 2 + index + int(phrase)) % motif.size()])
			if phrase == 2: pitch += 12 if index == 0 else 0
			if bar == 15: pitch = int(song.root) + 12
			note((bar * 4.0 + offsets[index]) * beat, beat * (0.6 if active else 1.15), pitch, 0.105 if id != "camp" else 0.085, 0.25, int(song.voice))
		if bar >= 8 and bar <= 11:
			note(bar * 4.0 * beat, beat * 2.8, root_note + 7, 0.028, 0.7, 1)
	var result := save_wave(path, true)
	result.bpm = song.bpm
	result.bars = 16
	return result

func generate(folder: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest := {"version": "audio.1", "seed": 842032, "tracks": {}, "effects": {}}
	for id: String in THEMES: manifest.tracks[id] = theme(id, folder + "/" + id + ".wav")
	for id: String in EFFECTS:
		var beat := 0.055 if id in ["navigate", "hit"] else 0.12
		prepare(EFFECTS[id].size() * beat + 0.4)
		for i in range(EFFECTS[id].size()):
			note(i * beat, beat * 1.6, EFFECTS[id][i], 0.08, 0.0, 2)
		manifest.effects[id] = save_wave(folder + "/" + id + ".wav", false)
	var file := FileAccess.open(folder + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	return manifest

func digest(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	return hash_context.finish().hex_encode()
