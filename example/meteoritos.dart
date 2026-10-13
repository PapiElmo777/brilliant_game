import 'package:brilliant_game/presentation/widgets/fondo_espacial.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: PruebaMeteoritos()));

class PruebaMeteoritos extends StatefulWidget {
  const PruebaMeteoritos({super.key});

  @override
  State<PruebaMeteoritos> createState() => _PruebaMeteoritosState();
}

class _PruebaMeteoritosState extends State<PruebaMeteoritos> {
  int _repeticion = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meteoritos sin fondo')),
    body: FondoEspacial(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                'assets/videos/meteoritos_transparente.webp',
                key: ValueKey(_repeticion),
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                excludeFromSemantics: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => setState(() => _repeticion++),
                child: const Text('Repetir prueba'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
