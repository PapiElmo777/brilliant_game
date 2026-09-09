import 'dart:collection';

import '../core/reglas.dart';
import 'celda.dart';
import 'tipo_zona.dart';

/// Conjunto no vacío de casillas con un tipo y una regla común.
/// Los identificadores son locales al tablero, independientes del color.
class Zona {
  final String id;
  final TipoZona tipo;
  final String? campoPuntuacion;
  final Map<String, Celda> _celdas = {};

  Zona({
    required this.id,
    required this.tipo,
    required Iterable<Celda> celdas,
    this.campoPuntuacion,
  }) {
    if (id.trim().isEmpty)
      throw ArgumentError('El ID de zona no puede estar vacío.');
    final posiciones = <(int, int)>{};
    for (final celda in celdas) {
      if (_celdas.containsKey(celda.id)) {
        throw ArgumentError(
          'La celda ${celda.id} está duplicada en la zona $id.',
        );
      }
      if (!posiciones.add((celda.fila, celda.columna))) {
        throw ArgumentError('Hay coordenadas duplicadas en la zona $id.');
      }
      _celdas[celda.id] = celda;
    }
    if (_celdas.isEmpty)
      throw ArgumentError('La zona $id debe contener celdas.');
    if (!validarValores(valores)) {
      throw ArgumentError(
        'Los valores iniciales de la zona $id incumplen su regla.',
      );
    }
  }

  Map<String, Celda> get celdas => UnmodifiableMapView(_celdas);
  ReglaZona get regla => tipo.regla;
  List<int> get valores => List.unmodifiable(
    _celdas.values.map((celda) => celda.valor).whereType<int>(),
  );
  bool get estaCompletada => _celdas.values.every((celda) => celda.estaOcupada);

  /// Valida una configuración propuesta, incluida la capacidad de la zona.
  bool validarValores(Iterable<int> valores) {
    final lista = valores.toList();
    return lista.length <= _celdas.length && regla.validarValores(lista);
  }

  Celda _obtenerCelda(String celdaId) {
    final celda = _celdas[celdaId];
    if (celda == null) {
      throw ArgumentError('La celda $celdaId no pertenece a la zona $id.');
    }
    return celda;
  }

  /// También permite reemplazar un valor, como el modelo original.
  /// La simulación excluye el valor anterior de la casilla elegida.
  bool puedeColocarValor(String celdaId, int valor) {
    _obtenerCelda(celdaId);
    return validarValores([
      for (final celda in _celdas.values)
        if (celda.id != celdaId && celda.valor != null) celda.valor!,
      valor,
    ]);
  }

  /// Rechaza la operación sin modificar el estado si incumple la regla.
  void colocarValor(String celdaId, int valor) {
    final celda = _obtenerCelda(celdaId);
    if (!puedeColocarValor(celdaId, valor)) {
      throw ArgumentError(
        'El valor $valor incumple la regla o el rango de la zona $id.',
      );
    }
    _celdas[celdaId] = celda.conValor(valor);
  }

  void vaciarCelda(String celdaId) {
    _celdas[celdaId] = _obtenerCelda(celdaId).sinValor();
  }
}
