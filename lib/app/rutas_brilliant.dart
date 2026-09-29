import 'package:flutter/material.dart';

import '../presentation/pages/menu_inicial_page.dart';

abstract final class RutasBrilliant {
  static const menu = '/';

  static Route<void> generar(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: menu),
      builder: (_) => const MenuInicialPage(),
    );
  }
}
