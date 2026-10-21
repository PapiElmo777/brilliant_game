import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bloc/inicio_estado.dart';
import '../../catalogo/definicion_tablero.dart';
import '../../catalogo/puntuacion_zonas.dart';
import '../../models/celda.dart';
import '../../models/tipo.dart';

class TableroView extends StatefulWidget {
  final DefinicionTablero definicion;
  final InicioEstado? estado;
  final Map<String, Celda>? celdasPartida;
  final Set<String> destinos;
  final ValueChanged<String> onCeldaSeleccionada;
  final Map<String, GlobalKey> clavesCeldas;

  /// En partida, permite tocar cualquier celda para que el BLoC informe si el
  /// destino no es válido.
  final bool interactiva;

  /// Puestos ya reclamados de cada zona completada.
  final Map<String, int> puestosReclamados;

  const TableroView({
    super.key,
    required this.definicion,
    required this.estado,
    required this.onCeldaSeleccionada,
    this.clavesCeldas = const {},
  }) : celdasPartida = null,
       destinos = const {},
       interactiva = true,
       puestosReclamados = const {};

  const TableroView.partida({
    super.key,
    required this.definicion,
    required Map<String, Celda> celdas,
    required this.destinos,
    required this.onCeldaSeleccionada,
    this.interactiva = true,
    this.puestosReclamados = const {},
  }) : estado = null,
       celdasPartida = celdas,
       clavesCeldas = const {};

  @override
  State<TableroView> createState() => _TableroViewState();
}

class _TableroViewState extends State<TableroView> {
  /// Zona que se muestra mientras se mantiene presionada una de sus celdas.
  DefinicionZona? _zonaResaltada;

  void _resaltar(DefinicionZona? zona) {
    if (zona != null) HapticFeedback.selectionClick();
    setState(() => _zonaResaltada = zona);
  }

  @override
  Widget build(BuildContext context) {
    final definicion = widget.definicion;
    final estado = widget.estado;
    final zonas = {
      for (final zona in definicion.zonas)
        for (final celda in zona.celdas) celda.id: zona,
    };
    final celdas = (estado?.celdas ?? widget.celdasPartida!).values.toList()
      ..sort((a, b) {
        final fila = a.fila.compareTo(b.fila);
        return fila == 0 ? a.columna.compareTo(b.columna) : fila;
      });
    final resaltada = _zonaResaltada;
    final idsResaltados = {...?resaltada?.celdas.map((celda) => celda.id)};
    final mapaCeldas = estado?.celdas ?? widget.celdasPartida!;
    // Las zonas con todas sus casillas ocupadas se oscurecen un poco.
    final idsCompletos = {
      for (final zona in definicion.zonas)
        if (zona.celdas.every(
          (celda) => mapaCeldas[celda.id]?.estaOcupada ?? false,
        ))
          for (final celda in zona.celdas) celda.id,
    };
    // Si la zona llega a las dos orillas (amarilla), la ficha deja libres la
    // primera y la última columna para no taparla.
    final fichaAngosta =
        resaltada != null &&
        resaltada.celdas.any((celda) => celda.columna == 0) &&
        resaltada.celdas.any((celda) => celda.columna == 6);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCC071226),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF355972)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, espacio) => Stack(
            children: [
              GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: celdas.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final celda = celdas[index];
                  final zona = zonas[celda.id]!;
                  return KeyedSubtree(
                    key: widget.clavesCeldas[celda.id],
                    child: CeldaView(
                      key: ValueKey('celda_${celda.id}'),
                      celda: celda,
                      tipo: zona.tipo,
                      esDestino: widget.destinos.contains(celda.id),
                      seleccionada: estado?.celdaSeleccionada == celda.id,
                      enPartida: estado == null,
                      pista: estado == null
                          ? null
                          : widget._pistaPreparacion(celda),
                      enZonaResaltada: idsResaltados.contains(celda.id),
                      atenuada:
                          resaltada != null &&
                          !idsResaltados.contains(celda.id),
                      completada: idsCompletos.contains(celda.id),
                      onMantener: (presionada) =>
                          _resaltar(presionada ? zona : null),
                      onTap:
                          (estado != null
                              ? !estado.interaccionBloqueada
                              : widget.interactiva)
                          ? () => widget.onCeldaSeleccionada(celda.id)
                          : null,
                    ),
                  );
                },
              ),
              if (resaltada != null)
                // La ficha se muestra en la mitad contraria a la zona.
                Positioned(
                  left: fichaAngosta ? espacio.maxWidth / 7 + 2 : 6,
                  right: fichaAngosta ? espacio.maxWidth / 7 + 2 : 6,
                  top: _zonaArriba(resaltada) ? null : 6,
                  bottom: _zonaArriba(resaltada) ? 6 : null,
                  child: IgnorePointer(
                    child: FichaZona(
                      zona: resaltada,
                      reclamados: widget.puestosReclamados[resaltada.id] ?? 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _zonaArriba(DefinicionZona zona) =>
      zona.celdas.map((celda) => celda.fila).reduce((a, b) => a + b) /
          zona.celdas.length <
      3;
}

/// Tipo, regla y puntos representativos de una zona.
class FichaZona extends StatelessWidget {
  final DefinicionZona zona;

  /// Puestos ya reclamados; sus puntos se muestran tachados.
  final int reclamados;
  const FichaZona({super.key, required this.zona, this.reclamados = 0});

  static String nombreTipo(Tipo tipo) => switch (tipo) {
    TipoAzul() => 'azul',
    TipoAmarillo() => 'amarilla',
    TipoRojo() => 'roja',
    TipoVerde() => 'verde',
    TipoMorado() => 'morada',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final puntos = puntosDeZona(zona);
    final tamano = zona.celdas.length;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('ficha_zona'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF20C2640),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: zona.tipo.color, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zona ${nombreTipo(zona.tipo)} · $tamano '
              '${tamano == 1 ? 'casilla' : 'casillas'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color.lerp(zona.tipo.color, Colors.white, .35),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              zona.tipo.descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB1C4D4)),
            ),
            if (puntos.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Al completarla: '),
                    for (var i = 0; i < puntos.length; i++) ...[
                      if (i > 0) const TextSpan(text: ' · '),
                      TextSpan(
                        text: '${i + 1}.º ${puntos[i]}',
                        style: i < reclamados
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF6F8798),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB6F6FF),
                ),
              ),
              if (reclamados > 0)
                Text(
                  reclamados == 1
                      ? '1.º puesto ya reclamado'
                      : '${[for (var i = 1; i <= reclamados && i <= puntos.length; i++) '$i.º'].join(' y ')} puestos ya reclamados',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFC66B),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on TableroView {
  String _pistaPreparacion(Celda celda) {
    final estado = this.estado!;
    if (!celda.esInicio) return 'Celda de juego';
    final origen = estado.celdaSeleccionada;
    if (origen == celda.id) return 'Retirar número';
    if (origen != null) {
      return celda.estaOcupada ? 'Intercambiar números' : 'Mover número aquí';
    }
    if (!celda.estaOcupada) return 'Colocar número seleccionado';
    return estado.numeroSeleccionado == null
        ? 'Elegir para mover o intercambiar'
        : 'Reemplazar por el número seleccionado';
  }
}

class CeldaView extends StatelessWidget {
  final Celda celda;
  final Tipo tipo;
  final VoidCallback? onTap;
  final bool esDestino;
  final bool enPartida;

  /// Indicación accesible de lo que hace tocar la celda.
  final String? pista;

  /// Número del tablero elegido para mover o intercambiar.
  final bool seleccionada;

  /// Resaltado de la zona mientras se mantiene presionada una de sus celdas.
  final bool enZonaResaltada;
  final bool atenuada;

  /// Su zona ya tiene todas las casillas ocupadas.
  final bool completada;

  /// Avisa al empezar (`true`) y terminar (`false`) de mantener presionado.
  final ValueChanged<bool>? onMantener;

  const CeldaView({
    super.key,
    required this.celda,
    required this.tipo,
    this.onTap,
    this.esDestino = false,
    this.enPartida = false,
    this.pista,
    this.seleccionada = false,
    this.enZonaResaltada = false,
    this.atenuada = false,
    this.completada = false,
    this.onMantener,
  });

  @override
  Widget build(BuildContext context) {
    // Una zona completa conserva su color, sólo un poco más oscuro.
    final color = completada
        ? Color.lerp(tipo.color, Colors.black, .28)!
        : tipo.color;
    final texto = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF071226);
    final estado = celda.valor == null ? 'vacía' : 'número ${celda.valor}';
    final resaltada = esDestino || seleccionada || enZonaResaltada;
    return Semantics(
      button: true,
      selected: seleccionada,
      enabled: onTap != null,
      onTap: onTap,
      label:
          'Fila ${celda.fila + 1}, columna ${celda.columna + 1}${celda.esInicio ? ', celda inicial' : ''}, $estado. ${tipo.descripcion}${completada ? ', zona completa' : ''}${esDestino ? ', destino disponible' : ''}',
      hint: pista != null
          ? pista!
          : enPartida
          ? (esDestino ? 'Colocar dado seleccionado' : 'Destino no válido')
          : celda.esInicio
          ? (celda.estaOcupada
                ? 'Retirar número'
                : 'Colocar número seleccionado')
          : 'Celda de juego',
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: onMantener == null ? null : (_) => onMantener!(true),
        onLongPressEnd: onMantener == null ? null : (_) => onMantener!(false),
        onLongPressCancel: onMantener == null ? null : () => onMantener!(false),
        child: AnimatedOpacity(
          opacity: atenuada ? .3 : 1,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(color, Colors.white, completada ? .1 : .18)!,
                    color,
                    Color.lerp(color, Colors.black, .2)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: resaltada
                      ? Colors.white
                      : celda.esInicio
                      ? const Color(0xFFB6F6FF)
                      : const Color(0x33FFFFFF),
                  width: resaltada
                      ? 3
                      : celda.esInicio
                      ? 2
                      : 1,
                ),
                boxShadow: resaltada
                    ? const [
                        BoxShadow(
                          color: Colors.white70,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : celda.esInicio
                    ? const [BoxShadow(color: Color(0x6672E9FF), blurRadius: 6)]
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTap,
                child: Center(
                  child: celda.valor != null
                      ? FittedBox(
                          child: Text(
                            '${celda.valor}',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: texto,
                            ),
                          ),
                        )
                      : esDestino
                      ? Icon(Icons.add_circle_outline, color: texto, size: 22)
                      : celda.esInicio
                      ? Icon(Icons.add_rounded, size: 20, color: texto)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
