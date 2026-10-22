Map<int, int> puntuacionesInmutables(Map<int, int> puntos) {
  if (puntos.isEmpty) return const {};
  if (puntos.length != 3 ||
      !{1, 2, 3}.every(puntos.containsKey) ||
      puntos.values.any((p) => p < 0) ||
      puntos[1]! < puntos[2]! ||
      puntos[2]! < puntos[3]!) {
    throw ArgumentError(
      'Se requieren puntos no negativos y decrecientes para los puestos 1, 2 y 3.',
    );
  }
  return Map.unmodifiable(puntos);
}
