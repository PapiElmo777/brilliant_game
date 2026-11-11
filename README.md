# Brilliant Game

Juego Flutter organizado como **Tablero → Zona → Celda**, con cuatro niveles seleccionables, preparación, dados y anclas, puntuación, victoria y resultados. Cada zona recibe un `Tipo` para su color y restricción, y una tabla de puntuación propia del nivel. Incluye configuración para Android e iOS.

## Fase 1 del multijugador: cuentas y autenticación

Implementados en Flutter **registro, inicio de sesión, cierre de sesión y borrado de cuentas**, conforme al alcance indicado por el usuario. Se reutiliza el servidor Java/Spring/SQLite independiente de `../brilliant_server`. Renombrado permanece fuera de esta entrega. El cierre de sesión se añadió el 3 de noviembre de 2026.

La app arranca en login; crear cuenta abre directamente el menú. El menú tiene acceso a «Mi cuenta», donde se puede cerrar sesión o eliminarla con contraseña actual y confirmación explícita. La cuenta aporta UUID y nombre a las partidas locales y resultados: ya no se pide un nombre por partida. Se conservan los cuatro niveles, reglas, puntuaciones y animaciones.

Desde el 3 de noviembre de 2026, el registro requiere **3–128 caracteres y al menos un carácter especial** (puntuación o símbolo, por ejemplo `a!2`). Los espacios no satisfacen el requisito de carácter especial. Las cuentas anteriores conservan acceso aunque su contraseña no tenga símbolo.

La sesión se conserva hasta **10 minutos al cerrar o dejar en segundo plano la app**, mediante almacenamiento protegido del dispositivo y validación contra el servidor al reabrir. No se guarda la contraseña. Cerrar sesión, caducar o perder la conexión desmonta las rutas protegidas y borra el acceso guardado. La pérdida de conexión muestra una ventana en login. Los apartados de entregas anteriores que siguen conservan su contexto histórico; las correcciones del 9 de noviembre al final describen el comportamiento vigente.

### Conexión práctica por Wi-Fi

Instala la misma app **Debug** en cada dispositivo y conecta todos a la misma red Wi-Fi de la computadora. La primera vez, en el acceso abre **Servidor**, escribe la dirección indicada por la terminal y pulsa **Guardar y conectar**. La app comprueba `/api/v1/health/ready` antes de guardar. Ejemplo: `192.168.0.31:8080`; añade `/api/v1` automáticamente. La dirección se recuerda al cerrar y abrir la app, sin recompilar. Si cambia la IP o la red, vuelve a Servidor antes de iniciar sesión. La sesión guardada pertenece únicamente al servidor elegido y puede recuperarse dentro de los diez minutos.

En esta Mac, Java 24/25 falló al aceptar conexiones LAN incluso con un socket mínimo. Java 21 incluido en Android Studio respondió correctamente desde el Samsung. Arrancar desde terminal con:

```sh
cd /Users/alfredojimenez/developer/brilliant_game/brilliant_server
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" -jar target/brilliant-server.jar --spring.profiles.active=lan
```

El perfil `lan` escucha en todas las interfaces y muestra las direcciones locales. Conserva SQLite y la clave en `./data`; usar siempre esta carpeta para conservar las cuentas. Usar `target/brilliant-server.jar`, el artefacto actual, o abrir `../brilliant_server/iniciar_servidor.command` con doble clic. Los nombres históricos con sufijos pueden contener versiones antiguas sin salas. Para reconstruir en el futuro, detener antes el servidor, ejecutar `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./mvnw verify` y arrancar `target/brilliant-server.jar` con el mismo perfil. No sobrescribir un JAR mientras Java lo usa.

En un emulador Android estándar ejecutado en la misma Mac, configurar `10.0.2.2:8080`; en simulador iOS, `http://localhost:8080`. El teléfono físico usa la IP Wi-Fi de la Mac. Para el uso normal no hace falta túnel ADB ni USB.

`shared_preferences` guarda exclusivamente la dirección, sin contraseñas ni tokens. La configuración guardada tiene prioridad sobre `--dart-define=API_BASE_URL=...`, que permanece disponible como configuración inicial de desarrollo. Cambiar el servidor requiere estar fuera de sesión y crea un cliente nuevo con formularios y navegación vacíos. Las cuentas pertenecen al servidor elegido.

El cliente no sigue redirecciones y solo envía Bearer al origen configurado. HTTP se admite únicamente en Debug; release/profile exige HTTPS. Android permite HTTP solo en Debug e iOS conserva sus permisos de desarrollo separados. Esta entrega prepara conexión y cuentas para varios dispositivos; las salas y partidas sincronizadas siguen pendientes.

### Verificación de cuentas

```sh
flutter analyze
flutter test
flutter build apk --debug --no-pub
flutter build ios --simulator --debug --no-pub
```

El recorrido real optativo requiere el JAR hermano generado y Java en `/usr/bin/java`:

```sh
flutter test test/auth/auth_api_e2e_test.dart --dart-define=RUN_AUTH_API_E2E=true
```

La prueba arranca Java desde una carpeta temporal, con puerto libre, datos y claves temporales. Recorre los formularios de registro/login/borrado, reinicia app y servidor para comprobar persistencia, abre una partida local con la identidad de la cuenta, comprueba duplicado sin distinguir mayúsculas, cancelación, contraseña incorrecta, borrado, login posterior rechazado y revocación del token. No toca cuentas ni datos existentes. Por defecto se omite para que `flutter test` no requiera Java.

Verificación de esta entrega (2 de noviembre de 2026): **296 pruebas Flutter aprobadas**, incluidas 21 comparaciones visuales; el recorrido Java optativo se omite en la suite normal y se ejecutó por separado correctamente. Análisis sin avisos, **17 pruebas del servidor aprobadas**, JAR generado, APK Android Debug y aplicación iOS Debug para simulador compilados. Revisadas visualmente las pantallas de login, registro, borrado y las dos capturas modificadas del menú. El recorrido real comprobó persistencia al reiniciar el servidor, acceso tras reiniciar el cliente y rechazo de login/token después del borrado. No se ejecutó la interfaz en teléfono físico ni sobre LAN, ni se realizó despliegue productivo.

Los documentos de trabajo sincronizados están en `docs/`, excluidos de GitHub. Las secciones de fases del juego que siguen describen entregas anteriores; el flujo de cuentas vigente es el de este apartado.

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

El menú actual usa `assets/images/backgrounds/PantallaMenu1.png` para la batalla y `assets/images/branding/LogoBrilliant.png` para el logo aportado por el usuario. El logo se sitúa debajo de la última nave, seguido del botón `NUEVA PARTIDA` y, debajo de este, «Que la Fuerza guíe tus números.». La ilustración ocupa toda la pantalla, sin franjas laterales ni copias desenfocadas. Una sombra gradual del propio cielo cubre la firma inferior original; el logo nuevo utiliza directamente su transparencia, sin filtros de color ni máscaras. El PNG original de 1774×887 se conserva sin redimensionar ni comprimir de nuevo. El botón es un control real de Flutter y mantiene la navegación al selector de niveles. El acceso a la cuenta aparece en la esquina superior. La portada permanece fija; en horizontal, la ilustración y los controles se distribuyen a los lados.

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

En el flujo autenticado, `NUEVA PARTIDA` abre el selector de niveles y la preparación usa el nombre de la cuenta sin abrir otro formulario. `MenuBloc` conserva sus eventos de nombre para componentes y pruebas del flujo original; la aplicación le entrega automáticamente el nombre autenticado. El UUID del servidor se pasa a `PartidaBloc` para marcador y resultados.

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
juega con un solo jugador local identificado por el UUID de la cuenta y la meta de 2 jugadores. `jugador_1` sigue siendo el valor predeterminado del motor cuando se usa de forma independiente.

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
desde el acceso con una cuenta de prueba: selección del nivel, seis colocaciones manuales en `tablero_01`,
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

`NUEVA PARTIDA` abre primero el selector de niveles, con cuatro tarjetas y sus miniaturas. Tocar una tarjeta o `NIVEL ALEATORIO` crea la preparación del mapa elegido con el nombre de la cuenta. El sorteo es uniforme entre los cuatro y se ejecuta una sola vez por selección. Volver desde el selector regresa al menú.

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

Rediseño del menú: las capturas de 390×844 y 320×568 reflejan la nueva portada. `menu_portada_test.dart` comprueba el botón de al menos 48 puntos, texto ampliado, barras del sistema, orden del logo y la frase, ausencia de desplazamiento y acceso al selector en cuatro tamaños, incluida orientación horizontal. El catálogo de iconos iOS y las cinco densidades Android se generaron desde el original sin transparencia. Verificación: **275 pruebas aprobadas** y análisis sin problemas.

## Actualización de contraseña: 3 de noviembre de 2026

Se redujo el mínimo a 3 caracteres y se exige puntuación o símbolo al registrar. El máximo sigue siendo 128 puntos de código Unicode; no se recortan las contraseñas. La validación se aplica en Flutter y Java y preserva el acceso y borrado de cuentas anteriores sin símbolo.

El JAR actualizado se generó por separado en `../brilliant_server/target/brilliant-server-passwords.jar`, sin sobrescribir el servidor abierto. Detener el proceso anterior antes de arrancar ese JAR desde la carpeta `brilliant_server`, conservando el mismo directorio de datos:

```sh
java -jar target/brilliant-server-passwords.jar --server.address=0.0.0.0 --server.port=8080
```

La prueba de integración admite elegir ese artefacto sin modificar el servidor en uso:

```sh
flutter test test/auth/auth_api_e2e_test.dart --dart-define=RUN_AUTH_API_E2E=true --dart-define=AUTH_SERVER_JAR=../brilliant_server/target/brilliant-server-passwords.jar
```

Verificación de esta actualización: **300 pruebas Flutter aprobadas**, análisis sin avisos, APK Debug generado y recorrido adicional Flutter → JAR correcto con `a!2`. El servidor pasó **19 pruebas**. La captura de registro se revisó visualmente y se actualizó con el nuevo requisito.

## Corrección de configuración de acceso: 3 de noviembre de 2026

El cliente valida que la ruta de `API_BASE_URL` termine en `/api/v1` (permite barra final). Un sufijo accidental como `/api/v1+` se rechaza como configuración inválida antes de enviar credenciales. Un `401` inesperado en login o registro muestra un rechazo de acceso y permite reintentar; no anuncia caducidad de una sesión que aún no existe. Los `401` de operaciones protegidas siguen limpiando la sesión.

Verificación: 28 pruebas de autenticación correctas y análisis sin avisos. La configuración de prueba del Samsung usa exactamente `--dart-define=API_BASE_URL=http://127.0.0.1:8080/api/v1` mediante el túnel ADB.

## Cerrar sesión: 3 de noviembre de 2026

Desde el menú, pulsar el nombre de la cuenta → **Cerrar sesión**. Flutter envía `POST /api/v1/auth/logout` sin cuerpo y con el Bearer de la sesión actual. Tras 204 elimina la identidad y el token de memoria y desmonta todas las rutas; atrás no permite volver al menú. La cuenta y sus demás sesiones se conservan y se puede iniciar sesión otra vez.

Si falla la conexión, el panel ofrece reintentar o elegir **Salir solo de este dispositivo**, indicando que no se confirmó el cierre remoto. No se reintenta automáticamente. Una respuesta tardía se descarta y no puede cerrar una sesión nueva. Los rechazos 401 y la caducidad limpian la sesión local.

La API ya implementaba logout; no se modificó ni recompiló el servidor abierto. El recorrido contra el JAR comprueba por botones reales el cierre, la revocación inmediata de ese token, la conservación de otra sesión y el acceso de nuevo con la misma cuenta.

Verificación del cierre de sesión: **317 pruebas Flutter aprobadas**, análisis sin avisos, APK Android Debug compilado y recorrido adicional Flutter → JAR correcto. Revisadas visualmente las capturas del panel de cuenta y del aviso de cierre no confirmado.

## Conexión persistente: 4 de noviembre de 2026

Análisis sin avisos, **347 pruebas Flutter aprobadas**, recorrido real Flutter → JAR correcto, APK Android Debug y app iOS para simulador compilados. Revisadas tres capturas nuevas de Servidor. El servidor pasó **20 pruebas**, incluida concurrencia de cuatro clientes. Samsung SM-N985F obtuvo HTTP 200 por Wi-Fi directo contra Java 21 en el puerto 8080. La comprobación con cuatro dispositivos físicos y las partidas en línea siguen pendientes.

## Una sesión por cuenta y registro local de pruebas: 5 de noviembre de 2026

Un segundo dispositivo recibe «La cuenta ya tiene una sesión abierta en otro dispositivo» sin cerrar la sesión del primero. Para probar varios dispositivos a la vez, crear una cuenta para cada uno. Logout permite el siguiente acceso inmediatamente. La app comprueba actividad cada 10 segundos y al volver al primer plano; 45 segundos sin actividad liberan la cuenta. Al volver después de ese tiempo es necesario iniciar sesión de nuevo. Los 401 limpian identidad y navegación; los fallos de red no afirman un cierre remoto. La sesión sigue únicamente en memoria y mantiene su caducidad de token.

Esta política reemplaza el comportamiento anterior que permitía varias sesiones de una cuenta. El servidor migra la base existente a V002, conserva las cuentas y exige actualizar también la app para mantener su actividad. Arrancar el JAR nuevo desde la carpeta del servidor, después de detener el anterior:

```sh
cd /Users/alfredojimenez/developer/brilliant_game/brilliant_server
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" -jar target/brilliant-server-accounts.jar --spring.profiles.active=lan
```

El perfil LAN crea `brilliant_server/data/cuentas-prueba.json`: archivo local solicitado con usuarios y contraseñas legibles para pruebas. Se completa después de registrar o iniciar sesión correctamente, actualiza renombrados y quita cuentas eliminadas; no recupera contraseñas antiguas de sus hashes. Está fuera de Git y solo su propietario puede leerlo. Se puede desactivar con `RECORD_TEST_ACCOUNTS=false`; producción prohíbe activarlo. Flutter sigue sin guardar contraseñas ni tokens.

Verificación: **352 pruebas Flutter aprobadas**, análisis sin avisos, APK Android Debug generado, **29 pruebas Java** y recorrido real Flutter → JAR correcto, incluyendo rechazo del segundo acceso sin afectar al primero, logout y acceso posterior. Se comprueban además actividad periódica, regreso al primer plano y rechazo de respuestas antiguas.

## Plan de partidas multijugador: 5 de noviembre de 2026

Se redactó el plan local `docs/PLAN_IMPLEMENTACION_MULTIJUGADOR.md`, sincronizado entre ambos proyectos y excluido de Git junto con la documentación de trabajo. Incluye salas de **2–6 jugadores en total**, menú Un jugador/Multijugador, lobby con Listo e Iniciar, preparación individual, dados comunes, rondas de 60 segundos, chat, reclamos compartidos, ranking, cambio de anfitrión, animación de derrota y revancha. Metas confirmadas: 2 → 26, 3 → 24, 4 → 22, 5–6 → 20. Los puestos de zona 4–6 dan 0 puntos; el ranking desempata por zonas completadas y después por quién alcanzó antes su puntuación. El número del lobby es la capacidad máxima y se puede iniciar desde dos presentes listos.

El documento separa requisitos confirmados, propuestas técnicas, casos por decidir, siete entregas y su matriz de verificación. Esta actualización es solo planificación: las partidas sincronizadas aún no están implementadas ni probadas; las cifras de pruebas anteriores corresponden al juego local y a cuentas/conexión.

Reglas posteriores confirmadas para este plan: conservar la meta pese a abandonos; el último participante gana por abandono. Se reemplaza el cierre automático por bloqueo por una **votación tras tres rondas consecutivas sin movimientos válidos para nadie**, aprobada por **más de la mitad de quienes siguen participando**. Una omisión voluntaria o timeout con movimientos disponibles no cuenta como bloqueo. El plan local incluye los estados, mayorías de 2–6 y pruebas previstas; la votación tiene un máximo de **60 segundos** y, si se aprueba, el **primero del ranking gana y recibe la animación de victoria**. Los demás ven su derrota y puesto.

**Flujo de implementación acordado:** al comenzar el desarrollo se creará la rama **`multiplayer`** desde `main` en cada repositorio (Flutter y servidor). Toda la implementación relacionada con el multijugador se hará allí, con commits por entrega. Cuando la funcionalidad completa esté terminada y verificada, se hará merge de `multiplayer` a **`main`** en ambos proyectos. Esta actualización solo documenta el acuerdo; las ramas se crearán al iniciar la implementación.


## Inicio de implementación multijugador: 5 de noviembre de 2026

Trabajo iniciado en la rama **`multiplayer`** de ambos repositorios, siguiendo el plan local. Primer bloque de la entrega 1: meta de seis jugadores (20), ranking por puntos/zonas/orden de puntuación, catálogo JSON de los cuatro mapas y motor Java de preparación, restricciones y anclas. El [contrato v1](contracts/multiplayer-v1.md) y sus [esquemas JSON](contracts/multiplayer-v1.schema.json) quedan versionados junto al código. Sus rutas de salas/partidas todavía no están expuestas.

Flutter conserva access y refresh únicamente en memoria y renueva el acceso antes de caducar, manteniendo la sesión exclusiva. Coordina renovación con logout/borrado, ignora respuestas tardías y respeta Retry-After. Ante respuesta de red incierta de refresh no reenvía el secreto; el acceso actual termina al caducar o recibir 401. Un proceso nuevo sigue requiriendo login.

Paridad comprobada mediante **80 estados y 2880 combinaciones de dados** compartidos por Dart y Java, con copias idénticas del catálogo y corpus. Verificación final: **362 pruebas Flutter aprobadas** (recorrido JAR optativo omitido) y análisis sin avisos. La suite Java tiene **33 pruebas aprobadas**, incluida actividad durante 21 minutos con reloj controlado, dos rotaciones y la misma sesión. La verificación de sesión exclusiva no acredita pertenencia única a salas: esta comprobación sigue pendiente al integrar su persistencia.

La entrega 1 permanece en curso. Aún faltan salas/lobby, canal/chat, rondas sincronizadas, premios transaccionales, continuidad, final y revancha. No se ha hecho merge a `main`, modificado las cuentas existentes ni reiniciado el servidor LAN. Los empates absolutos y las demás decisiones pendientes del plan continúan sin resolverse.


## Menú y lobby multijugador: 5 de noviembre de 2026

Implementada la entrega 2 en **`multiplayer`**: menú Un jugador/Multijugador, listado, Alojar partida con nombre/capacidad, cuatro mapas y selección aleatoria, participantes, Listo e Iniciar. Solo el anfitrión cambia configuración. Por indicación del usuario, **Listo se conserva al cambiar mapa o capacidad**; el invitado puede quitarlo y no se admite una capacidad menor que los presentes.

SQLite V003 conserva V001/V002 y agrega pertenencia única por cuenta, recibos idempotentes y eventos. Entradas simultáneas no sobrepasan el cupo; inicio/entrada congelan una lista válida. El cliente recupera la sala existente, consulta cada tres segundos en primer plano y confirma la salida con Java. Reintentos de resultados inciertos conservan el mismo comando. Logout/borrado liberan lugar y transfieren anfitrión sin eliminar el historial de los demás. Las reglas de abandono durante las rondas siguen en entrega 5.

**Alcance del inicio:** fija mapa, participantes, meta e ID de partida en PREPARING. La preparación individual y las rondas compartidas todavía no están integradas; no se abre una partida local en su lugar. WebSocket y chat corresponden a la siguiente entrega. Las cuentas reales y el servidor LAN no se han modificado ni reiniciado.

Verificación: **376 pruebas Flutter aprobadas**, dos recorridos JAR optativos omitidos en la suite normal, análisis sin avisos, **43 pruebas Java aprobadas**, reapertura V003 e identidades históricas. Se ejecutó aparte el [recorrido real de salas](contracts/multiplayer-v1.md): siete clientes Dart independientes contra el JAR, seis en una sala, séptimo rechazado y otra sala aislada, preparación común y transferencia de anfitrión. No es una prueba de seis teléfonos ni de dados compartidos. Capturas de menú/lobby revisadas; pruebas de 320×568, 390×844, horizontal y texto 2× sin desbordamientos.

El JAR estándar actualizado y el APK Android Debug están generados. Antes de arrancarlo sobre una base existente, respaldar SQLite con el proceso detenido: V003 se aplicará al arrancar y no se debe volver a un JAR que solo conozca V001/V002. Las pruebas usaron carpetas y cuentas temporales. El merge a `main` se mantiene reservado para completar y verificar todo el multijugador.


## Canal de eventos y chat: 6 de noviembre de 2026

Implementada la entrega 3 en **`multiplayer`**. El lobby recibe instantánea y eventos ordenados por WebSocket, comprueba saltos/duplicados y reconecta conservando identidad, mapa y Listo. La renovación de token sustituye el canal; aperturas simultáneas dejan vigente el último vínculo confirmado. Bearer solo en cabecera, sin query ni redirecciones, con autorización y caducidad comprobadas durante toda la conexión.

Chat disponible en lobby y preparación: burbuja con no leídos junto a los controles, mensajes de sistema y jugadores diferenciados, historial paginado y borrador conservado ante respuestas inciertas. Texto plano de hasta 300 puntos de código, 10 mensajes por cuenta cada 10 segundos, reintentos idempotentes y Retry-After. El servidor conserva historial; el cliente carga páginas de 20 y hasta 200 mensajes en memoria. Se mantienen los botones uniformes del menú principal.

V004 incorpora presencia de canal y mensajes sin cambiar migraciones aplicadas. Una vez enlazado, solo sus latidos mantienen la presencia de sala; consultar la cuenta o GET no oculta un canal perdido. Se reserva el lugar hasta 45 segundos y se recupera el mismo miembro dentro del plazo. El canal lee eventos después del commit, usa envíos acotados y evita que un cliente lento bloquee a otros. Las reglas de abandono y victoria durante rondas pertenecen a entrega 5.

Verificación: **394 pruebas Flutter aprobadas**, análisis sin avisos, **51 pruebas Java aprobadas** y recorrido real adicional contra el JAR con **seis canales Dart y otra sala aislada**: chat común, reconexión, renovación, mapa/Listo, latidos y preparación. Pruebas de teclado, texto 2×, envío incierto y logout con chat abierto. Capturas revisadas y JAR/APK Debug generados. Los dos recorridos JAR optativos se omiten en la suite normal; el de salas se ejecutó por separado. No representa seis teléfonos físicos ni una partida con dados compartidos.

El [contrato actualizado](contracts/multiplayer-v1.md) detalla frames, cierre, límites e historial. La siguiente entrega integra preparación individual y rondas de 60 segundos. No se reinició el servidor LAN ni se tocaron las cuentas reales. Respaldar SQLite con el servidor detenido antes de arrancar este JAR sobre datos existentes: aplicará V004 y después no se debe arrancar un JAR que solo conozca V003. No se ha hecho merge a `main`.


## Multijugador, entrega 4 — preparación individual y rondas compartidas (6 de noviembre de 2026)

Implementadas y verificadas las entregas 1–4 en `multiplayer`. Preparación manual privada de 1–6, confirmación definitiva y espera de todos los activos. Java genera dados comunes y rondas de exactamente 60 segundos; valida una sola colocación u omisión por participante y ronda. El timeout convierte pendientes en omisión y el avance es único incluso frente a acciones concurrentes.

V005 conserva V001–V004, migra participantes PREPARING y persiste tableros, rondas, acciones y proyecciones privadas por evento. HTTP y seis canales reciben exclusivamente su propio tablero; reconectar restaura la misma ronda. Flutter usa reloj monotónico anclado al servidor, propuestas locales, confirmación, omisión y animación de los dados recibidos. Se conserva Listo al cambiar configuración y el estilo uniforme del menú.

Verificación: 412 pruebas Flutter, análisis sin avisos, 59 pruebas Java y recorrido adicional de siete clientes/seis canales contra el JAR temporal: seis preparaciones diferentes, privacidad, dados/plazo iguales, colocación, omisiones, ronda siguiente, rechazo de ronda antigua y reconexión. Java verifica además timeout a los 60 segundos, carreras y migración V004→V005. Seis capturas nuevas revisadas en tres tamaños; controles probados con texto 2×. JAR y APK Debug generados.

Todo permanece en `multiplayer`, con commits en español y sin merge a main. No se reinició el servidor LAN ni se tocaron datos reales; respaldar SQLite con el proceso detenido antes de aplicar V005. La siguiente entrega es la 5: reclamos/premios transaccionales, continuidad, victoria y votación. No se han añadido puntos globales, final, ranking ni revancha en esta fase. Se mantienen pendientes las decisiones explícitas del plan local.


## Entrega 5 — premios, continuidad y votación (8 de noviembre de 2026)

Implementadas las entregas 1–5 en `multiplayer`. Reclamos y puestos globales únicos, cuarto–sexto +0, marcador propio/rivales, aviso de sistema y actualización de premios disponibles. Colocación, puntos y eventos son transaccionales e idempotentes. Alcanzar la meta fija un único ganador y resultado inmutable; no se aceptan más acciones ni se abre otra ronda.

Confirmaciones del usuario de esta entrega: pausar rondas durante votación; si no se aprueba, continuar y esperar otras tres rondas bloqueadas; retirar el voto de quien abandona y recalcular mayoría. Ranking con abandonos después de activos y orden de ingreso para empates absolutos, tras puntos/zonas/secuencia positiva. Ganador primero. Estas reglas reemplazan las propuestas anteriores.

Tres rondas sin movimientos legales para nadie abren una votación de 60 segundos; omitir con movimientos disponibles rompe la racha. Mayoría absoluta de activos, un voto definitivo por participante, cierre anticipado si se aprueba o resulta imposible aprobar y continuación al expirar sin mayoría. Reconectar y transferir anfitrión conserva la votación. Con un restante prevalece victoria por abandono, manteniendo meta y reclamos; un lote de expiraciones simultáneas no inventa un ganador por el orden de eliminación.

V006 preserva los checksums V001–V005, tableros, rondas y acciones. Agrega progreso, reclamos, votaciones y votos. Resultado con ganador, motivo, posiciones, nombres y puntos congelados; el borrado de cuentas o salidas posteriores no lo reordenan. La UI muestra un resumen del resultado; animaciones de victoria/derrota y revancha corresponden a entrega 6. La política de reinicio de Java y el anfitrión de revancha siguen pendientes.

Verificación: 427 pruebas Flutter, análisis sin avisos y 75 pruebas Java. Incluye reclamos concurrentes de seis, premios +0, reversión completa ante fallo, resultado fijo, mayorías 2–6, voto idempotente, plazo/racha, abandonos, reconexión real y migración V005→V006. Recorrido adicional de siete clientes Dart/seis canales contra el JAR con datos temporales: colocaciones legales hasta completar zonas reales, premios comunes, tableros privados, conservación de reclamos y victoria del último participante. No es una prueba de seis teléfonos. Nueve capturas nuevas/actualizadas de marcador, votación y resultado en tres tamaños; pruebas con texto 2× y chat accesible. JAR y APK Debug generados.

Trabajo en `multiplayer`, commits en español y sin merge a main. No se reinició el servidor LAN ni se tocaron datos reales. Respaldar SQLite con el proceso detenido antes de arrancar el JAR nuevo: aplica V006 y no se debe volver a un JAR anterior. Siguiente entrega: animaciones finales, presentación de resultados y revancha (fase 6).


## Entrega 6 — animaciones, ranking y revancha (8 de noviembre de 2026)

Entregas 1–6 implementadas en `multiplayer`. Solo el ganador recibe la celebración local reutilizada; los demás ven láser, impacto, caída y su puesto confirmado. Ver ranking permite omitir; movimiento reducido muestra el resultado sin desplazamientos ni destellos. Las animaciones son locales y no cambian el resultado, ni se repiten por eventos o reconexión dentro de la misma sesión de sala.

Ranking con ganador/motivo, puestos, puntos, zonas y abandonos del resultado inmutable; fila propia resaltada, Revancha y Salir al menú principal con confirmación remota. Chat accesible durante el final. Pruebas de tres tamaños y texto 2× sin desbordamientos.

Reglas de revancha confirmadas en esta entrega: anfitrión para el primer aceptante, sin recuperar automáticamente el anterior; se permite entrar a jugadores nuevos desde el listado. Aceptación parcial en la misma sala, reinicio de Listo/mapa al aceptar y otro ID al iniciar; meta según los nuevos participantes, sin arrastrar tableros, dados, puntos ni premios. Las personas que aún no aceptan conservan su resultado; al comenzar la siguiente partida se cierra esa aceptación. Cambiar mapa o capacidad dentro del nuevo lobby conserva Listo, como ya estaba confirmado.

V007 mantiene los checksums V001–V006 y agrega la vista de partida del miembro, aceptaciones y eventos autorizados por miembro. Resultados anteriores y nuevo lobby/juego pueden convivir sin mezclar tableros ni recibir estados futuros en eventos atrasados. El cupo cuenta solo al nuevo lobby. Transferencia de anfitrión entre aceptantes; un lobby vacío puede reabrirse si quedan personas en resultados.

Verificación: 440 pruebas Flutter, análisis sin avisos, 83 pruebas Java y recorrido adicional Dart→JAR con siete clientes/seis canales: final con premios y revancha de tres participantes, otro mapa, meta 24, preparación limpia y nueva ronda común. Incluye migración/reapertura V006→V007, aceptación concurrente e idempotente, privacidad de vistas y permisos. Ocho capturas de ranking/animaciones nuevas o actualizadas, revisadas visualmente. JAR y APK Debug generados. Las pruebas usan cuentas, bases y claves temporales; no equivalen a seis teléfonos físicos.

Commits en español en `multiplayer`, sin merge a main. No se reinició el servidor LAN ni se tocaron datos reales. Respaldar SQLite con el proceso detenido antes de aplicar V007; no volver después a un JAR anterior. Próxima entrega: evaluación completa, accesibilidad y comprobación LAN de varios dispositivos (fase 7). La política de reinicio del proceso Java sigue pendiente de decisión explícita.


## Corrección del servidor usado por los dispositivos — 9 de noviembre de 2026

El error genérico al listar o crear salas se debía a que el proceso LAN ejecutaba `brilliant-server-lan.jar` del 5 de noviembre, anterior al multijugador, con base V002. La app actual no encontraba las rutas de salas. Se respaldaron SQLite y la clave, se detuvo ese proceso y se arrancó `target/brilliant-server.jar` actual con Java 21/perfil LAN, aplicando V003–V007 y conservando las tres cuentas existentes. Las copias históricas LAN/cuentas/IP se actualizaron con el servidor detenido.

Para los siguientes arranques usar **`brilliant_server/iniciar_servidor.command`** (doble clic) o el JAR estándar. El iniciador fija la carpeta del servidor y usa el artefacto actual; evita seleccionar un JAR de una entrega antigua. Se corrigió la instrucción inicial que todavía apuntaba al nombre histórico LAN.

Verificación en la red real: Samsung SM-N985F y emulador Android, ambos configurados con `10.22.17.233:8080`, registraron cuentas temporales y listaron salas con 200. El Samsung creó una sala con 200, el emulador se unió con 200 y ambos consultaron el mismo lobby con dos participantes. Las cuentas temporales se eliminaron con 204. Se verificaron integridad SQLite, conservación de cuentas/contraseñas protegidas y clave original. Esta prueba usa HTTP desde ambos dispositivos; no es un recorrido visual de botones ni una prueba de seis teléfonos. El servidor actualizado queda abierto en una ventana visible de Terminal.


## Diseño común, historial y avatares — 9 de noviembre de 2026

El multijugador reutiliza DisenoJuegoFijo, nave/entrada, bandeja de números, disparos, dados animados, meteoritos, globo y panel de puntos del modo solitario. Se retiraron la cabecera y el pie duplicados durante preparación/rondas; reloj, historial, trofeo y chat quedan en la cabecera del juego. La preparación conserva la colocación manual y aleatoria animada y la confirmación definitiva ante Java. Las animaciones no generan dados ni colocaciones remotas.

Historial de tiradas con el mismo panel del modo solitario, restaurado desde las acciones del participante en Java. Cada entrada contiene ronda, dados, colocación/omisión, dado/celda y motivo. Los eventos y HTTP muestran exclusivamente el historial propio; el outbox público sigue vacío en ownHistory. Se conservan los puestos y puntos autoritativos. El acceso a ranking y el salto a resultados usan solo el icono de trofeo con etiqueta accesible.

Menú con icono de usuario sin el nombre como botón y «Bienvenido nombre» debajo del logo. Mi cuenta muestra el avatar y Seleccionar avatar, con las cuatro naves de los niveles. La elección se guarda en la cuenta con PUT /api/v1/users/me/avatar y se recupera al iniciar sesión/renovar; null representa el icono general. V008 agrega avatar_id sin modificar migraciones anteriores ni contraseñas, y valida los cuatro IDs del catálogo.

Verificación: análisis sin avisos, 446 pruebas Flutter, 86 Java y recorrido adicional de seis clientes contra el JAR nuevo (avatar tras refresh, historial privado, rondas, premios, final y revancha). Capturas revisadas de menú, cuenta, selector y preparación/ronda en tres tamaños; texto 2×, salida y chat. APK Debug generado. JAR compilado por separado para no sobrescribir un archivo abierto; servidor LAN actualizado con respaldo previo y las tres cuentas conservadas. El teléfono físico no estaba conectado durante esta comprobación visual.

Arranque definitivo, desde la carpeta del proyecto servidor:

```sh
cd /Users/alfredojimenez/developer/brilliant_game/brilliant_server
./iniciar_servidor.command
```

El iniciador usa Java 21 y target/brilliant-server.jar en perfil LAN. La IP se obtiene al arrancar; al cambiar de red hay que actualizar Servidor en la app. La red usada al finalizar esta corrección anuncia 192.168.0.31:8080. Para ver el diseño y elegir avatar hay que ejecutar/instalar el APK de esta actualización. Trabajo en multiplayer, commits en español y sin merge a main; la evaluación de seis teléfonos sigue pendiente.


## Correcciones de uso y rendimiento — 9 de noviembre de 2026

- Cerrar sesión visible junto a Mi cuenta en el menú; conserva el cierre remoto y la limpieza de navegación existentes.
- Access/refresh en almacenamiento seguro de Android/iOS, separado por servidor, sin contraseña. Se recupera el acceso antes de diez minutos y se valida/rota el token; logout, caducidad o pérdida de conexión borran la copia. En segundo plano se suspenden presencia y renovación. La reserva de cuenta en Java pasa a 600 segundos; la reserva de un lugar en sala sigue siendo 45 segundos.
- Se permite alternar dados antes de confirmar sin volver a bloquear la animación completada. Cambiar el dado descarta la celda propuesta.
- La celda elegida muestra el número provisional y su estado accesible, manteniendo intacto el tablero confirmado hasta la respuesta de Java.
- Fallos de presencia o renovación por red/servidor vuelven a login con una ventana. Un canal caído o una respuesta incierta de sala comprueban también HTTP antes de decidir si se perdió el servidor. La detección depende del latido de diez segundos y del tiempo de espera de red.
- El reloj actualiza su texto sin reconstruir el tablero cada segundo; se reutilizan partida interpretada, tablero y mensajes ordenados. El tablero tiene su propio límite de repintado. El clip de meteoritos pasa de 235 a 34 cuadros (28.045.974 a 4.009.562 bytes), preservando duración, transparencia y píxeles visibles de los cuadros retenidos, con el impacto sincronizado al nuevo recurso. `tool/optimize_meteor_clip.py` documenta la conversión desde el recurso original.

Los clientes simulados pueden inyectar SessionStore y no acceden al almacenamiento del teléfono. La recuperación no reconstruye una navegación antigua: abre el menú con la cuenta validada. Para usar la reserva de diez minutos se necesita actualizar también Java. La mejora de fluidez debe comprobarse en el teléfono; las pruebas de interfaz comprueban que el reloj no reconstruya el tablero, sin afirmar una medición de FPS en un dispositivo físico.

## Presentación de la misión, comunicaciones y podio — 9 de noviembre de 2026

Los dados se revelan desde el impacto de los meteoritos y desde el inicio de la explosión al omitir la caída. Permanecen visibles al terminar; los controles esperan al final del efecto. Cuando ambos dados carecen de destinos aparece el aviso del modo solitario y el botón Omitir ronda sin elegir un dado. Si únicamente el elegido está bloqueado, se indica cambiar al otro.

El ranking del trofeo ordena el top con las mismas prioridades de Java (abandono, puntos, zonas, secuencia e ingreso), se actualiza estando abierto y muestra las conquistas públicas con nombre, color, puesto y premio. Al finalizar usa exclusivamente los puestos congelados del resultado. Chat y ranking comparten paneles oscuros de estilo holográfico; los mensajes propios se distinguen de los del escuadrón y los avisos del sistema, con historial, reintentos y borradores conservados.

El podio incluye salto estelar, corona y alas de piloto, insignia dorada para el campeón y puesto propio en grande para los demás. La fila ganadora tiene una entrada dorada visible para todos. Son animaciones finitas, sin video adicional ni ciclos permanentes; movimiento reducido muestra el resultado estático. Se mantienen revancha, salida y chat.

Las zonas tienen un nombre legible consistente, por ejemplo Verde 1 y Verde 2. Se muestra en las conquistas del ranking, en la ficha al mantener presionada una casilla y en las etiquetas accesibles del tablero. Se conservan los identificadores del contrato y los datos de las partidas. Esta entrega solo requiere actualizar la app.

## Reglas, premios y avisos de misión — 11 de noviembre de 2026

- Reglas visibles a ambos lados del espacio superior de los dados en solitario y multijugador, calculadas desde los tipos del nivel: igualdad, desigualdad, cualquier número, dos números distintos y grupos naranjas 1–3/4–6. Los símbolos geométricos se dibujan para evitar glifos ausentes. Al tocar un símbolo se muestra la regla completa durante ocho segundos. Volver a tirar permanece disponible en la cabecera del modo solitario.
- En línea, cada zona pierde saturación y brillo conforme se ocupan sus puestos premiados. La transición dura 700 ms; sin premios queda apagada, manteniendo números, selección y destinos legibles. Se utilizan nextPlace y las puntuaciones reales de la zona, sin impedir jugadas válidas ni cambiar reclamos.
- La nave anuncia nueva ronda y segundos restantes, y cada reclamo nuevo con jugador, nombre de zona, puesto y puntos. Los avisos se encolan, destacan en ámbar y no repiten el historial al reconectar. Los avisos de falta de destinos tienen prioridad sobre la introducción de ronda.
- Mensajes nuevos de otros jugadores producen una sacudida finita del icono de chat y respuesta háptica del sistema, sin dispararse por historial, mensajes propios o del sistema. No se repite al reconstruir; se omite cuando el chat está abierto. La vibración física depende del dispositivo y sus ajustes.
- Pulso breve al cruzar los 30 segundos, una sola vez por ronda. Durante los últimos diez se muestra un radar rojo con el número grande que se vacía al terminar; no cubre el tablero ni intercepta controles. El tiempo sigue siendo el reloj monotónico anclado a Java. Movimiento reducido conserva los avisos estáticos.

Se incluyen capturas de los cuatro niveles, los tres estados de desgaste y el reloj en 30/10 segundos, también en pantalla pequeña, horizontal y texto ampliado. Las animaciones son locales y finitas, y el reloj actualiza solo sus indicadores. Esta entrega utiliza el contrato existente y requiere actualizar la app.


## Turno bloqueado — 11 de noviembre de 2026

Cuando ninguna orientación de los dados admite una colocación, la única acción de jugada es **Omitir turno**. Se oculta Confirmar jugada, se desactivan los dados y la colocación en el tablero, y en solitario se retira Volver a tirar hasta omitir. El aviso de la nave explica si el tablero está lleno, faltan anclas, no hay vecinos vacíos de las anclas o las reglas de color bloquean las casillas disponibles. Esta explicación tiene prioridad sobre las transmisiones temporales; navegación, chat y consulta de reglas siguen accesibles. Si al menos uno de los dados tiene un destino, se conserva el cambio entre dados y la confirmación normal. Omitir continúa siendo una decisión explícita y el servidor confirma el resultado.
