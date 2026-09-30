import 'dart:math';

import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

Tablero tableroInicial({int cantidad = 6, Tipo tipo = const TipoVerde()}) =>
    Tablero(
      id: 'inicio',
      zonas: [
        Zona(
          id: '1',
          tipo: tipo,
          celdas: [
            for (var i = 1; i <= cantidad; i++)
              Celda(id: 'C$i', fila: 0, columna: i, esInicio: true),
            Celda(id: 'normal', fila: 1, columna: 0),
          ],
        ),
      ],
    );

void main() {
  test('Al comenzar faltan los seis números y se bloquea la entrega', () {
    final preparacion = PreparacionInicial(tableroInicial());
    expect(preparacion.numerosFaltantes, {1, 2, 3, 4, 5, 6});
    expect(preparacion.estaLista, isFalse);
    expect(preparacion.crearTableroParaJuego, throwsStateError);
  });

  test('Permite cualquier orden y solo habilita con los seis números', () {
    final preparacion = PreparacionInicial(tableroInicial());
    final numeros = [6, 2, 4, 1, 5, 3];
    for (var i = 0; i < numeros.length; i++) {
      expect(preparacion.estaLista, isFalse);
      preparacion.colocarValor('C${i + 1}', numeros[i]);
    }
    expect(preparacion.estaLista, isTrue);
    expect(preparacion.numerosFaltantes, isEmpty);
    expect(preparacion.crearTableroParaJuego().obtenerCelda('C1').valor, 6);
  });

  test('Rechaza repetidos y fuera de rango sin modificar el estado', () {
    final preparacion = PreparacionInicial(tableroInicial());
    preparacion.colocarValor('C1', 3);
    for (final valor in [3, 0, 7]) {
      expect(() => preparacion.colocarValor('C2', valor), throwsArgumentError);
      expect(preparacion.celdas['C2']!.valor, isNull);
    }
    expect(preparacion.numerosFaltantes, {1, 2, 4, 5, 6});
  });

  test('Reemplazar o retirar devuelve el número anterior a los faltantes', () {
    final preparacion = PreparacionInicial(tableroInicial());
    preparacion.colocarValor('C1', 3);
    preparacion.colocarValor('C1', 3);
    preparacion.colocarValor('C1', 5);
    expect(preparacion.numerosFaltantes, {1, 2, 3, 4, 6});
    preparacion.vaciarCelda('C1');
    expect(preparacion.numerosFaltantes.length, 6);
  });

  test('Vaciar después de completar vuelve a bloquear el inicio', () {
    final preparacion = PreparacionInicial(tableroInicial());
    for (var i = 1; i <= 6; i++) {
      preparacion.colocarValor('C$i', i);
    }
    preparacion.vaciarCelda('C6');
    expect(preparacion.estaLista, isFalse);
    expect(preparacion.numerosFaltantes, {6});
    expect(preparacion.crearTableroParaJuego, throwsStateError);
  });

  test('Rechaza casillas normales o inexistentes', () {
    final preparacion = PreparacionInicial(tableroInicial());
    for (final id in ['normal', 'desconocida']) {
      expect(() => preparacion.colocarValor(id, 1), throwsArgumentError);
      expect(() => preparacion.vaciarCelda(id), throwsArgumentError);
    }
  });

  test('Conserva las restricciones del tipo de zona', () {
    final preparacion = PreparacionInicial(
      tableroInicial(tipo: const TipoAzul()),
    );
    preparacion.colocarValor('C1', 1);
    expect(() => preparacion.colocarValor('C2', 2), throwsArgumentError);
    expect(preparacion.celdas['C2']!.valor, isNull);
  });

  test('Exige exactamente seis casillas de inicio', () {
    for (final cantidad in [0, 5, 7]) {
      expect(
        () => PreparacionInicial(tableroInicial(cantidad: cantidad)),
        throwsArgumentError,
      );
    }
  });

  test('Acepta valores precargados válidos', () {
    final tablero = tableroInicial();
    tablero.colocarValor('C1', 4);
    final preparacion = PreparacionInicial(tablero);
    expect(preparacion.numerosFaltantes, {1, 2, 3, 5, 6});
    expect(preparacion.celdas['C1']!.valor, 4);
  });

  test('Rechaza precarga repetida o números fuera de casillas de inicio', () {
    final repetido = tableroInicial();
    repetido.colocarValor('C1', 1);
    repetido.colocarValor('C2', 1);
    expect(() => PreparacionInicial(repetido), throwsArgumentError);
    final ocupado = tableroInicial();
    ocupado.colocarValor('normal', 2);
    expect(() => PreparacionInicial(ocupado), throwsArgumentError);
  });

  test('Aísla el tablero original y las instantáneas anteriores', () {
    final tablero = tableroInicial();
    final preparacion = PreparacionInicial(tablero);
    final anterior = preparacion.celdas;
    tablero.colocarValor('C1', 6);
    expect(preparacion.celdas['C1']!.valor, isNull);
    preparacion.colocarValor('C2', 2);
    expect(tablero.obtenerCelda('C2').valor, isNull);
    expect(anterior['C2']!.valor, isNull);
    expect(() => preparacion.celdas.clear(), throwsUnsupportedError);
    expect(() => preparacion.numerosFaltantes.clear(), throwsUnsupportedError);
  });

  test('La entrega crea un tablero independiente con zonas y tipos', () {
    final preparacion = PreparacionInicial(tableroInicial());
    for (var i = 1; i <= 6; i++) {
      preparacion.colocarValor('C$i', i);
    }
    final juego = preparacion.crearTableroParaJuego();
    juego.vaciarCelda('C1');
    expect(preparacion.estaLista, isTrue);
    expect(juego.obtenerZona('1').tipo, isA<TipoVerde>());
  });

  group('Distribución aleatoria', () {
    test('Completa sólo las casillas vacías sin modificar la preparación', () {
      final preparacion = PreparacionInicial(tableroInicial());
      preparacion.colocarValor('C1', 4);
      final distribucion = preparacion.distribucionAleatoria(Random(3));
      expect(distribucion.map((d) => d.$2), [1, 2, 3, 5, 6]);
      expect(distribucion.map((d) => d.$1).toSet(), {
        'C2',
        'C3',
        'C4',
        'C5',
        'C6',
      });
      expect(preparacion.numerosFaltantes, {1, 2, 3, 5, 6});
      for (final (celdaId, valor) in distribucion) {
        preparacion.colocarValor(celdaId, valor);
      }
      expect(preparacion.estaLista, isTrue);
      expect(preparacion.celdas['C1']!.valor, 4);
    });

    test('Respeta las reglas de zona del primer tablero y varía', () {
      final resultados = <String>{};
      for (var semilla = 0; semilla < 20; semilla++) {
        final preparacion = PreparacionInicial(
          CatalogoTableros.predeterminado().crearTablero('tablero_01'),
        );
        final distribucion = preparacion.distribucionAleatoria(Random(semilla));
        for (final (celdaId, valor) in distribucion) {
          preparacion.colocarValor(celdaId, valor);
        }
        expect(preparacion.estaLista, isTrue);
        resultados.add(distribucion.toString());
      }
      expect(resultados.length, greaterThan(1));
    });

    test('Rechaza una configuración imposible', () {
      final preparacion = PreparacionInicial(
        tableroInicial(tipo: const TipoAzul()),
      );
      expect(
        () => preparacion.distribucionAleatoria(Random(1)),
        throwsStateError,
      );
      expect(preparacion.numerosFaltantes.length, 6);
    });
  });
}
