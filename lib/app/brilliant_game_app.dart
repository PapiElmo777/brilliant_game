import 'package:flutter/material.dart';

import 'rutas_brilliant.dart';
import 'tema_brilliant.dart';

class BrilliantGameApp extends StatelessWidget {
  const BrilliantGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brilliant Game',
      debugShowCheckedModeBanner: false,
      theme: TemaBrilliant.oscuro,
      initialRoute: RutasBrilliant.menu,
      onGenerateRoute: RutasBrilliant.generar,
    );
  }
}
