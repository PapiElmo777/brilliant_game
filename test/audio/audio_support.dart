import 'dart:async';
import 'package:brilliant_game/audio/game_audio.dart';

class FakeAudioBackend implements AudioBackend {
  final loaded = <String>[];
  final played = <({Object handle, String asset, double volume})>[];
  final stopped = <Object>[];
  final volumes = <(Object, double)>[];
  bool failed = false, disposed = false;
  Completer<void>? hold;
  int _id = 0;
  @override
  Future<void> initialize() async {
    if (failed) throw StateError('No audio device');
  }

  @override
  Future<void> load(String asset) async {
    loaded.add(asset);
  }

  @override
  Future<Object> play(String asset, double volume) async {
    final handle = ++_id;
    played.add((handle: handle, asset: asset, volume: volume));
    await hold?.future;
    return handle;
  }

  @override
  Future<void> stop(Object handle) async {
    stopped.add(handle);
  }

  @override
  void volume(Object handle, double value, Duration fade) {
    volumes.add((handle, value));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  List<String> get effects =>
      played.map((p) => p.asset.split('/').last).toList();
}

Future<void> flushAudio() => Future<void>.delayed(Duration.zero);
