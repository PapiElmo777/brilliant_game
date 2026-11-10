import 'recursos_nivel.dart';
import '../models/puntuaciones.dart';
import '../core/tablero.dart';
import '../models/celda.dart';
import '../models/tipo.dart';
import '../models/zona.dart';
import 'validador_tablero.dart';

class DefinicionZona {
  final String id;
  final Tipo tipo;
  final Map<int, int> puntuaciones;
  final String? campoPuntuacion;
  final List<Celda> celdas;

  DefinicionZona({
    required this.id,
    required this.tipo,
    required Iterable<Celda> celdas,
    this.campoPuntuacion,
    Map<int, int>? puntuaciones,
  }) : puntuaciones = puntuacionesInmutables(puntuaciones ?? tipo.puntuaciones),
       celdas = List.unmodifiable(celdas);

  /// Nombre legible que conserva el número para distinguir zonas del mismo color.
  String get nombre {
    final parts = id.split('_');
    final color = switch (parts.first) {
      'amarillo' => 'Amarilla',
      'rojo' => 'Roja',
      'morado' => 'Morada',
      'blanco' => 'Blanca',
      'naranja' => 'Naranja',
      'verde' => 'Verde',
      'azul' => 'Azul',
      final value =>
        value.isEmpty
            ? 'Sin nombre'
            : '${value[0].toUpperCase()}${value.substring(1)}',
    };
    return [color, ...parts.skip(1)].join(' ');
  }

  Zona crearZona() => Zona(
    id: id,
    tipo: tipo,
    celdas: celdas,
    campoPuntuacion: campoPuntuacion,
    puntuaciones: puntuaciones,
  );
}

class DefinicionTablero {
  final String id;
  final String? nombre;
  final RecursosNivel? recursos;
  final List<DefinicionZona> zonas;

  DefinicionTablero({
    required this.id,
    this.nombre,
    this.recursos,
    required Iterable<DefinicionZona> zonas,
  }) : zonas = List.unmodifiable(zonas) {
    validarTablero7x7(crearTablero());
  }

  Tablero crearTablero() =>
      Tablero(id: id, zonas: zonas.map((zona) => zona.crearZona()));
}
