import 'dart:async';
import 'package:bloc/bloc.dart';
import 'audio/game_audio.dart';
import 'audio/audio_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/brilliant_game_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La primera etapa prioriza el formato vertical de teléfono.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Bloc.observer = AudioEvents(GameAudio.instance, previous: Bloc.observer);
  runApp(const BrilliantGameApp());
  unawaited(GameAudio.instance.start());
}
