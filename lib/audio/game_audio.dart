import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioScene { menu, game }

enum AudioBus { effects, alerts }

enum GameSound {
  startup,
  click,
  back,
  panel,
  connect,
  disconnect,
  ready,
  launch,
  round,
  meteor,
  impact,
  reveal,
  select,
  preview,
  shot,
  place,
  reject,
  skip,
  zone1,
  zone2,
  zone3,
  zoneOther,
  zoneExhausted,
  chat,
  sent,
  thirty,
  tick,
  tickFinal,
  timeout,
  victory,
  podium,
  finish,
  alert;

  String get asset =>
      'assets/audio/sfx/${switch (this) {
        zone1 => 'zone_1',
        zone2 => 'zone_2',
        zone3 => 'zone_3',
        zoneOther => 'zone_other',
        zoneExhausted => 'zone_exhausted',
        tickFinal => 'tick_final',
        _ => name,
      }}.wav';
  AudioBus get bus => switch (this) {
    round ||
    reject ||
    zone1 ||
    zone2 ||
    zone3 ||
    zoneOther ||
    zoneExhausted ||
    chat ||
    thirty ||
    tick ||
    tickFinal ||
    timeout ||
    victory ||
    podium ||
    finish ||
    alert => AudioBus.alerts,
    _ => AudioBus.effects,
  };
  int get priority => switch (this) {
    alert || victory || podium || finish => 3,
    thirty || tickFinal || timeout || zone1 || zone2 || zone3 => 2,
    chat || zoneOther || round || reject || zoneExhausted => 1,
    _ => 0,
  };
  Duration get duration => Duration(
    milliseconds: switch (this) {
      victory || podium || finish => 5800,
      launch => 1700,
      zone1 || zone2 || zone3 => 1600,
      meteor || impact => 1550,
      thirty => 1400,
      alert => 1000,
      round => 900,
      startup => 1400,
      _ => 1000,
    },
  );
  double get gain => switch (this) {
    click || select || preview || sent || tick => .22,
    panel || back || place || chat => .32,
    meteor => .38,
    impact => .50,
    victory || podium || finish => .60,
    _ => .43,
  };
}

abstract interface class AudioBackend {
  Future<void> initialize();
  Future<void> load(String asset);
  Future<Object> play(String asset, double volume);
  Future<void> stop(Object handle);
  void volume(Object handle, double value, Duration fade);
  Future<void> dispose();
}

class _NativeVoice {
  final SoundHandle handle;
  const _NativeVoice(this.handle);
}

class SoloudAudioBackend implements AudioBackend {
  final _sources = <String, AudioSource>{};
  @override
  Future<void> initialize() async {
    await SoLoud.instance.init(bufferSize: 512);
    SoLoud.instance.setMaxActiveVoiceCount(8);
  }

  @override
  Future<void> load(String asset) async {
    _sources[asset] = await SoLoud.instance.loadAsset(asset);
  }

  @override
  Future<Object> play(String asset, double volume) async =>
      _NativeVoice(SoLoud.instance.play(_sources[asset]!, volume: volume));
  @override
  Future<void> stop(Object handle) =>
      SoLoud.instance.stop((handle as _NativeVoice).handle);
  @override
  void volume(Object handle, double value, Duration fade) {
    final voice = (handle as _NativeVoice).handle;
    if (SoLoud.instance.getIsValidVoiceHandle(voice)) {
      if (fade == Duration.zero) {
        SoLoud.instance.setVolume(voice, value);
      } else {
        SoLoud.instance.fadeVolume(voice, value, fade);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await SoLoud.instance.disposeAllSources();
    SoLoud.instance.deinit();
    _sources.clear();
  }
}

/// Playback belongs to the app, not to rebuilds or individual audio widgets.
/// Before start() this is inert, so widget tests never initialize native audio.
class GameAudio extends ChangeNotifier {
  static final instance = GameAudio(backend: SoloudAudioBackend());
  final AudioBackend backend;
  final DateTime Function() now;
  GameAudio({required this.backend, DateTime Function()? now})
    : now = now ?? DateTime.now;
  bool _ready = false, _foreground = true, _muted = false, _closed = false;
  double _effects = .7, _alerts = .8;
  AudioScene _scene = AudioScene.menu;
  SharedPreferences? _preferences;
  final _loaded = <String>{};
  final _handles = <Object, GameSound>{};
  final _last = <GameSound, DateTime>{};
  final _retire = <Object, Timer>{};
  int _effectVersion = 0, _priority = 0;
  final _soundVersions = <GameSound, int>{};
  DateTime? _priorityUntil;
  Future<void> _saving = Future.value();
  bool get ready => _ready;
  bool get muted => _muted;
  bool get foreground => _foreground;
  double get effectsVolume => _effects;
  double get alertsVolume => _alerts;
  AudioScene get scene => _scene;
  Future<void> start() async {
    if (_ready || _closed) return;
    try {
      _preferences = await SharedPreferences.getInstance();
      _muted = _preferences!.getBool('audio.muted') ?? false;
      _effects = (_preferences!.getDouble('audio.effects') ?? .7).clamp(0, 1);
      _alerts = (_preferences!.getDouble('audio.alerts') ?? .8).clamp(0, 1);
      await backend.initialize();
      // Load once, before gameplay; no downloads or disk reads on a tap.
      for (final asset in [for (final s in GameSound.values) s.asset]) {
        try {
          await backend.load(asset);
          _loaded.add(asset);
        } catch (e) {
          debugPrint('Audio asset unavailable: $asset ($e)');
        }
      }
      if (_closed) return;
      _ready = true;
      play(GameSound.startup);
    } catch (e) {
      debugPrint('Audio unavailable: $e');
      // An audio failure must never prevent entering the game.
    }
  }

  void setScene(AudioScene scene) {
    if (_scene == scene) return;
    _scene = scene;
    stopEffects();
  }

  void play(GameSound sound) {
    if (!_ready ||
        _closed ||
        !_foreground ||
        _muted ||
        !_loaded.contains(sound.asset)) {
      return;
    }
    final busGain = sound.bus == AudioBus.effects ? _effects : _alerts;
    if (busGain == 0) return;
    final time = now();
    final last = _last[sound];
    final cooldown = sound == GameSound.chat ? 1500 : 65;
    if (last != null && time.difference(last).inMilliseconds < cooldown) return;
    if (_priorityUntil?.isAfter(time) == true && sound.priority < _priority) {
      return;
    }
    _last[sound] = time;
    if (sound.priority >= 2) {
      _priority = sound.priority;
      _priorityUntil = time.add(sound.duration);
    }
    unawaited(
      _effect(
        sound,
        busGain * sound.gain,
        _effectVersion,
        _soundVersions[sound] ?? 0,
      ),
    );
  }

  Future<void> _effect(
    GameSound sound,
    double volume,
    int version,
    int soundVersion,
  ) async {
    try {
      final handle = await backend.play(sound.asset, volume);
      if (!_foreground ||
          _muted ||
          _closed ||
          version != _effectVersion ||
          soundVersion != (_soundVersions[sound] ?? 0)) {
        await backend.stop(handle);
        return;
      }
      _handles[handle] = sound;
      _retire[handle] = Timer(sound.duration, () {
        _handles.remove(handle);
        _retire.remove(handle);
      });
    } catch (e) {
      debugPrint('Sound unavailable: $e');
    }
  }

  void stop(GameSound sound) {
    _soundVersions[sound] = (_soundVersions[sound] ?? 0) + 1;
    for (final entry in _handles.entries.toList()) {
      if (entry.value == sound) _stopHandle(entry.key);
    }
  }

  void _stopHandle(Object handle) {
    _handles.remove(handle);
    _retire.remove(handle)?.cancel();
    unawaited(backend.stop(handle).catchError((Object _) {}));
  }

  void stopEffects() {
    _effectVersion++;
    for (final handle in _handles.keys.toList()) {
      _stopHandle(handle);
    }
    _priority = 0;
    _priorityUntil = null;
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    stopEffects();
    _last.clear();
  }

  void _safe(void Function() action) {
    try {
      action();
    } catch (e) {
      debugPrint('Audio device unavailable: $e');
    }
  }

  void configure({bool? muted, double? effects, double? alerts}) {
    _muted = muted ?? _muted;
    _effects = (effects ?? _effects).clamp(0, 1);
    _alerts = (alerts ?? _alerts).clamp(0, 1);
    // Existing sounds respect a volume change immediately.
    for (final entry in _handles.entries.toList()) {
      final gain = entry.value.bus == AudioBus.effects ? _effects : _alerts;
      _safe(
        () => backend.volume(
          entry.key,
          _muted ? 0 : gain * entry.value.gain,
          Duration.zero,
        ),
      );
    }
    if (_muted) {
      stopEffects();
    }
    notifyListeners();
    final prefs = _preferences;
    if (prefs != null) {
      final values = (_muted, _effects, _alerts);
      _saving = _saving
          .then((_) async {
            await prefs.setBool('audio.muted', values.$1);
            await prefs.setDouble('audio.effects', values.$2);
            await prefs.setDouble('audio.alerts', values.$3);
          })
          .catchError((Object e) {
            debugPrint('Audio preferences unavailable: $e');
          });
    }
  }

  Future<void> shutdown() async {
    _closed = true;
    stopEffects();
    if (_ready) await backend.dispose();
    await _saving;
    _ready = false;
  }
}
