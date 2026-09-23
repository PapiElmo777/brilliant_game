import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/preparacion_inicial_test.dart' show tableroInicial;

Future<InicioEstado> enviar(InicioBloc bloc, InicioEvento evento) {
  final siguiente = bloc.stream.first;
  bloc.add(evento);
  return siguiente;
}

Future<void> completar(InicioBloc bloc) async {
  for (var i = 1; i <= 6; i++) {
    await enviar(bloc, ValorInicialColocado('C$i', i));
  }
}

void main() {
  late InicioBloc bloc;
  setUp(() => bloc = InicioBloc(tableroInicial()));
  tearDown(() => bloc.close());

  test('Inicia bloqueado y no entrega el tablero de juego', () {
    expect(bloc.state.fase, FaseInicio.preparando);
    expect(bloc.state.puedeIniciar, isFalse);
    expect(bloc.state.numerosFaltantes, {1, 2, 3, 4, 5, 6});
    expect(bloc.crearTableroParaJuego, throwsStateError);
  });

  test('Rechaza InicioSolicitado mientras falte un número', () async {
    for (var i = 1; i <= 5; i++) {
      await enviar(bloc, ValorInicialColocado('C$i', i));
    }
    final estado = await enviar(bloc, const InicioSolicitado());
    expect(estado.fase, FaseInicio.preparando);
    expect(estado.numerosFaltantes, {6});
    expect(estado.error, isNotNull);
    expect(bloc.crearTableroParaJuego, throwsStateError);
  });

  test('Completar habilita y solicitar inicio cambia de fase', () async {
    await completar(bloc);
    expect(bloc.state.fase, FaseInicio.listo);
    expect(bloc.state.puedeIniciar, isTrue);
    expect(bloc.crearTableroParaJuego, throwsStateError);
    final estado = await enviar(bloc, const InicioSolicitado());
    expect(estado.fase, FaseInicio.iniciado);
    expect(estado.puedeIniciar, isFalse);
    expect(estado.error, isNull);
    expect(bloc.crearTableroParaJuego().obtenerCelda('C6').valor, 6);
  });

  test('Rechaza duplicados sin alterar celdas ni faltantes', () async {
    await enviar(bloc, const ValorInicialColocado('C1', 3));
    final estado = await enviar(bloc, const ValorInicialColocado('C2', 3));
    expect(estado.error, isNotNull);
    expect(estado.celdas['C2']!.valor, isNull);
    expect(estado.numerosFaltantes, {1, 2, 4, 5, 6});
  });

  test(
    'Un error de entrada no cierra el bloc y se limpia al corregir',
    () async {
      for (final evento in const [
        ValorInicialColocado('C1', 7),
        ValorInicialColocado('normal', 1),
        ValorInicialRetirado('inexistente'),
      ]) {
        final estado = await enviar(bloc, evento);
        expect(estado.error, isNotNull);
        expect(estado.numerosFaltantes.length, 6);
      }
      final estado = await enviar(bloc, const ValorInicialColocado('C1', 1));
      expect(estado.error, isNull);
      expect(estado.numerosFaltantes, {2, 3, 4, 5, 6});
    },
  );

  test('Retirar al estar listo vuelve a bloquear', () async {
    await completar(bloc);
    final estado = await enviar(bloc, const ValorInicialRetirado('C4'));
    expect(estado.fase, FaseInicio.preparando);
    expect(estado.puedeIniciar, isFalse);
    expect(estado.numerosFaltantes, {4});
    expect(
      (await enviar(bloc, const InicioSolicitado())).fase,
      FaseInicio.preparando,
    );
  });

  test(
    'Después de iniciar no permite editar, retirar ni iniciar otra vez',
    () async {
      await completar(bloc);
      await enviar(bloc, const InicioSolicitado());
      for (final evento in const [
        ValorInicialColocado('C1', 2),
        ValorInicialRetirado('C1'),
        InicioSolicitado(),
      ]) {
        final estado = await enviar(bloc, evento);
        expect(estado.fase, FaseInicio.iniciado);
        expect(estado.celdas['C1']!.valor, 1);
        expect(estado.error, isNotNull);
      }
    },
  );

  test('Los estados pasados y sus colecciones no cambian', () async {
    final inicial = bloc.state;
    await enviar(bloc, const ValorInicialColocado('C1', 1));
    expect(inicial.celdas['C1']!.valor, isNull);
    expect(inicial.numerosFaltantes.length, 6);
    expect(() => bloc.state.celdas.clear(), throwsUnsupportedError);
    expect(() => bloc.state.numerosFaltantes.clear(), throwsUnsupportedError);
  });

  test('Procesa eventos rápidos en orden antes de iniciar', () async {
    final iniciado = bloc.stream.firstWhere(
      (estado) => estado.fase == FaseInicio.iniciado,
    );
    for (var i = 1; i <= 6; i++) {
      bloc.add(ValorInicialColocado('C$i', i));
    }
    bloc.add(const InicioSolicitado());
    expect((await iniciado).numerosFaltantes, isEmpty);
  });

  test(
    'Precarga completa comienza lista, sin iniciar automáticamente',
    () async {
      final tablero = tableroInicial();
      for (var i = 1; i <= 6; i++) {
        tablero.colocarValor('C$i', i);
      }
      final precargado = InicioBloc(tablero);
      addTearDown(precargado.close);
      expect(precargado.state.fase, FaseInicio.listo);
      expect(precargado.crearTableroParaJuego, throwsStateError);
    },
  );
}
