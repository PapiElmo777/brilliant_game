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
