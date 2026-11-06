import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'package:brilliant_game/core/anclas.dart';
import 'package:brilliant_game/core/preparacion_inicial.dart';
import 'package:brilliant_game/core/tablero.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/export_multiplayer_catalog_test.dart' as catalog;

Map<String, Object> corpus() {
  final random = Random(61);
  final states = <Object>[];
  for (final id in CatalogoTableros.predeterminado().definiciones.keys) {
    final prep = PreparacionInicial(
      CatalogoTableros.predeterminado().crearTablero(id),
    );
    for (final (cell, value) in prep.distribucionAleatoria(random)) {
      prep.colocarValor(cell, value);
    }
    final board = prep.crearTableroParaJuego();
    for (var step = 0; step < 20; step++) {
      states.add({
        'boardId': id,
        'preparation': step == 0,
        'placements': {
          for (final c in board.celdas.values)
            if (c.valor != null) c.id: c.valor,
        },
        'completedZones':
            board.zonas.values
                .where((z) => z.estaCompletada)
                .map((z) => z.id)
                .toList()
              ..sort(),
        'probes': [
          for (var value = 1; value <= 6; value++)
            for (var anchor = 1; anchor <= 6; anchor++)
              {
                'value': value,
                'anchor': anchor,
                'destinations': destinosConAncla(board, value, anchor).toList()
                  ..sort(),
              },
        ],
      });
      final moves = [
        for (var v = 1; v <= 6; v++)
          for (var a = 1; a <= 6; a++)
            for (final cell in destinosConAncla(board, v, a)) (cell, v),
      ];
      if (moves.isEmpty) break;
      final (cell, value) = moves[random.nextInt(moves.length)];
      board.colocarValor(cell, value);
    }
  }
  return {'rulesVersion': 1, 'states': states};
}

void main() {
  test('Catálogo, geometría y premios no divergen de la copia Java', () {
    expect(
      jsonDecode(
        File('test/fixtures/multiplayer/catalog-v1.json').readAsStringSync(),
      ),
      catalog.catalogJson(),
    );
  });
  test('Casos compartidos de preparación y anclas en los cuatro niveles', () {
    final file = File('test/fixtures/multiplayer/parity-v1.json');
    if (const bool.fromEnvironment('UPDATE_MULTIPLAYER_CATALOG')) {
      file.writeAsStringSync('${jsonEncode(corpus())}\n');
    }
    final data = jsonDecode(file.readAsStringSync()) as Map;
    for (final state in data['states'] as List) {
      final Tablero board = CatalogoTableros.predeterminado().crearTablero(
        state['boardId'],
      );
      for (final entry in (state['placements'] as Map).entries) {
        board.colocarValor(entry.key as String, entry.value as int);
      }
      for (final probe in state['probes'] as List) {
        expect(
          destinosConAncla(board, probe['value'], probe['anchor']).toList()
            ..sort(),
          probe['destinations'],
        );
      }
      expect(
        board.zonas.values
            .where((z) => z.estaCompletada)
            .map((z) => z.id)
            .toList()
          ..sort(),
        state['completedZones'],
      );
    }
  });
}
