import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Cada solicitud pide el nombre y entrega una definición limpia',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      expect(bloc.state.fase, FaseMenu.menuVisible);
      final estados = <MenuEstado>[];
      final subscription = bloc.stream.listen(estados.add);
      addTearDown(subscription.cancel);
      Future<MenuEstado> solicitar(String nombre) {
        final listo = bloc.stream.firstWhere(
          (e) => e.fase == FaseMenu.partidaPreparada,
        );
        bloc
          ..add(const NuevaPartidaSolicitada())
          ..add(NombreJugadorConfirmado(nombre));
        return listo;
      }

      final primera = await solicitar('  Alfredo ');
      expect(primera.jugador, 'Alfredo');
      final tablero = primera.tablero!.crearTablero();
      tablero.colocarValor('f1_c2', 4);
      final segunda = await solicitar('Ana');
      expect(segunda.jugador, 'Ana');
      expect(segunda.solicitudId, greaterThan(primera.solicitudId));
      expect(
        segunda.tablero!.crearTablero().celdas.values.every(
          (c) => !c.estaOcupada,
        ),
        isTrue,
      );
      expect(estados.map((e) => e.fase), [
        FaseMenu.pidiendoNombre,
        FaseMenu.creandoPartida,
        FaseMenu.partidaPreparada,
        FaseMenu.pidiendoNombre,
        FaseMenu.creandoPartida,
        FaseMenu.partidaPreparada,
      ]);
    },
  );

  test(
    'Un nombre vacío o demasiado largo se rechaza y se vuelve a pedir',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      bloc
        ..add(const NuevaPartidaSolicitada())
        ..add(const NombreJugadorConfirmado('   '));
      final vacio = await bloc.stream.firstWhere((e) => e.error != null);
      expect(vacio.fase, FaseMenu.pidiendoNombre);
      expect(vacio.tablero, isNull);
      bloc.add(NombreJugadorConfirmado('x' * 17));
      final largo = await bloc.stream.firstWhere(
        (e) => e.error != null && e.error != vacio.error,
      );
      expect(largo.fase, FaseMenu.pidiendoNombre);
      bloc.add(const NombreJugadorConfirmado('Luz'));
      final listo = await bloc.stream.firstWhere(
        (e) => e.fase == FaseMenu.partidaPreparada,
      );
      expect(listo.error, isNull);
      expect(listo.jugador, 'Luz');
    },
  );

  test('Cancelar vuelve al menú y conserva el último nombre', () async {
    final bloc = MenuBloc();
    addTearDown(bloc.close);
    bloc
      ..add(const NuevaPartidaSolicitada())
      ..add(const NombreJugadorConfirmado('Alfredo'));
    await bloc.stream.firstWhere((e) => e.fase == FaseMenu.partidaPreparada);
    bloc
      ..add(const NuevaPartidaSolicitada())
      ..add(const CapturaNombreCancelada());
    final menu = await bloc.stream.firstWhere(
      (e) => e.fase == FaseMenu.menuVisible,
    );
    expect(menu.jugador, 'Alfredo');
    expect(menu.tablero, isNull);
  });

  test('Confirmar un nombre sin haberlo pedido se ignora', () async {
    final bloc = MenuBloc();
    addTearDown(bloc.close);
    bloc.add(const NombreJugadorConfirmado('Alfredo'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.fase, FaseMenu.menuVisible);
    expect(bloc.state.jugador, isNull);
  });

  test(
    'Un catálogo sin el primer tablero publica un error recuperable',
    () async {
      final bloc = MenuBloc(catalogo: CatalogoTableros(definiciones: []));
      addTearDown(bloc.close);
      final error = bloc.stream.firstWhere(
        (e) => e.error != null && e.fase == FaseMenu.menuVisible,
      );
      bloc
        ..add(const NuevaPartidaSolicitada())
        ..add(const NombreJugadorConfirmado('Alfredo'));
      expect((await error).fase, FaseMenu.menuVisible);
      expect(bloc.state.tablero, isNull);
    },
  );
}
