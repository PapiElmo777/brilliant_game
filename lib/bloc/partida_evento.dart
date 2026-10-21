sealed class PartidaEvento {
  const PartidaEvento();
}

class MeteorosSolicitados extends PartidaEvento {
  final int tiradaAnteriorId;
  const MeteorosSolicitados(this.tiradaAnteriorId);
}

class ImpactoConfirmado extends PartidaEvento {
  final int tiradaId;
  const ImpactoConfirmado(this.tiradaId);
}

class MeteorosCompletados extends PartidaEvento {
  final int tiradaId;
  const MeteorosCompletados(this.tiradaId);
}

class DadoSeleccionado extends PartidaEvento {
  final int tiradaId;
  final int dadoId;
  const DadoSeleccionado(this.tiradaId, this.dadoId);
}

class MovimientoDadosCompletado extends PartidaEvento {
  final int tiradaId;
  const MovimientoDadosCompletado(this.tiradaId);
}

class DestinoSeleccionado extends PartidaEvento {
  final int tiradaId;
  final String celdaId;
  const DestinoSeleccionado(this.tiradaId, this.celdaId);
}

class TiroOmitido extends PartidaEvento {
  final int tiradaId;
  const TiroOmitido(this.tiradaId);
}

/// El jugador no quiere ninguno de los dos números: omite la tirada y pasa
/// directamente a la siguiente.
class DadosRelanzados extends PartidaEvento {
  final int tiradaId;
  const DadosRelanzados(this.tiradaId);
}

/// La celebración de victoria terminó o el jugador la omitió.
class CelebracionCompletada extends PartidaEvento {
  final int tiradaId;
  const CelebracionCompletada(this.tiradaId);
}
