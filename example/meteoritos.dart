import 'package:brilliant_game/presentation/widgets/meteoritos_video.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: PruebaMeteoritos()));

class PruebaMeteoritos extends StatefulWidget {
  const PruebaMeteoritos({super.key});

  @override
  State<PruebaMeteoritos> createState() => _PruebaMeteoritosState();
}

class _PruebaMeteoritosState extends State<PruebaMeteoritos> {
  int _tirada = 1;
  ResultadoVideo? _resultado;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071226),
    appBar: AppBar(title: const Text('Prueba de meteoritos')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Video provisional: el fondo cuadriculado pertenece al archivo. '
              'Reproducción sin audio.',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: MeteoritosVideo(
              tiradaId: _tirada,
              onCompletado: (id, resultado) {
                if (id == _tirada) setState(() => _resultado = resultado);
              },
            ),
          ),
          if (_resultado != null)
            Text(
              'Resultado: ${_resultado!.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ElevatedButton(
            onPressed: _resultado == null
                ? null
                : () => setState(() {
                    _tirada++;
                    _resultado = null;
                  }),
            child: const Text('Repetir prueba'),
          ),
        ],
      ),
    ),
  );
}
