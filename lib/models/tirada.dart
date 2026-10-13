import 'dart:math';

class Dado {
  final int id;
  final int valor;

  Dado(this.id, this.valor) {
    if (valor < 1 || valor > 6) throw ArgumentError('Dado fuera de rango.');
  }
}

class Tirada {
  final int id;
  final List<Dado> dados;

  Tirada(this.id, int primero, int segundo)
    : dados = List.unmodifiable([Dado(0, primero), Dado(1, segundo)]);

  factory Tirada.lanzar(int id, Random azar) =>
      Tirada(id, azar.nextInt(6) + 1, azar.nextInt(6) + 1);
}

enum ResultadoRonda { colocada, omitida }

class RegistroTirada {
  final Tirada tirada;
  final ResultadoRonda resultado;
  final int? dadoId;
  final String? celdaId;

  const RegistroTirada.colocada(this.tirada, int dado, String celda)
    : resultado = ResultadoRonda.colocada,
      dadoId = dado,
      celdaId = celda;

  const RegistroTirada.omitida(this.tirada)
    : resultado = ResultadoRonda.omitida,
      dadoId = null,
      celdaId = null;
}
