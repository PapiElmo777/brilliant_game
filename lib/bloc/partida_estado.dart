import '../core/marcador.dart';
import '../models/celda.dart';
import '../models/tirada.dart';

enum FasePartida {
  tirando,
  revelandoResultados,
  eligiendoNumero,
  moviendoDados,
  eligiendoDestino,
  sinMovimientos,
  rondaResuelta,

  /// Se alcanzó la meta: la partida terminó y se reproduce la celebración.
  celebrandoVictoria,

  /// Menú final con el ranking de la partida.
  mostrandoResultados,
}

/// Fila del ranking final, con el nombre que muestra la interfaz.
class ResultadoJugador {
  final String jugadorId;
  final String nombre;
  final int puntos;
  final int zonasCompletadas;
  final int posicion;
  final bool esLocal;

  const ResultadoJugador({
    required this.jugadorId,
    required this.nombre,
    required this.puntos,
    required this.zonasCompletadas,
    required this.posicion,
    required this.esLocal,
  });
}

class PartidaEstado {
  final FasePartida fase;
  final Tirada tirada;
  final int? dadoSeleccionado;

  /// Celda escrita en esta ronda, todavía modificable hasta lanzar de nuevo.
  final String? celdaColocada;

  /// Puntos del jugador y meta para ganar según el número de jugadores.
  final int puntos;
  final int meta;

  /// Puestos ya reclamados de cada zona completada (1 = primer puesto).
  final Map<String, int> puestosReclamados;

  /// Zona completada con la colocación de esta ronda, si la hubo.
  final Reclamo? reclamoRonda;
  final Map<String, Celda> celdas;
  final Set<String> destinos;
  final bool puedeOmitir;
  final List<RegistroTirada> historial;
  final String? error;

  /// Ranking de la partida; se llena al terminar.
  final List<ResultadoJugador> resultados;

  PartidaEstado({
    required this.fase,
    required this.tirada,
    required Map<String, Celda> celdas,
    required Iterable<RegistroTirada> historial,
    this.dadoSeleccionado,
    this.celdaColocada,
    this.puntos = 0,
    required this.meta,
    Map<String, int> puestosReclamados = const {},
    this.reclamoRonda,
    Set<String> destinos = const {},
    this.puedeOmitir = false,
    this.error,
    Iterable<ResultadoJugador> resultados = const [],
  }) : celdas = Map.unmodifiable(celdas),
       resultados = List.unmodifiable(resultados),
       destinos = Set.unmodifiable(destinos),
       puestosReclamados = Map.unmodifiable(puestosReclamados),
       historial = List.unmodifiable(historial);

  Dado? get seleccionado =>
      dadoSeleccionado == null ? null : tirada.dados[dadoSeleccionado!];
  Dado? get ancla =>
      dadoSeleccionado == null ? null : tirada.dados[1 - dadoSeleccionado!];
  bool get animandoMeteoros =>
      fase == FasePartida.tirando || fase == FasePartida.revelandoResultados;
  bool get puedeSeleccionar =>
      fase == FasePartida.eligiendoNumero ||
      fase == FasePartida.eligiendoDestino ||
      fase == FasePartida.sinMovimientos ||
      puedeModificar;

  /// Tras colocar, la jugada se puede cambiar hasta lanzar los meteoros.
  bool get puedeModificar =>
      fase == FasePartida.rondaResuelta && celdaColocada != null;

  /// Alcanzó la meta de puntos.
  bool get gano => puntos >= meta;

  /// La partida terminó al alcanzar la meta; ya no se aceptan jugadas.
  bool get partidaTerminada =>
      fase == FasePartida.celebrandoVictoria ||
      fase == FasePartida.mostrandoResultados;

  /// Los dados suben bajo la nave al elegir uno, o cuando ya no hay elección
  /// posible para dejar libre el lugar del botón bajo el tablero.
  bool get dadosArriba =>
      dadoSeleccionado != null ||
      fase == FasePartida.sinMovimientos ||
      fase == FasePartida.rondaResuelta;
}
