import 'dart:math';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

class AzarNivel implements Random {
  final int indice;
  int llamadas = 0;
  AzarNivel(this.indice);
  @override
  int nextInt(int max) {
    expect(max, 4);
    llamadas++;
    return indice;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

Future<void> enviar(MenuBloc bloc, MenuEvento evento) async {
  bloc.add(evento);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'Selecciona nivel antes del nombre y crea partidas independientes',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      for (final n in [1, 2, 3, 4]) {
        await enviar(bloc, const NuevaPartidaSolicitada());
        expect(bloc.state.fase, FaseMenu.seleccionandoNivel);
        await enviar(bloc, const NombreJugadorConfirmado('Antes de elegir'));
        expect(bloc.state.fase, FaseMenu.seleccionandoNivel);
        await enviar(bloc, NivelSeleccionado('tablero_0$n'));
        expect(bloc.state.fase, FaseMenu.pidiendoNombre);
        await enviar(bloc, const NombreJugadorConfirmado('  Ana  '));
        expect(bloc.state.jugador, 'Ana');
        expect(bloc.state.tablero!.id, 'tablero_0$n');
        expect(bloc.state.solicitudId, n);
        final a = bloc.state.tablero!.crearTablero(),
            b = bloc.state.tablero!.crearTablero();
        final inicial = a.celdas.values.firstWhere((c) => c.esInicio);
        a.colocarValor(inicial.id, n == 4 ? 4 : 1);
        expect(b.celdas.values.every((c) => !c.estaOcupada), isTrue);
      }
    },
  );
  for (var indice = 0; indice < 4; indice++) {
    test('El sorteo puede elegir nivel ${indice + 1}, una sola vez', () async {
      final azar = AzarNivel(indice);
      final menu = MenuBloc(azar: azar);
      addTearDown(menu.close);
      await enviar(menu, const NuevaPartidaSolicitada());
      await enviar(menu, const NivelAleatorioSolicitado());
      await enviar(menu, const NivelAleatorioSolicitado());
      await enviar(menu, const NivelSeleccionado('tablero_01'));
      expect(azar.llamadas, 1);
      expect(menu.state.tablero!.id, 'tablero_0${indice + 1}');
      expect(menu.state.fase, FaseMenu.pidiendoNombre);
    });
  }
  test(
    'Cancelar nombre conserva nivel; cancelar selector vuelve al menú',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      await enviar(bloc, const NuevaPartidaSolicitada());
      await enviar(bloc, const NivelSeleccionado('tablero_03'));
      await enviar(bloc, const NombreJugadorConfirmado('Ana'));
      await enviar(bloc, const NuevaPartidaSolicitada());
      await enviar(bloc, const NivelSeleccionado('tablero_04'));
      await enviar(bloc, const CapturaNombreCancelada());
      expect(bloc.state.fase, FaseMenu.seleccionandoNivel);
      expect(bloc.state.tablero!.id, 'tablero_04');
      expect(bloc.state.jugador, 'Ana');
      await enviar(bloc, const SeleccionNivelCancelada());
      expect(bloc.state.fase, FaseMenu.menuVisible);
      expect(bloc.state.tablero, isNull);
    },
  );
  test(
    'Nombres y niveles inválidos se rechazan sin perder la selección',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      await enviar(bloc, const NuevaPartidaSolicitada());
      await enviar(bloc, const NivelSeleccionado('no_existe'));
      expect(bloc.state.error, isNotNull);
      expect(bloc.state.fase, FaseMenu.seleccionandoNivel);
      await enviar(bloc, const NivelSeleccionado('tablero_02'));
      for (final nombre in [' ', 'x' * 17]) {
        await enviar(bloc, NombreJugadorConfirmado(nombre));
        expect(bloc.state.error, isNotNull);
        expect(bloc.state.tablero!.id, 'tablero_02');
      }
      await enviar(bloc, const NombreJugadorConfirmado('Luz'));
      await enviar(bloc, const NombreJugadorConfirmado('Duplicado'));
      expect(bloc.state.solicitudId, 1);
      expect(bloc.state.jugador, 'Luz');
    },
  );
  test('Catálogo vacío informa un error recuperable', () async {
    final bloc = MenuBloc(catalogo: CatalogoTableros(definiciones: []));
    addTearDown(bloc.close);
    await enviar(bloc, const NuevaPartidaSolicitada());
    expect(bloc.state.fase, FaseMenu.menuVisible);
    expect(bloc.state.error, isNotNull);
  });
}
