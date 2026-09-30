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
    if (settings.arguments case (
      DefinicionTablero definicion,
      String jugador,
    ) when settings.name == preparacion) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => BlocProvider(
          create: (_) =>
              InicioBloc(definicion.crearTablero(), animarEntrada: true),
          child: PreparacionPage(definicion: definicion, jugador: jugador),
        ),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: menu),
      builder: (context) => MenuInicialPage(
        onNuevaPartida: (tablero, jugador) {
          // MenuBloc evita solicitudes duplicadas; el diálogo del nombre
          // puede seguir cerrándose sobre el menú en este momento.
          if (ModalRoute.of(context)?.isActive != true) return;
          Navigator.of(
            context,
          ).pushNamed(preparacion, arguments: (tablero, jugador));
        },
      ),
    );
  }
}
