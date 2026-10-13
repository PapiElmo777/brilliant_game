import '../models/celda.dart';

enum FaseInicio { preparando, listo, iniciado }

enum FaseVisualInicio {
  llegandoNave,
  mostrandoNumeros,
  preparando,
  disparando,
  listo,
  iniciado,
}

class DisparoPendiente {
  final int id;
  final int numero;
  final String celdaId;

  const DisparoPendiente({
    required this.id,
    required this.numero,
    required this.celdaId,
  });
}

class InicioEstado {
  final FaseInicio fase;
  final FaseVisualInicio faseVisual;
  final int? numeroSeleccionado;

  /// Celda inicial ocupada elegida para mover o intercambiar su número.
  final String? celdaSeleccionada;
  final DisparoPendiente? disparoPendiente;
  final Map<String, Celda> celdas;
  final Set<int> numerosFaltantes;
  final String? error;

  InicioEstado({
    required this.fase,
    required Map<String, Celda> celdas,
    required Set<int> numerosFaltantes,
    FaseVisualInicio? faseVisual,
    this.numeroSeleccionado,
    this.celdaSeleccionada,
    this.disparoPendiente,
    this.error,
  }) : faseVisual =
           faseVisual ??
           switch (fase) {
             FaseInicio.preparando => FaseVisualInicio.preparando,
             FaseInicio.listo => FaseVisualInicio.listo,
             FaseInicio.iniciado => FaseVisualInicio.iniciado,
           },
       celdas = Map.unmodifiable(celdas),
       numerosFaltantes = Set.unmodifiable(numerosFaltantes);

  bool get interaccionBloqueada => switch (faseVisual) {
    FaseVisualInicio.preparando || FaseVisualInicio.listo => false,
    _ => true,
  };

  bool get puedeIniciar => fase == FaseInicio.listo && !interaccionBloqueada;

  /// Hay algo que cancelar: una selección o números ya colocados.
  bool get puedeReiniciar =>
      fase != FaseInicio.iniciado &&
      (numeroSeleccionado != null ||
          celdaSeleccionada != null ||
          numerosFaltantes.length < 6);
}
