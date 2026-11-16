# Guía del entrenador y del entrenador asistente

Idiomas: Español · [English](coach.en.md) · [Bahasa Indonesia](coach.id.md)

Inicias sesión con tu dirección de correo electrónico y tu contraseña.

Eres **Entrenador** o **Entrenador asistente**. Tus permisos se aplican a los equipos en cuyo **Cuerpo técnico** te ha
incluido un administrador. Barra inferior: **Equipos**, **Partidos**, **Entrenos**, **Jugadores**.
El botón redondo con tus iniciales (arriba a la derecha) abre un menú: **Perfil** (tu nombre, cerrar sesión),
**Idioma** y **Tema** (**Sistema**, **Claro**, **Oscuro**; se recuerda en este navegador, **Sistema** sigue a tu
dispositivo).

## Qué puede y qué no puede hacer un asistente
| Tarea | Entrenador | Asistente |
|---|---|---|
| Crear partidos, convocatoria, empezar/finalizar, reloj, anotar cualquier estadística | sí | sí |
| Calendario de entrenos, asistencia, planes, asignaciones, ausencias | sí | sí |
| Lesiones, altura/peso, resultados de pruebas físicas | sí | sí |
| Asignar jugadores a un equipo, resolver casos de elegibilidad (equipos propios) | sí | no (solo lectura) |
| Solicitar un jugador nuevo o una baja (requiere aprobación del administrador) | sí | no |
| Cambiar el dorsal preferido de un jugador | sí | no (solo lectura) |
| Exportar la plantilla del equipo (CSV) | sí (equipos que entrenas ahora) | no |
| Catálogo de ejercicios: crear, editar y archivar los propios | sí | sí |

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
Tú (y la administración) ves todas las jugadas. Familias y jugadores ven las jugadas del equipo (periodos, puntos del
rival, tiempos muertos, notas del equipo) y solo las de sus hijos o las propias, con el marcador oficial.

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

## 7. Catálogo de ejercicios y añadir ejercicios
**Entrenos > Planes** tiene una tercera pestaña, **Ejercicios**: el catálogo de ejercicios.
- Los ejercicios **Globales** (los de las plantillas más el test de Cooper, en tu idioma) son de solo lectura. Los
  ejercicios propios de la academia se crean con **Nuevo ejercicio**, se editan, se archivan (**Archivar**) y se
  restauran (**Restaurar**); pueden hacerlo entrenadores, entrenadores asistentes y administradores. Filtra con
  **Todos**, **Globales** y **De la academia**; **Mostrar archivados** incluye los archivados; **Cargar más** al final.
  La búsqueda de planes también encuentra ejercicios del catálogo.
- **Añadir ejercicios** en una sesión, en el diálogo **Nueva sesión** y **Añadir del catálogo** en el editor de planes:
  busca (p. ej. "cooper"); primero salen los ejercicios del catálogo y debajo los elementos de tus planes y plantillas
  que coinciden. Marca varios y pulsa **Añadir (n)**: se añaden en el orden en que los marcaste. En el diálogo de nueva
  sesión se añaden cuando la sesión ya existe; si falla, la sesión se mantiene y el diálogo explica por qué.
- El elemento añadido conserva su propio texto, que puedes editar, y lleva la marca **Del catálogo de ejercicios**.
  Archivar un ejercicio no cambia los elementos que lo usan, pero un ejercicio archivado no se puede volver a añadir
  ("Ese ejercicio está archivado: elige otro").

## 8. Dorsales
- La página del jugador muestra el **Dorsal preferido**. Los entrenadores lo cambian (**Cambiar dorsal preferido**; una
  o dos cifras, vacío lo quita); los entrenadores asistentes solo lo ven. Familias y jugadores pueden indicarlo como
  deseo.
- Al asignar un jugador a uno de tus equipos sin escribir dorsal, la aplicación usa el preferido si está libre en ese
  equipo; si no, el de su equipo más reciente que tuviera dorsal, si está libre; si no, ninguno, y dice qué regla se
  aplicó. Sin dorsal se abre en el acto el selector: muestra los **Dorsales ocupados** con su jugador y los **Dorsales
  libres** (0-99); un dorsal ocupado se rechaza nombrando a quien lo tiene.

## 9. Exportaciones
- **Plantilla del equipo** (solo el entrenador actual del equipo; no para un equipo que entrenaste en una temporada
  terminada): el icono de descarga de la barra superior del equipo (**Exportar la plantilla (CSV)**) guarda los
  jugadores con sus datos, categoría, elegibilidad y el contacto de sus tutores, y el cuerpo técnico como segundo
  bloque. Lo genera el servidor: necesita conexión, usa el idioma de la aplicación y queda registrado en la actividad de
  la academia. Los entrenadores asistentes no tienen esta exportación.
- **Plantilla en PDF**: el icono PDF justo después del icono CSV (**Descargar la plantilla (PDF)**) imprime la misma
  plantilla en una hoja, para las mismas personas (el entrenador actual del equipo), y queda registrado en la
  actividad igual. Un equipo con más de 60 jugadores, 20 técnicos o 4 tutores de un jugador no cabe: la aplicación
  dice "La plantilla es demasiado grande para una hoja: usa el archivo CSV.". Si el servicio de PDF no responde: "El
  PDF no está disponible ahora. Inténtalo más tarde o usa el archivo CSV.".
- **Hoja del partido (PDF)**: en la pantalla de un partido, el icono PDF de la barra superior (**Descargar la hoja del
  partido (PDF)**) guarda la hoja del partido con el marcador y las líneas de estadísticas que puedes ver. La genera
  el servidor en el idioma de la aplicación; necesita conexión (sin ella el icono está desactivado) y aparece cuando
  el partido tiene convocatoria. Si no se puede generar: "La hoja del partido no está disponible ahora. Inténtalo más
  tarde.".
- Se generan en tu dispositivo con lo que la pantalla ya cargó (icono de descarga **Exportar**): las **Estadísticas de
  temporada** (una fila por partido más los totales) y las estadísticas de un partido como **Archivo CSV** o **Archivo
  Excel**; la lista de partidos y la semana de entrenos como calendario del equipo (partidos y sesiones de la temporada
  elegida) en CSV, Excel o **Archivo de calendario (.ics)**, que el calendario del móvil o del ordenador puede importar.
  Excel se carga la primera vez que lo eliges y entonces necesita conexión; sin ella la aplicación lo indica y el CSV sigue
  funcionando.

## 10. Tu nombre
**Perfil > Tu nombre** cambia tu propio nombre y apellidos tal como te ve esta academia (**Guardar nombre**; necesita
conexión); empieza con tu nombre y apellidos tal como los guarda esta academia. El correo lo cambia el
administrador.

## 11. Cuotas al día (solo entrenador)
En la página de un equipo que entrenas ahora como **Entrenador**, la sección **Cuotas al día** muestra a cada jugador
como **Al día** o **Con cuotas pendientes** y cuántos tienen cuotas pendientes (p. ej. "2 de 12 con cuotas
pendientes"). "Solo se ve si cada jugador está al día, sin importes." Los entrenadores asistentes, y los entrenadores de
otros equipos, no la ven. Los pagos los registra el administrador de la academia.

---
Estado: redactada a partir de las pantallas implementadas y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
