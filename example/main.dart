import 'package:brilliant_game/brilliant_game.dart';

void main() {
  // Ejemplo mínimo de arquitectura, no transcripción del tablero de la foto.
  final tablero = Tablero(
    id: 'ejemplo',
    zonas: [
      Zona(
        id: '2',
        tipo: TipoZona.verde,
        campoPuntuacion: 'puntosZona2',
        celdas: [
          Celda(id: 'C1', fila: 0, columna: 0, esInicio: true),
          Celda(id: 'C2', fila: 1, columna: 0),
        ],
      ),
      Zona(
        id: '5',
        tipo: TipoZona.azul,
        celdas: [
          Celda(id: 'C3', fila: 0, columna: 1),
          Celda(id: 'C4', fila: 1, columna: 1),
        ],
      ),
    ],
  );

  tablero.colocarValor('C1', 4);
  tablero.colocarValor('C2', 2);
  tablero.colocarValor('C3', 5);
  print('Zona 2: ${tablero.extraerValoresDeZona('2')}');
  print('Zona 2 completada: ${tablero.obtenerZona('2').estaCompletada}');
  print(
    '¿Se puede poner 3 en C4 (azul)? ${tablero.puedeColocarValor('C4', 3)}',
  );
  print('Vecino derecho de C1: ${tablero.obtenerVecinos('C1')['derecha']?.id}');
}
