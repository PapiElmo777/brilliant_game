import '../core/reglas.dart';

/// El tipo es el color de la zona; su regla se deriva de él.
enum TipoZona {
  verde,
  azul,
  rojo,
  morado,
  amarillo;

  ReglaZona get regla => switch (this) {
    TipoZona.verde => ReglaZona.cualquierNumero,
    TipoZona.azul => ReglaZona.todosIguales,
    TipoZona.rojo || TipoZona.amarillo => ReglaZona.todosDiferentes,
    TipoZona.morado => ReglaZona.maxDosDiferentes,
  };
}
