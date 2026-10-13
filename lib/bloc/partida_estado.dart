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
    Set<String> destinos = const {},
    this.puedeOmitir = false,
    this.error,
  }) : celdas = Map.unmodifiable(celdas),
       destinos = Set.unmodifiable(destinos),
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
      fase == FasePartida.sinMovimientos;
  bool get dadosArriba => dadoSeleccionado != null;
}
