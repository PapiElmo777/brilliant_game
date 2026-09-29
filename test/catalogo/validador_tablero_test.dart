import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

List<Celda> celdas({int cantidad = 49, int iniciales = 6}) => [
  for (var i = 0; i < cantidad; i++)
    Celda(id: 'c$i', fila: i ~/ 7, columna: i % 7, esInicio: i < iniciales),
];

DefinicionZona zona(List<Celda> celdas, {String id = 'verde'}) =>
    DefinicionZona(id: id, tipo: const TipoVerde(), celdas: celdas);

DefinicionTablero definir(List<Celda> celdas) =>
    DefinicionTablero(id: 'prueba', zonas: [zona(celdas)]);

void main() {
  test('Acepta una definición completa', () {
    expect(() => definir(celdas()), returnsNormally);
  });

  for (final cantidad in [48, 50]) {
    test('Rechaza $cantidad celdas', () {
      expect(() => definir(celdas(cantidad: cantidad)), throwsArgumentError);
    });
  }

  for (final posicion in [(-1, 0), (7, 0), (0, -1), (0, 7)]) {
    test('Rechaza la coordenada fuera de rango $posicion', () {
      final lista = celdas();
      lista[48] = Celda(id: 'c48', fila: posicion.$1, columna: posicion.$2);
      expect(() => definir(lista), throwsArgumentError);
    });
  }

  for (final cantidad in [0, 5, 7]) {
    test('Rechaza $cantidad celdas iniciales', () {
      expect(() => definir(celdas(iniciales: cantidad)), throwsArgumentError);
    });
  }

  test('Rechaza valores en celdas no iniciales', () {
    final lista = celdas();
    lista[48] = lista[48].conValor(2);
    expect(() => definir(lista), throwsArgumentError);
  });

  test('Acepta precarga válida y rechaza números iniciales repetidos', () {
    final lista = celdas();
    lista[0] = lista[0].conValor(1);
    lista[1] = lista[1].conValor(2);
    expect(() => definir(lista), returnsNormally);
    lista[1] = lista[1].conValor(1);
    expect(() => definir(lista), throwsArgumentError);
  });

  test('Rechaza zonas con el mismo ID', () {
    final lista = celdas();
    expect(
      () => DefinicionTablero(
        id: 'prueba',
        zonas: [zona(lista.sublist(0, 7)), zona(lista.sublist(7))],
      ),
      throwsArgumentError,
    );
  });

  for (final entreZonas in [false, true]) {
    for (final duplicarId in [false, true]) {
      test(
        'Rechaza duplicado de ${duplicarId ? 'ID' : 'posición'}, entre zonas: $entreZonas',
        () {
          final lista = celdas();
          lista[48] = Celda(
            id: duplicarId ? 'c0' : 'c48',
            fila: duplicarId ? 6 : 0,
            columna: duplicarId ? 6 : 0,
          );
          expect(
            () => DefinicionTablero(
              id: 'prueba',
              zonas: entreZonas
                  ? [
                      zona(lista.sublist(0, 7)),
                      zona(lista.sublist(7), id: 'otra'),
                    ]
                  : [zona(lista)],
            ),
            throwsArgumentError,
          );
        },
      );
    }
  }

  test('La validación jugable no cambia el contrato genérico de Tablero', () {
    final tablero = Tablero(
      id: 'pequeno',
      zonas: [zona(celdas(cantidad: 2)).crearZona()],
    );
    expect(tablero.celdas.length, 2);
    expect(() => validarTablero7x7(tablero), throwsArgumentError);
  });
}
