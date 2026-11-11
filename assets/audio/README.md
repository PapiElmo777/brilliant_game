# Brilliant — original voiceless audio

All WAVs in this directory are original procedural synthesis, derived from the
first Brilliant galactic audio mockup approved by Alfredo (2026-11-11).
No speech, external recordings, sampled instruments or third-party music.
No Kenney samples were needed in this implementation.

Rebuild: `python3 tool/generate_audio.py` (Python standard library).
The generator preserves the first mockup's harmony, chirps, laser sweeps,
meteor impact and short cues, exported independently for event playback.
`manifest.json` records provenance, duration and bytes for every resource.

Format: PCM 16-bit WAV, 22050 Hz mono effects, except the approved stereo cues
described below. All 33 effects are included in the APK and need no network.
Menu and gameplay background music have been removed, including their assets
and generator. Only effects and alerts remain in the sound controls.

Native player: flutter_soloud (separate dependency license retained by Flutter).

Zone completion now uses the approved “Sector asegurado cristal” preview for
all three places, reproduced by `tool/audio/zone_completed.py`. These replacement
effects retain the preview's stereo PCM at 44100 Hz, 1.6 seconds.

All match results (victory, podium and remaining places) use the approved
“Cierre imperial original” preview, reproduced by `tool/audio/imperial_finish.py`.
The cue retains its stereo PCM at 44100 Hz, 5.8 seconds; effect tracking and priority cover the full cue. Result visuals still distinguish player positions.
