import 'package:flutter/material.dart';

/// Logotipo `BRILLIANT by Alfredo` con resplandor cian.
class LogotipoBrilliant extends StatelessWidget {
  const LogotipoBrilliant({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'BRILLIANT by Alfredo',
      excludeSemantics: true,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'BRILLIANT',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFFE2F9FF),
                shadows: [Shadow(color: Color(0x8872E9FF), blurRadius: 24)],
              ),
            ),
          ),
          Text(
            'by Alfredo',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 3,
              color: Color(0xFF72E9FF),
            ),
          ),
        ],
      ),
    );
  }
}
