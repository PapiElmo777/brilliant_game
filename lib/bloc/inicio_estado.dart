import '../models/celda.dart';

enum FaseInicio { preparando, listo, iniciado }

/// Instantánea inmutable para consultar desde la futura interfaz.
class InicioEstado {
  final FaseInicio fase;
  final Map<String, Celda> celdas;
  final Set<int> numerosFaltantes;
  final String? error;

  InicioEstado({
    required this.fase,
    required Map<String, Celda> celdas,
    required Set<int> numerosFaltantes,
    this.error,
  }) : celdas = Map.unmodifiable(celdas),
       numerosFaltantes = Set.unmodifiable(numerosFaltantes);

  bool get puedeIniciar => fase == FaseInicio.listo;
}
