import 'package:flutter/material.dart';
import '../../models/celda.dart';
import '../../models/tirada.dart';
import 'dados_partida.dart';

class HistorialTiradas extends StatelessWidget {
  final List<RegistroTirada> registros;
  final Map<String, Celda> celdas;
  const HistorialTiradas({
    super.key,
    required this.registros,
    this.celdas = const {},
  });

  String _destino(String? celdaId) {
    final celda = celdas[celdaId];
    return celda == null
        ? 'Colocado'
        : 'Fila ${celda.fila + 1}, columna ${celda.columna + 1}';
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Historial de tiradas',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Expanded(
                child: registros.isEmpty
                    ? const Center(child: Text('Aún no hay rondas resueltas.'))
                    : ListView.builder(
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final r = registros[registros.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Número de ronda; volver a tirar no cuenta
                                // como una ronda nueva.
                                Text('${registros.length - index}:'),
                                for (final dado in r.tirada.dados)
                                  FichaDado(
                                    dado: dado,
                                    seleccionado: r.dadoId == dado.id,
                                    etiqueta:
                                        'Dado ${dado.id + 1}: ${dado.valor}${r.dadoId == dado.id ? ', colocado' : ''}',
                                  ),
                                Text(
                                  r.resultado == ResultadoRonda.omitida
                                      ? 'Omitida'
                                      : _destino(r.celdaId),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
    child: Text(
      'Tiradas · ${registros.length}${registros.isEmpty ? '' : '  (${registros.last.tirada.dados.map((d) => d.valor).join(' · ')})'}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
