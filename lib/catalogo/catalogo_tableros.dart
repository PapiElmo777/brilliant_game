import '../core/tablero.dart';
import 'definicion_tablero.dart';
import 'tablero_01.dart';

class CatalogoTableros {
  final Map<String, DefinicionTablero> definiciones;

  factory CatalogoTableros.predeterminado() =>
      CatalogoTableros(definiciones: [tablero01]);

  CatalogoTableros({required Iterable<DefinicionTablero> definiciones})
    : definiciones = _indexar(definiciones);

  DefinicionTablero obtenerDefinicion(String id) {
    final definicion = definiciones[id];
    if (definicion == null) {
      throw ArgumentError('El tablero $id no existe en el catálogo.');
    }
    return definicion;
  }

  Tablero crearTablero(String id) => obtenerDefinicion(id).crearTablero();

  static Map<String, DefinicionTablero> _indexar(
    Iterable<DefinicionTablero> definiciones,
  ) {
    final resultado = <String, DefinicionTablero>{};
    for (final definicion in definiciones) {
      if (resultado.containsKey(definicion.id)) {
        throw ArgumentError('El tablero ${definicion.id} está duplicado.');
      }
      resultado[definicion.id] = definicion;
    }
    return Map.unmodifiable(resultado);
  }
}
