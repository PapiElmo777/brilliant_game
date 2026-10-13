import 'dart:ui';

import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final casos = <Tipo, (Color, String, Map<int, int>)>{
    const TipoAzul(): (
      const Color(0xFF2196F3),
      'Todos los números deben de ser iguales',
      {1: 7, 2: 5, 3: 3},
    ),
    const TipoAmarillo(): (
      const Color(0xFFFFC107),
      'Todos los números deben de ser distintos',
      {1: 8, 2: 6, 3: 4},
    ),
    const TipoRojo(): (
      const Color(0xFFF44336),
      'Todos los números deben de ser distintos',
      {1: 8, 2: 6, 3: 4},
    ),
    const TipoVerde(): (
      const Color(0xFF4CAF50),
      'Se puede colocar cualquier número',
      {1: 4, 2: 3, 3: 2},
    ),
    const TipoMorado(): (
      const Color(0xFF9C27B0),
      'Máximo dos números diferentes por zona',
      {1: 8, 2: 6, 3: 4},
    ),
  };

  for (final caso in casos.entries) {
    test('${caso.key.runtimeType}: color, descripción y puntuaciones', () {
      expect(caso.key.color, caso.value.$1);
      expect(caso.key.descripcion, caso.value.$2);
      expect(caso.key.puntuaciones, caso.value.$3);
      expect(() => caso.key.puntuaciones[1] = 99, throwsUnsupportedError);
    });
    test('${caso.key.runtimeType}: acepta inicio y no modifica la entrada', () {
      final actuales = <int>[];
      expect(caso.key.esPosibleAgregar(actuales, 4), isTrue);
      expect(actuales, isEmpty);
    });
  }

  test('Azul solo permite repetir el número existente', () {
    const tipo = TipoAzul();
    expect(tipo.esPosibleAgregar([4, 4], 4), isTrue);
    expect(tipo.esPosibleAgregar([4, 4], 5), isFalse);
  });

  for (final tipo in const [TipoRojo(), TipoAmarillo()]) {
    test('${tipo.runtimeType}: rechaza un número ya colocado', () {
      expect(tipo.esPosibleAgregar([1, 2], 3), isTrue);
      expect(tipo.esPosibleAgregar([1, 2], 2), isFalse);
      expect(validarValoresDeTipo(tipo, [1, 1, 2]), isFalse);
    });
  }

  test('Verde no impone restricciones de color; la zona controla el rango', () {
    const tipo = TipoVerde();
    expect(tipo.esPosibleAgregar([1, 2, 3], 3), isTrue);
    expect(tipo.esPosibleAgregar([], 7), isTrue);
    final zona = Zona(
      id: '2',
      tipo: tipo,
      celdas: [Celda(id: 'C1', fila: 0, columna: 0)],
    );
    expect(zona.puedeColocarValor('C1', 7), isFalse);
    expect(() => zona.colocarValor('C1', 7), throwsArgumentError);
    expect(zona.valores, isEmpty);
  });

  test('Morado acepta hasta dos distintos sin modificar actuales', () {
    const tipo = TipoMorado();
    final actuales = [3, 5, 3];
    expect(tipo.esPosibleAgregar(actuales, 5), isTrue);
    expect(tipo.esPosibleAgregar(actuales, 1), isFalse);
    expect(actuales, [3, 5, 3]);
  });

  test(
    'Zona admite otra implementación de Tipo sin cambiar enums ni switches',
    () {
      final zona = Zona(
        id: 'prueba',
        tipo: const _TipoSoloPares(),
        celdas: [Celda(id: 'C1', fila: 0, columna: 0)],
      );
      expect(zona.puedeColocarValor('C1', 3), isFalse);
      zona.colocarValor('C1', 4);
      expect(zona.valores, [4]);
    },
  );
}

// Doble de prueba para comprobar que Zona depende del contrato abstracto.
class _TipoSoloPares extends Tipo {
  const _TipoSoloPares();

  @override
  Color get color => const Color(0xFF000000);

  @override
  String get descripcion => 'Solo pares';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) => posible.isEven;

  @override
  Map<int, int> get puntuaciones => const {};
}
