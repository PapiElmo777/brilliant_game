import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

Zona zona(
  String id,
  String celdaId,
  int fila,
  int columna, {
  Tipo tipo = const TipoVerde(),
}) => Zona(
  id: id,
  tipo: tipo,
  celdas: [Celda(id: celdaId, fila: fila, columna: columna)],
);

Tablero crearTablero() => Tablero(
  id: 'nivel1',
  zonas: [
    Zona(
      id: '2',
      tipo: const TipoAzul(),
      celdas: [
        Celda(id: 'C00', fila: 0, columna: 0),
        Celda(id: 'C01', fila: 0, columna: 1),
      ],
    ),
    Zona(
      id: '7',
      tipo: const TipoAzul(),
      celdas: [
        Celda(id: 'C10', fila: 1, columna: 0),
        Celda(id: 'C11', fila: 1, columna: 1),
      ],
    ),
  ],
);

void main() {
  test('Busca casillas y vecinos ortogonales aunque sean de otra zona', () {
    final tablero = crearTablero();
    expect(tablero.obtenerCeldaEn(0, 0)?.id, 'C00');
    expect(tablero.obtenerCeldaEn(2, 2), isNull);
    final vecinos = tablero.obtenerVecinos('C00');
    expect(vecinos['arriba'], isNull);
    expect(vecinos['izquierda'], isNull);
    expect(vecinos['derecha']?.id, 'C01');
    expect(vecinos['abajo']?.id, 'C10');
    expect(vecinos.length, 4);
  });

  test('Admite huecos en el tablero', () {
    final tablero = Tablero(
      id: 'irregular',
      zonas: [zona('2', 'A', 0, 0), zona('7', 'B', 0, 2)],
    );
    expect(tablero.obtenerCeldaEn(0, 1), isNull);
    expect(tablero.obtenerVecinos('A')['derecha'], isNull);
  });

  test('Zonas del mismo tipo aplican sus reglas de forma independiente', () {
    final tablero = crearTablero();
    tablero.colocarValor('C00', 4);
    tablero.colocarValor('C10', 2);
    expect(tablero.extraerValoresDeZona('2'), [4]);
    expect(tablero.extraerValoresDeZona('7'), [2]);
    expect(tablero.puedeColocarValor('C01', 2), isFalse);
    expect(tablero.puedeColocarValor('C11', 2), isTrue);
    expect(tablero.obtenerZonaDeCelda('C10').id, '7');
  });

  test(
    'Distintos tableros pueden reutilizar IDs con otros tipos y posiciones',
    () {
      final uno = Tablero(id: 'nivel1', zonas: [zona('2', 'A', 0, 0)]);
      final dos = Tablero(
        id: 'nivel2',
        zonas: [zona('2', 'A', 4, 5, tipo: const TipoRojo())],
      );
      uno.colocarValor('A', 6);
      expect(dos.obtenerCelda('A').valor, isNull);
      expect(uno.obtenerZona('2').tipo, const TipoVerde());
      expect(dos.obtenerZona('2').tipo, const TipoRojo());
      expect(dos.obtenerCeldaEn(4, 5)?.id, 'A');
    },
  );

  test('Extracción vacía, parcial, completa y tras vaciar', () {
    final tablero = crearTablero();
    expect(tablero.extraerValoresDeZona('2'), isEmpty);
    tablero.colocarValor('C00', 4);
    expect(tablero.extraerValoresDeZona('2'), [4]);
    tablero.colocarValor('C01', 4);
    expect(tablero.extraerValoresDeZona('2'), [4, 4]);
    tablero.vaciarCelda('C00');
    expect(tablero.extraerValoresDeZona('2'), [4]);
  });

  test('Tablero valida antes de modificar y sus consultas ven los cambios', () {
    final tablero = crearTablero();
    tablero.colocarValor('C00', 4);
    expect(() => tablero.colocarValor('C01', 5), throwsArgumentError);
    expect(tablero.obtenerCeldaEn(0, 1)?.valor, isNull);
    tablero.obtenerZona('2').colocarValor('C01', 4);
    expect(tablero.obtenerCelda('C01').valor, 4);
    expect(tablero.celdas['C01']?.valor, 4);
    expect(tablero.obtenerVecinos('C00')['derecha']?.valor, 4);
  });

  test('Rechaza referencias inexistentes en consultas y acciones', () {
    final tablero = crearTablero();
    expect(() => tablero.obtenerZona('X'), throwsArgumentError);
    expect(() => tablero.extraerValoresDeZona('X'), throwsArgumentError);
    expect(() => tablero.obtenerCelda('X'), throwsArgumentError);
    expect(() => tablero.obtenerVecinos('X'), throwsArgumentError);
    expect(() => tablero.puedeColocarValor('X', 1), throwsArgumentError);
    expect(() => tablero.colocarValor('X', 1), throwsArgumentError);
    expect(() => tablero.vaciarCelda('X'), throwsArgumentError);
  });

  test('Rechaza tableros vacíos o sin identificador', () {
    expect(() => Tablero(id: 'nivel1', zonas: []), throwsArgumentError);
    expect(
      () => Tablero(id: '', zonas: [zona('2', 'A', 0, 0)]),
      throwsArgumentError,
    );
  });

  test('Rechaza IDs de zona repetidos', () {
    expect(
      () => Tablero(
        id: 'nivel1',
        zonas: [zona('2', 'A', 0, 0), zona('2', 'B', 1, 0)],
      ),
      throwsArgumentError,
    );
  });

  test('Rechaza una celda en dos zonas por ID', () {
    expect(
      () => Tablero(
        id: 'nivel1',
        zonas: [zona('2', 'A', 0, 0), zona('7', 'A', 1, 0)],
      ),
      throwsArgumentError,
    );
  });

  test('Rechaza coordenadas superpuestas entre zonas', () {
    expect(
      () => Tablero(
        id: 'nivel1',
        zonas: [zona('2', 'A', 0, 0), zona('7', 'B', 0, 0)],
      ),
      throwsArgumentError,
    );
  });

  test('Las colecciones no permiten romper la pertenencia de las celdas', () {
    final entrada = [zona('2', 'A', 0, 0)];
    final tablero = Tablero(id: 'nivel1', zonas: entrada);
    entrada.clear();
    expect(tablero.zonas.length, 1);
    expect(() => tablero.zonas.clear(), throwsUnsupportedError);
    expect(() => tablero.celdas.clear(), throwsUnsupportedError);
  });
}
