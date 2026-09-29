import 'package:flutter/material.dart';

import '../catalogo/definicion_tablero.dart';
import '../presentation/pages/menu_inicial_page.dart';

abstract final class RutasBrilliant {
  static const menu = '/';
  static const preparacion = '/preparacion';

  static Route<void> generar(RouteSettings settings) {
    if (settings.name == preparacion && settings.arguments is DefinicionTablero) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Preparación')),
          body: const Center(child: Text('Acomoda los números en las celdas iniciales')),
        ),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: menu),
      builder: (context) => MenuInicialPage(
        onNuevaPartida: (tablero) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.of(context).pushNamed(preparacion, arguments: tablero);
        },
      ),
    );
  }
}
