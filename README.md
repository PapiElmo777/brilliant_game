# Brilliant Game

Juego Flutter organizado como **Tablero → Zona → Celda**, con cuatro niveles seleccionables, preparación, dados y anclas, puntuación, victoria y resultados. Cada zona recibe un `Tipo` para su color y restricción, y una tabla de puntuación propia del nivel. Incluye configuración para Android e iOS.

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

Las siete implementaciones están en `lib/models/tipo.dart`. Tienen constructores `const` y mapas de puntuación inmutables.

| Clase | Color ARGB | Restricción | Puntuaciones (claves 1, 2, 3) |
|---|---|---|---|
| `TipoAzul` | `0xFF2196F3` | Todos iguales | 7, 6, 3 |
| `TipoAmarillo` | `0xFFFFC107` | Todos diferentes | 8, 6, 4 |
| `TipoRojo` | `0xFFF44336` | Todos diferentes | 6, 4, 2 |
| `TipoVerde` | `0xFF4CAF50` | Cualquier número | 4, 3, 2 |
| `TipoMorado` | `0xFF9C27B0` | Máximo dos números distintos | 6, 4, 2 |
| `TipoBlanco` | `0xFFECEFF1` | Todos iguales | Configurada por zona y nivel |
| `TipoNaranja` | `0xFFFF9800` | Solo 1–3 o solo 4–6, según su grupo | 6, 4, 3 |

La tabla muestra los valores predeterminados de los tipos originales. `DefinicionZona.puntuaciones` y `Zona.puntuaciones` permiten sustituirlos por las del nivel. `Marcador.reclamar(zona: ..., jugadorId: ...)` consulta esa tabla efectiva, que también usa la ficha de puntos. Las claves 1, 2 y 3 corresponden al puesto al completar una zona. Las puntuaciones son inmutables y se conservan al copiar los tableros; los tipos personalizados sin puntuación conservan la posibilidad de no otorgar puntos.

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

Si Android falla en `parseDebugLocalResources` con nombres como
`launch_background 3.xml` dentro de `build/`, limpiar los archivos generados y
volver a compilar:

```sh
flutter clean
flutter pub get
flutter run -t lib/main.dart
```

Usar el mismo SDK de Flutter en el editor y la terminal. La primera compilación
después de limpiar reconstruye los archivos generados y puede tardar más. Si
reaparecen copias con sufijos `2` o `3`, revisar si una herramienta de
sincronización o copia está modificando la carpeta del proyecto. No renombrar
recursos dentro de `build/`, porque se generan de nuevo al compilar.

## Alcance de la primera adaptación del motor

La primera adaptación cubrió las restricciones de color y el modelo de zonas sin exigir conectividad geométrica. Las etapas siguientes, descritas a continuación, incorporan la interfaz, dados, anclas, puntuación, victoria y cuatro niveles. Multijugador y persistencia siguen fuera del alcance actual.

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

Android e iOS utilizan por ahora los identificadores de desarrollo generados por Flutter. Para ejecutar iOS en un dispositivo físico, configurar el equipo de firma en Xcode. Android e iOS usan el icono de Brilliant aportado en `assets/images/branding/IconB.png`, generado en todos los tamaños de sus catálogos nativos.

La integración de `flutter_bloc` ya está declarada. El punto de entrada y la presentación están separados de las exportaciones del motor en `lib/brilliant_game.dart`.

## Catálogo de tableros: fase 2

El catálogo predeterminado incluye `tablero_01`, con las 9 zonas, 49 celdas y seis posiciones iniciales del plan. Cada llamada crea un tablero con zonas independientes y sin valores colocados:

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

Las posiciones en píxeles y los controladores de animación pertenecen a los widgets de presentación. La fase 4 conecta este flujo con los widgets de preparación.

## Interfaz estática: fase 4

El menú actual muestra `assets/images/backgrounds/PantallaMenu1.png` como fondo, con su logotipo integrado. Sobre el espacio oscuro entre la batalla y la firma presenta «Que la Fuerza guíe tus números.» y el único botón `NUEVA PARTIDA`. El botón es un control real de Flutter y mantiene la navegación al selector de niveles. La portada permanece fija; en horizontal, la ilustración y los controles se distribuyen a los lados.

La navegación escucha `MenuBloc` y crea un `InicioBloc` nuevo por pantalla. La preparación representa las 49 celdas del modelo y resalta las seis iniciales con contorno cian y un signo +. La bandeja muestra los números faltantes, identifica la selección visual y semánticamente y permite cancelarla. Tocar una celda inicial ocupada retira su número.

Los errores y el progreso reflejan el estado del BLoC. `INICIO` sólo aparece al completar la preparación; al confirmar, se muestra el estado iniciado y las celdas quedan bloqueadas. Volver al menú y solicitar otra partida crea un tablero vacío. No se implementa todavía el desarrollo posterior de la partida.

La fase 4 estableció colocaciones instantáneas; la fase 5 las sustituyó por la confirmación al terminar el vuelo y activó la entrada animada. Preparación y partida permanecen fijas: el tablero se ajusta al espacio disponible y los controles pasan a un lateral en horizontal.

`test/presentation/flujo_interfaz_test.dart` cubre navegación, colores, selección accesible, errores, colocación, retiro, inicio, partidas nuevas y ausencia de desbordamientos en tamaños 320×568, 430×932 y 844×390 con texto ampliado.

## Animaciones: fase 5

Al abrir la preparación, la nave entra durante un segundo con desaceleración y rebote. Después se activa el haz en 280 ms y se presentan los números de forma escalonada. La interacción permanece bloqueada hasta que `PresentacionNumerosCompletada` confirma la secuencia al BLoC.

Cada colocación válida monta un `DisparoNumeroOverlay` identificado por el ID del disparo. El número viaja durante 650 ms con brillo y estela cian. El origen y destino se calculan desde las posiciones globales de los widgets, sin guardar píxeles en el BLoC. Sólo al terminar se envía `DisparoNumeroCompletado`; reconstruir el widget no repite esa confirmación. Salir de la pantalla descarta la animación sin confirmar una colocación pendiente.

La bandeja conserva el espacio de las fichas utilizadas, sin mostrarlas ni incluirlas en la semántica. El indicador y el control de cancelación también mantienen su espacio para que el destino del disparo no salte al confirmar la colocación. El tablero permanece fijo durante toda la preparación y la partida, incluido el vuelo.

Los errores reciben una breve sacudida y un resplandor en su panel, además del mensaje visible. `INICIO` aparece con escala y opacidad cuando el BLoC lo permite. Todos estos efectos respetan `MediaQuery.disableAnimations`: se presentan los estados finales y se mantienen las confirmaciones necesarias sin bloquear el flujo.

Las pruebas de animación cubren tiempos, confirmación única, reconstrucciones, cancelación al desmontar, aparición escalonada, estabilidad de la celda de destino y preparación completa con movimiento reducido. La revisión en dispositivos y las capturas doradas de referencia corresponden a la fase 6.

## Verificación y recursos: fase 6

La fase 6 original utilizaba recursos dibujados con Flutter; las ilustraciones incorporadas después sustituyen el fondo del menú y los fondos y naves de cada nivel. El fondo lunar (`FondoEspacial`), la nave con el marciano (`NaveMarciano`), el logotipo (`LogotipoBrilliant`), los botones de panel (`BotonPanel`), las celdas y los efectos de haz, estela y partículas son widgets o `CustomPainter` independientes. Al ser vectoriales se adaptan a cualquier densidad de pantalla y pueden animarse por separado. Las ilustraciones actuales están registradas en las carpetas de `assets/images/`; los botones, las celdas y los efectos siguen siendo widgets independientes.

La aplicación se limita a orientación vertical en teléfonos. Los errores de preparación se muestran sólo en el panel junto al tablero. El disparo añade chispas deterministas a la estela y un destello al llegar a la celda.

`test/golden/` contiene las capturas doradas del menú, la preparación vacía, un número seleccionado y la preparación completa con `INICIO`, en 390×844 y 320×568. Cargan Roboto desde el SDK de Flutter y sólo se comparan en macOS. Para regenerarlas tras un cambio visual intencional:

```sh
flutter test --update-goldens test/golden
```

## Nombre del jugador, acomodo aleatorio e INICIO fijo

Al pulsar `NUEVA PARTIDA` se pide el nombre del jugador. `MenuBloc` pasa a la fase `pidiendoNombre`; `NombreJugadorConfirmado(nombre)` valida entre 1 y 16 caracteres, sin espacios sobrantes, y prepara `tablero_01`. `CapturaNombreCancelada` vuelve al menú. El último nombre aceptado se propone en la siguiente partida y la preparación lo muestra en su encabezado.

`Acomodo aleatorio` envía `ColocacionAleatoriaSolicitada`. `PreparacionInicial.distribucionAleatoria` busca, sobre una copia, una colocación de los números faltantes que cumpla las reglas de zona; los números ya colocados se conservan. `InicioBloc` dispara las colocaciones una por una, del número menor al mayor, con la misma animación y confirmación que la colocación manual. Si no existe una distribución válida se publica un error sin disparar.

Al completar la preparación, `BotonInicio` presenta `INICIO` en el espacio reservado al pie de la pantalla fija. El botón entra desde abajo con rebote y emite dos pulsos de resplandor; con movimiento reducido aparece directamente. Tras iniciar, el panel confirma las posiciones.

## Prueba provisional de meteoritos

El primer paso del plan de anclas incorpora `assets/videos/meteoritos.mp4` y el
widget `MeteoritosVideo`. La prueba independiente se abre con:

```sh
flutter run -t example/meteoritos.dart
```

Reproduce una sola vez por ID de tirada, sin deformar el video y alineado abajo.
La reproducción no se reinicia al reconstruir el widget. El resultado de cierre
incluye el ID y distingue finalización, movimiento reducido y fallo. La carga,
la reproducción fallida o una espera mayor de 25 segundos permiten continuar;
el widget no genera dados ni modifica el tablero. Cambiar de tirada o salir
invalida las confirmaciones anteriores.

El fondo cuadriculado está grabado en el archivo y sigue visible. El audio se
mantiene silenciado para esta prueba. La pantalla de ejemplo permite repetir el
clip; todavía no conecta INICIO con una partida ni sincroniza dados con el
impacto. Esa integración corresponde a los siguientes pasos del plan.

Las pruebas del reproductor están en
`test/presentation/meteoritos_video_test.dart`.

## Partida: tiradas, anclas e historial

`assets/videos/meteoritos_transparente.webp` sustituye al MP4 en la partida.
Es una versión animada de 242 cuadros a 24 fps con el fondo cuadriculado
retirado mediante un recorte aproximado; puede dejar restos en humo y bordes
semitransparentes. `MeteoritosAnimacion` cubre toda la pantalla de partida,
reproduce el clip a velocidad x7 (unos 1,4 s), decodifica el recurso una sola
vez por tirada, confirma el impacto en el cuadro 120 y la finalización al
terminar el clip. Con movimiento reducido, fallo de carga o una espera mayor de 30 segundos
confirma ambos eventos sin bloquear la ronda. `example/meteoritos.dart` muestra
ahora este recurso. `MeteoritosVideo` y el MP4 se conservan mientras se decide
qué animación queda en la versión final.

Al pulsar `INICIO`, la preparación entrega una copia del tablero a un nuevo
`PartidaBloc` y se abre `PartidaPage` con el aviso «¡El juego comenzó!».
`PartidaBloc` genera los dos dados antes de la animación y recorre las fases
`tirando`, `revelandoResultados`, `eligiendoNumero`, `moviendoDados`,
`eligiendoDestino`, `sinMovimientos` y `rondaResuelta`. Todos los eventos llevan
el ID de la tirada; las confirmaciones antiguas o duplicadas se ignoran.

- Tocar un dado sube ambos bajo la nave. El seleccionado es el número que se
  escribe y el otro es el ancla, que el alien anuncia en su globo.
- `destinosConAncla` (en `lib/core/anclas.dart`) devuelve las celdas vacías
  ortogonalmente adyacentes a un valor igual al ancla que aceptan el número
  según su zona. Las casillas se resaltan en blanco con un signo ⊕.
- Tocar una casilla no válida, o una casilla antes de elegir número, muestra el
  aviso en el globo del alien sin modificar el tablero.
- `OMITIR TIRO` sólo aparece si ninguna de las dos elecciones tiene destinos;
  el BLoC vuelve a validar colocaciones y omisiones.
- Tras colocar u omitir aparece `LANZAR METEOROS`, grande debajo del tablero; no
  se lanza otra tirada automáticamente.
- Después de colocar y antes de lanzar, la jugada se puede cambiar: tocar otro
  destino resaltado mueve el número, tocar el número escrito lo retira y tocar
  el otro dado deshace la colocación para elegir de nuevo. El historial
  conserva un solo registro de la ronda; al lanzar, la jugada queda fija.
- Salir con la flecha o con el regreso del sistema pide confirmación, porque se
  pierde el progreso; al aceptar se vuelve al menú principal.
- Preparación y partida no permiten desplazarse. `DisenoJuegoFijo` reserva
  espacio para la cabecera, los controles y el pie, y ajusta el tablero al área
  restante. En pantallas pequeñas compacta la nave y los mensajes; en horizontal
  coloca los controles a la izquierda. Las pruebas conservan casillas de al
  menos 32 puntos con texto ampliado y barras del sistema.
- `Tiradas · N`, en el encabezado, abre el historial. Una colocación ilumina el
  dado escrito e indica fila y columna; una omisión no ilumina ninguno.

Pruebas: `test/core/anclas_test.dart`, `test/bloc/partida_bloc_test.dart`,
`test/presentation/meteoritos_animacion_test.dart` y
`test/presentation/partida_page_test.dart`.

## Preparación con intercambio, zonas y puntuación

- Durante la preparación, tocar un número colocado lo elige; tocar otra celda
  inicial lo mueve o lo intercambia con el número que haya ahí, y tocarlo de
  nuevo lo retira. Un número de la bandeja sobre una celda ocupada la
  reemplaza y el anterior vuelve a la bandeja. `PreparacionInicial.intercambiar`
  valida el cambio sobre una copia antes de aplicarlo.
- `Cancelar selección` (`PreparacionReiniciada`) aparece en cuanto hay una
  selección o números colocados, y regresa todos los números a la bandeja.
- La zona amarilla es una sola, con cinco casillas separadas (las cuatro
  esquinas y el centro); sus números deben ser distintos.
- Mantener presionada cualquier celda resalta su zona completa, atenúa las
  demás y muestra su regla y los puntos al completarla.
- Mantener presionada una celda muestra los puntos de su zona por puesto,
  con los puestos ya reclamados tachados.

## Puntuación y meta (bases del multijugador)

Cada color da puntos según el orden en que los jugadores completan una zona
(`Tipo.puntuaciones`, puesto → puntos):

| Color | 1.º | 2.º | 3.º |
|---|---|---|---|
| Azul | 7 | 6 | 3 |
| Morado | 6 | 4 | 2 |
| Verde | 4 | 3 | 2 |
| Amarillo | 8 | 6 | 4 |
| Rojo | 6 | 4 | 2 |

`Marcador` (`lib/core/marcador.dart`) es el registro compartido entre
jugadores: `reclamar` asigna el siguiente puesto libre de la zona y sus puntos
(después del tercero da 0), `liberar` deshace el último reclamo y `puntosDe`
suma los puntos de un jugador. Cada jugador reclama una zona una sola vez.

La meta para ganar depende del número de jugadores (`metaDePuntos`): 2 → 26,
3 → 24, 4 → 22 y 5 → 20. Mientras no exista el multijugador, `PartidaBloc`
juega con un solo jugador local (`jugador_1`) y la meta de 2 jugadores.

En la partida, escribir el número que completa una zona reclama el puesto y
el alien anuncia los puntos; si la jugada se cambia antes de lanzar, el
reclamo se libera.

## Omitir la caída, volver a tirar y zonas completas

- Tocar la pantalla mientras caen los meteoritos detiene el video, revela los
  dos números y muestra sólo la explosión final, dibujada con el mismo
  `ExplosionPainter` de la victoria. Los toques de los primeros 300 ms se
  ignoran por si el lanzamiento fue un doble toque, y el toque también llega a
  la flecha de regreso y al historial.
- «VOLVER A TIRAR», a la derecha de los dados, funciona como omitir: si no
  convence ninguno de los dos números, la tirada se registra como omitida sin
  cambiar el tablero y comienza directamente la siguiente, sin pulsar «LANZAR
  METEOROS» (`DadosRelanzados`). Está disponible antes de escribir el número.
- Las zonas con todas sus casillas ocupadas se oscurecen un poco sin perder su
  color, y el lector de pantalla las anuncia como «zona completa».

## Victoria y resultados

Llegar a la meta termina la partida. La jugada ganadora es definitiva:
`PartidaBloc` pasa a `FasePartida.celebrandoVictoria` e ignora selecciones,
destinos, omisiones y lanzamientos. `CelebracionCompletada(tiradaId)` lleva a
`FasePartida.mostrandoResultados` una sola vez; las confirmaciones repetidas o
de otra tirada se ignoran.

`CelebracionVictoria` (`lib/presentation/widgets/celebracion_victoria.dart`)
dibuja la secuencia en Flutter, sin recursos externos, en unos 6,4 s:

1. El tablero brilla al alcanzar la meta.
2. La nave concentra energía y el tablero tiembla.
3. Un rayo baja al centro del tablero con un destello.
4. El tablero estalla: bola de fuego, dos ondas expansivas, chispas, brasas,
   humo y las 49 casillas saliendo disparadas con giro en 3D.
5. La nave vuela al centro con estela y dice «¡Buen trabajo, has ganado!» con
   la puntuación final, entre confeti y rayos de luz.
6. La nave sale hacia arriba y aparece el menú de resultados.

La celebración dibuja copias de la nave y del tablero en su posición real
mientras la página oculta los originales (`ControlCelebracion`), y hace
temblar y atenúa el resto de la partida. Las partículas usan semillas fijas.
Tocar la pantalla o el regreso del sistema la omiten. Con movimiento reducido
sólo se muestra la felicitación durante 1,8 s.

`ResultadosPartida` muestra el trofeo, la meta y el ranking
(`Marcador.ranking`, por ahora sólo con el jugador local, su nombre, puntos y
zonas completadas). «EMPEZAR DE NUEVO» abre una preparación nueva del mismo
tablero con el mismo nombre, sin volver a pedirlo. «SALIR AL MENÚ» y el
regreso del sistema vuelven al menú sin confirmación. Los empates comparten
posición hasta que se defina el desempate del multijugador.

Pruebas: `test/core/marcador_test.dart`, `test/bloc/partida_bloc_test.dart`,
`test/presentation/celebracion_victoria_test.dart`,
`test/presentation/resultados_partida_test.dart` y la captura
`test/golden/capturas/partida_victoria.png`.

## Pruebas del recorrido completo del usuario

`test/presentation/flujo_completo_usuario_test.dart` recorre la aplicación
desde el menú: captura del nombre, seis colocaciones manuales en `tablero_01`,
INICIO, elección e intercambio de dados, destinos concretos e historial.
En 390×844 continúa hasta ganar a 26 puntos en 20 rondas; en 320×568, con texto
ampliado, completa dos rondas. Ambos recorridos vuelven a una preparación
vacía y comprueban un tamaño mínimo de casilla de 32 puntos.

Los escenarios complementarios comprueban dobles, omisión, suma y reversión
de puntos, puestos reclamados y victoria a 26 puntos en pantalla. Una prueba
con movimiento habilitado verifica impacto, revelado y bloqueo de selección
hasta terminar el movimiento de los dados. Se programan los resultados del
azar; las acciones se realizan mediante controles de la interfaz, sin enviar
eventos de juego directamente al BLoC. El clip de esa prueba usa cuadros
simulados: no sustituye la revisión del recurso real en Android e iOS.

`test/golden/partida_capturas_test.dart` conserva referencias visuales de los
resultados, los destinos resaltados y el historial. Comparte la carga de
fuentes con las capturas de menú y preparación. Las comparaciones se ejecutan
en macOS y deben revisarse visualmente antes de actualizar referencias.



## Cuatro niveles, fondos y personajes

`NUEVA PARTIDA` abre primero el selector de niveles, con cuatro tarjetas y sus miniaturas. Tocar una tarjeta o `NIVEL ALEATORIO` solicita el nombre y crea la preparación del mapa elegido. El sorteo es uniforme entre los cuatro y se ejecuta una sola vez por selección. Cancelar el nombre vuelve al selector; volver desde el selector regresa al menú.

| Nivel | Definición | Zonas | Nave y personaje |
|---|---|---:|---|
| 1 | `tablero_01` | 9 | `Maul N1.png` |
| 2 | `tablero_02` | 10 | `Obi N2.png` |
| 3 | `tablero_03` | 8 | `Anakin N3.png` |
| 4 | `tablero_04` | 8 | `Luke N4.png` |

Los cuatro mapas reproducen 49 celdas y sus seis posiciones iniciales. Blanco y amarillo forman una sola zona por mapa aunque sus celdas estén separadas; blanco exige números iguales y amarillo números distintos. En Nivel 4, la fila 1 es una zona naranja que acepta 4–6 y la fila 7 es otra que acepta 1–3; ambas permiten repeticiones y puntúan independientemente 6/4/3. Las demás agrupaciones y las tablas de puntos están definidas en `docs/reglas_mapas.md`.

`RecursosNivel` relaciona cada mapa con `Nivel N.png`, `Mini N.png` y su nave con personaje. Preparación, partida y resultados conservan el fondo seleccionado. La nave se muestra en preparación, partida y celebración con su proporción original, y el origen de los disparos se ajusta al recurso. Nave y personaje son una ilustración única: se anima el conjunto. El selector conserva el escenario neutro y el menú usa su ilustración propia `PantallaMenu1.png`. `EMPEZAR DE NUEVO` conserva nivel y nombre, con un tablero vacío.

Los cambios se comprueban con `test/catalogo/niveles_test.dart`, `test/bloc/menu_bloc_test.dart` y `test/presentation/niveles_flujo_test.dart`. Este último usa recorridos fijos y dados programados para jugar por controles reales hasta ganar en cada mapa, comprobar los puntos y el personaje de la celebración y reiniciar. Las capturas de los cuatro niveles y del selector están en `test/golden/niveles_capturas_test.dart`; las imágenes se precargan antes de capturar para evitar referencias incompletas.

Se agregó `flutter_lints` y se corrigieron los avisos detectados. Las referencias visuales se revisaron con los nuevos fondos, naves y controles antes de actualizarlas. La revisión de fluidez en teléfonos físicos y en iOS sigue pendiente. La compilación Android de depuración se genera con `flutter build apk --debug --no-pub`.

Los recursos aportados `Nivel 4.png` y `Mini 4.png` contienen «VI» en la ilustración; el selector los identifica como Nivel 4 y se conservaron las imágenes originales.

Verificación de esta entrega (22 de octubre de 2026): **264 pruebas aprobadas**, análisis sin problemas y APK de depuración compilado. No se comprobó el rendimiento en teléfono físico ni se compiló iOS.

El número romano original de cada fondo se encuadra en `NumeroFondoNivel`, justo encima de la nave en preparación y partida. Permanece fijo junto a la nave y queda fuera de las barras del sistema. El paisaje permanece fijo, sin duplicar el número detrás del tablero; las imágenes originales no se modifican. Las capturas incluyen un caso del Nivel 3 con barras del sistema y las pruebas de encuadre cubren los cuatro niveles, texto ampliado y orientación horizontal.

Verificación del ajuste del fondo: **271 pruebas aprobadas** y análisis sin problemas.

La preparación y la partida mantienen visibles el tablero completo, los dados y los botones sin desplazamiento. Las pruebas arrastran el tablero en ambos sentidos y comprueban que ni este ni la nave cambian de posición. El selector, el historial y los resultados conservan su desplazamiento propio.

Rediseño del menú: las capturas de 390×844 y 320×568 reflejan la nueva portada. `menu_portada_test.dart` comprueba el botón de al menos 48 puntos, texto ampliado, barras del sistema, ausencia de desplazamiento y acceso al selector en cuatro tamaños, incluida orientación horizontal. El catálogo de iconos iOS y las cinco densidades Android se generaron desde el original sin transparencia. Verificación: **275 pruebas aprobadas** y análisis sin problemas.
