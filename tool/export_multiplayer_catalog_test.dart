// Ejecutar: flutter test tool/export_multiplayer_catalog_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'package:brilliant_game/models/tipo.dart';
import 'package:flutter_test/flutter_test.dart';

String rule(Tipo tipo) => switch (tipo) {
  TipoBlanco() => 'WHITE',
  TipoAzul() => 'BLUE',
  TipoRojo() => 'RED',
  TipoAmarillo() => 'YELLOW',
  TipoVerde() => 'GREEN',
  TipoMorado() => 'PURPLE',
  TipoNaranja(:final grupo) =>
    grupo == GrupoNaranja.alto ? 'ORANGE_HIGH' : 'ORANGE_LOW',
  _ => throw StateError('Tipo sin contrato'),
};

Map<String, Object> catalogJson() => {
  'rulesVersion': 1,
  'boards': [
    for (final board in CatalogoTableros.predeterminado().definiciones.values)
      {
        'id': board.id,
        'zones': [
          for (final zone in board.zonas)
            {
              'id': zone.id,
              'rule': rule(zone.tipo),
              'prizes': [for (var i = 1; i <= 3; i++) zone.puntuaciones[i]!],
              'cells': [
                for (final cell in zone.celdas)
                  {
                    'id': cell.id,
                    'row': cell.fila,
                    'column': cell.columna,
                    'initial': cell.esInicio,
                  },
              ],
            },
        ],
      },
  ],
};

void main() {
  test('El catálogo versionado coincide con los cuatro mapas Dart', () {
    final file = File('test/fixtures/multiplayer/catalog-v1.json');
    if (const bool.fromEnvironment('UPDATE_MULTIPLAYER_CATALOG')) {
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(catalogJson())}\n',
      );
    }
    expect(jsonDecode(file.readAsStringSync()), catalogJson());
  });
}
