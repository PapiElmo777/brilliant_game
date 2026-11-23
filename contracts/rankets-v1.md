# Rankets — contrato v1

`GET /api/v1/rankets?offset=0&limit=25` requiere la sesión Bearer activa del servidor configurado. `offset` debe ser entero >= 0; `limit`, entre 1 y 50. Valores inválidos: 400 `VALIDATION_ERROR`. Sesión ausente o inválida: 401.

## Clasificación

Participan las cuentas existentes con al menos un registro en `match_players`, incluso con cero victorias. Una cuenta recién registrada o que solo juega en modo individual no tiene posición (`me: null`). Una partida iniciada crea los participantes; no es necesario ganar para aparecer.

Cada partida multijugador con estado `FINISHED` suma una victoria únicamente a `result_json.winnerMemberId`, enlazado a la identidad de cuenta del miembro. Se incluyen los motivos oficiales TARGET, END_VOTE y ABANDONMENT. Sin ganador no hay victoria. Los resultados inmutables del historial son la fuente de datos: consultar, reconectar o repetir comandos no añade victorias. Cada revancha tiene otro ID y cuenta de forma independiente.

Orden principal: victorias totales descendentes. Empates comparten puesto con RANK (1, 1, 3); nombre sin distinguir mayúsculas e ID estabilizan la presentación y la paginación, sin desempatar el puesto. Todos los niveles valen igual. `winsByLevel` es informativo: no filtra ni modifica la clasificación.

Nombre y avatar son los actuales de la cuenta. Una cuenta eliminada deja de aparecer; sus victorias no se transfieren a otra cuenta que use el mismo nombre. Los resultados originales se conservan. No se modifica ninguna migración ni se crean contadores que puedan divergir del historial.

## Respuesta

Objeto con `entries`, `total`, `offset`, `limit`, `me`. `me` devuelve la posición del usuario autenticado aunque no esté en la página solicitada. La respuesta se obtiene dentro de una transacción para conservar una vista consistente.

Cada jugador contiene `userId`, `username`, `avatarId` (nullable), `position`, `played`, `wins` y `winsByLevel`: `tablero_01`, `tablero_02`, `tablero_03`, `tablero_04`, incluidos los ceros. `played` cuenta participaciones iniciadas. No se exponen sesiones, contraseñas ni tableros privados.

## Cliente

Trofeo «Rankets» en el menú. Clasificación paginada, fila propia destacada y tarjeta con posición propia; desglose visible de los cuatro niveles. Actualización manual y al volver a abrir la pantalla. Estados de carga, lista vacía, error con reintento, servidor antiguo y sesión inválida. Las respuestas obsoletas se descartan al iniciar otra consulta.

Verificación reproducible: `flutter analyze`, `flutter test test/rankets`, `./mvnw test`. Las pruebas nuevas de Java incluyen datos históricos, resultados idempotentes, empates, borrado/renombrado, niveles, paginación y la ruta HTTP autenticada con MockMvc sin abrir un puerto.
