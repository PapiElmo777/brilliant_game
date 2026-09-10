# Brilliant Game

Motor de Brilliant organizado como **Tablero → Zona → Celda**. Cada zona tiene un objeto `Tipo` que define su color, descripción, restricción y puntuaciones. El paquete requiere Flutter porque utiliza `Color` de `dart:ui`; no incluye todavía una interfaz gráfica.

## Contrato de los tipos

```dart
import 'dart:ui';

abstract class Tipo {
  const Tipo();

  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);
  Map<int, int> get puntuaciones;
}
```

Las cinco implementaciones están en `lib/models/tipo.dart`. Tienen constructores `const` y mapas de puntuación inmutables.

| Clase | Color ARGB | Restricción | Puntuaciones (claves 1, 2, 3) |
|---|---|---|---|
| `TipoAzul` | `0xFF2196F3` | Todos iguales | 7, 5, 3 |
| `TipoAmarillo` | `0xFFFFC107` | Todos diferentes | 8, 6, 4 |
| `TipoRojo` | `0xFFF44336` | Todos diferentes | 8, 6, 4 |
| `TipoVerde` | `0xFF4CAF50` | Cualquier número | 4, 3, 2 |
| `TipoMorado` | `0xFF9C27B0` | Máximo dos números distintos | 8, 6, 4 |

Las claves de puntuación se conservan como fueron especificadas. Todavía no se asignan puntos ni se determina qué clave corresponde a un evento de la partida. Naranja no forma parte del modelo.

## Responsabilidades

- **Tablero** contiene zonas. Los identificadores son libres e independientes del color. Comprueba IDs duplicados y coordenadas superpuestas; permite huecos y varias zonas del mismo tipo.
- **Zona** contiene sus celdas y recibe un `Tipo`. Comprueba capacidad y rango 1–6 y delega la restricción de color en `tipo.esPosibleAgregar`.
- **Tipo** contiene el comportamiento del color. Su método evalúa la incorporación a los números actuales de una zona válida; no gestiona capacidad, posiciones o rango. Por ejemplo, `TipoVerde.esPosibleAgregar` siempre devuelve `true`, pero una zona verde rechaza el 7.
- **Celda** es inmutable y contiene ID, fila, columna, `esInicio` y un valor opcional. Su color y pertenencia se obtienen de la zona.

`validarValoresDeTipo` comprueba una configuración completa: recorre los valores en orden, verifica el rango y consulta al tipo para cada incorporación. Así también rechaza estados iniciales inválidos, como `[1, 1, 2]` en rojo. No contiene otro enum ni un `switch` con reglas duplicadas.

Los IDs de zona y celda son únicos dentro de un tablero y reutilizables en otros. Crear instancias de `Zona` distintas para partidas independientes, ya que compartir una zona comparte su estado.

## Ejemplo

```dart
import 'package:brilliant_game/brilliant_game.dart';

final tablero = Tablero(
  id: 'nivel1',
  zonas: [
    Zona(
      id: '2',
      tipo: const TipoAzul(),
      celdas: [
        Celda(id: 'C1', fila: 0, columna: 0, esInicio: true),
        Celda(id: 'C2', fila: 1, columna: 0),
      ],
    ),
  ],
);

tablero.colocarValor('C1', 4);
final posible = tablero.puedeColocarValor('C2', 5); // false
final zona = tablero.obtenerZona('2');
final color = zona.tipo.color;
final descripcion = zona.tipo.descripcion;
final puntos = zona.tipo.puntuaciones[1]; // 7
```

`example/main.dart` contiene una demostración esquemática, comprobada por `test/example_test.dart`. No reproduce todas las casillas o puntuaciones de la fotografía y no es una aplicación con pantalla.

## Operaciones conservadas

- `obtenerCeldaEn(fila, columna)`: devuelve una celda o `null` en huecos y bordes.
- `obtenerVecinos(celdaId)`: arriba, abajo, izquierda y derecha, incluso entre zonas.
- `extraerValoresDeZona(zonaId)`: omite casillas vacías y conserva el orden de definición.
- `obtenerZonaDeCelda(celdaId)`: obtiene la zona y su tipo.
- `colocarValor(celdaId, valor)` y `vaciarCelda(celdaId)`: disponibles en tablero y zona.
- `estaCompletada`: todas las celdas de la zona tienen valor.
- `esInicio` y `campoPuntuacion`: conservan su información sin añadir reglas de partida.
- Las cuatro funciones `cumpleRegla...` anteriores se conservan como adaptadores de los nuevos tipos y validan la configuración completa y el rango.

Colocar permite reemplazar valores, excluyendo el anterior de la simulación. Una operación inválida lanza `ArgumentError` sin modificar el estado. `puedeColocarValor` devuelve `false` ante un número o combinación inválidos; un ID inexistente genera `ArgumentError`.

Las colecciones no permiten alterar la estructura. Las celdas devueltas representan el estado en el momento de la consulta: volver a consultarlas tras un cambio. `conValor` y `sinValor` crean copias independientes, sin modificar el tablero.

## Estructura

```text
lib/
  brilliant_game.dart       Exportaciones públicas
  models/
    tipo.dart               Tipo y sus cinco implementaciones
    zona.dart               Contenedor de celdas y validación
    celda.dart              Casilla inmutable
  core/
    reglas.dart             Validación completa y adaptadores
    tablero.dart            Zonas y consultas espaciales
example/
  main.dart                 Ejemplo de uso del motor
test/
  models/                   Tipos, puntuaciones, zonas y celdas
  core/                     Reglas y tablero
  example_test.dart         Verificación de la demostración
```

## Migración

- `TipoZona.azul` → `const TipoAzul()`; de igual manera para los otros colores.
- Importar `models/tipo.dart` o la entrada pública `brilliant_game.dart`.
- `Zona.tipo` es ahora `Tipo`.
- `TipoZona`, `ReglaZona` y `zona.regla` se retiran. Para consultar una incorporación usar `zona.tipo.esPosibleAgregar(actuales, posible)`; para validar toda la zona usar `zona.validarValores(valores)`.
- La identidad del tipo se puede consultar con `is TipoAzul`; los tipos ya no son valores de un enum.
- Los tests usan `flutter_test` y se ejecutan con `flutter test`. El paquete ya no se ejecuta en una VM Dart independiente por su uso de `dart:ui`.

## Preparación y pruebas

Requiere Flutter con Dart `>=3.9.0 <4.0.0`.

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/example_test.dart
```

## Alcance

Esta etapa no implementa turnos, dados, asignación de puntos, restricciones de inicio o de adyacencia al colocar, fin de partida, persistencia ni interfaz gráfica. Tampoco exige conectividad geométrica de una zona. Esas reglas pueden añadirse sobre el modelo actual.

Validación de esta adaptación: **74 pruebas aprobadas con Flutter**, incluido el ejemplo y las puntuaciones de los cinco tipos.
