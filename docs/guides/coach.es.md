# Guía del entrenador y del entrenador asistente

Idiomas: Español · [English](coach.en.md) · [Bahasa Indonesia](coach.id.md)

Eres **Entrenador** o **Entrenador asistente**. Tus permisos se aplican a los equipos en cuyo **Cuerpo técnico** te ha
incluido un administrador. Barra inferior: **Equipos**, **Partidos**, **Entrenos**, **Jugadores**. **Perfil** está en la
barra superior.

## Qué puede y qué no puede hacer un asistente
| Tarea | Entrenador | Asistente |
|---|---|---|
| Crear partidos, convocatoria, empezar/finalizar, reloj, anotar cualquier estadística | sí | sí |
| Calendario de entrenos, asistencia, planes, asignaciones, ausencias | sí | sí |
| Lesiones, altura/peso, resultados de pruebas físicas | sí | sí |
| Asignar jugadores a un equipo, resolver casos de elegibilidad (equipos propios) | sí | no (solo lectura) |
| Solicitar un jugador nuevo o una baja (requiere aprobación del administrador) | sí | no |

Las pantallas no permitidas muestran "Solo lectura: no tienes permiso para modificar esto."

## 1. Preparar un partido
Pestaña **Partidos**: lista con filtro de equipo y estados (Programado, En juego, Finalizado, Cancelado).
1. **Nuevo partido**: equipo, rival, fecha. El formato por defecto es 4 periodos de 10 minutos.
2. Abre el partido y elige **Preparar convocatoria**: marca a los jugadores, indica **Titular** y el **Dorsal**. Hace
   falta al menos un titular. La convocatoria necesita conexión; una vez guardada, queda en caché en el dispositivo.
3. **Empezar partido**.

## 2. Anotar en directo
La vista en vivo tiene una cabecera (marcador, periodo, reloj) y tres pestañas: **Pista**, **Jugadas**, **Estadísticas**.
- **Iniciar P1** / **Terminar P1** controlan los periodos. **Poner en marcha el reloj**, **Parar el reloj** y
  **Restar/Sumar 10 segundos** manejan un reloj local (comodidad, no se guarda como jugada).
- **Pista** muestra los cinco en pista y el banquillo. Toca a un jugador para abrir las acciones: 2 PT / 3 PT / TL
  anotado o fallado, Asistencia, Rebote ofensivo, Rebote defensivo, Robo, Tapón, Pérdida, Falta personal / técnica /
  antideportiva.
- Toca a un jugador del banquillo para sustituir: "Entra X por…" y elige quién sale.
- Botones de cabecera: **Rival +1 / +2 / +3**, **Tiempo muerto**, **Tiempo muerto rival**, **Deshacer**.
- **Jugadas** lista cada anotación con su estado de sincronización y quién la registró. **Anular** cancela una jugada
  (se registra una anulación; no se borra nada). **Deshacer** anula tu última jugada vigente.
- **Estadísticas**: parciales, tabla por jugador, total del equipo y **Copiar resultado**. El aviso "N avisos de
  coherencia (corrige con Anular)" indica que las jugadas se contradicen (p. ej. una sustitución de alguien que no estaba
  en pista).
- **Finalizar partido** lo cierra. Después todavía se puede corregir.
Varias personas (dos entrenadores, familias) pueden anotar a la vez; sus jugadas se ordenan por tiempo de juego.

## 3. Sin conexión y el aviso "N sin sincronizar"
Cada jugada se guarda primero en el dispositivo y se envía en segundo plano. Puedes seguir anotando sin red mientras la
pestaña de la aplicación siga abierta.
- Cada jugada muestra **Pendiente**, **Enviando**, **Sincronizada** o **Rechazada: motivo**.
- El aviso **"N sin sincronizar"** (con **Reintentar**) muestra las jugadas aún no confirmadas. Desaparece solo al volver la
  conexión, al reabrir la aplicación o al iniciar sesión de nuevo. Los reintentos esperan de 1 a 60 segundos.
- **Inicia sesión de nuevo para sincronizar; los datos se conservan**: tu sesión ha caducado. Inicia sesión y la cola se
  enviará.
- Las jugadas **Rechazadas** (p. ej. "sin permiso", "partido cancelado") nunca se aceptarán: **Descártalas**.
- Reenviar un lote es seguro: los duplicados se reconocen y nada se cuenta dos veces.
- Límites conocidos: reabrir la aplicación sin ninguna red depende de un service worker que aún no se ha comprobado en un
  navegador real; no abras el mismo partido en dos pestañas del mismo dispositivo.

## 4. Entrenamientos
Pestaña **Entrenos**: calendario semanal con anterior/siguiente/hoy y filtro de equipo. Menú: **Planes**, **Horarios**,
**Ausencias**, **Asignaciones**.
- **Horarios > Nuevo horario**: día, hora, duración, lugar, validez. Las sesiones se crean solas con antelación; una sesión
  puntual se añade con **Nueva sesión**.
- Abre una sesión para ver el detalle; **Cancelar sesión** pide un motivo. **Asistencia**: marca a cada jugador
  **Presente**, **Tarde** (minutos 1-180), **Ausente** o **Justificada** y pulsa **Guardar asistencia**. Quien tiene una
  ausencia prevista aparece con una etiqueta y preseleccionado como Justificada; los lesionados muestran **Lesionado**.
- **Planes**: pestañas **Mis planes** y **Plantillas**. Una plantilla es de solo lectura; **Usar plantilla** la copia. En
  el editor añade ejercicios (título, minutos, series, repeticiones, enlace de vídeo https) y reordénalos con Subir/Bajar.
- **Asignar**: a un equipo o a un jugador, con fecha límite. **Asignaciones** muestra los totales Hecho / Parcial / No
  hecho; abre una para ver a cada jugador y marcar tú mismo el cumplimiento si hace falta.
- **Ausencias**: registra una ausencia prevista de cualquier jugador (desde, hasta, motivo).

## 5. Salud y forma física
**Jugadores** > un jugador > icono de salud:
- **Lesiones**: **Registrar lesión** (zona, gravedad Leve/Moderada/Grave, fecha, regreso previsto). **Marcar recuperada**
  al volver. Los lesionados se muestran como no disponibles.
- **Crecimiento**: **Añadir medida** (altura cm, peso kg; una por día); gráfico o tabla.
- **Pruebas físicas**: **Registrar resultado**; la aplicación responde con la **banda esperada** para la edad y el género.
  "Sin norma para esta edad y género" significa que no hay norma aplicable; **Referencia pendiente** indica que la norma es
  provisional.

## 6. Solicitar jugadores (solo entrenador)
**Jugadores** > **Solicitar nuevo jugador**: nombre, apellidos, fecha de nacimiento, género, correo opcional, equipo
inicial (uno que entrenes) y una nota para el administrador. **Mis solicitudes** las lista; cancela una pendiente con
**Cancelar solicitud**. Para dar de baja a un jugador de tu equipo usa **Dar de baja** en su ficha: se envía como
solicitud. Hasta su aprobación, el jugador solo lo ven los administradores y tú. No puedes aprobar tu propia solicitud.

---
Estado: redactada a partir de las pantallas implementadas y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
