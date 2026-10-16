import 'dart:math';

import 'package:flutter/material.dart';

import 'rutas_brilliant.dart';
import 'tema_brilliant.dart';

class BrilliantGameApp extends StatelessWidget {
  final Random? azarPartida;

  const BrilliantGameApp({super.key, this.azarPartida});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brilliant Game',
      debugShowCheckedModeBanner: false,
      theme: TemaBrilliant.oscuro,
      initialRoute: RutasBrilliant.menu,
      onGenerateRoute: (settings) =>
          RutasBrilliant.generar(settings, azarPartida: azarPartida),
    );
  }
}
