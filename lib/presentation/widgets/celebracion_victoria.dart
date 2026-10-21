import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../catalogo/definicion_tablero.dart';
import '../../models/celda.dart';
import '../../models/tipo.dart';
import 'explosion_painter.dart';
import 'nave_marciano.dart';
import 'tablero_view.dart';

const _cian = Color(0xFF72E9FF);
const _dorado = Color(0xFFFFC94D);
const _naranja = Color(0xFFFF8A1F);

/// Duración total de la celebración, en segundos.
const duracionCelebracion = 6.4;

// Etapas de la línea de tiempo, en segundos.
const _inicioCarga = .7;
const _inicioDisparo = 1.4;
const _inicioExplosion = 1.7;
const _inicioVuelo = 3.1;
const _inicioFelicitacion = 3.9;
const _inicioSalida = 5.7;

/// Tiempo durante el que se ignoran los toques, para que un doble toque en
/// la casilla ganadora no omita la celebración apenas empieza.
const esperaParaOmitir = 1.5;

/// Estado que la celebración comparte con la página de partida: temblor de
/// pantalla, originales ocultos y atenuación del resto de la interfaz.
class ControlCelebracion extends ChangeNotifier {
  Offset _temblor = Offset.zero;
  bool _ocultarNave = false;
  bool _ocultarTablero = false;
  double _atenuacion = 0;

  Offset get temblor => _temblor;
  bool get ocultarNave => _ocultarNave;
  bool get ocultarTablero => _ocultarTablero;
  double get atenuacion => _atenuacion;

  void _actualizar({
    required Offset temblor,
    required bool ocultarNave,
    required bool ocultarTablero,
    required double atenuacion,
  }) {
    if (temblor == _temblor &&
        ocultarNave == _ocultarNave &&
        ocultarTablero == _ocultarTablero &&
        atenuacion == _atenuacion) {
      return;
    }
    _temblor = temblor;
    _ocultarNave = ocultarNave;
    _ocultarTablero = ocultarTablero;
    _atenuacion = atenuacion;
    notifyListeners();
  }
}

double _tramo(double t, double inicio, double fin) =>
    ((t - inicio) / (fin - inicio)).clamp(0.0, 1.0);

/// Celebración de victoria: la nave carga energía, dispara al tablero, este
/// estalla en fragmentos, la nave vuela al centro, felicita al jugador y se
/// retira. Tocar la pantalla la omite. Confirma [onCompletada] una sola vez.
class CelebracionVictoria extends StatefulWidget {
  final DefinicionTablero definicion;
  final Map<String, Celda> celdas;
  final int puntos;

  /// Ubicación de la nave y del tablero originales en la página.
  final GlobalKey nave;
  final GlobalKey tablero;
  final ControlCelebracion control;
  final VoidCallback onCompletada;

  const CelebracionVictoria({
    super.key,
    required this.definicion,
    required this.celdas,
    required this.puntos,
    required this.nave,
    required this.tablero,
    required this.control,
    required this.onCompletada,
  });

  @override
  State<CelebracionVictoria> createState() => _CelebracionVictoriaState();
}

class _Medidas {
  final Size pantalla;
  final Rect nave;
  final Rect tablero;
  const _Medidas(this.pantalla, this.nave, this.tablero);
}

class _CelebracionVictoriaState extends State<CelebracionVictoria>
    with SingleTickerProviderStateMixin {
  // Con movimiento reducido Flutter acortaría la animación; aquí se
  // conserva para que la felicitación alcance a leerse.
  late final AnimationController _linea = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (duracionCelebracion * 1000).round()),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final _Particulas _particulas = _Particulas(math.Random(2026));
  _Medidas? _medidas;
  List<_Fragmento> _fragmentos = const [];
  bool _reducido = false;
  bool _iniciada = false;
  bool _completada = false;

  @override
  void initState() {
    super.initState();
    _linea.addListener(_sincronizar);
    _linea.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) _completar();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducido = MediaQuery.disableAnimationsOf(context);
    if (_iniciada) return;
    _iniciada = true;
    if (_reducido) {
      // Sin movimiento: sólo la felicitación, un momento antes de los
      // resultados.
      _linea.duration = const Duration(milliseconds: 1800);
    }
    _linea.forward();
  }

  void _medir() {
    if (!mounted) return;
    final base = context.findRenderObject();
    if (base is! RenderBox || !base.hasSize) return;
    Rect? rect(GlobalKey clave) {
      final caja = clave.currentContext?.findRenderObject();
      if (caja is! RenderBox || !caja.hasSize) return null;
      return base.globalToLocal(caja.localToGlobal(Offset.zero)) & caja.size;
    }

    final pantalla = base.size;
    final lado = math.min(pantalla.width - 24, pantalla.height * .5);
    final tablero =
        rect(widget.tablero) ??
        Rect.fromCenter(
          center: pantalla.center(Offset(0, pantalla.height * .1)),
          width: lado,
          height: lado,
        );
    final nave =
        rect(widget.nave) ??
        Rect.fromCenter(
          center: Offset(pantalla.width / 2, pantalla.height * .15),
          width: 140,
          height: 140 / 1.65,
        );
    setState(() {
      _medidas = _Medidas(pantalla, nave, tablero);
      _fragmentos = _crearFragmentos(tablero);
    });
    _sincronizar();
  }

  /// Copia de cada casilla en su posición dentro del tablero, con una
  /// trayectoria determinista que se aleja del centro.
  List<_Fragmento> _crearFragmentos(Rect tablero) {
    final tipos = {
      for (final zona in widget.definicion.zonas)
        for (final celda in zona.celdas) celda.id: zona.tipo,
    };
    // Mismo diseño que TableroView: borde de 1, relleno de 8 y separación 4.
    const margen = 9.0;
    const separacion = 4.0;
    final lado = (tablero.width - margen * 2 - separacion * 6) / 7;
    final azar = math.Random(49);
    final centro = tablero.center;
    final distanciaMaxima = tablero.width * .75;
    return [
      for (final celda in widget.celdas.values)
        () {
          final rect = Rect.fromLTWH(
            tablero.left + margen + celda.columna * (lado + separacion),
            tablero.top + margen + celda.fila * (lado + separacion),
            lado,
            lado,
          );
          var direccion = rect.center - centro;
          final distancia = direccion.distance;
          direccion = distancia < 1
              ? Offset.fromDirection(azar.nextDouble() * math.pi * 2)
              : direccion / distancia;
          direccion = Offset.fromDirection(
            direccion.direction + (azar.nextDouble() - .5) * .5,
          );
          final rapidez =
              (520 + azar.nextDouble() * 520) *
              (.7 + distancia / distanciaMaxima * .6);
          return _Fragmento(
            celda: celda,
            tipo: tipos[celda.id] ?? const TipoVerde(),
            rect: rect,
            velocidad: direccion * rapidez + const Offset(0, -260),
            giro: (
              (azar.nextDouble() - .5) * 14,
              (azar.nextDouble() - .5) * 14,
              (azar.nextDouble() - .5) * 8,
            ),
          );
        }(),
    ];
  }

  /// Omite la celebración sólo si ya pasó la espera inicial.
  void _omitir() {
    final transcurrido = _linea.value * _linea.duration!.inMilliseconds / 1000;
    final espera = _reducido ? .6 : esperaParaOmitir;
    if (transcurrido < espera) return;
    _completar();
  }

  void _completar() {
    if (_completada) return;
    _completada = true;
    widget.onCompletada();
  }

  /// Tiempo actual de la línea, en segundos de la secuencia completa.
  double get _t => _reducido
      ? _inicioFelicitacion +
            _linea.value * (_inicioSalida - _inicioFelicitacion)
      : _linea.value * duracionCelebracion;

  void _sincronizar() {
    if (_medidas == null || _reducido) {
      widget.control._actualizar(
        temblor: Offset.zero,
        ocultarNave: false,
        ocultarTablero: false,
        atenuacion: _reducido ? .7 : 0,
      );
      return;
    }
    widget.control._actualizar(
      temblor: _temblor(_t),
      // La celebración dibuja sus propias copias en el mismo lugar.
      ocultarNave: true,
      ocultarTablero: true,
      atenuacion: _tramo(_t, _inicioExplosion, _inicioVuelo),
    );
  }

  /// Vibración que crece durante la carga y se amortigua tras la explosión.
  Offset _temblor(double t) {
    double amplitud;
    if (t < _inicioCarga) {
      amplitud = 0;
    } else if (t < _inicioExplosion) {
      amplitud = 3 * _tramo(t, _inicioCarga, _inicioExplosion);
    } else {
      amplitud = 16 * math.exp(-3.2 * (t - _inicioExplosion));
    }
    if (amplitud < .2) return Offset.zero;
    return Offset(
          math.sin(t * 53) * .6 + math.sin(t * 97 + 1) * .4,
          math.cos(t * 61) * .6 + math.sin(t * 89 + 2) * .4,
        ) *
        amplitud;
  }

  @override
  void dispose() {
    _linea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _linea,
                builder: (context, _) =>
                    _reducido ? _escenaReducida() : _escena(_t),
              ),
            ),
          ),
        ),
        // Tocar en cualquier momento salta directo a los resultados.
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Omitir celebración',
            child: GestureDetector(
              key: const ValueKey('saltar_celebracion'),
              behavior: HitTestBehavior.opaque,
              onTap: _omitir,
            ),
          ),
        ),
      ],
    );
  }

  Widget _escenaReducida() {
    final medidas = _medidas;
    return Stack(
      children: [
        if (medidas != null)
          Positioned(
            left: 0,
            right: 0,
            top: medidas.pantalla.height * .32,
            child: Column(
              children: [
                SizedBox(
                  width: math.min(220, medidas.pantalla.width * .55),
                  child: const NaveMarciano(),
                ),
                _GloboVictoria(puntos: widget.puntos, aparicion: 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _escena(double t) {
    final medidas = _medidas;
    if (medidas == null) return const SizedBox.shrink();
    final temblor = _temblor(t);
    final tablero = medidas.tablero;
    final antesDeExplotar = t < _inicioExplosion;
    final nave = _posicionNave(t, medidas);
    final destello = _destello(t);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tablero intacto, con un pulso de luz al alcanzar la meta.
        if (antesDeExplotar)
          Positioned.fromRect(
            rect: tablero.shift(temblor),
            child: _TableroCargado(
              definicion: widget.definicion,
              celdas: widget.celdas,
              brillo: _brilloLogro(t),
              carga: _tramo(t, _inicioCarga, _inicioExplosion),
            ),
          )
        else ...[
          _marcoQueSeDesvanece(tablero.shift(temblor), t),
          for (final fragmento in _fragmentos)
            _fragmentoEn(fragmento, t - _inicioExplosion, temblor),
        ],
        // Explosión, chispas, humo y ondas expansivas.
        Positioned.fill(
          child: CustomPaint(
            painter: ExplosionPainter(
              t: t - _inicioExplosion,
              centro: tablero.center + temblor,
              radio: tablero.width * .62,
              particulas: _particulas.explosion,
            ),
          ),
        ),
        // Carga de energía y rayo de la nave.
        Positioned.fill(
          child: CustomPaint(
            painter: _RayoPainter(
              t: t,
              orbe: _orbe(
                medidas.nave,
              ).translate(temblor.dx * .3, temblor.dy * .3),
              objetivo: tablero.center + temblor,
              particulas: _particulas,
            ),
          ),
        ),
        // Rayos de luz y confeti de la felicitación.
        Positioned.fill(
          child: CustomPaint(
            painter: _FiestaPainter(
              t: t - _inicioFelicitacion,
              centro: nave.center,
              particulas: _particulas,
            ),
          ),
        ),
        // Estela de la nave mientras vuela.
        Positioned.fill(
          child: CustomPaint(
            painter: _EstelaNavePainter(
              puntos: [
                for (var i = 1; i <= 6; i++)
                  _posicionNave(t - i * .035, medidas).center,
              ],
              actual: nave.center,
              intensidad: _intensidadEstela(t),
              ancho: nave.width,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: nave,
          child: Transform.rotate(
            angle: _inclinacionNave(t),
            child: NaveMarciano(hazActivo: t < _inicioVuelo),
          ),
        ),
        if (t >= _inicioFelicitacion && t < _inicioSalida + .25)
          Positioned(
            left: 16,
            right: 16,
            top: nave.bottom + 6,
            child: _GloboVictoria(
              puntos: widget.puntos,
              aparicion: _aparicionGlobo(t),
            ),
          ),
        if (destello > 0)
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: destello)),
          ),
        if (t > esperaParaOmitir)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Opacity(
              opacity: .45 + .25 * math.sin(t * 3),
              child: const Text(
                'Toca para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: Color(0xFFB6F6FF),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Centro de la base de la nave, donde se concentra la energía.
  Offset _orbe(Rect nave) =>
      Offset(nave.center.dx, nave.top + nave.height * 125 / 182);

  double _brilloLogro(double t) {
    if (t >= _inicioCarga) return 0;
    return math.sin(_tramo(t, 0, _inicioCarga) * math.pi);
  }

  /// Destello blanco al disparar y otro, menor, al estallar.
  double _destello(double t) {
    final disparo = t >= _inicioDisparo && t < _inicioDisparo + .35
        ? .6 * (1 - _tramo(t, _inicioDisparo + .04, _inicioDisparo + .35))
        : 0.0;
    final explosion = t >= _inicioExplosion && t < _inicioExplosion + .45
        ? .55 * (1 - _tramo(t, _inicioExplosion, _inicioExplosion + .45))
        : 0.0;
    return math.max(disparo, explosion);
  }

  Widget _marcoQueSeDesvanece(Rect rect, double t) {
    final p = _tramo(t, _inicioExplosion, _inicioExplosion + .35);
    if (p >= 1) return const SizedBox.shrink();
    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: 1 - p,
        child: Transform.scale(
          scale: 1 + p * .18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFE4A8).withValues(alpha: .9),
                width: 3 * (1 - p) + 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fragmentoEn(_Fragmento f, double t, Offset temblor) {
    const gravedad = 1500.0;
    const arrastre = 1.6;
    final avance = (1 - math.exp(-arrastre * t)) / arrastre;
    final desplazamiento =
        f.velocidad * avance + Offset(0, .5 * gravedad * t * t);
    final opacidad = 1 - _tramo(t, .75, 1.4);
    if (opacidad <= 0) return const SizedBox.shrink();
    final escala = t < .12
        ? 1 + t / .12 * .15
        : 1.15 - _tramo(t, .12, 1.4) * .45;
    final calor = (1 - _tramo(t, 0, .6)) * .75;
    final (gx, gy, gz) = f.giro;
    return Positioned.fromRect(
      rect: f.rect.shift(desplazamiento + temblor),
      child: Opacity(
        opacity: opacidad,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0015)
            ..rotateX(gx * t)
            ..rotateY(gy * t)
            ..rotateZ(gz * t)
            ..scaleByDouble(escala, escala, 1, 1),
          child: ColorFiltered(
            // Las casillas salen al rojo vivo y se enfrían en el aire.
            colorFilter: ColorFilter.mode(
              _naranja.withValues(alpha: calor),
              BlendMode.srcATop,
            ),
            child: CeldaView(celda: f.celda, tipo: f.tipo),
          ),
        ),
      ),
    );
  }

  /// La nave retrocede con el disparo, vuela al centro y sale hacia arriba.
  Rect _posicionNave(double t, _Medidas m) {
    final inicial = m.nave;
    final ancho = math.min(m.pantalla.width * .55, inicial.width * 1.7);
    final escalaFinal = ancho / inicial.width;
    final centroFinal = Offset(m.pantalla.width / 2, m.pantalla.height * .36);
    var centro = inicial.center;
    var escala = 1.0;
    if (t >= _inicioDisparo && t < _inicioVuelo) {
      // Retroceso por el disparo.
      final r = _tramo(t, _inicioDisparo, _inicioDisparo + .6);
      centro += Offset(0, -10 * math.sin(r * math.pi));
    }
    if (t >= _inicioVuelo) {
      final p = Curves.easeOutBack.transform(
        _tramo(t, _inicioVuelo, _inicioFelicitacion),
      );
      // Trayectoria curva: primero se eleva y luego baja al centro.
      final control = Offset(
        inicial.center.dx +
            (centroFinal.dx - inicial.center.dx) * .5 +
            m.pantalla.width * .18,
        math.min(inicial.center.dy, centroFinal.dy) - 40,
      );
      final q = p.clamp(0.0, 1.0);
      final bezier =
          inicial.center * ((1 - q) * (1 - q)) +
          control * (2 * (1 - q) * q) +
          centroFinal * (q * q);
      centro = bezier + (centroFinal - inicial.center) * (p - q);
      escala = 1 + (escalaFinal - 1) * p;
      if (t >= _inicioFelicitacion) {
        // Flota suavemente mientras felicita.
        centro += Offset(0, math.sin((t - _inicioFelicitacion) * 4) * 5);
      }
      if (t >= _inicioSalida) {
        final s = Curves.easeInCubic.transform(
          _tramo(t, _inicioSalida, duracionCelebracion),
        );
        centro += Offset(
          0,
          -(centroFinal.dy + inicial.height * escalaFinal * 1.5) * s,
        );
        escala *= 1 - s * .2;
      }
    }
    return Rect.fromCenter(
      center: centro,
      width: inicial.width * escala,
      height: inicial.height * escala,
    );
  }

  double _inclinacionNave(double t) {
    if (t < _inicioVuelo) return 0;
    if (t < _inicioFelicitacion) {
      return math.sin(_tramo(t, _inicioVuelo, _inicioFelicitacion) * math.pi) *
          .22;
    }
    if (t < _inicioSalida)
      return math.sin((t - _inicioFelicitacion) * 2.6) * .04;
    return -.28 *
        Curves.easeOut.transform(_tramo(t, _inicioSalida, _inicioSalida + .3));
  }

  double _intensidadEstela(double t) {
    if (t >= _inicioVuelo && t < _inicioFelicitacion) {
      return math.sin(_tramo(t, _inicioVuelo, _inicioFelicitacion) * math.pi);
    }
    if (t >= _inicioSalida) return _tramo(t, _inicioSalida, _inicioSalida + .2);
    return 0;
  }

  double _aparicionGlobo(double t) {
    if (t < _inicioFelicitacion) return 0;
    final entrada = _tramo(t, _inicioFelicitacion, _inicioFelicitacion + .6);
    final salida = _tramo(t, _inicioSalida - .1, _inicioSalida + .2);
    return entrada * (1 - salida);
  }
}

class _Fragmento {
  final Celda celda;
  final Tipo tipo;
  final Rect rect;
  final Offset velocidad;
  final (double, double, double) giro;
  const _Fragmento({
    required this.celda,
    required this.tipo,
    required this.rect,
    required this.velocidad,
    required this.giro,
  });
}

/// Copia del tablero que brilla al alcanzar la meta y se calienta durante la
/// carga del rayo.
class _TableroCargado extends StatelessWidget {
  final DefinicionTablero definicion;
  final Map<String, Celda> celdas;
  final double brillo;
  final double carga;

  const _TableroCargado({
    required this.definicion,
    required this.celdas,
    required this.brillo,
    required this.carga,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    // El resplandor va detrás del tablero; encima sólo la luz de la carga.
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        if (brillo > 0)
          BoxShadow(
            color: _dorado.withValues(alpha: .7 * brillo),
            blurRadius: 34,
            spreadRadius: 3,
          ),
        if (carga > 0)
          BoxShadow(
            color: _cian.withValues(alpha: .55 * carga),
            blurRadius: 40,
            spreadRadius: 2,
          ),
      ],
    ),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: brillo > 0
            ? Border.all(color: _dorado.withValues(alpha: brillo), width: 2)
            : null,
        gradient: carga > 0
            ? RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .35 * carga * carga),
                  _cian.withValues(alpha: .12 * carga),
                  Colors.transparent,
                ],
                stops: const [0, .4, 1],
              )
            : null,
      ),
      child: TableroView.partida(
        definicion: definicion,
        celdas: celdas,
        destinos: const {},
        interactiva: false,
        onCeldaSeleccionada: (_) {},
      ),
    ),
  );
}

/// Globo de felicitación bajo la nave.
class _GloboVictoria extends StatelessWidget {
  final int puntos;
  final double aparicion;
  const _GloboVictoria({required this.puntos, required this.aparicion});

  @override
  Widget build(BuildContext context) {
    final escala = .6 + .4 * Curves.elasticOut.transform(aparicion.clamp(0, 1));
    return Semantics(
      liveRegion: true,
      label: '¡Buen trabajo, has ganado! $puntos puntos',
      excludeSemantics: true,
      child: Opacity(
        opacity: Curves.easeOut.transform(aparicion.clamp(0, 1)),
        child: Transform.scale(
          scale: escala,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF2183F63), Color(0xF20B1F38)],
                ),
                border: Border.all(color: _cian, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _cian.withValues(alpha: .45),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Buen trabajo, has ganado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: _cian, blurRadius: 12)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFFFFF1C2), _dorado, Color(0xFFFFB020)],
                    ).createShader(rect),
                    child: Text(
                      '$puntos puntos',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Partículas precalculadas con una semilla fija para que la animación sea
/// idéntica en cada reproducción y en las pruebas.
class _Particulas {
  final ParticulasExplosion explosion;
  final List<(double angulo, double radio, double fase)> energia;
  final List<
    (double angulo, double rapidez, double giro, double fase, int color)
  >
  confeti;
  final List<(double angulo, double distancia, double fase, double tamano)>
  destellos;

  _Particulas(math.Random azar)
    : explosion = ParticulasExplosion(azar),
      energia = [
        for (var i = 0; i < 40; i++)
          (
            azar.nextDouble() * math.pi * 2,
            50 + azar.nextDouble() * 70,
            azar.nextDouble(),
          ),
      ],
      confeti = [
        for (var i = 0; i < 110; i++)
          (
            -math.pi / 2 + (azar.nextDouble() - .5) * math.pi * 1.5,
            260 + azar.nextDouble() * 560,
            (azar.nextDouble() - .5) * 14,
            azar.nextDouble() * math.pi * 2,
            azar.nextInt(_coloresConfeti.length),
          ),
      ],
      destellos = [
        for (var i = 0; i < 18; i++)
          (
            azar.nextDouble() * math.pi * 2,
            .55 + azar.nextDouble() * .7,
            azar.nextDouble() * math.pi * 2,
            5 + azar.nextDouble() * 9,
          ),
      ];
}

const _coloresConfeti = [
  _cian,
  _dorado,
  Color(0xFFFF5C8A),
  Color(0xFF7CF29A),
  Color(0xFFB98CFF),
  Colors.white,
];

/// Orbe de energía bajo la nave, chispas que convergen en espiral y el rayo
/// que baja al tablero.
class _RayoPainter extends CustomPainter {
  final double t;
  final Offset orbe;
  final Offset objetivo;
  final _Particulas particulas;

  const _RayoPainter({
    required this.t,
    required this.orbe,
    required this.objetivo,
    required this.particulas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t < _inicioCarga || t > _inicioExplosion + .2) return;
    final carga = _tramo(t, _inicioCarga, _inicioDisparo);
    final aditivo = Paint()..blendMode = BlendMode.plus;

    // Chispas de energía que convergen en espiral hacia el orbe.
    if (t < _inicioDisparo + .05) {
      for (final (angulo, radio, fase) in particulas.energia) {
        final p = ((carga * 1.6 + fase) % 1);
        final r = radio * (1 - Curves.easeIn.transform(p));
        final a = angulo + p * 2.4;
        final punto = orbe + Offset(math.cos(a), math.sin(a)) * r;
        final cola =
            orbe + Offset(math.cos(a - .25), math.sin(a - .25)) * (r + 10);
        canvas.drawLine(
          cola,
          punto,
          aditivo
            ..shader = null
            ..color = _cian.withValues(alpha: .85 * carga * (1 - p * .5))
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Orbe con núcleo blanco y halo pulsante.
    final pulso = 1 + .12 * math.sin(t * 38);
    final radioOrbe = (4 + 16 * Curves.easeIn.transform(carga)) * pulso;
    final apagado = 1 - _tramo(t, _inicioDisparo + .15, _inicioExplosion + .2);
    if (apagado > 0) {
      canvas.drawCircle(
        orbe,
        radioOrbe * 3.2,
        aditivo
          ..shader =
              RadialGradient(
                colors: [
                  _cian.withValues(alpha: .55 * apagado),
                  _cian.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: orbe, radius: radioOrbe * 3.2),
              ),
      );
      canvas.drawCircle(
        orbe,
        radioOrbe,
        aditivo
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: apagado),
              const Color(0xFFB6F6FF).withValues(alpha: .9 * apagado),
              _cian.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(Rect.fromCircle(center: orbe, radius: radioOrbe)),
      );
    }

    // Rayo: se extiende muy rápido y parpadea mientras dura.
    if (t >= _inicioDisparo) {
      final extension = Curves.easeOut.transform(
        _tramo(t, _inicioDisparo, _inicioDisparo + .07),
      );
      final desvanecer = 1 - _tramo(t, _inicioExplosion, _inicioExplosion + .2);
      final punta = Offset.lerp(orbe, objetivo, extension)!;
      final parpadeo = 1 + .18 * math.sin(t * 90) + .08 * math.sin(t * 157);
      for (final (ancho, color, alfa) in [
        (46.0, _cian, .22),
        (22.0, _cian, .55),
        (9.0, const Color(0xFFE6FDFF), .95),
      ]) {
        canvas.drawLine(
          orbe,
          punta,
          aditivo
            ..shader = null
            ..color = color.withValues(alpha: alfa * desvanecer)
            ..strokeWidth = ancho * parpadeo * desvanecer.clamp(.3, 1)
            ..strokeCap = StrokeCap.round
            ..maskFilter = ancho > 20
                ? const MaskFilter.blur(BlurStyle.normal, 10)
                : null,
        );
      }
      aditivo.maskFilter = null;
      // Destello de lente en el punto de impacto.
      final flare = desvanecer * extension;
      if (flare > 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: punta,
            width: 260 * flare,
            height: 10 * flare,
          ),
          aditivo
            ..shader =
                RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: .9 * flare),
                    _cian.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCenter(center: punta, width: 260, height: 10),
                ),
        );
        canvas.drawCircle(
          punta,
          38 * flare,
          aditivo
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(alpha: flare),
                _cian.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: punta, radius: 38)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RayoPainter old) => old.t != t || old.orbe != orbe;
}

/// Rayos de luz girando detrás de la nave, confeti y destellos.
class _FiestaPainter extends CustomPainter {
  final double t;
  final Offset centro;
  final _Particulas particulas;

  const _FiestaPainter({
    required this.t,
    required this.centro,
    required this.particulas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0) return;
    final aditivo = Paint()..blendMode = BlendMode.plus;
    final duracion = _inicioSalida - _inicioFelicitacion;

    // Rayos de luz.
    final rayos =
        _tramo(t, 0, .5) * (1 - _tramo(t, duracion - .2, duracion + .3));
    if (rayos > 0) {
      final radio = size.longestSide * .7;
      aditivo.shader = RadialGradient(
        colors: [
          _dorado.withValues(alpha: .28 * rayos),
          _cian.withValues(alpha: .1 * rayos),
          Colors.transparent,
        ],
        stops: const [0, .35, 1],
      ).createShader(Rect.fromCircle(center: centro, radius: radio));
      const cantidad = 14;
      for (var i = 0; i < cantidad; i++) {
        final a = t * .45 + i * math.pi * 2 / cantidad;
        canvas.drawPath(
          Path()
            ..moveTo(centro.dx, centro.dy)
            ..lineTo(
              centro.dx + math.cos(a - .07) * radio,
              centro.dy + math.sin(a - .07) * radio,
            )
            ..lineTo(
              centro.dx + math.cos(a + .07) * radio,
              centro.dy + math.sin(a + .07) * radio,
            )
            ..close(),
          aditivo,
        );
      }
      aditivo.shader = null;
    }

    // Destellos de cuatro puntas alrededor de la nave.
    for (final (angulo, distancia, fase, tamano) in particulas.destellos) {
      final brillo = math.max(0.0, math.sin(fase + t * 5)) * rayos;
      if (brillo <= 0) continue;
      final p =
          centro +
          Offset(math.cos(angulo), math.sin(angulo)) *
              (size.shortestSide * .32 * distancia);
      final s = tamano * (.6 + .4 * brillo);
      final estrella = Path()
        ..moveTo(p.dx, p.dy - s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s)
        ..close();
      canvas.drawPath(
        estrella,
        aditivo..color = Colors.white.withValues(alpha: brillo),
      );
    }

    // Confeti con volteo en 3D, arrastre, gravedad y vaivén.
    const arrastre = 1.4;
    const gravedad = 420.0;
    final pintura = Paint();
    for (final (angulo, rapidez, giro, fase, color) in particulas.confeti) {
      if (t > 2.6) break;
      final avance = (1 - math.exp(-arrastre * t)) / arrastre;
      final p =
          centro +
          Offset(math.cos(angulo), math.sin(angulo)) * (rapidez * avance) +
          Offset(math.sin(fase + t * 4) * 14, .5 * gravedad * t * t * .6);
      if (p.dy > size.height + 20) continue;
      final alfa = 1 - _tramo(t, 1.8, 2.6);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(fase + giro * t);
      canvas.scale(1, math.cos(fase * 3 + t * 9));
      pintura.color = _coloresConfeti[color].withValues(alpha: alfa);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
          const Radius.circular(1.5),
        ),
        pintura,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FiestaPainter old) => old.t != t || old.centro != centro;
}

/// Estela luminosa detrás de la nave mientras vuela.
class _EstelaNavePainter extends CustomPainter {
  final List<Offset> puntos;
  final Offset actual;
  final double intensidad;
  final double ancho;

  const _EstelaNavePainter({
    required this.puntos,
    required this.actual,
    required this.intensidad,
    required this.ancho,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensidad <= 0) return;
    final aditivo = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    var anterior = actual;
    for (var i = 0; i < puntos.length; i++) {
      final p = 1 - i / puntos.length;
      canvas.drawLine(
        anterior,
        puntos[i],
        aditivo
          ..color = _cian.withValues(alpha: .45 * p * intensidad)
          ..strokeWidth = ancho * .35 * p,
      );
      anterior = puntos[i];
    }
    // Líneas de velocidad.
    final direccion = actual - puntos.last;
    if (direccion.distance < 30) return;
    final unidad = direccion / direccion.distance;
    final normal = Offset(-unidad.dy, unidad.dx);
    aditivo.maskFilter = null;
    for (var i = -2; i <= 2; i++) {
      final inicio = actual + normal * (i * ancho * .18) - unidad * ancho * .4;
      canvas.drawLine(
        inicio,
        inicio - unidad * (direccion.distance * 1.4),
        aditivo
          ..color = Colors.white.withValues(alpha: .35 * intensidad)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_EstelaNavePainter old) =>
      old.actual != actual || old.intensidad != intensidad;
}
