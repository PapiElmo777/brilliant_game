import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:brilliant_game/audio/game_audio.dart';
import 'package:brilliant_game/audio/audio_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudioBackend backend;
  late GameAudio audio;
  late DateTime time;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeAudioBackend();
    time = DateTime(2026);
    audio = GameAudio(backend: backend, now: () => time);
  });
  tearDown(() async {
    await audio.shutdown();
  });
  test(
    'All referenced assets exist, have provenance and stay below 10 MiB',
    () {
      final entries =
          (jsonDecode(File('assets/audio/manifest.json').readAsStringSync())
                  as List)
              .cast<Map<String, dynamic>>();
      final paths = entries.map((e) => 'assets/audio/${e['file']}').toSet();
      expect(
        paths,
        containsAll([
          for (final s in GameSound.values) s.asset,
          for (final s in AudioScene.values) GameAudio.musicAsset(s),
        ]),
      );
      expect(
        entries.every((e) => (e['source'] as String).startsWith('Original')),
        isTrue,
      );
      expect(
        entries.fold<int>(0, (sum, e) => sum + (e['bytes'] as int)),
        lessThan(10 * 1024 * 1024),
      );
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    },
  );
  test(
    'Preloads once and preserves chosen scene during initialization',
    () async {
      audio.setScene(AudioScene.game);
      await audio.start();
      await flushAudio();
      await audio.start();
      expect(
        backend.loaded.length,
        GameSound.values.length + AudioScene.values.length,
      );
      expect(
        backend.played.where((p) => p.loop).single.asset,
        endsWith('game.wav'),
      );
    },
  );
  test('Missing native device never stops app startup', () async {
    backend.failed = true;
    await audio.start();
    audio.play(GameSound.select);
    expect(audio.ready, isFalse);
    expect(backend.played, isEmpty);
  });
  test('Mute stops effects and persists independent volume controls', () async {
    await audio.start();
    await flushAudio();
    audio.configure(music: .12, effects: .24, alerts: .36);
    audio.configure(muted: true);
    final count = backend.played.length;
    audio.play(GameSound.alert);
    await flushAudio();
    expect(backend.played.length, count);
    await audio.shutdown();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('audio.muted'), isTrue);
    expect(prefs.getDouble('audio.music'), .12);
    expect(prefs.getDouble('audio.effects'), .24);
    expect(prefs.getDouble('audio.alerts'), .36);
  });
  test(
    'Background cancels sounds, pauses music, and never replays old notices',
    () async {
      await audio.start();
      await flushAudio();
      audio.play(GameSound.chat);
      await flushAudio();
      audio.setForeground(false);
      final count = backend.played.length;
      audio.play(GameSound.victory);
      await flushAudio();
      expect(backend.played.length, count);
      expect(backend.paused.last.$2, isTrue);
      audio.setForeground(true);
      await flushAudio();
      expect(backend.played.length, count);
      expect(backend.paused.last.$2, isFalse);
    },
  );
  test('Rapid chat is grouped; muted effects do not mute alerts', () async {
    await audio.start();
    await flushAudio();
    backend.played.clear();
    audio.configure(effects: 0);
    audio.play(GameSound.select);
    audio.play(GameSound.chat);
    audio.play(GameSound.chat);
    await flushAudio();
    expect(backend.effects, ['chat.wav']);
    time = time.add(const Duration(seconds: 2));
    audio.play(GameSound.chat);
    await flushAudio();
    expect(backend.effects.length, 2);
  });
  test('Victory takes priority and ducks the music', () async {
    await audio.start();
    await flushAudio();
    backend.played.clear();
    audio.play(GameSound.victory);
    audio.play(GameSound.chat);
    audio.play(GameSound.select);
    await flushAudio();
    expect(backend.effects, ['victory.wav']);
    expect(backend.volumes.last.$2, closeTo(audio.musicVolume * .28, .00001));
  });
  test(
    'Impact cancels a meteor even if native playback finishes asynchronously',
    () async {
      await audio.start();
      await flushAudio();
      backend.hold = Completer<void>();
      audio.play(GameSound.meteor);
      audio.stop(GameSound.meteor);
      backend.hold!.complete();
      await flushAudio();
      final meteor = backend.played.last;
      expect(backend.stopped, contains(meteor.handle));
    },
  );
  test('A scene change invalidates a pending old effect', () async {
    await audio.start();
    await flushAudio();
    backend.hold = Completer<void>();
    audio.play(GameSound.chat);
    final chat = backend.played.last;
    audio.setScene(AudioScene.game);
    backend.hold!.complete();
    await flushAudio();
    expect(backend.stopped, contains(chat.handle));
    expect(backend.played.last.asset, endsWith('game.wav'));
  });
  testWidgets('Settings expose mute and all three volume controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AudioSettings(audio: audio)),
      ),
    );
    expect(find.text('Silenciar todo'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(audio.muted, isTrue);
    expect(
      tester
          .widgetList<Slider>(find.byType(Slider))
          .every((s) => s.onChanged == null),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
