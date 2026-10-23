# Plan de implementación: cuatro niveles, colores y selección de mapa

Fecha: 22 de octubre de 2026.
Estado: implementado el catálogo de cuatro niveles, reglas, puntuación por zona, selector y recursos visuales. Verificación automática completada: 264 pruebas aprobadas, análisis sin problemas y compilación Android de depuración correcta. Pendiente revisión de fluidez en teléfonos físicos y en iOS.

## 1. Objetivo y alcance

Incorporar tres mapas nuevos al catálogo y presentar los cuatro niveles antes de solicitar el nombre del jugador. El tablero actual será el Nivel 1. Cada nivel tendrá su propio fondo, miniatura, nave con personaje, distribución, seis posiciones iniciales y puntuaciones. Se podrá escoger cualquier nivel o elegir uno al azar; todos estarán disponibles desde el principio.

El flujo será:

`Menú principal → NUEVA PARTIDA → selección de nivel → nombre → preparación del nivel elegido → partida → celebración → resultados`.

Se mantienen las reglas generales de dados, anclas, edición de la ronda, omisión, relanzamiento y victoria. La meta seguirá dependiendo del número de jugadores: 26, 24, 22 o 20 para 2, 3, 4 o 5 jugadores. La modalidad actual conserva la meta de 26 y un solo jugador local. Este trabajo no agrega multijugador, desbloqueos, guardado ni sonido. Los pasos y criterios siguientes conservan la especificación de la etapa; el resultado de implementación se registra al final.

## 2. Fuentes y decisiones

- `docs/reglas_mapas.md`: matrices completas, coordenadas iniciales, puntuaciones y agrupaciones de los niveles 2, 3 y 4. Las matrices y sus tablas se implementarán literalmente; no se deducirán de los fondos ni de las miniaturas.
- Imagen «SIGNIFICADOS DE LAS ZONAS» aportada en el chat: referencia de restricciones de color. El blanco del proyecto corresponde al gris de la imagen: números iguales dentro de su zona.
- `lib/catalogo/tablero_01.dart`: referencia vigente del Nivel 1, con nueve zonas; se conservan distribución, IDs, seis posiciones iniciales y puntuaciones. La mención de trece zonas en el antiguo plan de interfaz queda desactualizada y se corrigió al documentar esta etapa.
- Para naranja se aplica la especificación concreta ya confirmada en `reglas_mapas.md`: zona superior 4–6 y zona inferior 1–3. La imagen expresa la regla general de escoger uno de esos grupos; en este mapa el grupo ya está asignado a cada franja, no lo decide el primer número colocado.
- Confirmación del usuario: todas las celdas blancas de cada mapa constituyen una sola zona, igual que las amarillas aunque estén separadas. Blanco exige números iguales; amarillo exige distintos. En Nivel 4, naranja superior abarca (1,1)–(1,7) y naranja inferior (7,1)–(7,7); ambas puntúan 6/4/3 de manera independiente. El límite 4 del rango superior se interpreta según la especificación previa, pues quedó omitido en el último mensaje.
- Blanco y naranja son colores distintos de azul y amarillo, aunque algunas restricciones coincidan. Deben conservar sus nombres, representación y puntuación propios.

## 3. Catálogo y recursos

| Nivel | ID del tablero | Fondo | Miniatura | Zonas esperadas |
|---|---|---|---|---:|
| 1 | `tablero_01` | `assets/images/backgrounds/Nivel 1.png` | `assets/images/minis/Mini 1.png` | 9 |
| 2 | `tablero_02` | `assets/images/backgrounds/Nivel 2.png` | `assets/images/minis/Mini 2.png` | 10, según tabla de agrupaciones |
| 3 | `tablero_03` | `assets/images/backgrounds/Nivel 3.png` | `assets/images/minis/Mini 3.png` | 8, según tabla de agrupaciones |
| 4 | `tablero_04` | `assets/images/backgrounds/Nivel 4.png` | `assets/images/minis/Mini 4.png` | 8, según tabla de agrupaciones |

Inventario comprobado: los cuatro fondos están presentes, de aproximadamente 841 × 1870 píxeles; las cuatro miniaturas están presentes, de 1254 × 1254 píxeles. La cuarta miniatura se incorporó durante la redacción y se verificó antes de cerrar el plan.

Registrar `assets/images/minis/` en `pubspec.yaml`; backgrounds ya está registrado. Respetar espacios, mayúsculas y extensiones de las rutas. Los niveles deberán tener un orden explícito del 1 al 4, independiente del orden de lectura de los archivos.

## 4. Reglas de las zonas

| Color o variante | Restricción |
|---|---|
| Verde | Cualquier número entre 1 y 6; permite repeticiones. |
| Azul | Todos los números iguales en su zona. |
| Blanco | Todos los números iguales en su zona, incluso entre celdas separadas. |
| Rojo y amarillo | Todos los números diferentes en su respectiva zona. |
| Morado | Máximo dos números diferentes; permite repeticiones. |
| Naranja superior | Solo 4, 5 y 6; permite repeticiones. |
| Naranja inferior | Solo 1, 2 y 3; permite repeticiones. |

La validación global 1–6 permanece en el motor. Las restricciones se aplican durante preparación, reemplazo, intercambio, acomodo aleatorio y colocación con ancla. No se duplicarán reglas en los widgets.

Crear `TipoBlanco` y un `TipoNaranja` configurable por grupo permitido (bajo 1–3 o alto 4–6), con identidad y descripción claras. Una franja naranja tiene siete celdas y permite repeticiones; no debe heredar la restricción de valores distintos de rojo o amarillo.

Actualizar los nombres y la presentación de las zonas, incluidos `FichaZona.nombreTipo`, las etiquetas del lector de pantalla, las descripciones de reglas y las copias de casillas utilizadas en la celebración. En blanco, usar números, contornos e indicadores de destino con contraste oscuro cuando corresponda; comprobar también la selección y el oscurecimiento de zona completada.

## 5. Puntuación configurable por nivel y zona

Actualmente `Tipo.puntuaciones` fija una sola escala por color, `Marcador.reclamar` la consulta directamente y `puntosDeZona` hace lo mismo. Eso no permite que el morado valga 6/4/2 en Nivel 1 y 7/5/3 en Nivel 3.

Solución prevista:

1. Añadir puntuaciones inmutables a `DefinicionZona` y a `Zona`, con puestos 1, 2 y 3 explícitos. Validar claves, valores enteros no negativos y no crecientes por puesto.
2. Para conservar usos existentes, aceptar por defecto las puntuaciones actuales del tipo cuando no se indique una tabla de zona. Los mapas nuevos declararán sus tablas explícitamente. Ningún tipo compartido se modifica al seleccionar un nivel.
3. Hacer que `Marcador.reclamar` reciba la zona y el jugador, y calcule los puntos desde `zona.puntuaciones`. Migrar llamadas y pruebas para que no pueda recibirse el ID de una zona con los puntos de otra.
4. `puntosDeZona` y la ficha visual usarán la misma tabla efectiva que el marcador; lo mostrado y lo otorgado deberán coincidir.
5. Preservar la configuración al crear y copiar tableros: `DefinicionZona.crearZona`, `PreparacionInicial._copiar`, la copia de `PartidaBloc` y cualquier otra fábrica. Una copia no puede volver silenciosamente a las puntuaciones del Nivel 1.
6. Mantener reclamos independientes por ID de zona, reversión de puntos al editar y bloqueo definitivo al ganar. Los puestos posteriores al tercero siguen dando cero puntos.

Puntos por primer, segundo y tercer puesto:

| Color | Nivel 1 actual | Nivel 2 | Nivel 3 | Nivel 4 |
|---|---|---|---|---|
| Blanco | — | 3 / 2 / 1 | 8 / 6 / 4 | — |
| Amarillo | 8 / 6 / 4 | 6 / 4 / 2 | 7 / 5 / 3 | 8 / 6 / 4 |
| Rojo | 6 / 4 / 2 | 6 / 4 / 2 | 6 / 4 / 2 | 6 / 4 / 2 |
| Verde | 4 / 3 / 2 | 4 / 3 / 2 | 6 / 5 / 4 | 3 / 2 / 1 |
| Azul | 7 / 6 / 3 | 7 / 6 / 3 | 7 / 5 / 3 | 8 / 6 / 4 |
| Morado | 6 / 4 / 2 | 6 / 4 / 2 | 7 / 5 / 3 | 7 / 5 / 3 |
| Naranja | — | — | — | 6 / 4 / 3 por franja |

## 6. Definición de los mapas

Todos son de 7 × 7, con 49 coordenadas únicas, exactamente seis posiciones iniciales y una sola zona por celda. Conservar IDs de celda `fN_cN` y zonas con IDs estables; los IDs pueden repetirse entre tableros, porque cada partida tiene su propia instancia.

Crear `tablero_02.dart`, `tablero_03.dart` y `tablero_04.dart`. Registrar los cuatro en `CatalogoTableros.predeterminado`. Ampliar `DefinicionTablero` con número de nivel, ruta de fondo, miniatura, ruta de nave y etiqueta de personaje; mantener compatibles las definiciones artificiales empleadas en pruebas mediante metadatos opcionales y validar los recursos en el catálogo de producción.

### Nivel 2

- Iniciales: (1,5), (3,1), (4,3), (5,6), (6,2), (7,5).
- Blanco: una zona con ambas celdas separadas, confirmado.
- Amarillo: una sola zona con todas sus celdas separadas, confirmado.
- Agrupación propuesta: rojo izquierdo y derecho; verde superior derecho e inferior izquierdo; azul superior e inferior; morado superior izquierdo e inferior derecho.
- Control de colores: B=2, A=5, R=12, V=10, C=10, M=10.

### Nivel 3

- Iniciales: (2,3), (2,6), (4,4), (5,2), (5,7), (7,3).
- Blanco: una zona con las cinco celdas separadas, confirmado.
- Amarillo: una sola zona a ambos lados, confirmado.
- Agrupación propuesta: dos rojos; verde único; azul único; morado superior e inferior, este último con ambas mitades de fila 7.
- Control de colores: B=5, A=6, R=12, V=9, C=5, M=12.

### Nivel 4

- Iniciales: (1,5), (3,3), (3,6), (4,1), (6,5), (7,2).
- Naranja: dos zonas independientes de siete celdas, fila 1 con 4–6 y fila 7 con 1–3, confirmado. Cada franja reclama puntos por separado.
- Amarillo: una sola zona con todas sus celdas separadas, confirmado.
- Agrupación propuesta: rojo izquierdo y derecho; verde único con sus cuatro celdas separadas; azul único con sus seis celdas separadas; morado central único.
- Control de colores: N=14, A=6, R=12, V=4, C=6, M=7.

La agrupación será explícita y seguirá la tabla de `reglas_mapas.md`, que ya especifica todos los colores. No se crearán zonas automáticamente por conectividad ni se fusionarán todas las celdas de un color. Los recuentos esperados según esa tabla son 10 zonas en Nivel 2, 8 en Nivel 3 y 8 en Nivel 4. Las entradas identificadas como propuestas en la fuente se adoptan como base de implementación, sin atribuirles una confirmación adicional del usuario.

## 7. Selección de nivel y navegación

### Presentación

Pantalla con título «ELIGE TU NIVEL», cuatro tarjetas ordenadas y opción «NIVEL ALEATORIO». Cada tarjeta muestra la miniatura completa con proporción cuadrada, el texto «NIVEL N» y respuesta visual al tocar. La miniatura es la ilustración aportada; no debe sustituirse por una cuadrícula generada del tablero.

Usar una cuadrícula de dos columnas cuando haya espacio. En ancho reducido o con texto ampliado, permitir una columna y desplazamiento para mantener legibles las tarjetas y accesibles todas las opciones. Etiquetas semánticas por nivel y para la selección aleatoria; la imagen decorativa no duplica la lectura del nombre.

Tocar una tarjeta confirma ese nivel y abre el diálogo de nombre. «NIVEL ALEATORIO» escoge uniformemente entre los cuatro (25 % cada uno), una sola vez, y después solicita el nombre; el diálogo indicará el nivel elegido. No habrá niveles bloqueados ni preferencia por niveles no jugados.

### BLoC

Ampliar `MenuBloc` con fase `seleccionandoNivel`, eventos de selección por ID, elección aleatoria y cancelación, y el tablero seleccionado en el estado. Inyectar una fuente de azar controlable para las pruebas de selección.

- `NuevaPartidaSolicitada` abre primero el selector.
- Un nivel válido pasa a `pidiendoNombre`; una selección inválida no navega ni crea una partida.
- El nombre válido crea la partida con el tablero seleccionado, eliminando el ID fijo `tablero_01` del flujo actual.
- Mientras el selector, el diálogo o la navegación estén en curso, los toques repetidos no abren copias ni vuelven a sortear.
- Cancelar el nombre devuelve al selector y conserva la última selección; volver desde el selector lleva al menú principal.
- La intención de navegar se procesa una sola vez por `solicitudId`. Los widgets manejan rutas y diálogos; el BLoC maneja selección y estado.
- El nombre anterior se puede seguir proponiendo como ahora.

Implementar la selección como una ruta propia vinculada al mismo `MenuBloc` del flujo, usando `BlocProvider.value` cuando corresponda. Al confirmar nombre, reemplazar el selector por preparación, dejando la pila `menú → preparación`; así volver desde la preparación mantiene el comportamiento actual. Verificar cancelaciones y que los listeners no abran dos diálogos al cambiar de ruta.

«EMPEZAR DE NUEVO» desde resultados conserva el nivel y el nombre y abre una preparación limpia directamente. «SALIR AL MENÚ» permite elegir otro nivel al volver a pulsar NUEVA PARTIDA.

## 8. Fondos por nivel

Extender `FondoEspacial` para recibir la ruta del fondo. En preparación, partida, celebración y resultados se utiliza el fondo del nivel activo. El fondo pertenece a la pantalla y permanece fijo. Preparación y partida también mantienen fijo su contenido.

El paisaje se encuadra con `BoxFit.cover` y alineación superior. En preparación y partida, `NumeroFondoNivel` muestra la franja original que contiene el número, justo encima de la nave, y la mantiene fija junto a ella; el paisaje fijo omite esa franja para evitar duplicados. Se respetan las barras del sistema y se conserva la imagen original sin editarla. Revisar el encuadre en vertical, horizontal y con texto ampliado. Añadir una atenuación si hace falta para legibilidad de mensajes, dados y botones. Cuando se usa imagen, sustituir la escena dibujada de estrellas, planeta y suelo; evitar superponer dos escenarios completos.

El menú principal y el selector conservarán inicialmente el fondo espacial neutro actual, pues todavía no hay nivel activo. En la celebración se mantiene el fondo del nivel, sin duplicarlo en la capa de efectos. Los ejemplos y tableros de prueba sin metadatos podrán usar el fondo actual.

### 8.1. Nave y personaje de cada nivel

Se revisaron visualmente los cuatro archivos de `assets/images/characters/`. Cada imagen contiene juntos la nave y su personaje; los cuatro PNG tienen canal alfa y fondo transparente.

| Nivel | Archivo de nave y personaje | Tamaño |
|---|---|---|
| 1 | `assets/images/characters/Maul N1.png` | 1448 × 1086 |
| 2 | `assets/images/characters/Obi N2.png` | 1448 × 1086 |
| 3 | `assets/images/characters/Anakin N3.png` | 1448 × 1086 |
| 4 | `assets/images/characters/Luke N4.png` | 1386 × 1135 |

La carpeta `characters/` ya está registrada en `pubspec.yaml`. Mantener las rutas exactas y asociarlas explícitamente al nivel; no deducir la asignación por el orden de los archivos.

- Preparación y partida muestran la nave del nivel elegido. También se usa la misma imagen en las copias de la celebración, tanto normal como con movimiento reducido. «EMPEZAR DE NUEVO» conserva la nave junto con nivel, fondo y nombre.
- Reutilizar un componente de nave con imagen configurable y metadatos de presentación. Mantener la nave dibujada como alternativa para el menú neutro y los ejemplos sin nivel. El selector sigue mostrando las miniaturas aportadas.
- Mostrar la imagen con `BoxFit.contain`, sin estirarla ni recortar alas, cúpula o punta. El diseño actual asume una proporción 1,65; las imágenes nuevas tienen proporciones aproximadas 1,33 y 1,22. Ajustar los contenedores de preparación, partida y celebración para el encuadre real, sin encoger el tablero ni desplazar controles fuera de alcance.
- Conservar entrada, disparo de números, temblor, vuelo al centro, escala y salida mediante transformaciones de la imagen completa. El personaje no se anima de manera independiente: estos recursos son ilustraciones únicas, no capas separadas ni secuencias de cuadros.
- Dibujar haz, carga, destellos y estela en capas propias. Calcular el origen del disparo y del rayo desde el encuadre visible de la nave; si se necesitan ajustes por imagen, usar un punto de emisión normalizado en sus metadatos de presentación. Esas medidas pertenecen al widget, no al BLoC.
- Sustituir también las llamadas fijas a `NaveMarciano` dentro de `CelebracionVictoria`; ocultar la nave original y mostrar una copia con el mismo recurso y encuadre evita un cambio de personaje al ganar. Retirar la suposición fija 1,65 de las medidas de respaldo.
- El globo de mensajes sigue siendo un widget independiente y mantiene textos, semántica y reglas existentes. La etiqueta accesible de la nave describe el personaje del nivel, en vez de anunciar siempre al marciano anterior.
- Revisar los bordes sobre los cuatro fondos reales: en la inspección se observaron pequeños restos claros y de color alrededor de algunos contornos. No se han retocado los archivos; comprobar su apariencia al tamaño de juego antes de decidir si necesitan limpieza.

## 9. Orden de implementación y comprobaciones

1. Transcribir y validar la tabla completa de agrupaciones de `reglas_mapas.md`, incluidas las regiones separadas que pertenecen a una misma zona. Los cuatro fondos y las cuatro miniaturas ya están disponibles. No es necesario volver a solicitar al usuario los datos ya especificados en la tabla.
2. Implementar reglas blanca/naranja y puntuaciones por zona; migrar marcador, fichas y copias. Comprobar que el Nivel 1 conserva sus reglas y puntos.
3. Incorporar los tres mapas y los metadatos de los cuatro niveles, validar matrices, zonas, posiciones y preparación posible.
4. Implementar BLoC, selector con miniaturas, elección aleatoria y flujo anterior al nombre.
5. Integrar fondos y naves por nivel, incluidos sus encuadres y efectos en preparación, partida y celebración; conservar el fondo en resultados y registrar recursos.
6. Ampliar pruebas funcionales y capturas visuales, ejecutar análisis y suite, y revisar composición en dispositivos.
7. Actualizar README y planes anteriores para describir el comportamiento vigente y registrar resultados reales de verificación.

## 10. Pruebas necesarias

### Dominio, mapas y puntuación

- Blanco acepta números iguales y rechaza el primer valor diferente, aunque las celdas estén separadas.
- Naranja acepta extremos y repeticiones de su grupo, rechaza el grupo contrario y valores fuera de 1–6.
- Comparar las 49 posiciones de cada mapa contra matrices esperadas independientes, no contra datos generados por el propio catálogo. Verificar seis iniciales exactas, controles de colores, IDs únicos y pertenencia exacta a las agrupaciones documentadas.
- Dos fábricas o dos niveles no comparten estado mutable.
- La zona blanca solo puntúa cuando está completa, no por cada celda aislada. Cada franja naranja tiene reclamo propio.
- Verificar las tablas de todos los niveles y los tres puestos; cuarto y quinto puesto dan cero. Comparar puntos mostrados con los otorgados.
- Verificar puntos después de cada copia y del traspaso de preparación a partida; cambiar de nivel no altera los puntos del anterior.
- Preparación manual válida en cada nivel; acomodo aleatorio completo y parcial; intercambio inválido no modifica el tablero. Incluir Nivel 4 con restricciones en las dos iniciales naranjas y un estado parcial sin solución, que debe mostrar error recuperable.
- Destinos con ancla respetan simultáneamente adyacencia, vaciedad y restricciones blanca/naranja.
- Completar una zona, editar la ronda y volver a colocar revierte y reasigna la puntuación correcta. La victoria bloquea cambios y usa la meta vigente.

### Menú, integración y presentación

- NUEVA PARTIDA muestra primero los cuatro niveles con sus miniaturas, antes del nombre.
- Cada tarjeta conduce al mapa, fondo y nave con personaje correspondientes. El sorteo usa los cuatro candidatos, y una fuente de azar fija permite verificar los cuatro resultados sin pruebas estadísticas inestables.
- Cancelar nombre, volver, tocar repetidamente y reconstruir no duplican rutas, diálogos ni sorteos.
- Recorrer por controles reales selector → nombre → seis colocaciones → INICIO → tirada → colocación válida en cada nivel. Dados controlados y destinos esperados concretos; no seleccionar destinos copiando la respuesta del BLoC.
- Un recorrido completo hasta resultados por nivel verifica puntuación, nombre, fondo y reinicio vacío del mismo nivel. Los casos blanca/naranja deberán aparecer además en recorridos específicos aunque el camino ganador no los necesite.
- Movimiento reducido, fallo del recurso de meteoritos, omisión de celebración y regreso del sistema conservan el nivel seleccionado.
- Comprobar en 320×568, 390×844, 430×932 y horizontal 844×390, con texto normal y ampliado a 1,5×. Conservar casillas de al menos 32 puntos en los tamaños comprobados y controles visibles sin desplazamiento en preparación y partida. En horizontal, distribuir controles y tablero en dos columnas.
- Verificar que cada nivel carga la ruta de nave correcta en preparación y partida, que su copia durante la victoria usa el mismo recurso y que reiniciar conserva la asociación. Comprobar entrada, origen de disparo, encuadre y movimiento reducido.
- Capturas del selector y preparación de los cuatro niveles, naves y personajes, zonas blanca/naranja, puntos y resultados con el fondo elegido. Revisar visualmente contraste, recortes y correspondencia de recursos antes de actualizar referencias.
- Medir fluidez y memoria en teléfono con fondos reales, miniaturas, meteoritos y celebración; una prueba con imágenes simuladas no sustituye esta comprobación.

## 11. Criterios de aceptación y estado inicial

La etapa se cierra cuando los cuatro niveles se pueden elegir manualmente o al azar antes del nombre; cada uno reproduce exactamente su especificación y usa sus recursos; las reglas y puntuaciones nuevas funcionan en todo el flujo; Nivel 1 conserva su comportamiento; y reiniciar mantiene nivel y nombre sin compartir la partida anterior.

También deben coincidir las agrupaciones con la tabla de la fuente, estar verificados los doce recursos visuales (cuatro fondos, cuatro miniaturas y cuatro naves con personaje), revisadas las capturas y aprobados el análisis y las pruebas. La revisión en dispositivos debe quedar registrada con sus resultados y limitaciones reales.

Estado previo comprobado el 22 de octubre: 230 pruebas aprobadas y siete comparaciones visuales fallidas (cinco de preparación y dos de partida); análisis con una advertencia por `flutter_lints` ausente. Resolver esa dependencia y revisar las referencias anteriores como parte de la verificación, sin aprobarlas mediante una regeneración indiscriminada.

`docs/` continúa ignorado de forma general para no incorporar recursos de referencia pesados. Se versionan expresamente este plan, `reglas_mapas.md` y el plan de interfaz corregido junto con los cambios de implementación, mediante commits locales; los demás archivos ignorados permanecen fuera.

## 12. Pendientes identificados al redactar

1. Revisar visualmente el ajuste de las imágenes verticales en las pantallas reales; la alineación centrada es una propuesta técnica ajustable.
2. Comprobar el encuadre de las cuatro naves, el origen de sus efectos y la apariencia de sus bordes transparentes sobre los fondos de juego.

La fuente ya incluye matrices, posiciones iniciales, tablas de puntos y agrupaciones para todos los colores. Su revisión comprobó 49 celdas por mapa, recuentos de colores consistentes y seis posiciones iniciales con el color correcto en cada nivel. No se detectaron contradicciones internas en esos datos. La comprobación se hizo sobre el documento; no sustituye las pruebas de los mapas cuando se implementen.


## 13. Resultado de implementación (22 de octubre de 2026)

- Se incorporaron los niveles 2–4 con las agrupaciones documentadas y se mantuvieron el mapa y las puntuaciones del Nivel 1.
- Blanco y naranja se validan desde el motor. La puntuación efectiva vive en la zona y se conserva en preparación, copias de partida, reclamos y fichas visuales.
- El selector permite escoger los cuatro niveles o elegir uno al azar antes del nombre. Soporta cancelación, repetición de toques, errores de nombre y lectura accesible de las tarjetas.
- Los cuatro fondos, las cuatro miniaturas y las cuatro naves con personaje se integraron sin modificar los originales. La nave del nivel se conserva durante la celebración normal y con movimiento reducido; reiniciar conserva nivel y nombre.
- La disposición del selector se ajusta a texto ampliado y a pantallas pequeñas. Se mejoró el contraste de los controles de preparación sobre los fondos.
- Se añadieron recorridos independientes por controles de interfaz hasta la victoria para cada nivel, comprobando puntuación acumulada, celebración y reinicio vacío.
- Se revisaron las referencias visuales existentes y diez capturas nuevas de selector, preparación y partida. La carga de imágenes de prueba se espera explícitamente antes de capturar.
- Android compila en modo de depuración. La instalación en el emulador disponible falló por falta de espacio; no se da por comprobado el comportamiento de esta compilación en ese emulador ni la fluidez en teléfono físico. iOS no se compiló en esta revisión.
- Los originales `Nivel 4.png` y `Mini 4.png` muestran «VI» en su ilustración, aunque corresponden al Nivel 4 por nombre de archivo y por asignación del catálogo. Se conservan como fueron aportados.

Verificación final: `flutter test --no-pub` aprobó las 264 pruebas; `flutter analyze --no-pub` terminó sin problemas y `flutter build apk --debug --no-pub` generó el APK correctamente. Los siete fallos visuales y la advertencia de análisis registrados al inicio quedaron resueltos. No se probó rendimiento en teléfonos físicos ni se compiló iOS.

Ajuste de encuadre posterior: el número romano de cada recurso acompaña a la nave en los cuatro niveles, manteniendo la pantalla fija. Se añadieron seis comprobaciones de posición con barras del sistema y una captura adicional del Nivel 3 que reproduce el caso reportado.

Verificación del ajuste del fondo: **271 pruebas aprobadas** y análisis sin problemas.

Ajuste posterior de pantalla fija: preparación y partida usan `DisenoJuegoFijo`, sin contenedores de desplazamiento. En vertical reservan el espacio del pie y adaptan el tablero al alto restante; en pantallas pequeñas compactan los controles y en horizontal los sitúan a un lado del tablero. Se mantienen el fondo, el número encima de la nave y los efectos de colocación y victoria. Las pruebas verifican que arrastrar no mueve la nave ni el tablero, además de la visibilidad de controles, barras del sistema y texto ampliado.

Verificación de pantalla fija: **271 pruebas aprobadas**, referencias visuales actualizadas y análisis sin problemas.
