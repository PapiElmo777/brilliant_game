# Reglas de los mapas: niveles 2, 3 y 4

## Alcance y referencias

Este documento especifica los tres mapas que se incorporarán al juego a partir de las imágenes proporcionadas. Se conservan sus nombres originales: **Nivel 2**, **Nivel 3** y **Nivel 4**. No se renumeran como niveles 1, 2 y 3; el proyecto ya contiene un tablero inicial.

Para la distribución y las puntuaciones se toma como referencia la cuadrícula dibujada a la derecha de cada imagen y su tabla de puntos. Los círculos negros identifican exclusivamente las celdas de preparación inicial: no son colores, zonas adicionales ni números preasignados.

Las posiciones, los colores, las puntuaciones y las celdas iniciales que siguen están transcritos de esas cuadrículas. Las reglas de color ya existentes se recuperan del proyecto. La agrupación de las zonas blancas y amarillas y la independencia de las dos zonas naranjas están confirmadas por el usuario. Las demás agrupaciones inferidas de las fotografías se identifican como propuestas en la sección correspondiente.

## Convenciones comunes

- Cada mapa es un tablero completo de **7 filas × 7 columnas**, con 49 celdas jugables, sin huecos.
- Las filas se numeran de arriba hacia abajo y las columnas de izquierda a derecha, del 1 al 7.
- Una coordenada se escribe como **(fila, columna)**. Por ejemplo, `(1, 5)` es la quinta celda de la primera fila.
- Cada celda pertenece a una única zona. Su color y condición de celda inicial son propiedades independientes.
- Una celda blanca es una celda jugable, no un espacio vacío ni un obstáculo.
- Los mapas definen dónde se juega y cómo se puntúan sus zonas; se conservan las reglas generales de turnos, dados y anclas del juego.

### Leyenda de las matrices

| Símbolo | Color |
|---|---|
| B | Blanco |
| A | Amarillo |
| R | Rojo |
| V | Verde |
| C | Celeste / azul |
| M | Morado |
| N | Naranja / ocre |

### Preparación inicial

1. El jugador acomoda los números **1, 2, 3, 4, 5 y 6**, una vez cada uno, en las seis celdas iniciales del mapa elegido.
2. El jugador decide qué número va en cada posición; los círculos de las imágenes no asignan valores concretos.
3. Durante la preparación solo se pueden ocupar esas seis celdas. Las otras 43 permanecen vacías.
4. La distribución debe respetar las restricciones de las zonas, también durante la preparación.
5. La partida puede comenzar cuando las seis celdas iniciales están ocupadas y la distribución es válida.
6. Al comenzar, esas celdas conservan sus números y forman parte de sus zonas con normalidad.

### Restricciones de los colores existentes

Estas restricciones proceden del modelo actual del juego. Las puntuaciones se sustituyen por las del nivel correspondiente.

| Color | Regla dentro de cada zona |
|---|---|
| Celeste / azul | Todos los números deben ser iguales. |
| Amarillo | Todos los números deben ser distintos. |
| Rojo | Todos los números deben ser distintos. |
| Verde | Se permite cualquier número del 1 al 6, con repeticiones. |
| Morado | Se permiten como máximo dos números distintos, con repeticiones. |
| Blanco | Todos los números deben ser iguales, igual que en celeste / azul. |
| Naranja superior | Solo se permiten los números 4, 5 y 6. |
| Naranja inferior | Solo se permiten los números 1, 2 y 3. |

### Interpretación de las puntuaciones

Los encabezados **1.º, 2.º y 3.º** indican el orden en que los jugadores completan **una misma zona**, siguiendo la regla de puntuación actual del proyecto. No representan el número escrito en una celda ni la cantidad de casillas ocupadas.

Una zona se completa cuando todas sus celdas tienen un número válido. El primer jugador en completarla recibe los puntos de la primera columna; el segundo, los de la segunda; y el tercero, los de la tercera. Según el marcador actual, los puestos posteriores dan 0 puntos y cada jugador puede reclamar una misma zona una sola vez.

Las tablas asignan puntos por color dentro de cada nivel. Si un color tiene varias zonas independientes, cada zona concede sus propios puntos y mantiene su propio orden de finalización. Completar una parte de una zona no concede puntos.

## Nivel 2

### Distribución de colores

```text
Fila\Col.  1  2  3  4  5  6  7
    1      M  M  M  B  V  V  V
    2      M  A  C  C  C  A  V
    3      M  R  R  C  C  R  V
    4      R  R  R  A  R  R  R
    5      V  R  C  C  R  R  M
    6      V  A  C  C  C  A  M
    7      V  V  V  B  M  M  M
```

### Celdas iniciales

| Fila | Columna | Color |
|---|---|---|
| 1 | 5 | Verde |
| 3 | 1 | Morado |
| 4 | 3 | Rojo |
| 5 | 6 | Rojo |
| 6 | 2 | Amarillo |
| 7 | 5 | Morado |

### Puntos por zona

| Color | 1.º | 2.º | 3.º |
|---|---:|---:|---:|
| Blanco | 3 | 2 | 1 |
| Amarillo | 6 | 4 | 2 |
| Rojo | 6 | 4 | 2 |
| Verde | 4 | 3 | 2 |
| Celeste / azul | 7 | 6 | 3 |
| Morado | 6 | 4 | 2 |

Control de transcripción: 2 blancas, 5 amarillas, 12 rojas, 10 verdes, 10 celestes y 10 moradas; total: **49**.

## Nivel 3

### Distribución de colores

```text
Fila\Col.  1  2  3  4  5  6  7
    1      A  A  M  B  M  A  A
    2      B  A  M  M  M  A  B
    3      R  R  R  M  R  R  R
    4      R  R  R  B  R  R  R
    5      V  C  C  C  C  C  V
    6      V  V  V  V  V  V  V
    7      M  M  M  B  M  M  M
```

### Celdas iniciales

| Fila | Columna | Color |
|---|---|---|
| 2 | 3 | Morado |
| 2 | 6 | Amarillo |
| 4 | 4 | Blanco |
| 5 | 2 | Celeste / azul |
| 5 | 7 | Verde |
| 7 | 3 | Morado |

### Puntos por zona

| Color | 1.º | 2.º | 3.º |
|---|---:|---:|---:|
| Blanco | 8 | 6 | 4 |
| Amarillo | 7 | 5 | 3 |
| Rojo | 6 | 4 | 2 |
| Verde | 6 | 5 | 4 |
| Celeste / azul | 7 | 5 | 3 |
| Morado | 7 | 5 | 3 |

Control de transcripción: 5 blancas, 6 amarillas, 12 rojas, 9 verdes, 5 celestes y 12 moradas; total: **49**.

## Nivel 4

### Distribución de colores

El color ocre de la cuadrícula se denomina **naranja** en este documento y corresponde a las franjas superior e inferior de la fotografía.

Las dos franjas son zonas independientes: la superior (fila 1) admite únicamente **4, 5 y 6**; la inferior (fila 7) admite únicamente **1, 2 y 3**. Los extremos de ambos rangos están incluidos. Se permiten repeticiones: la restricción naranja limita el rango, no exige números distintos. Ambas franjas comparten el color naranja y la misma escala de puntuación: **6, 4 y 3 puntos** para el primer, segundo y tercer puesto, respectivamente. Cada franja tiene su propio orden de finalización y concede puntos de forma independiente; completar una no completa ni reclama puntos de la otra. Esta restricción también se aplica a sus celdas iniciales `(1, 5)` y `(7, 2)`.

```text
Fila\Col.  1  2  3  4  5  6  7
    1      N  N  N  N  N  N  N
    2      A  R  C  V  C  R  A
    3      R  R  M  M  M  R  R
    4      A  V  C  M  C  V  A
    5      R  R  M  M  M  R  R
    6      A  R  C  V  C  R  A
    7      N  N  N  N  N  N  N
```

### Celdas iniciales

| Fila | Columna | Color |
|---|---|---|
| 1 | 5 | Naranja |
| 3 | 3 | Morado |
| 3 | 6 | Rojo |
| 4 | 1 | Amarillo |
| 6 | 5 | Celeste / azul |
| 7 | 2 | Naranja |

### Puntos por zona

| Color | 1.º | 2.º | 3.º |
|---|---:|---:|---:|
| Naranja | 6 | 4 | 3 |
| Amarillo | 8 | 6 | 4 |
| Rojo | 6 | 4 | 2 |
| Verde | 3 | 2 | 1 |
| Celeste / azul | 8 | 6 | 4 |
| Morado | 7 | 5 | 3 |

Control de transcripción: 14 naranjas, 6 amarillas, 12 rojas, 4 verdes, 6 celestes y 7 moradas; total: **49**.

## Agrupación de celdas en zonas

El color no basta para identificar una zona. Las cuadrículas no incluyen identificadores de zona y algunas zonas pueden contener celdas separadas, como ya ocurre con el amarillo del tablero existente. Por ello, **no se debe generar una zona por color ni separar automáticamente todas las regiones desconectadas**.

Las filas de blanco, amarillo y naranja de la siguiente tabla están confirmadas. Las demás conservan la agrupación propuesta a partir de las fotografías. Las referencias a filas y columnas usan las matrices anteriores.

| Nivel | Color | Agrupación |
|---|---|---|
| 2 | Blanco | Confirmado: una sola zona con las dos celdas blancas, aunque estén separadas. |
| 2 | Amarillo | Confirmado: una zona con las cinco celdas amarillas, incluido el centro. |
| 2 | Rojo | Dos zonas de seis celdas: mitad izquierda (columnas 1–3) y mitad derecha (columnas 5–7). |
| 2 | Verde | Dos zonas de cinco celdas: superior derecha e inferior izquierda. |
| 2 | Celeste | Dos zonas de cinco celdas: superior (filas 2–3) e inferior (filas 5–6). |
| 2 | Morado | Dos zonas de cinco celdas: superior izquierda e inferior derecha. |
| 3 | Blanco | Confirmado: una sola zona con las cinco celdas blancas, aunque estén separadas. |
| 3 | Amarillo | Confirmado: una zona con las seis celdas amarillas de ambos lados. |
| 3 | Rojo | Dos zonas de seis celdas: izquierda (columnas 1–3) y derecha (columnas 5–7). |
| 3 | Verde | Una zona con las nueve celdas verdes. |
| 3 | Celeste | Una zona con las cinco celdas celestes de la fila 5. |
| 3 | Morado | Dos zonas de seis celdas: superior (filas 1–3) e inferior (fila 7, a ambos lados del blanco). |
| 4 | Naranja | Confirmado: dos zonas de siete celdas; fila 1 con valores 4–6 y fila 7 con valores 1–3. |
| 4 | Amarillo | Confirmado: una zona con las seis celdas amarillas de los bordes. |
| 4 | Rojo | Dos zonas de seis celdas: izquierda (columnas 1–2) y derecha (columnas 6–7). |
| 4 | Verde | Una zona con las cuatro celdas verdes. |
| 4 | Celeste | Una zona con las seis celdas celestes. |
| 4 | Morado | Una zona con las siete celdas moradas del centro. |

## Decisiones confirmadas

1. **Zonas naranjas del Nivel 4:** la primera abarca de (1,1) a (1,7) y admite solo 4, 5 y 6; la segunda abarca de (7,1) a (7,7) y admite solo 1, 2 y 3. Se permiten repeticiones. Son dos zonas independientes y ambas conceden 6, 4 y 3 puntos para el primer, segundo y tercer puesto, respectivamente. Cada una se completa y puntúa por separado, con su propio orden de finalización. El límite inferior 4 de la franja superior se conserva de la especificación previa y de la imagen de reglas; en el último mensaje ese número quedó omitido.
2. **Zona blanca:** todas las celdas blancas de un mismo mapa forman una única zona, aunque no estén conectadas. Todos sus números deben ser iguales. Solo se completa y puntúa cuando están ocupadas todas sus celdas; las celdas blancas no puntúan por separado.

3. **Zona amarilla:** todas las celdas amarillas de un mismo mapa forman una sola zona, aunque estén separadas. Sus números deben ser distintos; agruparlas como el blanco no significa compartir su regla de números iguales.

## Criterios de aceptación de la implementación

- Cada mapa reproduce exactamente su matriz de 49 colores y las seis coordenadas iniciales documentadas.
- La preparación permite distribuir los seis números sin fijar una solución de antemano y rechaza una distribución incompleta o inválida.
- Las puntuaciones se configuran por nivel y zona; un mismo color puede otorgar puntos diferentes en otro mapa.
- Cada zona tiene un identificador propio, incluso cuando comparte color con otra, y sus reclamos de puntos son independientes.
- El modelo admite celdas separadas dentro de una misma zona cuando así se confirme.
- Las zonas blancas exigen números iguales; la naranja superior acepta 4–6 y la inferior 1–3, con repeticiones. Sus puntuaciones son las de este documento, incluso cuando comparten una restricción con otro color.
- Los datos de los nuevos mapas no alteran la distribución ni las puntuaciones del tablero ya implementado.

La implementación de los mapas está en `lib/catalogo/tablero_02.dart`, `tablero_03.dart` y `tablero_04.dart`. El catálogo incorpora los tres junto al Nivel 1 existente. Este documento conserva la especificación de referencia; el avance y la verificación se registran en `PLAN_IMPLEMENTACION_NIVELES.md`.
