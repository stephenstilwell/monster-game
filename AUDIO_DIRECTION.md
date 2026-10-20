# Lanternwild audio direction

Original, warm handheld-inspired synthesis with a woodland character: rounded pulse/flute leads, plucked bell accompaniment, triangle-like bass and quiet synthesized percussion. No borrowed melodies, samples, external services or runtime generation. The current audio pass is separately authorized polish after M6; M7 remains unstarted.

| Context / title | Tempo | Loop | Character |
| --- | --- | --- | --- |
| Sanctuary / Lanterns at Home | 96 BPM | 40 s | Major-key welcome, soft lead and answering phrases |
| Forest / Thread Through the Leaves | 108 BPM | 35.56 s | Airy minor/modal flute and stepping accompaniment |
| Camp and settlement / Embers Rest | 80 BPM | 48 s | Unhurried plucked lead; no percussion |
| Wild battle / Bramble Dance | 132 BPM | 29.09 s | Shorter melodic rhythms, stronger kick/snare pulse |
| Guardian / Beneath the Old Roots | 144 BPM | 26.67 s | Lower minor register and urgent rhythmic lead |

Each theme has sixteen 4/4 bars: related call/answer phrases, a lifted bridge with an additional sustained voice, and a return. Chord thirds follow the major/minor palette. Melodies and chord sequences live in tools/audio/score_recipes.gd. This is a compact synthesized score, not an orchestral soundtrack or a new content milestone.

## Reproducible pipeline

Run tools/audio/generate_score.gd in headless Godot, then editor import. Seed 842032 supplies an independent percussion noise table; no global/game RNG is used. Oscillator tables, attack/release envelopes, panning and quiet wraparound stereo echoes render offline to five music WAVs and eight effects. assets/generated/audio/manifest.json records version audio.1, sample frames, tempo, bars, duration, RMS and PCM SHA-256. All assets are stereo, 22,050 Hz, 16-bit PCM, normalized to a 0.62 peak for headroom. Lossless compress/mode=0 import sidecars are part of the asset contract; do not restore Godot's default QOA compression while using PCM frame counts. No trimming or normalization on import.

The earlier tools/art/progression_recipes.gd mono score remains a historical M6 foundation fixture; the default app uses the new audio directory exclusively. Regenerating M6 art cannot replace the new score.

## Runtime mix

Scene-local audio_director.gd owns five music players and independent UI, combat and outcome effect voices. Themes crossfade over 0.8 seconds and resume their previous positions within the current session. Stereo loops use sample frames (PCM byte count divided by four). Returning from a battle continues exploration instead of restarting its first phrase. Camp and settlement share the restful theme; Continue enters the pending battle directly. Rapid context changes settle all old voices to silence.

The existing saved music/SFX settings remain independent: mute and three levels. Music mute pauses musical time; unmute resumes. SFX mute stops effects and releases ducking. Capture, growth, victory and defeat jingles temporarily reduce music to 42% of its selected gain. Navigation/back/confirm effects cannot interrupt these jingles. Outcomes retain the existing successful-result-checkpoint timing; retrying a failed save does not announce success early. Two hit events in one turn have distinct presentation keys.

## Acceptance and review

The audio suite regenerates and byte-compares every asset/manifest; checks stereo PCM, length, peak/RMS, stereo separation, bounded loop seams and absent long silent gaps; exercises fades, resume, mute, ducking and rapid context changes. Current app flow checks actual sanctuary, field, camp, wild/guardian and settlement selection. Graphical-session playback tests cross real loop boundaries, pause/resume, concurrent effects and record the mixed audio to .godot/audio_validation/mix_preview.wav. Cache-free import runs use committed WAVs and sidecars.

Automated waveform/playback checks establish signal integrity, not musical taste or perceived loudness. Listen for fatigue, repetitive motifs, transition timing, audible seam clicks and balance on headphones and speakers. Crossfades are time-based, not beat-synchronized; track positions are presentation-only and reset on application restart. No environmental ambience, spatial audio, adaptive stems or platform export certification is claimed.