import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Cada solicitud entrega una definición para una partida limpia',
    () async {
      final bloc = MenuBloc();
      addTearDown(bloc.close);
      expect(bloc.state.fase, FaseMenu.menuVisible);
      final estados = <MenuEstado>[];
      final subscription = bloc.stream.listen(estados.add);
      addTearDown(subscription.cancel);
      Future<MenuEstado> solicitar() {
        final listo = bloc.stream.firstWhere(
          (e) => e.fase == FaseMenu.partidaPreparada,
        );
        bloc.add(const NuevaPartidaSolicitada());
        return listo;
      }

      final primera = await solicitar();
      final tablero = primera.tablero!.crearTablero();
      tablero.colocarValor('f1_c2', 4);
      final segunda = await solicitar();
      expect(segunda.solicitudId, greaterThan(primera.solicitudId));
      expect(
        segunda.tablero!.crearTablero().celdas.values.every(
          (c) => !c.estaOcupada,
        ),
        isTrue,
      );
      expect(estados.map((e) => e.fase), [
        FaseMenu.creandoPartida,
        FaseMenu.partidaPreparada,
        FaseMenu.creandoPartida,
        FaseMenu.partidaPreparada,
      ]);
    },
  );

  test(
    'Un catálogo sin el primer tablero publica un error recuperable',
    () async {
      final bloc = MenuBloc(catalogo: CatalogoTableros(definiciones: []));
      addTearDown(bloc.close);
      final error = bloc.stream.firstWhere((e) => e.error != null);
      bloc.add(const NuevaPartidaSolicitada());
      expect((await error).fase, FaseMenu.menuVisible);
      expect(bloc.state.tablero, isNull);
    },
  );
}
