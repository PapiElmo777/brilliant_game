# Plan de implementación de la interfaz de Brilliant Game

## 1. Objetivo

Implementar la primera interfaz jugable de **Brilliant Game** en Flutter, con una temática visual de ovnis y un flujo controlado mediante BLoC.

Esta etapa comprende:

- Menú principal con la opción `NUEVA PARTIDA`.
- Transición desde el menú hacia la preparación del tablero.
- Animación de llegada de la nave espacial.
- Aparición de los números del 1 al 6 desde la nave.
- Selección y colocación animada de esos números en seis celdas iniciales.
- Validación de las colocaciones mediante las reglas existentes del motor.
- Aparición del botón `INICIO` solamente cuando la preparación sea válida.
- Preparación de la arquitectura para incorporar posteriormente varios tableros de 7×7.

La implementación de turnos, puntuación y desarrollo completo de la partida queda fuera de esta etapa.

## 2. Estado actual del proyecto

El repositorio contiene el motor del juego, pero todavía no contiene una aplicación gráfica completa.

Ya existen:

- `Tablero`, `Zona` y `Celda`.
- Los tipos de zona azul, amarillo, rojo, verde y morado.
- Las reglas de colocación propias de cada tipo.
- `PreparacionInicial`, que exige colocar exactamente una vez los números 1, 2, 3, 4, 5 y 6.
- `InicioBloc`, con estados de preparación, listo e iniciado.
- Eventos para colocar, retirar y confirmar el inicio.

La interfaz debe consumir esta lógica y no volver a implementar las reglas dentro de los widgets.

## 3. Principios de arquitectura

### 3.1 BLoC como fuente de verdad

Todas las decisiones funcionales de la interfaz deben provenir de BLoC:

- Pantalla o fase activa.
- Tablero seleccionado.
- Número seleccionado.
- Celdas ocupadas.
- Números faltantes.
- Validación de una colocación.
- Disparo pendiente.
- Bloqueo de interacción.
- Errores de usuario.
- Disponibilidad del botón `INICIO`.
- Confirmación de que comenzó la partida.

Los widgets sólo deben representar el estado y enviar eventos.

### 3.2 Responsabilidad de las animaciones

Los `AnimationController` permanecerán en la capa de presentación. BLoC controlará el inicio y la terminación lógica de las animaciones, pero no emitirá un estado por cada cuadro.

Ejemplo:

1. BLoC valida un destino y publica un disparo pendiente.
2. El widget reproduce la animación.
3. Cuando la animación termina, el widget envía un evento a BLoC.
4. BLoC confirma la colocación y publica el nuevo tablero.

### 3.3 Reutilización del motor

Las reglas de color, rango, duplicados y celdas iniciales continuarán en el motor actual. La interfaz no debe decidir por sí misma si un valor es válido.

### 3.4 Compatibilidad con varios tableros

`Tablero` debe conservarse como un modelo genérico. No se debe modificar su contrato para obligar a todos sus usos a contener 49 celdas, porque actualmente admite otras configuraciones y huecos.

La restricción 7×7 pertenecerá a una nueva capa de definición o catálogo de tableros jugables.

## 4. Dirección visual

Las imágenes proporcionadas son referencias visuales, no pantallas que deban usarse como una sola imagen interactiva.

La interfaz debe conservar:

- Escenario lunar nocturno.
- Cielo azul oscuro con estrellas y planetas.
- Nave espacial con el marciano como personaje principal.
- Iluminación cian y efectos de resplandor.
- Botones con apariencia de panel tecnológico.
- Celdas biseladas y de colores intensos.
- Composición vertical, inicialmente orientada a teléfonos.

La nave, el fondo, el logotipo, los números, el tablero, las partículas y los botones deben ser elementos independientes para permitir animación y adaptación a distintas pantallas.

Los círculos negros dibujados en la imagen del tablero son solamente anotaciones para identificar las celdas iniciales. **No deben aparecer en el producto final.** Las celdas iniciales se identificarán visualmente con un contorno o resplandor cian.

## 5. Flujo de usuario

### 5.1 Menú principal

Al abrir la aplicación se mostrará:

- Fondo espacial/lunar.
- Nave con el marciano.
- Logotipo `BRILLIANT by Alfredo`.
- Botón principal `NUEVA PARTIDA`.

En esta etapa no deben aparecer opciones adicionales. La opción `SALIR` queda fuera del alcance inicial.

### 5.2 Nueva partida

Al pulsar `NUEVA PARTIDA`:

1. Se crea una instancia nueva del primer tablero.
2. Se crea un estado de preparación nuevo, sin reutilizar valores de una partida anterior.
3. Se realiza la transición a la pantalla del tablero.
4. La nave entra desde la parte superior.
5. La nave desacelera y se acomoda con un pequeño rebote.
6. Se activa el haz de luz.
7. Los números del 1 al 6 aparecen desde la nave de forma escalonada.
8. Se muestra el mensaje: `Acomoda los números en las celdas iniciales`.
9. Se habilita la interacción.

### 5.3 Selección y colocación

1. El usuario toca uno de los números disponibles.
2. El número seleccionado queda resaltado.
3. El usuario toca una celda inicial.
4. BLoC comprueba la operación con el motor existente.
5. Si la operación es válida, comienza el disparo.
6. El número viaja visualmente desde la nave hasta el centro de la celda.
7. Al finalizar el disparo, el número queda colocado.
8. El número desaparece de la bandeja de disponibles.

Durante el disparo se bloquearán nuevas selecciones, toques en el tablero y el botón `INICIO`.

### 5.4 Intentos inválidos

Si la colocación no es válida:

- No se reproduce el disparo.
- No cambia el contenido del tablero.
- El número permanece disponible.
- La celda puede realizar una animación breve de vibración o destello rojo.
- Se muestra un mensaje breve y comprensible.
- La interfaz permanece operativa para intentar otra colocación.

### 5.5 Corrección de posiciones

El usuario podrá tocar una celda inicial ocupada para retirar su valor y devolverlo a la bandeja. Esto evita estados en los que una elección temprana impida completar una distribución válida.

La operación utilizará el evento de retiro ya existente y nunca modificará celdas que no sean iniciales.

### 5.6 Inicio de la partida

El botón `INICIO`:

- Permanecerá oculto mientras falte algún número.
- Aparecerá cuando los seis números estén colocados y el estado sea válido.
- Puede entrar con una animación corta de escala y opacidad.
- Enviará `InicioSolicitado` al BLoC.
- Sólo provocará la transición cuando el estado pase a iniciado.

Después de iniciar, las posiciones iniciales quedarán bloqueadas.

## 6. Primer tablero 7×7

### 6.1 Convención de coordenadas

En este documento las coordenadas son de base 1 para facilitar su lectura: filas `F1` a `F7` y columnas `C1` a `C7`.

En el código se utilizarán coordenadas de base 0: filas y columnas de `0` a `6`.

### 6.2 Matriz de colores

Abreviaturas:

- `Am`: amarillo.
- `Ve`: verde.
- `Az`: azul.
- `Mo`: morado.
- `Ro`: rojo.
- `*`: celda inicial.

| Fila | C1 | C2 | C3 | C4 | C5 | C6 | C7 |
|---|---|---|---|---|---|---|---|
| F1 | Am | Ve* | Az | Mo | Mo | Mo | Am |
| F2 | Ve | Ve | Az | Az | Mo | Mo* | Ve |
| F3 | Ve | Ro | Ro | Az | Mo | Ve | Ve |
| F4 | Ve | Ro* | Mo | Am | Ve* | Ve | Ve |
| F5 | Ve | Ro | Mo | Mo | Ro | Ro | Az |
| F6 | Ro | Ro | Mo* | Ro | Ro | Az | Az |
| F7 | Am | Mo | Mo | Ro | Ro* | Az | Am |

### 6.3 Celdas iniciales

Las seis celdas iniciales son:

| Coordenada visual | Coordenada interna | Color |
|---|---|---|
| F1-C2 | fila 0, columna 1 | Verde |
| F2-C6 | fila 1, columna 5 | Morado |
| F4-C2 | fila 3, columna 1 | Rojo |
| F4-C5 | fila 3, columna 4 | Verde |
| F6-C3 | fila 5, columna 2 | Morado |
| F7-C5 | fila 6, columna 4 | Rojo |

### 6.4 Definición de zonas

Para el Nivel 1 se mantienen las agrupaciones explícitas de `tablero_01.dart`: cada región de verde, azul, rojo y morado tiene su zona, y las cinco celdas amarillas separadas forman una sola zona. La conectividad geométrica no determina por sí sola la pertenencia. Los niveles posteriores se definen en `reglas_mapas.md`.

Esta definición produce 9 zonas y cubre exactamente las 49 celdas.

| Zona propuesta | Tipo | Celdas |
|---|---|---|
| `amarillo` | Amarillo | F1-C1, F1-C7, F4-C4, F7-C1, F7-C7 |
| `verde_1` | Verde | F1-C2, F2-C1, F2-C2, F3-C1, F4-C1, F5-C1 |
| `azul_1` | Azul | F1-C3, F2-C3, F2-C4, F3-C4 |
| `morado_1` | Morado | F1-C4, F1-C5, F1-C6, F2-C5, F2-C6, F3-C5 |
| `verde_2` | Verde | F2-C7, F3-C6, F3-C7, F4-C5, F4-C6, F4-C7 |
| `rojo_1` | Rojo | F3-C2, F3-C3, F4-C2, F5-C2, F6-C1, F6-C2 |
| `morado_2` | Morado | F4-C3, F5-C3, F5-C4, F6-C3, F7-C2, F7-C3 |
| `rojo_2` | Rojo | F5-C5, F5-C6, F6-C4, F6-C5, F7-C4, F7-C5 |
| `azul_2` | Azul | F5-C7, F6-C6, F6-C7, F7-C6 |

### 6.5 Validación de una definición 7×7

Cada tablero registrado en el catálogo debe comprobar:

- Exactamente 49 celdas.
- Filas y columnas dentro del intervalo 0–6.
- Cobertura de todas las coordenadas del cuadrado 7×7.
- Ninguna coordenada duplicada.
- Identificadores de celda y zona únicos.
- Cada celda pertenece a una sola zona.
- Exactamente seis celdas iniciales.
- Todas las celdas no iniciales están vacías al comenzar.

## 7. Catálogo de tableros

Se creará una abstracción equivalente a:

```text
CatalogoTableros
 ├── tablero_01
 ├── tablero_02
 └── ...
```

Cada definición debe proporcionar al menos:

- ID estable.
- Nombre visible opcional.
- Lista de zonas.
- Lista de celdas por zona.
- Tipo de cada zona.
- Celdas iniciales.
- Fábrica que produzca una instancia nueva e independiente de `Tablero`.

Nunca debe reutilizarse una instancia mutable de `Zona` o `Tablero` entre partidas.

Para esta etapa, `NUEVA PARTIDA` seleccionará directamente `tablero_01`. La selección de tableros podrá agregarse después sin cambiar la pantalla de preparación.

## 8. Diseño BLoC

### 8.1 BLoC del menú

Responsabilidades:

- Recibir la solicitud de nueva partida.
- Seleccionar la definición de tablero correspondiente.
- Emitir la intención de navegar a la preparación.

Eventos propuestos:

```text
NuevaPartidaSolicitada
```

Estados o fases propuestas:

```text
menuVisible
creandoPartida
partidaPreparada
```

Las acciones de navegación son efectos de presentación. Deben ejecutarse desde un `BlocListener`, no directamente desde el método que reduce los eventos.

### 8.2 BLoC de preparación

Se debe ampliar el `InicioBloc` existente en lugar de duplicar sus validaciones.

Debe conservar compatibilidad con:

- `ValorInicialColocado`.
- `ValorInicialRetirado`.
- `InicioSolicitado`.
- `FaseInicio.preparando`.
- `FaseInicio.listo`.
- `FaseInicio.iniciado`.

Eventos de presentación propuestos:

```text
LlegadaNaveCompletada
PresentacionNumerosCompletada
NumeroInicialSeleccionado(valor)
CeldaInicialSeleccionada(celdaId)
DisparoNumeroCompletado
SeleccionCancelada
```

Datos adicionales propuestos para el estado:

```text
faseVisual
numeroSeleccionado
disparoPendiente
interaccionBloqueada
celdas
numerosFaltantes
error
```

Fases visuales propuestas:

```text
llegandoNave
mostrandoNumeros
preparando
disparando
listo
iniciado
```

`puedeIniciar` debe seguir derivándose del estado de dominio y no de la visibilidad del botón.

### 8.3 Modelo de disparo pendiente

El estado de disparo debe contener al menos:

- Número.
- ID de celda de destino.
- Identificador único de la animación, para no repetirla durante reconstrucciones.

Las posiciones visuales de origen y destino deben calcularse en los widgets mediante coordenadas globales. No deben guardarse píxeles dependientes del dispositivo en el BLoC.

### 8.4 Validación previa al disparo

Antes de emitir el disparo pendiente, el BLoC necesita consultar si la colocación es válida sin modificar el tablero.

Si la API actual de `PreparacionInicial` no expone esta consulta, se agregará un método de sólo lectura que delegue en `Tablero.puedeColocarValor`, comprobando primero:

- Que la celda exista.
- Que sea una celda inicial.
- Que el número esté entre 1 y 6.
- Que el número no esté colocado en otra celda.
- Que la zona acepte el valor.

La mutación definitiva ocurrirá al recibir `DisparoNumeroCompletado`.

## 9. Componentes de interfaz

Componentes sugeridos:

```text
BrilliantGameApp
 ├── MenuInicialPage
 │    ├── FondoEspacial
 │    ├── NaveMarciano
 │    ├── LogotipoBrilliant
 │    └── BotonesMenu
 └── PreparacionPage
      ├── FondoEspacial
      ├── NaveEntrada
      ├── MensajePreparacion
      ├── BandejaNumeros
      ├── TableroView
      │    └── CeldaView
      ├── DisparoNumeroOverlay
      ├── MensajeError
      └── BotonInicio
```

### 9.1 `TableroView`

- Debe construirse desde el modelo, no desde una imagen plana.
- Debe utilizar una cuadrícula cuadrada de siete columnas.
- Cada celda debe obtener su color desde el `Tipo` de su zona.
- Las celdas iniciales deben tener un brillo identificable incluso antes de ser ocupadas.
- Sólo debe enviar IDs de celda a BLoC.
- Debe adaptarse al ancho disponible sin perder la proporción cuadrada.

### 9.2 `BandejaNumeros`

- Mostrará exclusivamente `numerosFaltantes`.
- Mantendrá el orden visual del 1 al 6.
- Resaltará `numeroSeleccionado`.
- Ignorará interacciones cuando el estado esté bloqueado.
- No conservará una lista local independiente del estado BLoC.

### 9.3 `DisparoNumeroOverlay`

- Se dibujará por encima de la nave, la bandeja y el tablero.
- Usará las posiciones globales del origen y de la celda destino.
- Podrá incluir escala, estela cian, brillo y partículas.
- Al terminar enviará exactamente una confirmación al BLoC.
- Debe protegerse contra reconstrucciones que intenten repetir el mismo disparo.

## 10. Recursos visuales necesarios

Preparar como recursos separados:

- Fondo lunar sin controles.
- Nave y marciano con fondo transparente.
- Logotipo con fondo transparente.
- Marcos o texturas de los botones.
- Marco de celda o tratamiento equivalente construido en Flutter.
- Efectos de haz, brillo y partículas.

No se deben incrustar los botones ni el tablero interactivo dentro de una imagen de fondo.

Si se generan nuevos recursos, deben conservar una estética coherente con las referencias y exportarse en resolución suficiente para pantallas de alta densidad.

**Decisión de la fase 6:** en esta etapa los recursos se dibujan con Flutter (`CustomPainter` y widgets) en lugar de imágenes: fondo lunar, nave y marciano, logotipo, botones de panel, celdas y efectos de haz, estela y partículas. Cumplen la separación exigida, son vectoriales y se adaptan a cualquier densidad. Las carpetas de `assets/images/` quedan reservadas para sustituirlos por ilustraciones más adelante, si se decide.

## 11. Plataformas iniciales

La primera entrega se enfocará en Android e iOS. El botón `SALIR` no formará parte de esta etapa y su posible comportamiento se decidirá en una fase posterior.

## 12. Manejo de errores

Los errores funcionales deben provenir de BLoC y mostrarse sin bloquear permanentemente la pantalla.

Casos mínimos:

- Número ya utilizado.
- Número fuera de rango.
- Celda inexistente.
- Celda que no es inicial.
- Restricción de zona incumplida.
- Intento de iniciar con números faltantes.
- Intento de editar después de iniciar.

Un evento válido posterior debe limpiar el error anterior, conservando el comportamiento actual de `InicioBloc`.

## 13. Accesibilidad y adaptación

- Mantener contraste suficiente entre números y fichas.
- No comunicar selección o error únicamente mediante color.
- Agregar etiquetas semánticas a botones, números y celdas.
- Respetar áreas táctiles mínimas.
- Permitir reducir o simplificar animaciones cuando el sistema solicite movimiento reducido.
- Evitar que el tablero quede fuera de pantalla en dispositivos pequeños.
- Priorizar inicialmente el formato vertical mostrado en las referencias.

## 14. Estrategia de pruebas

### 14.1 Pruebas del catálogo

- `tablero_01` contiene exactamente 49 celdas.
- Las 49 coordenadas del 7×7 están presentes una vez.
- Existen exactamente 9 zonas.
- Existen exactamente seis celdas iniciales.
- Las seis celdas iniciales coinciden con las coordenadas documentadas.
- Cada zona tiene el tipo y las celdas especificadas.
- Dos llamadas a la fábrica crean tableros independientes.

### 14.2 Pruebas de BLoC

- Nueva partida crea una preparación limpia.
- La interacción permanece bloqueada durante la entrada de la nave.
- Seleccionar un número actualiza el estado.
- Seleccionar una celda no inicial produce error y no dispara.
- Una combinación prohibida por la zona no dispara.
- Una operación válida crea un disparo pendiente sin colocar prematuramente el valor.
- Confirmar el disparo coloca el valor una sola vez.
- Durante el disparo se ignoran acciones incompatibles.
- Retirar un valor lo devuelve a los faltantes.
- Colocar los seis números cambia a listo.
- `InicioSolicitado` sólo inicia desde listo.
- Después de iniciar no se permiten ediciones.

### 14.3 Pruebas de widgets

- El menú muestra solamente el botón `NUEVA PARTIDA`.
- Nueva partida abre la preparación.
- La bandeja refleja los números faltantes del BLoC.
- El número seleccionado se distingue visual y semánticamente.
- El tablero representa las 49 celdas y los colores correctos.
- Las seis celdas iniciales muestran su indicador.
- El error es visible y no modifica el tablero.
- El botón `INICIO` está oculto antes de completar la preparación.
- El botón aparece cuando `puedeIniciar` es verdadero.
- Una reconstrucción no repite el mismo disparo.

### 14.4 Pruebas visuales

- Captura dorada del menú.
- Captura dorada de la preparación vacía.
- Captura dorada con número seleccionado.
- Captura dorada con los seis números colocados y el botón `INICIO` visible.
- Revisión en al menos un teléfono pequeño y uno grande.

## 15. Orden de implementación

### Fase 1: base de la aplicación

1. Configurar Android e iOS como plataformas objetivo iniciales.
2. Crear el punto de entrada Flutter ejecutable.
3. Agregar la integración de `flutter_bloc` como dependencia de presentación.
4. Crear tema, colores y estructura de navegación.

### Fase 2: datos del primer tablero

1. Crear el catálogo de tableros.
2. Implementar `tablero_01` con sus 9 zonas y 49 celdas.
3. Marcar las seis celdas iniciales.
4. Crear el validador 7×7.
5. Cubrir la configuración con pruebas unitarias.

### Fase 3: flujo BLoC

1. Implementar el BLoC del menú.
2. Ampliar `InicioBloc` para selección, fases visuales y disparo pendiente.
3. Agregar validación previa no mutante.
4. Conservar las pruebas y contratos actuales.
5. Agregar las nuevas pruebas de eventos y estados.

### Fase 4: interfaz estática

1. Construir el menú.
2. Construir la pantalla de preparación.
3. Dibujar el tablero desde el modelo.
4. Implementar la bandeja de números.
5. Implementar mensajes, errores y botón `INICIO`.

### Fase 5: animaciones

1. Entrada y acomodo de la nave.
2. Activación del haz.
3. Aparición escalonada de los números.
4. Disparo desde la nave hasta una celda.
5. Retroalimentación de intento inválido.
6. Aparición del botón `INICIO`.

### Fase 6: verificación

1. Ejecutar análisis estático.
2. Ejecutar las pruebas existentes y nuevas.
3. Realizar pruebas visuales en varios tamaños.
4. Revisar accesibilidad y movimiento reducido.
5. Comparar el resultado con las referencias visuales.

## 16. Criterios de aceptación de esta etapa

La etapa se considerará terminada cuando:

- La aplicación abra en el menú espacial.
- El menú muestre exclusivamente `NUEVA PARTIDA`.
- `NUEVA PARTIDA` cree una partida limpia con `tablero_01`.
- La nave complete su entrada antes de habilitar la colocación.
- Aparezcan exactamente los números faltantes del 1 al 6.
- Las 49 celdas coincidan con la matriz documentada.
- Sólo las seis celdas iniciales permitan la preparación.
- Cada colocación se valide antes de animarse.
- Un disparo válido termine en la celda seleccionada.
- Un intento inválido no altere el estado.
- Sea posible retirar y recolocar valores antes de iniciar.
- `INICIO` permanezca oculto hasta alcanzar un estado válido.
- Pulsar `INICIO` cambie el estado a iniciado y bloquee la preparación.
- La interfaz no duplique las reglas del motor.
- El flujo funcional esté controlado por BLoC.
- Las pruebas existentes continúen aprobando.

## 17. Decisiones asumidas

Para que Codex pueda comenzar sin reinterpretar las imágenes, esta especificación adopta las siguientes decisiones:

1. Las zonas se definen explícitamente en el catálogo. En Nivel 1 las cinco celdas amarillas forman una sola zona aunque estén separadas.
2. Los círculos negros de la referencia no forman parte de la interfaz final.
3. Las seis celdas circuladas son las únicas celdas iniciales.
4. El primer tablero se selecciona directamente al pulsar `NUEVA PARTIDA`.
5. La interfaz inicial está optimizada para orientación vertical.
6. Las animaciones se ejecutan en widgets y se coordinan mediante eventos y estados BLoC.
7. La colocación definitiva ocurre al terminar el disparo, no al comenzarlo.
8. El usuario puede retirar un valor inicial antes de comenzar la partida.
9. Los recursos visuales de esta etapa se dibujan en Flutter en lugar de usar imágenes (ver sección 10).

## 18. Fuera de alcance

No forma parte de esta entrega:

- Sistema completo de turnos.
- Tiradas o generación posterior de números.
- Puntuación durante la partida.
- Fin de partida.
- Guardado o carga de partidas.
- Selector visual de tableros.
- Multijugador.
- Sonido o música, salvo que se agreguen posteriormente como una tarea separada.
- Implementación de todos los tableros futuros.
