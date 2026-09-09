import 'package:brilliant_game/brilliant_game.dart';
import 'package:test/test.dart';

Zona crearZona(
  TipoZona tipo, {
  List<int?> valores = const [null, null, null],
}) => Zona(
  id: '2',
  tipo: tipo,
  campoPuntuacion: 'puntos2',
  celdas: [
    for (var i = 0; i < valores.length; i++)
      Celda(id: 'C$i', fila: 0, columna: i, valorInicial: valores[i]),
  ],
);

void main() {
  final ejemplos = <TipoZona, (List<int>, List<int>?)>{
    TipoZona.verde: ([1, 6, 3, 3], null),
    TipoZona.azul: ([4, 4, 4, 4], [4, 4, 5]),
    TipoZona.rojo: ([1, 2, 3, 4], [1, 2, 2]),
    TipoZona.amarillo: ([1, 2, 3, 4], [1, 2, 2]),
    TipoZona.morado: ([5, 5, 2, 5], [5, 2, 1]),
  };

  for (final entry in ejemplos.entries) {
    test('${entry.key.name}: valida números, vacíos, rango y capacidad', () {
      final zona = crearZona(entry.key, valores: [null, null, null, null]);
      expect(zona.validarValores(entry.value.$1), isTrue);
      if (entry.value.$2 != null) {
        expect(zona.validarValores(entry.value.$2!), isFalse);
      }
      expect(zona.validarValores([]), isTrue);
      expect(zona.validarValores([0]), isFalse);
      expect(zona.validarValores([7]), isFalse);
      expect(zona.validarValores([1, 2, 3, 4, 5]), isFalse);
    });
  }

  test('Cada tipo tiene una regla fija y rojo y amarillo la comparten', () {
    expect(TipoZona.values.length, 5);
    expect(TipoZona.verde.regla, ReglaZona.cualquierNumero);
    expect(TipoZona.azul.regla, ReglaZona.todosIguales);
    expect(TipoZona.rojo.regla, ReglaZona.todosDiferentes);
    expect(TipoZona.amarillo.regla, ReglaZona.todosDiferentes);
    expect(TipoZona.morado.regla, ReglaZona.maxDosDiferentes);
  });

  test('Completada refleja ocupación real y cambia al vaciar', () {
    final zona = crearZona(TipoZona.verde);
    expect(zona.estaCompletada, isFalse);
    zona.colocarValor('C0', 1);
    expect(zona.estaCompletada, isFalse);
    zona.colocarValor('C1', 2);
    zona.colocarValor('C2', 3);
    expect(zona.estaCompletada, isTrue);
    zona.vaciarCelda('C1');
    expect(zona.estaCompletada, isFalse);
    expect(zona.valores, [1, 3]);
    expect(zona.campoPuntuacion, 'puntos2');
  });

  test('Consulta y rechazo de una colocación no modifican la zona', () {
    final zona = crearZona(TipoZona.azul, valores: [4, null, 4]);
    final anterior = zona.celdas['C1'];
    expect(zona.puedeColocarValor('C1', 5), isFalse);
    expect(zona.valores, [4, 4]);
    expect(() => zona.colocarValor('C1', 5), throwsArgumentError);
    expect(zona.celdas['C1'], same(anterior));
    expect(zona.valores, [4, 4]);
    zona.colocarValor('C1', 4);
    expect(zona.estaCompletada, isTrue);
  });

  test('Reemplazar excluye el valor previo y conserva estado ante errores', () {
    final zona = crearZona(TipoZona.rojo, valores: [1, 2, null]);
    zona.colocarValor('C0', 1);
    zona.colocarValor('C0', 3);
    expect(zona.valores, [3, 2]);
    expect(() => zona.colocarValor('C0', 2), throwsArgumentError);
    expect(() => zona.colocarValor('C0', 7), throwsArgumentError);
    expect(zona.valores, [3, 2]);
  });

  test('Morado permite reemplazar uno de dos distintos por un tercero', () {
    final zona = crearZona(TipoZona.morado, valores: [1, 2, null]);
    zona.colocarValor('C0', 3);
    expect(zona.valores, [3, 2]);
    expect(() => zona.colocarValor('C2', 1), throwsArgumentError);
  });

  test('Rechaza configuraciones iniciales que incumplen el tipo', () {
    expect(
      () => crearZona(TipoZona.azul, valores: [1, 2]),
      throwsArgumentError,
    );
    expect(
      () => crearZona(TipoZona.rojo, valores: [1, 1]),
      throwsArgumentError,
    );
    expect(
      () => crearZona(TipoZona.morado, valores: [1, 2, 3]),
      throwsArgumentError,
    );
  });

  test('Rechaza zona sin identidad, vacía, IDs y coordenadas duplicadas', () {
    final celda = Celda(id: 'C1', fila: 0, columna: 0);
    expect(
      () => Zona(id: '', tipo: TipoZona.verde, celdas: [celda]),
      throwsArgumentError,
    );
    expect(
      () => Zona(id: '2', tipo: TipoZona.verde, celdas: []),
      throwsArgumentError,
    );
    expect(
      () => Zona(id: '2', tipo: TipoZona.verde, celdas: [celda, celda]),
      throwsArgumentError,
    );
    expect(
      () => Zona(
        id: '2',
        tipo: TipoZona.verde,
        celdas: [
          celda,
          Celda(id: 'C2', fila: 0, columna: 0),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('Rechaza acciones sobre una celda ajena', () {
    final zona = crearZona(TipoZona.verde);
    expect(() => zona.puedeColocarValor('X', 1), throwsArgumentError);
    expect(() => zona.colocarValor('X', 1), throwsArgumentError);
    expect(() => zona.vaciarCelda('X'), throwsArgumentError);
  });

  test(
    'El llamador no puede cambiar la estructura ni los valores por las vistas',
    () {
      final entrada = [Celda(id: 'C0', fila: 0, columna: 0)];
      final zona = Zona(id: '2', tipo: TipoZona.verde, celdas: entrada);
      entrada.clear();
      expect(zona.celdas.length, 1);
      expect(() => zona.celdas.clear(), throwsUnsupportedError);
      expect(() => zona.valores.add(2), throwsUnsupportedError);
      zona.celdas['C0']!.conValor(4);
      expect(zona.valores, isEmpty);
    },
  );
}
