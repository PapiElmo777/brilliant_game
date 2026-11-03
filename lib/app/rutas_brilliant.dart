import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/inicio_bloc.dart';
import '../auth/auth_repository.dart';

import '../catalogo/definicion_tablero.dart';
import '../presentation/pages/menu_inicial_page.dart';
import '../presentation/pages/preparacion_page.dart';

abstract final class RutasBrilliant {
  static const menu = '/';
  static const preparacion = '/preparacion';

  static Route<void> generar(
    RouteSettings settings, {
    Random? azarPartida,
    Account? cuenta,
  }) {
    if (settings.arguments case (
      DefinicionTablero definicion,
      String? jugador,
    ) when settings.name == preparacion) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => BlocProvider(
          create: (_) =>
              InicioBloc(definicion.crearTablero(), animarEntrada: true),
          child: PreparacionPage(
            definicion: definicion,
            jugador: cuenta?.username ?? jugador,
            jugadorId: cuenta?.id,
            azarPartida: azarPartida,
          ),
        ),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: menu),
      builder: (context) => MenuInicialPage(
        cuenta: cuenta,
        onNuevaPartida: (tablero, jugador) {
          // MenuBloc evita solicitudes duplicadas. La ruta del menú debe
          // seguir activa al completar la selección del nivel.
          if (ModalRoute.of(context)?.isActive != true) return;
          Navigator.of(
            context,
          ).pushNamed(preparacion, arguments: (tablero, jugador));
        },
      ),
    );
  }
}
