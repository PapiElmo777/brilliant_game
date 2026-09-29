import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/inicio_bloc.dart';

import '../catalogo/definicion_tablero.dart';
import '../presentation/pages/menu_inicial_page.dart';
import '../presentation/pages/preparacion_page.dart';

abstract final class RutasBrilliant {
  static const menu = '/';
  static const preparacion = '/preparacion';

  static Route<void> generar(RouteSettings settings) {
    if (settings.name == preparacion &&
        settings.arguments is DefinicionTablero) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final definicion = settings.arguments! as DefinicionTablero;
          return BlocProvider(
            create: (_) => InicioBloc(definicion.crearTablero(), animarEntrada: true),
            child: PreparacionPage(definicion: definicion),
          );
        },
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
