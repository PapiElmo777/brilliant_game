sealed class InicioEvento {
  const InicioEvento();
}

final class ValorInicialColocado extends InicioEvento {
  final String celdaId;
  final int valor;
  const ValorInicialColocado(this.celdaId, this.valor);
}

final class ValorInicialRetirado extends InicioEvento {
  final String celdaId;
  const ValorInicialRetirado(this.celdaId);
}

final class InicioSolicitado extends InicioEvento {
  const InicioSolicitado();
}

final class LlegadaNaveCompletada extends InicioEvento {
  const LlegadaNaveCompletada();
}

final class PresentacionNumerosCompletada extends InicioEvento {
  const PresentacionNumerosCompletada();
}

final class NumeroInicialSeleccionado extends InicioEvento {
  final int valor;
  const NumeroInicialSeleccionado(this.valor);
}

final class CeldaInicialSeleccionada extends InicioEvento {
  final String celdaId;
  const CeldaInicialSeleccionada(this.celdaId);
}

final class DisparoNumeroCompletado extends InicioEvento {
  final int disparoId;
  const DisparoNumeroCompletado(this.disparoId);
}

final class SeleccionCancelada extends InicioEvento {
  const SeleccionCancelada();
}
