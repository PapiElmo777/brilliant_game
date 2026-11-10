import 'package:flutter/material.dart';
import '../../catalogo/catalogo_tableros.dart';

class AvatarUsuario extends StatelessWidget {
  final String? avatarId;
  final double size;
  const AvatarUsuario({super.key, this.avatarId, this.size = 48});
  @override
  Widget build(BuildContext context) {
    final resources = avatarId == null
        ? null
        : CatalogoTableros.predeterminado()
              .obtenerDefinicion(avatarId!)
              .recursos;
    return SizedBox.square(
      dimension: size,
      child: CircleAvatar(
        backgroundColor: const Color(0xFF16405A),
        child: resources == null
            ? Icon(Icons.person_rounded, size: size * .65)
            : Padding(
                padding: EdgeInsets.all(size * .08),
                child: Image.asset(
                  resources.nave,
                  fit: BoxFit.contain,
                  semanticLabel: 'Avatar de nave del nivel ${resources.numero}',
                ),
              ),
      ),
    );
  }
}
