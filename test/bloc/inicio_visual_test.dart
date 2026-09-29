import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inicio_bloc_test.dart' show enviar;

Tablero tablero() =>
    CatalogoTableros.predeterminado().crearTablero('tablero_01');

Future<void> presentar(InicioBloc bloc) async {
  await enviar(bloc, const LlegadaNaveCompletada());
  await enviar(bloc, const PresentacionNumerosCompletada());
}

Future<DisparoPendiente> disparar(
  InicioBloc bloc,
  String id,
  int numero,
) async {
  await enviar(bloc, NumeroInicialSeleccionado(numero));
  final estado = await enviar(bloc, CeldaInicialSeleccionada(id));
  return estado.disparoPendiente!;
}

void main() {
  late InicioBloc bloc;
  setUp(() => bloc = InicioBloc(tablero(), animarEntrada: true));
  tearDown(() => bloc.close());

  test(
    'Bloquea acciones hasta terminar llegada y presentación en orden',
    () async {
      expect(bloc.state.faseVisual, FaseVisualInicio.llegandoNave);
      expect(bloc.state.interaccionBloqueada, isTrue);
      final estados = <InicioEstado>[];
      final subscription = bloc.stream.listen(estados.add);
      addTearDown(subscription.cancel);
      bloc.add(const PresentacionNumerosCompletada());
      bloc.add(const NumeroInicialSeleccionado(1));
      bloc.add(const ValorInicialColocado('f1_c2', 1));
      bloc.add(const InicioSolicitado());
      await enviar(bloc, const LlegadaNaveCompletada());
      expect(estados.length, 1);
      expect(bloc.state.faseVisual, FaseVisualInicio.mostrandoNumeros);
      expect(bloc.state.interaccionBloqueada, isTrue);
      bloc.add(const LlegadaNaveCompletada());
      bloc.add(const CeldaInicialSeleccionada('f1_c2'));
      await enviar(bloc, const PresentacionNumerosCompletada());
      expect(estados.length, 2);
      expect(bloc.state.faseVisual, FaseVisualInicio.preparando);
      expect(bloc.state.interaccionBloqueada, isFalse);
      expect(bloc.state.numeroSeleccionado, isNull);
      expect(bloc.state.numerosFaltantes.length, 6);
    },
  );

  test('Selección, cancelación y corrección limpian el error', () async {
    await presentar(bloc);
    await enviar(bloc, const CeldaInicialSeleccionada('f1_c2'));
    expect(bloc.state.error, isNotNull);
    await enviar(bloc, const NumeroInicialSeleccionado(3));
    expect(bloc.state.numeroSeleccionado, 3);
    expect(bloc.state.error, isNull);
    await enviar(bloc, const SeleccionCancelada());
    expect(bloc.state.numeroSeleccionado, isNull);
    for (final valor in [0, 7]) {
      await enviar(bloc, NumeroInicialSeleccionado(valor));
      expect(bloc.state.error, isNotNull);
    }
    await enviar(bloc, const ValorInicialColocado('f1_c2', 3));
    await enviar(bloc, const NumeroInicialSeleccionado(3));
    expect(bloc.state.error, isNotNull);
    expect(bloc.state.numeroSeleccionado, isNull);
  });

  test(
    'Destinos inexistentes o no iniciales no disparan ni pierden selección',
    () async {
      await presentar(bloc);
      await enviar(bloc, const NumeroInicialSeleccionado(2));
      for (final id in ['ausente', 'f1_c1']) {
        await enviar(bloc, CeldaInicialSeleccionada(id));
        expect(bloc.state.error, isNotNull);
        expect(bloc.state.disparoPendiente, isNull);
        expect(bloc.state.numeroSeleccionado, 2);
        expect(bloc.state.numerosFaltantes.length, 6);
        expect(bloc.state.celdas.values.every((c) => !c.estaOcupada), isTrue);
      }
    },
  );

  test('Una regla de zona incumplida rechaza el disparo sin mutar', () async {
    final restringido = InicioBloc(
      Tablero(
        id: 'azul',
        zonas: [
          Zona(
            id: 'azul',
            tipo: const TipoAzul(),
            celdas: [
              for (var i = 0; i < 6; i++)
                Celda(id: 'c$i', fila: 0, columna: i, esInicio: true),
            ],
          ),
        ],
      ),
    );
    addTearDown(restringido.close);
    await enviar(restringido, const ValorInicialColocado('c0', 1));
    await enviar(restringido, const NumeroInicialSeleccionado(2));
    await enviar(restringido, const CeldaInicialSeleccionada('c1'));
    expect(restringido.state.error, isNotNull);
    expect(restringido.state.disparoPendiente, isNull);
    expect(restringido.state.celdas['c1']!.valor, isNull);
    expect(restringido.state.numeroSeleccionado, 2);
  });

  test('Confirma una sola vez y bloquea acciones durante el disparo', () async {
    await presentar(bloc);
    final disparo = await disparar(bloc, 'f1_c2', 1);
    final pendiente = bloc.state;
    expect(pendiente.celdas['f1_c2']!.valor, isNull);
    expect(pendiente.numerosFaltantes.contains(1), isTrue);
    expect(pendiente.interaccionBloqueada, isTrue);
    expect(pendiente.puedeIniciar, isFalse);
    final estados = <InicioEstado>[];
    final subscription = bloc.stream.listen(estados.add);
    addTearDown(subscription.cancel);
    for (final evento in [
      const NumeroInicialSeleccionado(2),
      const CeldaInicialSeleccionada('f2_c6'),
      const ValorInicialColocado('f2_c6', 2),
      const ValorInicialRetirado('f1_c2'),
      const SeleccionCancelada(),
      const InicioSolicitado(),
      const LlegadaNaveCompletada(),
      const PresentacionNumerosCompletada(),
      DisparoNumeroCompletado(disparo.id + 1),
    ]) {
      bloc.add(evento);
    }
    await enviar(bloc, DisparoNumeroCompletado(disparo.id));
    expect(estados.length, 1);
    expect(bloc.state.celdas['f1_c2']!.valor, 1);
    expect(bloc.state.celdas['f2_c6']!.valor, isNull);
    expect(bloc.state.disparoPendiente, isNull);
    expect(bloc.state.numeroSeleccionado, isNull);
    expect(pendiente.celdas['f1_c2']!.valor, isNull);
    bloc.add(DisparoNumeroCompletado(disparo.id));
    await enviar(bloc, const CeldaInicialSeleccionada('f1_c2'));
    expect(estados.length, 2);
    expect(bloc.state.numerosFaltantes.length, 6);
    final siguiente = await disparar(bloc, 'f2_c6', 1);
    expect(siguiente.id, greaterThan(disparo.id));
    bloc.add(DisparoNumeroCompletado(disparo.id));
    await enviar(bloc, DisparoNumeroCompletado(siguiente.id));
    expect(bloc.state.celdas['f2_c6']!.valor, 1);
    expect(bloc.state.celdas['f1_c2']!.valor, isNull);
  });

  test('Completar permite iniciar y bloquea ediciones posteriores', () async {
    await presentar(bloc);
    final ids = bloc.state.celdas.values
        .where((c) => c.esInicio)
        .map((c) => c.id)
        .toList();
    for (var i = 0; i < ids.length; i++) {
      final disparo = await disparar(bloc, ids[i], i + 1);
      expect(bloc.state.puedeIniciar, isFalse);
      await enviar(bloc, DisparoNumeroCompletado(disparo.id));
    }
    expect(bloc.state.faseVisual, FaseVisualInicio.listo);
    expect(bloc.state.puedeIniciar, isTrue);
    await enviar(bloc, CeldaInicialSeleccionada(ids.last));
    expect(bloc.state.puedeIniciar, isFalse);
    expect(bloc.state.numerosFaltantes, {6});
    final ultimo = await disparar(bloc, ids.last, 6);
    await enviar(bloc, DisparoNumeroCompletado(ultimo.id));
    await enviar(bloc, const InicioSolicitado());
    expect(bloc.state.faseVisual, FaseVisualInicio.iniciado);
    expect(bloc.state.interaccionBloqueada, isTrue);
    for (final evento in [
      NumeroInicialSeleccionado(1),
      CeldaInicialSeleccionada(ids.first),
      const SeleccionCancelada(),
    ]) {
      await enviar(bloc, evento);
      expect(bloc.state.error, isNotNull);
      expect(bloc.state.numerosFaltantes, isEmpty);
    }
    expect(bloc.crearTableroParaJuego().obtenerCelda(ids.last).valor, 6);
  });

  test(
    'Precarga lista espera la presentación antes de habilitar inicio',
    () async {
      final precarga = tablero();
      var valor = 1;
      for (final celda in precarga.celdas.values.where((c) => c.esInicio)) {
        precarga.colocarValor(celda.id, valor++);
      }
      final listo = InicioBloc(precarga, animarEntrada: true);
      addTearDown(listo.close);
      expect(listo.state.fase, FaseInicio.listo);
      expect(listo.state.puedeIniciar, isFalse);
      await presentar(listo);
      expect(listo.state.puedeIniciar, isTrue);
    },
  );
}
