import '../core/tablero.dart';
import '../models/celda.dart';
import '../models/tipo.dart';
import '../models/zona.dart';
import 'validador_tablero.dart';

class DefinicionZona {
  final String id;
  final Tipo tipo;
  final String? campoPuntuacion;
  final List<Celda> celdas;

  DefinicionZona({
    required this.id,
    required this.tipo,
    required Iterable<Celda> celdas,
    this.campoPuntuacion,
  }) : celdas = List.unmodifiable(celdas);

  Zona crearZona() => Zona(
    id: id,
    tipo: tipo,
    celdas: celdas,
    campoPuntuacion: campoPuntuacion,
  );
}

class DefinicionTablero {
  final String id;
  final String? nombre;
  final List<DefinicionZona> zonas;

  DefinicionTablero({
    required this.id,
    this.nombre,
    required Iterable<DefinicionZona> zonas,
  }) : zonas = List.unmodifiable(zonas) {
    validarTablero7x7(crearTablero());
  }

  Tablero crearTablero() =>
      Tablero(id: id, zonas: zonas.map((zona) => zona.crearZona()));
}
