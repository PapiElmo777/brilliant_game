import 'dart:ui';

/// Define la presentación, restricción de color y puntuaciones de una zona.
/// El rango 1–6 y la capacidad se validan al operar sobre la zona.
abstract class Tipo {
  const Tipo();

  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuaciones;
}

class TipoAzul extends Tipo {
  const TipoAzul();

  @override
  Color get color => const Color(0xFF2196F3);

  @override
  String get descripcion => 'Todos los números deben de ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      actuales.isEmpty || actuales.every((elemento) => elemento == posible);

  @override
  Map<int, int> get puntuaciones => const {1: 7, 2: 5, 3: 3};
}

class TipoAmarillo extends Tipo {
  const TipoAmarillo();

  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      actuales.isEmpty || actuales.every((elemento) => elemento != posible);

  @override
  Map<int, int> get puntuaciones => const {1: 8, 2: 6, 3: 4};
}

class TipoRojo extends Tipo {
  const TipoRojo();

  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      actuales.isEmpty || actuales.every((elemento) => elemento != posible);

  @override
  Map<int, int> get puntuaciones => const {1: 8, 2: 6, 3: 4};
}

class TipoVerde extends Tipo {
  const TipoVerde();

  @override
  Color get color => const Color(0xFF4CAF50);

  @override
  String get descripcion => 'Se puede colocar cualquier número';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) => true;

  @override
  Map<int, int> get puntuaciones => const {1: 4, 2: 3, 3: 2};
}

class TipoMorado extends Tipo {
  const TipoMorado();

  @override
  Color get color => const Color(0xFF9C27B0);

  @override
  String get descripcion => 'Máximo dos números diferentes por zona';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }

  @override
  Map<int, int> get puntuaciones => const {1: 8, 2: 6, 3: 4};
}
