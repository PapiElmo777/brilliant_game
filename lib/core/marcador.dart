import 'dart:collection';

import '../models/zona.dart';

/// Puntos necesarios para ganar según el número de jugadores.
const metaPorJugadores = {2: 26, 3: 24, 4: 22, 5: 20, 6: 20};

int metaDePuntos(int jugadores) {
  final meta = metaPorJugadores[jugadores];
  if (meta == null) {
    throw ArgumentError('La partida admite de 2 a 6 jugadores.');
  }
  return meta;
}

/// Un jugador completó una zona en el puesto indicado y obtuvo sus puntos.
class Reclamo {
  final String zonaId;
  final String jugadorId;
  final int puesto;
  final int puntos;

  const Reclamo({
    required this.zonaId,
    required this.jugadorId,
    required this.puesto,
    required this.puntos,
  });
}

/// Lugar de un jugador al final de la partida.
class PosicionRanking {
  final String jugadorId;
  final int puntos;
  final int zonasCompletadas;

  /// Empezando en 1; solo los empates absolutos comparten posición.
  final int posicion;

  const PosicionRanking({
    required this.jugadorId,
    required this.puntos,
    required this.zonasCompletadas,
    required this.posicion,
  });
}

/// Registro compartido de quién completó cada zona y en qué orden. Todos los
/// jugadores tienen las mismas zonas: el primero en completar una recibe los
/// puntos del primer puesto, que quedan reclamados para los demás.
class Marcador {
  final int jugadores;
  final int meta;
  final Map<String, List<Reclamo>> _reclamos = {};
  final Map<Reclamo, int> _secuencias = {};
  int _secuencia = 0;

  Marcador({required this.jugadores}) : meta = metaDePuntos(jugadores);

  /// Reclamos por zona, en orden de llegada.
  Map<String, List<Reclamo>> get reclamos => UnmodifiableMapView({
    for (final entrada in _reclamos.entries)
      if (entrada.value.isNotEmpty)
        entrada.key: List.unmodifiable(entrada.value),
  });

  int puestosReclamados(String zonaId) => _reclamos[zonaId]?.length ?? 0;

  /// Asigna al jugador el siguiente puesto libre de la zona. Después del
  /// tercer puesto la zona ya no da puntos.
  Reclamo reclamar({required Zona zona, required String jugadorId}) {
    final zonaId = zona.id;
    final lista = _reclamos.putIfAbsent(zonaId, () => []);
    if (lista.any((reclamo) => reclamo.jugadorId == jugadorId)) {
      throw StateError('El jugador $jugadorId ya completó la zona $zonaId.');
    }
    if (lista.length >= jugadores) {
      throw StateError('Todos los jugadores ya completaron la zona $zonaId.');
    }
    final puesto = lista.length + 1;
    final reclamo = Reclamo(
      zonaId: zonaId,
      jugadorId: jugadorId,
      puesto: puesto,
      puntos: zona.puntuaciones[puesto] ?? 0,
    );
    lista.add(reclamo);
    _secuencias[reclamo] = ++_secuencia;
    return reclamo;
  }

  /// Deshace un reclamo; sólo puede retirarse el último de su zona.
  void liberar(Reclamo reclamo) {
    final lista = _reclamos[reclamo.zonaId];
    if (lista == null || lista.isEmpty || !identical(lista.last, reclamo)) {
      throw StateError('Sólo se puede liberar el último reclamo de la zona.');
    }
    lista.removeLast();
    _secuencias.remove(reclamo);
  }

  int puntosDe(String jugadorId) => _reclamos.values
      .expand((lista) => lista)
      .where((reclamo) => reclamo.jugadorId == jugadorId)
      .fold(0, (total, reclamo) => total + reclamo.puntos);

  bool haGanado(String jugadorId) => puntosDe(jugadorId) >= meta;

  int zonasCompletadasDe(String jugadorId) => _reclamos.values
      .where((lista) => lista.any((r) => r.jugadorId == jugadorId))
      .length;

  // Los reclamos de cero puntos no cambian cuándo se alcanzó la puntuación.
  int _momentoPuntuacion(String jugadorId) => _secuencias.entries
      .where((e) => e.key.jugadorId == jugadorId && e.key.puntos > 0)
      .fold(0, (ultimo, e) => e.value > ultimo ? e.value : ultimo);

  int _comparar(String a, String b) {
    final puntos = puntosDe(b).compareTo(puntosDe(a));
    if (puntos != 0) return puntos;
    final zonas = zonasCompletadasDe(b).compareTo(zonasCompletadasDe(a));
    if (zonas != 0) return zonas;
    return _momentoPuntuacion(a).compareTo(_momentoPuntuacion(b));
  }

  /// Ordena a los [jugadores] de la partida de mayor a menor puntuación.
  /// Incluye a quienes aún no tienen puntos.
  List<PosicionRanking> ranking(Iterable<String> jugadores) {
    final ordenados = jugadores.toSet().toList()..sort(_comparar);
    final resultado = <PosicionRanking>[];
    for (var i = 0; i < ordenados.length; i++) {
      final id = ordenados[i];
      final puntos = puntosDe(id);
      final empatado = i > 0 && _comparar(ordenados[i - 1], id) == 0;
      resultado.add(
        PosicionRanking(
          jugadorId: id,
          puntos: puntos,
          zonasCompletadas: zonasCompletadasDe(id),
          posicion: empatado ? resultado.last.posicion : i + 1,
        ),
      );
    }
    return List.unmodifiable(resultado);
  }
}
