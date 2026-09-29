import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CatalogoTableros catalogo;

  setUp(() => catalogo = CatalogoTableros.predeterminado());

  test('El primer tablero reproduce las 49 posiciones y las 13 zonas', () {
    final tablero = catalogo.crearTablero('tablero_01');
    const matriz = [
      [
        'amarillo_1',
        'verde_1',
        'azul_1',
        'morado_1',
        'morado_1',
        'morado_1',
        'amarillo_2',
      ],
      [
        'verde_1',
        'verde_1',
        'azul_1',
        'azul_1',
        'morado_1',
        'morado_1',
        'verde_2',
      ],
      [
        'verde_1',
        'rojo_1',
        'rojo_1',
        'azul_1',
        'morado_1',
        'verde_2',
        'verde_2',
      ],
      [
        'verde_1',
        'rojo_1',
        'morado_2',
        'amarillo_3',
        'verde_2',
        'verde_2',
        'verde_2',
      ],
      ['verde_1', 'rojo_1', 'morado_2', 'rojo_2', 'rojo_2', 'rojo_2', 'azul_2'],
      ['rojo_1', 'rojo_1', 'morado_2', 'rojo_2', 'rojo_2', 'azul_2', 'azul_2'],
      [
        'amarillo_4',
        'morado_2',
        'morado_2',
        'rojo_2',
        'rojo_2',
        'azul_2',
        'amarillo_5',
      ],
    ];
    final tipos = <String, Tipo>{
      'amarillo': const TipoAmarillo(),
      'verde': const TipoVerde(),
      'azul': const TipoAzul(),
      'morado': const TipoMorado(),
      'rojo': const TipoRojo(),
    };
    expect(tablero.id, 'tablero_01');
    expect(tablero.celdas.length, 49);
    expect(tablero.zonas.length, 13);
    for (var fila = 0; fila < 7; fila++) {
      for (var columna = 0; columna < 7; columna++) {
        final celda = tablero.obtenerCeldaEn(fila, columna)!;
        final zona = tablero.obtenerZonaDeCelda(celda.id);
        final idEsperado = matriz[fila][columna];
        final tipoEsperado = tipos[idEsperado.split('_').first]!;
        expect(zona.id, idEsperado);
        expect(zona.tipo.runtimeType, tipoEsperado.runtimeType);
        expect(zona.tipo.color, tipoEsperado.color);
        expect(celda.valor, isNull);
      }
    }
  });

  test('Las seis iniciales coinciden y permiten completar la preparación', () {
    final tablero = catalogo.crearTablero('tablero_01');
    final iniciales = tablero.celdas.values.where((celda) => celda.esInicio);
    expect(iniciales.map((c) => (c.fila, c.columna)).toSet(), {
      (0, 1),
      (1, 5),
      (3, 1),
      (3, 4),
      (5, 2),
      (6, 4),
    });
    final preparacion = PreparacionInicial(tablero);
    var valor = 1;
    for (final celda in iniciales) {
      preparacion.colocarValor(celda.id, valor++);
    }
    expect(preparacion.estaLista, isTrue);
    expect(preparacion.crearTableroParaJuego().celdas.length, 49);
  });

  test('Las partidas no comparten zonas ni valores con la definición', () {
    final primero = catalogo.crearTablero('tablero_01');
    final segundo = catalogo.crearTablero('tablero_01');
    for (final id in primero.zonas.keys) {
      expect(identical(primero.zonas[id], segundo.zonas[id]), isFalse);
    }
    primero.colocarValor('f1_c2', 5);
    expect(segundo.obtenerCelda('f1_c2').valor, isNull);
    final tercero = catalogo.crearTablero('tablero_01');
    expect(tercero.obtenerCelda('f1_c2').valor, isNull);
    segundo.colocarValor('f1_c2', 3);
    expect(primero.obtenerCelda('f1_c2').valor, 5);
  });

  test('El catálogo rechaza IDs desconocidos y definiciones duplicadas', () {
    expect(() => catalogo.crearTablero('inexistente'), throwsArgumentError);
    final definicion = catalogo.obtenerDefinicion('tablero_01');
    expect(
      () => CatalogoTableros(definiciones: [definicion, definicion]),
      throwsArgumentError,
    );
  });

  test('Las colecciones de definiciones son inmutables y copian entradas', () {
    final original = catalogo.obtenerDefinicion('tablero_01');
    final zonas = original.zonas.toList();
    final copia = DefinicionTablero(id: 'copia', zonas: zonas);
    zonas.clear();
    expect(copia.zonas.length, 13);
    final celdas = original.zonas.first.celdas.toList();
    final zona = DefinicionZona(
      id: 'copia',
      tipo: const TipoVerde(),
      celdas: celdas,
    );
    celdas.clear();
    expect(zona.celdas.length, 1);
    final definiciones = [copia];
    final otro = CatalogoTableros(definiciones: definiciones);
    definiciones.clear();
    expect(otro.definiciones.keys, ['copia']);
    expect(() => copia.zonas.clear(), throwsUnsupportedError);
    expect(() => zona.celdas.clear(), throwsUnsupportedError);
    expect(() => otro.definiciones.clear(), throwsUnsupportedError);
  });
}
