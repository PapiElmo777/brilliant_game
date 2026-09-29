import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/brilliant_game_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La primera etapa prioriza el formato vertical de teléfono.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BrilliantGameApp());
}
