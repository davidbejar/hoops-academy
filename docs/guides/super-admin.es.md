# Guía del superadministrador

Idiomas: Español · [English](super-admin.en.md) · [Bahasa Indonesia](super-admin.id.md)

Inicias sesión con tu dirección de correo electrónico y tu contraseña.

El **superadministrador** gestiona la plataforma: crea y retira academias y consulta su uso. Es un rol de realm de Keycloak
(`super_admin`), no un rol de academia. Un superadministrador **no puede leer el contenido de las academias** (jugadores,
partidos, datos de salud): la plataforma no tiene acceso a él. Las excepciones son la lista de **administradores** de
una academia (nombre, correo y estado de la invitación), que el superadministrador gestiona (ver abajo, ADR-0023), y la
búsqueda de **Usuarios**, que muestra cada login con su nombre y sus roles en cada academia (enmienda de ADR-0029).

## Administración de la aplicación y contextos
Tu login puede trabajar en varios **contextos**: **Administración de la aplicación** (por ser superadministrador) y cada
academia de la que eres miembro. Cada contexto tiene su propio menú.
- Si tu único contexto es la Administración de la aplicación (sin pertenencia a ninguna academia), entras directamente
  en su **Resumen**.
- Con varios contextos entras en el último que usaste en este navegador, o en la lista para elegir uno. Cambia cuando
  quieras con la etiqueta de contexto de la cabecera: en el móvil abre una hoja abajo; en pantallas anchas, un panel
  junto al menú lateral (botón **Cambiar de contexto**). Cada fila muestra el nombre y tu rol, p. ej. "Administración de
  la aplicación / Super administrador" o "Hangtuah / Administrador". La elección se recuerda en este navegador y se
  olvida al cerrar sesión.
- Un enlace antiguo a una página `/platform/...` abre la misma página dentro de la Administración de la aplicación.
- El botón redondo con tus iniciales (arriba a la derecha, en todos los contextos) abre un menú: **Perfil**, **Idioma** y
  **Tema** (**Sistema**, **Claro**, **Oscuro**; se recuerda en este navegador, **Sistema** sigue a tu dispositivo).

El menú de la Administración de la aplicación tiene **Resumen** (el panel central), **Academias**, **Usuarios**,
**Peticiones** (una insignia cuenta las solicitudes de academia pendientes) y **Auditoría**. El panel muestra las mismas
áreas como tarjetas (**Aprobaciones pendientes**, **Auditoría**) y además **Facturación**, que indica "Próximamente":
aún no hay nada que configurar.

## Academias
**Academias** lista las academias con un buscador (nombre o identificador) y filtros de estado: **Activa**,
**Suspendida**, **Retirada**. Abre una para ver su detalle y su uso.

## Crear una academia
**Academias > Nueva academia** (véase también `docs/runbooks/onboard-tenant.md`):
- **Nombre de la academia**, **Identificador (slug)** (minúsculas, números y guiones, 3-50), **Zona horaria**, **Idioma**.
- **Correo del primer administrador**, nombre y apellidos.
Al **Crear**, la academia y su primer administrador existen a la vez, se cargan las categorías de edad por defecto (U8 a
U18, SENIOR) y se te muestra **una sola vez** la **contraseña temporal** del administrador (ver "Primer inicio de sesión"
más abajo). No se envía ningún correo. Si ese correo ya tiene acceso a la plataforma (p. ej. administra otra academia),
no hay contraseña temporal: la persona entra con la contraseña que ya tiene. Si el proveedor de identidad no está
disponible, la creación falla entera y no queda nada a medias ("502").

## Primer inicio de sesión con contraseña temporal (ADR-0024)
- Un acceso nuevo recibe una contraseña temporal generada por el servidor (16 letras y cifras) que se muestra **una sola
  vez** a quien lo creó. Se muestra en un diálogo **Contraseña temporal**: la contraseña en un campo grande de
  letra monoespaciada, un botón **Copiar contraseña** y un **Hecho** explícito; el diálogo no se cierra de otra forma y la
  contraseña no se conserva en ningún sitio. La plataforma nunca la guarda; si se pierde, genera otra (**Generar nueva
  contraseña temporal**, más abajo).
- Entrégala **en privado**: en persona, por teléfono o por una mensajería de confianza, nunca junto con la dirección de
  correo en el mismo mensaje.
- La persona abre la aplicación, entra con su correo y la contraseña temporal, y Keycloak le pide en ese momento
  **elegir una contraseña nueva** (al menos 12 caracteres, distinta de su correo). Desde entonces solo vale la suya.
- Varios intentos fallidos bloquean el acceso durante un tiempo (protección contra fuerza bruta).

- **Una contraseña temporal caduca a los 3 días** si nadie la ha usado (ADR-0028). El acceso queda desactivado: la
  persona ve "Tu contraseña temporal ha caducado. Pide una nueva al administrador de tu academia." en la página de inicio
  de sesión. La fila del administrador muestra **Contraseña temporal caducada** junto a **Invitación pendiente**; usa
  **Generar nueva contraseña temporal** (botón de llave) para darle una nueva, lo que también reactiva el acceso. La
  comprobación se hace en segundo plano cada vez que se genera una contraseña temporal o alguien entra por primera vez,
  así que una contraseña caducada puede seguir funcionando un tiempo hasta el siguiente de esos eventos. A quien ya
  eligió su propia contraseña no le afecta nunca.

## Ciclo de vida y su significado
| Estado | Significado |
|---|---|
| **Activa** | funcionamiento normal |
| **Suspendida** | parada reversible. Todos los miembros reciben "no encontrado" (404) en todas las API de la academia y la academia desaparece de su lista. Los datos no se tocan. Los demás servicios guardan la pertenencia en caché hasta 30 s, así que el efecto puede tardar ese tiempo. |
| **Retirada** | terminal. Se bloquean los accesos de inmediato; los datos se conservan hasta la fecha **conservados hasta** (por defecto 365 días tras la retirada). Aún no existe un proceso de purga (véase `docs/roadmap.md`), de modo que los datos no se borran solos. |

Acciones en el detalle de la academia:
- **Suspender**: el motivo es obligatorio.
- **Reactivar**: solo desde Suspendida; devuelve el acceso tal como estaba.
- **Retirar**: el motivo es obligatorio y un aviso explica que empieza el plazo de conservación. No se puede deshacer.
Cada cambio de ciclo de vida queda en el registro de auditoría (solo se añade) de la academia.

## Administradores
En el detalle de la academia (**Academias >** la academia) la sección **Administradores** lista cada administrador con
nombre, correo, estado de la invitación (**Invitación pendiente** / **Invitación aceptada**) y sus otros roles en la
academia. Cada fila tiene **Editar administrador**, **Quitar administrador** y, mientras la invitación está pendiente,
el botón de llave **Generar nueva contraseña temporal**; arriba está **Añadir administrador**. La sección funciona en academias activas y suspendidas; en
una **retirada** solo muestra una nota (sus administradores ya no se pueden consultar ni modificar). Las mismas
operaciones existen en la API de plataforma `/platform/tenants/{id}/admins`.
- **Listar**: los administradores activos con nombre, correo, estado de la invitación y sus otros roles en la academia.
- **Añadir** (correo, nombre, apellidos, idioma opcional): si un miembro de la academia tiene ese correo, pasa a ser
  administrador (se conservan sus datos; si no tenía acceso se le crea uno, con una contraseña temporal que se muestra una
  vez). Si no, se crea un nuevo administrador igual que al primero y el diálogo muestra su contraseña temporal. Si el correo ya
  tiene acceso, una nota dice que la persona entra con su contraseña actual. Si el correo es de un miembro desactivado, se
  rechaza.
- **Editar** nombre, apellidos o correo. Un correo nuevo pasa a ser también la dirección de inicio de sesión (usuario y
  correo de Keycloak); no se envía ningún correo y la contraseña no cambia (una contraseña temporal pendiente sigue
  valiendo). A diferencia de un administrador de academia, puedes hacerlo aunque el acceso se use en varias academias:
  el correo nuevo sustituye entonces al anterior en todas las academias donde la persona es miembro activo (una
  persona, un correo) y el registro de auditoría de cada una lo anota. Si otro miembro de una de esas academias ya usa
  la dirección nueva, el cambio se rechaza ("correo en uso") y no cambia nada en ninguna academia.
- **Quitar** (pide confirmación): la persona pierde el rol de administrador; sus otros roles se mantienen y, si era su
  único rol, queda desactivada en esta academia. Su acceso nunca se borra (puede usarse en otras academias).
- **No se puede quitar al último administrador.** Una academia necesita siempre al menos un administrador activo. Cuando
  solo hay un administrador en la lista, su botón **Quitar** está desactivado y la fila explica: "Una academia necesita al
  menos un administrador. Añade otro administrador antes de quitar a este." Si otra persona acaba de cambiar la lista y el
  servidor aun así lo rechaza, ves el mismo mensaje. Añade primero al nuevo administrador y después quita al anterior.
- **Generar nueva contraseña temporal** (botón de llave; sustituye al antiguo «Reenviar invitación») muestra una
  **nueva contraseña temporal** en el mismo diálogo (una vez; la anterior deja de valer), solo
  mientras la invitación esté pendiente y la persona aún no haya elegido contraseña. También repara a los administradores
  creados antes de este cambio que nunca recibieron contraseña (no podían entrar).
Cada cambio queda en el registro de auditoría de la academia contigo como autor.

## Panel de uso
El detalle muestra **Uso** por servicio (Núcleo, Partidos, Deportistas): miembros, jugadores, jugadores activos, equipos,
temporadas, partidos, partidos en vivo, eventos de partido, sesiones de entreno, registros de asistencia, planes,
resultados de pruebas, lesiones y medidas corporales. Si un servicio no responde, un aviso "Sin datos de: ..." lo nombra y el
resto se sigue mostrando. Se guarda una instantánea por academia y día (02:30 UTC); el gráfico de evolución aún no está en la
aplicación.

## Usuarios
**Usuarios** busca cualquier login de la plataforma: escribe al menos 2 caracteres de un nombre o de un correo (da igual
mayúsculas o minúsculas); 25 resultados por página. Cada login muestra su correo y, por cada academia a la que
pertenece, el nombre de la persona, sus roles y su estado (también miembros inactivos y academias suspendidas o
retiradas), o "No pertenece a ninguna academia". Toca una academia para abrir su página. La lista es de solo lectura:
el correo de un administrador o una contraseña temporal se cambian en la página de la academia (**Administradores**,
arriba).

## Peticiones (solicitudes de academia)
Los visitantes piden una academia con el formulario de la página de inicio. **Peticiones** lista esas solicitudes por
estado (**Pendientes**, **Aceptadas**, **Rechazadas**); la insignia del menú cuenta las pendientes. Las solicitudes de
dentro de una academia (aprobación de jugadores) no están aquí.
- **Aceptar** abre **Crear la academia**, rellenado con la solicitud: revisa el identificador (slug), la zona horaria y
  el nombre del administrador. Quien la solicitó será el primer administrador de la academia, sea cual sea el rol que
  indicó. Un login nuevo recibe una contraseña temporal que se muestra una sola vez (ver "Primer inicio de sesión"
  arriba); un login que ya existe no recibe ninguna. El solicitante recibe un correo de aceptación en el idioma de la
  solicitud con la dirección de acceso, nunca la contraseña.
- **Rechazar** pide un **Motivo**, que se envía por correo a quien la solicitó.
- Si el correo no se pudo enviar, la solicitud muestra **Correo no enviado**; la decisión se mantiene.
- Una solicitud que otra persona ya decidió responde "Esta solicitud ya se ha decidido".

## Auditoría
**Auditoría** muestra el registro de auditoría de todas las academias, de lo más reciente a lo más antiguo, cada entrada
con su academia; el icono de reloj en la página de una academia muestra solo esa academia. Filtra por intervalo de
fechas y por una o varias acciones; cambia de página con las flechas de abajo. Solo se muestran los nombres de las
academias y de sus administradores actuales; los demás miembros y los jugadores aparecen por su tipo, porque la
plataforma no lee el contenido de la academia más allá de la identidad de sus administradores (ADR-0023, ADR-0029). Las
entradas no se modifican y se conservan (aún no hay retención).

El icono de descarga (**Exportar la actividad (CSV)**) guarda todo lo que seleccionan los filtros actuales, no solo la
página en pantalla, como archivo CSV en el idioma de la aplicación. Necesita conexión (el archivo lo genera el servidor)
y se detiene en 10.000 filas: si lo indica, acota las fechas o las acciones. La exportación queda registrada como
**Registro de auditoría exportado** en cada academia que tenga filas en el archivo.

---
Estado: redactada a partir de las pantallas implementadas, el contrato y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
