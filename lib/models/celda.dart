class Celda {
  final String id;
  final int fila;
  final int columna;
  final bool esInicio;
  final int? valor;

  Celda({
    required this.id,
    required this.fila,
    required this.columna,
    this.esInicio = false,
    int? valorInicial,
  }) : valor = valorInicial {
    if (id.trim().isEmpty)
      throw ArgumentError('El ID de celda no puede estar vacío.');
    if (valorInicial != null && (valorInicial < 1 || valorInicial > 6)) {
      throw ArgumentError(
        'El valor debe estar entre 1 y 6. Se recibió: $valorInicial',
      );
    }
  }

  bool get estaOcupada => valor != null;

  /// Crea una copia; no modifica la celda ni el tablero del que procede.
  Celda conValor(int nuevoValor) => Celda(
    id: id,
    fila: fila,
    columna: columna,
    esInicio: esInicio,
    valorInicial: nuevoValor,
  );

  Celda sinValor() =>
      Celda(id: id, fila: fila, columna: columna, esInicio: esInicio);
}
