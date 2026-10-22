import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/menu_bloc.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/boton_panel.dart';
import '../widgets/dialogo_nombre_jugador.dart';
import '../widgets/fondo_espacial.dart';

class SeleccionNivelPage extends StatelessWidget {
  const SeleccionNivelPage({super.key});
  @override
  Widget build(BuildContext context) => BlocConsumer<MenuBloc, MenuEstado>(
    listenWhen: (anterior, actual) => anterior.fase != actual.fase,
    listener: (context, estado) async {
      final bloc = context.read<MenuBloc>();
      if (estado.fase == FaseMenu.pidiendoNombre) {
        final nombre = await DialogoNombreJugador.mostrar(
          context,
          inicial: estado.jugador,
          nivel: estado.tablero?.nombre,
        );
        if (bloc.isClosed) return;
        bloc.add(
          nombre == null
              ? const CapturaNombreCancelada()
              : NombreJugadorConfirmado(nombre),
        );
      } else if (estado.fase == FaseMenu.partidaPreparada) {
        Navigator.of(context).pop((estado.tablero!, estado.jugador!));
      }
    },
    builder: (context, estado) {
      final bloc = context.read<MenuBloc>();
      final habilitado = estado.fase == FaseMenu.seleccionandoNivel;
      return Scaffold(
        body: FondoEspacial(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, espacio) {
                final columnas =
                    espacio.maxWidth < 350 ||
                        MediaQuery.textScalerOf(context).scale(16) > 20
                    ? 1
                    : 2;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Volver al menú',
                                  onPressed: habilitado
                                      ? () => Navigator.of(context).pop()
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const Expanded(
                                  child: Text(
                                    'ELIGE TU NIVEL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnas,
                            mainAxisExtent: columnas == 1 ? (espacio.maxHeight * .68).clamp(190.0, 330.0) : null,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: .82,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final nivel = bloc.niveles[index];
                              return _TarjetaNivel(
                                nivel: nivel,
                                seleccionado: estado.tablero?.id == nivel.id,
                                onTap: habilitado
                                    ? () =>
                                          bloc.add(NivelSeleccionado(nivel.id))
                                    : null,
                              );
                            }, childCount: bloc.niveles.length),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                            child: Column(
                              children: [
                                if (estado.error != null)
                                  Text(
                                    estado.error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                BotonPanel(
                                  key: const ValueKey('nivel_aleatorio'),
                                  texto: 'NIVEL ALEATORIO',
                                  icono: Icons.shuffle_rounded,
                                  onPressed: habilitado
                                      ? () => bloc.add(
                                          const NivelAleatorioSolicitado(),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _TarjetaNivel extends StatelessWidget {
  final DefinicionTablero nivel;
  final bool seleccionado;
  final VoidCallback? onTap;
  const _TarjetaNivel({
    required this.nivel,
    required this.seleccionado,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: seleccionado,
    label: 'Elegir ${nivel.nombre}',
    excludeSemantics: true,
    child: Material(
      color: const Color(0xE6102B4A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: seleccionado ? Colors.white : const Color(0xFF72E9FF),
          width: seleccionado ? 3 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('elegir_${nivel.id}'),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  nivel.recursos!.miniatura,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                nivel.nombre!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
