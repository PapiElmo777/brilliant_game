# Brilliant Game

Motor de Brilliant organizado como **Tablero → Zona → Celda**. Cada zona tiene un objeto `Tipo` que define su color, descripción, restricción y puntuaciones. El paquete requiere Flutter porque utiliza `Color` de `dart:ui`; incluye la base ejecutable de la aplicación para Android e iOS. La interfaz jugable está en implementación.

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

Esta etapa no implementa turnos, dados, asignación de puntos, restricciones de adyacencia durante el juego, fin de partida, persistencia ni interfaz gráfica. Tampoco exige conectividad geométrica de una zona. Esas reglas pueden añadirse sobre el modelo actual.

Validación de esta adaptación: **74 pruebas aprobadas con Flutter**, incluido el ejemplo y las puntuaciones de los cinco tipos.


## Preparación inicial con BLoC

`PreparacionInicial` controla la colocación manual de los números 1, 2, 3, 4, 5 y 6, cada uno exactamente una vez. El tablero debe definir exactamente seis celdas con `esInicio: true`. Las demás casillas deben estar vacías. Se pueden proporcionar valores iniciales válidos al construirlo.

En esta etapa el jugador elige la distribución; no se genera automáticamente una distribución aleatoria. Se conservan las restricciones de cada tipo de zona y el rango 1–6. El diseño del tablero debe permitir esa distribución; esta validación no resuelve ni busca distribuciones posibles.

`InicioBloc`, basado en el paquete `bloc`, expone tres fases:

- `preparando`: faltan números; el inicio se rechaza.
- `listo`: están los seis números; se permite solicitar inicio.
- `iniciado`: se aceptó la solicitud y se bloquean las ediciones de preparación.

Eventos: `ValorInicialColocado(celdaId, valor)`, `ValorInicialRetirado(celdaId)` e `InicioSolicitado()`. Los eventos se procesan en orden. Una colocación inválida conserva los valores existentes y publica `state.error`; una operación válida limpia el error.

```dart
final bloc = InicioBloc(tableroConSeisCasillasIniciales);
final subscription = bloc.stream.listen((estado) {
  // En una futura pantalla, habilitar el botón con estado.puedeIniciar.
  // Solo avanzar cuando estado.fase == FaseInicio.iniciado.
  print(estado.numerosFaltantes);
});

bloc.add(const ValorInicialColocado('C1', 4));
// Colocar los cinco números restantes en las otras casillas iniciales.
bloc.add(const InicioSolicitado()); // Se rechaza si falta algún número.

// Después de observar FaseInicio.iniciado:
// final tableroParaJuego = bloc.crearTableroParaJuego();
// await subscription.cancel();
// await bloc.close();
```

El BLoC usa una copia del tablero recibido. Sus estados son instantáneas inmutables. `crearTableroParaJuego()` entrega una nueva copia independiente solamente después del inicio. Modificar el tablero original no altera la preparación.

No hay navegación ni pantalla implementada: el bloqueo está en la lógica y deberá respetarlo la interfaz. Las operaciones de bajo nivel de `Tablero` siguen disponibles para construir datos y para el juego posterior; el flujo de preparación debe usar `InicioBloc`.

Pruebas de esta funcionalidad: `test/core/preparacion_inicial_test.dart` y `test/bloc/inicio_bloc_test.dart`.

## Aplicación Flutter: fase 1

La aplicación arranca desde `lib/main.dart`. La fase 1 estableció una pantalla provisional con el título BRILLIANT, sustituida por el menú en la fase 4. Incluye tema oscuro, colores de presentación y una ruta inicial centralizada. El menú interactivo y la preparación del tablero se incorporarán en las siguientes fases de `docs/PLAN_IMPLEMENTACION_INTERFAZ.md` (documento local).

Ejecutar en un dispositivo o simulador disponible:

```sh
flutter pub get
flutter run
```

Android e iOS utilizan por ahora los identificadores de desarrollo generados por Flutter. Para ejecutar iOS en un dispositivo físico, configurar el equipo de firma en Xcode. Los recursos e iconos nativos son todavía los predeterminados.

La integración de `flutter_bloc` ya está declarada. El punto de entrada y la presentación están separados de las exportaciones del motor en `lib/brilliant_game.dart`.

## Catálogo de tableros: fase 2

El catálogo predeterminado incluye `tablero_01`, con las 13 zonas, 49 celdas y seis posiciones iniciales del plan. Cada llamada crea un tablero con zonas independientes y sin valores colocados:

```dart
final catalogo = CatalogoTableros.predeterminado();
final tablero = catalogo.crearTablero('tablero_01');
final preparacion = PreparacionInicial(tablero);
```

`DefinicionTablero` y `DefinicionZona` conservan colecciones inmutables. Se pueden registrar más definiciones con `CatalogoTableros(definiciones: [...])`; los IDs duplicados o desconocidos generan `ArgumentError`.

Cada definición valida la geometría 7×7 y la preparación inicial al construirse. Reutiliza las validaciones del motor para IDs y posiciones únicos, reglas de zona, seis celdas iniciales, valores iniciales sin repetir y celdas no iniciales vacías. `Tablero` conserva su contrato genérico y admite otros tamaños fuera del catálogo.

Los IDs de celda tienen el formato `f1_c2`, usando base 1 para facilitar su lectura. Las propiedades `fila` y `columna` siguen usando base 0. Las iniciales del primer tablero son `f1_c2`, `f2_c6`, `f4_c2`, `f4_c5`, `f6_c3` y `f7_c5`.

Las pruebas de `test/catalogo/` verifican la matriz completa, los tipos, las posiciones iniciales, la independencia entre partidas y el rechazo de configuraciones inválidas. Esta fase añade los datos que utiliza la pantalla de preparación de la fase 4.

## Flujo BLoC de presentación: fase 3

`MenuBloc` recibe `NuevaPartidaSolicitada` y publica las fases `creandoPartida` y `partidaPreparada`. El estado entrega la definición de `tablero_01` y un `solicitudId` creciente. La futura pantalla debe escuchar esta intención mediante `BlocListener`, crear el tablero con `state.tablero!.crearTablero()` y navegar. Las solicitudes nuevas permiten crear partidas independientes; el BLoC no ejecuta navegación.

`InicioBloc(tablero, animarEntrada: true)` comienza en `llegandoNave`, bloqueando las acciones de preparación. `LlegadaNaveCompletada` avanza a `mostrandoNumeros` y `PresentacionNumerosCompletada` habilita la interacción. El constructor sin esta opción conserva el comportamiento anterior, sin esperar animaciones.

Durante la preparación:

- `NumeroInicialSeleccionado(valor)` selecciona un número disponible y `SeleccionCancelada` limpia la selección.
- `CeldaInicialSeleccionada(celdaId)` retira el valor si la celda inicial está ocupada. Si está vacía, valida el número seleccionado y publica un `DisparoPendiente` con ID, número y destino.
- La validación utiliza `PreparacionInicial.validarColocacion`, que lanza `ArgumentError` ante una operación inválida sin modificar el tablero.
- La presentación confirma la animación mediante `DisparoNumeroCompletado(disparo.id)`. Sólo entonces se coloca el valor. Confirmaciones antiguas o duplicadas se ignoran.
- Durante el disparo, las demás acciones no modifican la preparación. Tras iniciar, las ediciones publican un error y conservan el tablero.

`fase` conserva el estado del dominio; `faseVisual`, `numeroSeleccionado`, `disparoPendiente` e `interaccionBloqueada` coordinan la presentación. `puedeIniciar` requiere que el dominio esté listo y que no haya interacción bloqueada. Los eventos anteriores de colocación, retiro e inicio siguen disponibles.

Las posiciones en píxeles y los controladores de animación corresponden a los widgets de las próximas fases. La fase 4 conecta este flujo con los widgets de preparación.

## Interfaz estática: fase 4

El menú muestra un escenario lunar, una nave con marciano, el logotipo y únicamente `NUEVA PARTIDA`. El fondo y la nave se dibujan por separado con Flutter, sin usar una imagen plana como interfaz.

La navegación escucha `MenuBloc` y crea un `InicioBloc` nuevo por pantalla. La preparación representa las 49 celdas del modelo y resalta las seis iniciales con contorno cian y un signo +. La bandeja muestra los números faltantes, identifica la selección visual y semánticamente y permite cancelarla. Tocar una celda inicial ocupada retira su número.

Los errores y el progreso reflejan el estado del BLoC. `INICIO` sólo aparece al completar la preparación; al confirmar, se muestra el estado iniciado y las celdas quedan bloqueadas. Volver al menú y solicitar otra partida crea un tablero vacío. No se implementa todavía el desarrollo posterior de la partida.

En esta fase las colocaciones se confirman al renderizar el disparo pendiente, sin animación. La fase 5 sustituirá esa confirmación por la llegada efectiva del número y activará la entrada animada. La interfaz utiliza desplazamiento vertical cuando el espacio o el tamaño del texto lo requieren.

`test/presentation/flujo_interfaz_test.dart` cubre navegación, colores, selección accesible, errores, colocación, retiro, inicio, partidas nuevas y ausencia de desbordamientos en tamaños 320×568, 430×932 y 844×390 con texto ampliado.
