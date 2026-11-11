# Audio de Brilliant

Implementación en la rama `audio`. Identidad: primera maqueta galáctica aprobada,
sin voces. Los 35 WAV originales (33 efectos y 2 bucles) suman 6.15 MiB.

## Recursos

`assets/audio/manifest.json`: procedencia, duración y tamaño de cada archivo.
`tool/generate_audio.py`: reconstruye todo con Python estándar, sin descargas.
`assets/audio/README.md`: formato y procedencia. No se utilizaron paquetes externos
de muestras; todos los sonidos proceden de la síntesis original de la maqueta.

## Reproducción

`GameAudio` inicializa flutter_soloud una sola vez, después de abrir la interfaz.
Precarga los recursos, mantiene separadas música, efectos y avisos, guarda sus
volúmenes y el silencio general en SharedPreferences. Un fallo de audio no bloquea
el acceso al juego. La implementación nativa limita la mezcla a 8 voces y protege
la música contra el robo de voces. Los cambios de ambiente cruzan ambos bucles
con fundido; las alertas prioritarias atenúan la música temporalmente.

Al minimizar o perder el foco se detienen los efectos y se pausa la música. Al
regresar no se reproducen avisos acumulados. Las operaciones de reproducción
pendientes se invalidan cuando cambia la pantalla o se detiene un efecto.

Los controles están en el login, el menú, la cabecera de salas y las opciones de
salida de una partida. Música, efectos y avisos se pueden ajustar por separado.

## Eventos

| Recursos | Disparador |
|---|---|
| menu / game | Navegación, preparación y partida |
| startup / launch | Arranque, entrada de misión e inicio de partida |
| click / back / panel | Controles comunes, navegación, paneles y reglas |
| connect / disconnect / ready | Acceso, salas, participantes y preparación |
| round / meteor | Inicio real de cada animación de tirada |
| impact / reveal | Callback de impacto, también al omitir la caída |
| select / preview | Elegir dado/número y tocar una celda |
| shot / place | Salida y llegada del número; colocación local aceptada |
| reject / skip | Error, falta de destinos y omisión aceptada |
| zone_1 / zone_2 / zone_3 | Puesto de una zona propia recién reclamada |
| zone_other / zone_exhausted | Reclamo ajeno y agotamiento de los tres puestos |
| chat / sent | Mensaje nuevo de otro jugador y transmisión propia |
| thirty / tick / tick_final / timeout | Umbral de 30 s, últimos 10 s, últimos 3 s y cierre |
| victory / podium / finish | Victoria, otro puesto del podio y cierre de misión |
| alert | Pérdida de conexión y votación de fin de partida |

`AudioEvents` observa cambios de estado de Bloc, sin sonidos desde los métodos
build. Las secuencias de chat excluyen el historial y las reconexiones. Las zonas
se comparan por jugador, zona y puesto. El reloj guarda el mínimo ya observado
por ronda para evitar repeticiones por correcciones de hora. Solo suena mientras
la jugada siga pendiente y el canal esté conectado. Los resultados no repiten
su fanfarria al actualizarse la sala.

## Comprobación

- `flutter test test/audio`: mezcla, prioridades, preferencias, fallos del motor,
  ciclo de vida, carreras asíncronas, chat, reclamos y cuenta regresiva.
- `flutter test`: reglas, flujos, widgets y capturas de todos los niveles.
- `flutter analyze` y compilación Android arm64.
- Revisar en Android: inicio, panel de sonido, minimizar/regresar, tirada completa
  y omitida, colocación, cierre de ronda y resultados; comparar también con un
  teléfono físico para evaluar latencia y volumen de sus altavoces.
