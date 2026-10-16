import 'dart:io';

import 'package:flutter/services.dart';

/// Carga Roboto y los iconos de Material desde el SDK para que las capturas
/// muestren texto legible en lugar de la fuente de pruebas.
Future<void> cargarFuentesPrueba() async {
  var directorio = File(Platform.resolvedExecutable).parent;
  while (directorio.path != directorio.parent.path &&
      !Directory('${directorio.path}/artifacts/material_fonts').existsSync()) {
    directorio = directorio.parent;
  }
  final fuentes = Directory('${directorio.path}/artifacts/material_fonts');
  if (!fuentes.existsSync()) return;
  Future<ByteData> leer(String nombre) async =>
      ByteData.sublistView(await File('${fuentes.path}/$nombre').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final peso in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(leer('Roboto-$peso.ttf'));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(leer('MaterialIcons-Regular.otf'))).load();
}
