import 'package:flutter/material.dart';

const tintaEspacial = Color(0xFF081728);
const cianHolograma = Color(0xFF96ECFF);
const oroGalactico = Color(0xFFF4D681);

/// Superficie común a las comunicaciones y al marcador, sobre el juego.
class PanelGalactico extends StatelessWidget {
  final Widget child;
  const PanelGalactico({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(top: BorderSide(color: Color(0x665ACDE5))),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF142C40), tintaEspacial],
      ),
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: child,
    ),
  );
}

class CabeceraGalactica extends StatelessWidget {
  final String title, caption, closeLabel;
  final IconData icon;
  final Key closeKey;
  final bool compact;
  const CabeceraGalactica({
    super.key,
    required this.title,
    required this.caption,
    required this.icon,
    required this.closeLabel,
    required this.closeKey,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 8, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0x446C9AB0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(height: compact ? 6 : 14),
        Row(
          children: [
            Icon(icon, color: cianHolograma, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact)
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Color(0xFF8BA7BB),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: closeKey,
              tooltip: closeLabel,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Color(0xFFA7BECE)),
            ),
          ],
        ),
      ],
    ),
  );
}
