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
U18, SENIOR) y el administrador recibe un correo con un enlace para elegir contraseña. Si el proveedor de identidad no está
disponible, la creación falla entera y no queda nada a medias ("502").

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
**Reenviar invitación**; arriba está **Añadir administrador**. La sección funciona en academias activas y suspendidas; en
una **retirada** solo muestra una nota (sus administradores ya no se pueden consultar ni modificar). Las mismas
operaciones existen en la API de plataforma `/platform/tenants/{id}/admins`.
- **Listar**: los administradores activos con nombre, correo, estado de la invitación y sus otros roles en la academia.
- **Añadir** (correo, nombre, apellidos, idioma opcional): si un miembro de la academia tiene ese correo, pasa a ser
  administrador (se conservan sus datos; si no tenía acceso recibe el correo para crear contraseña). Si no, se invita a un
  nuevo administrador igual que al primero. Si el correo es de un miembro desactivado, se rechaza.
- **Editar** nombre, apellidos o correo. Un correo nuevo pasa a ser también la dirección de inicio de sesión (usuario y
  correo de Keycloak) y recibe un correo de verificación, o de nuevo la invitación si sigue pendiente. A diferencia de un
  administrador de academia, puedes hacerlo aunque el acceso se use en varias academias.
- **Quitar** (pide confirmación): la persona pierde el rol de administrador; sus otros roles se mantienen y, si era su
  único rol, queda desactivada en esta academia. Su acceso nunca se borra (puede usarse en otras academias).
- **No se puede quitar al último administrador.** Una academia necesita siempre al menos un administrador activo. Cuando
  solo hay un administrador en la lista, su botón **Quitar** está desactivado y la fila explica: "Una academia necesita al
  menos un administrador. Añade otro administrador antes de quitar a este." Si otra persona acaba de cambiar la lista y el
  servidor aun así lo rechaza, ves el mismo mensaje. Añade primero al nuevo administrador y después quita al anterior.
- **Reenviar invitación**: solo mientras la invitación esté pendiente.
Cada cambio queda en el registro de auditoría de la academia contigo como autor.

## Panel de uso
El detalle muestra **Uso** por servicio (Núcleo, Partidos, Deportistas): miembros, jugadores, jugadores activos, equipos,
temporadas, partidos, partidos en vivo, eventos de partido, sesiones de entreno, registros de asistencia, planes,
resultados de pruebas, lesiones y medidas corporales. Si un servicio no responde, un aviso "Sin datos de: ..." lo nombra y el
resto se sigue mostrando. Se guarda una instantánea por academia y día (02:30 UTC); el gráfico de evolución aún no está en la
aplicación.

---
Estado: redactada a partir de las pantallas implementadas, el contrato y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
