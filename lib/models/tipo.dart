import 'dart:ui';

/// Define la presentación, restricción de color y puntuaciones de una zona.
/// El rango 1–6 y la capacidad se validan al operar sobre la zona.
abstract class Tipo {
  const Tipo();

  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);

  /// Puntos por puesto al completar la zona: el primer jugador en hacerlo
  /// recibe `puntuaciones[1]`, el segundo `[2]` y el tercero `[3]`.
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
  Map<int, int> get puntuaciones => const {1: 7, 2: 6, 3: 3};
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
  Map<int, int> get puntuaciones => const {1: 6, 2: 4, 3: 2};
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
  Map<int, int> get puntuaciones => const {1: 6, 2: 4, 3: 2};
}

class TipoBlanco extends TipoAzul {
  const TipoBlanco();
  @override
  Color get color => const Color(0xFFECEFF1);
}

enum GrupoNaranja { bajo, alto }

class TipoNaranja extends Tipo {
  final GrupoNaranja grupo;
  const TipoNaranja(this.grupo);
  @override
  Color get color => const Color(0xFFFF9800);
  @override
  String get descripcion => grupo == GrupoNaranja.alto
      ? 'Solo números del 4 al 6, con repeticiones'
      : 'Solo números del 1 al 3, con repeticiones';
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    bool permitido(int n) =>
        grupo == GrupoNaranja.alto ? n >= 4 && n <= 6 : n >= 1 && n <= 3;
    return permitido(posible) && actuales.every(permitido);
  }

  @override
  Map<int, int> get puntuaciones => const {1: 6, 2: 4, 3: 3};
}
