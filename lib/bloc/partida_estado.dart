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
  }) : celdas = Map.unmodifiable(celdas),
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

  /// Los dados suben bajo la nave al elegir uno, o cuando ya no hay elección
  /// posible para dejar libre el lugar del botón bajo el tablero.
  /// Alcanzó la meta. Por ahora sólo detiene los lanzamientos; la
  /// celebración de victoria se definirá más adelante.
  bool get gano => puntos >= meta;

  bool get dadosArriba =>
      dadoSeleccionado != null ||
      fase == FasePartida.sinMovimientos ||
      fase == FasePartida.rondaResuelta;
}
