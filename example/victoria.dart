import 'dart:math';

import 'package:brilliant_game/app/tema_brilliant.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/bloc/partida_evento.dart';
import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Demostración de la victoria: arma un tablero a cuatro jugadas de la meta y
/// las juega solo, para revisar la celebración en el dispositivo.
///
/// flutter run -t example/victoria.dart
///
/// Con `--dart-define=MANUAL=true` la última jugada queda pendiente para
/// hacerla con un toque, como en una partida real.
void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TemaBrilliant.oscuro,
    home: const DemostracionVictoria(),
  ),
);

const _ultimaJugadaManual = bool.fromEnvironment('MANUAL');

class _Dados implements Random {
  final List<int> valores;
  int _indice = 0;
  _Dados(this.valores);
  @override
  int nextInt(int max) => valores[_indice++ % valores.length] - 1;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class DemostracionVictoria extends StatefulWidget {
  const DemostracionVictoria({super.key});

  @override
  State<DemostracionVictoria> createState() => _DemostracionVictoriaState();
}

class _DemostracionVictoriaState extends State<DemostracionVictoria> {
  late PartidaBloc _bloc = _crear();

  PartidaBloc _crear() {
    final tablero = tablero01.crearTablero();
    const iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];
    for (var i = 0; i < iniciales.length; i++) {
      tablero.colocarValor(iniciales[i], i + 1);
    }
    for (final (zona, hueco, valor) in [
      ('azul_1', 'f1_c3', 1),
      ('azul_2', 'f5_c7', 3),
      ('morado_1', 'f1_c4', 2),
      ('morado_2', 'f4_c3', 5),
    ]) {
      for (final celda in tablero.obtenerZona(zona).celdas.values) {
        if (celda.id != hueco) tablero.colocarValor(celda.id, valor);
      }
    }
    tablero.colocarValor('f4_c7', 4);
    final bloc = PartidaBloc(
      tablero,
      azar: _Dados([1, 1, 3, 4, 2, 1, 5, 3]),
      nombreJugador: 'Demo',
    );
    _jugar(bloc);
    return bloc;
  }

  Future<void> _jugar(PartidaBloc bloc) async {
    const destinos = ['f1_c3', 'f5_c7', 'f1_c4', 'f4_c3'];
    Future<void> paso(PartidaEvento evento) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!bloc.isClosed) bloc.add(evento);
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    for (var ronda = 1; ronda <= 4; ronda++) {
      await paso(MeteorosCompletados(ronda));
      await paso(DadoSeleccionado(ronda, 0));
      await paso(MovimientoDadosCompletado(ronda));
      if (ronda == 4 && _ultimaJugadaManual) return;
      await paso(DestinoSeleccionado(ronda, destinos[ronda - 1]));
      if (ronda < 4) await paso(MeteorosSolicitados(ronda));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: PartidaPage(
      key: ObjectKey(_bloc),
      definicion: tablero01,
      jugador: 'Demo',
      cargarMeteoritos: () async => throw StateError('Sin video'),
      onEmpezarDeNuevo: () => setState(() {
        _bloc.close();
        _bloc = _crear();
      }),
    ),
  );
}
