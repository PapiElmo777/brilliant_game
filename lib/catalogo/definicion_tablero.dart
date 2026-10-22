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
