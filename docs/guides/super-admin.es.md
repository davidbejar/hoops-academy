# Guía del superadministrador

Idiomas: Español · [English](super-admin.en.md) · [Bahasa Indonesia](super-admin.id.md)

Inicias sesión con tu dirección de correo electrónico y tu contraseña.

El **superadministrador** gestiona la plataforma: crea y retira academias y consulta su uso. Es un rol de realm de Keycloak
(`super_admin`), no un rol de academia. Un superadministrador **no puede leer el contenido de las academias** (jugadores,
partidos, datos de salud): la plataforma no tiene acceso a él. La única excepción es la lista de **administradores** de
una academia (nombre, correo y estado de la invitación), que el superadministrador gestiona (ver abajo, ADR-0023).

## Encontrar la consola
- Un superadministrador sin pertenencia a ninguna academia entra directamente en **Plataforma**.
- Quien además pertenece a una academia ve la navegación de esa academia; abre **Perfil > Consola de plataforma** para ir a
  la plataforma.

## Lista de academias
**Plataforma** lista las academias con un buscador (nombre o identificador) y filtros de estado: **Activa**,
**Suspendida**, **Retirada**. Abre una para ver su detalle y su uso.

## Crear una academia
**Plataforma > Nueva academia** (véase también `docs/runbooks/onboard-tenant.md`):
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
En el detalle de la academia (**Plataforma >** la academia) la sección **Administradores** lista cada administrador con
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

---
Estado: redactada a partir de las pantallas implementadas, el contrato y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
