import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/inicio_bloc.dart';
import '../../bloc/inicio_estado.dart';
import '../../bloc/inicio_evento.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/nave_marciano.dart';
import '../widgets/tablero_view.dart';
import '../widgets/bandeja_numeros.dart';

class PreparacionPage extends StatelessWidget {
  final DefinicionTablero definicion;

  const PreparacionPage({super.key, required this.definicion});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InicioBloc, InicioEstado>(
      listenWhen: (anterior, actual) =>
          actual.disparoPendiente != null &&
          anterior.disparoPendiente?.id != actual.disparoPendiente?.id,
      listener: (context, estado) {
        final bloc = context.read<InicioBloc>();
        final id = estado.disparoPendiente!.id;
        // La fase estática confirma al renderizar; la animación sustituirá este paso.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!bloc.isClosed) bloc.add(DisparoNumeroCompletado(id));
        });
      },
      builder: (context, estado) => Scaffold(
        body: FondoEspacial(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Volver al menú',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const Expanded(child: Text('BRILLIANT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
                              Text(definicion.nombre ?? definicion.id, style: const TextStyle(color: Color(0xFF9FBACB))),
                            ],
                          ),
                          const SizedBox(width: 170, child: NaveMarciano()),
                          const Text('PREPARA TU MISIÓN', style: TextStyle(fontSize: 12, letterSpacing: 2.5, color: Color(0xFF72E9FF))),
                          const SizedBox(height: 8),
                          const Text('Acomoda los números en las celdas iniciales', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          BandejaNumeros(
                            estado: estado,
                            onSeleccionado: (numero) => context.read<InicioBloc>().add(NumeroInicialSeleccionado(numero)),
                          ),
                          const SizedBox(height: 20),
                          TableroView(
                            definicion: definicion,
                            estado: estado,
                            onCeldaSeleccionada: (id) => context.read<InicioBloc>().add(CeldaInicialSeleccionada(id)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
