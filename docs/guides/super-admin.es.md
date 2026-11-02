# Guía del superadministrador

Idiomas: Español · [English](super-admin.en.md) · [Bahasa Indonesia](super-admin.id.md)

Inicias sesión con tu dirección de correo electrónico y tu contraseña.

El **superadministrador** gestiona la plataforma: crea y retira academias y consulta su uso. Es un rol de realm de Keycloak
(`super_admin`), no un rol de academia. Un superadministrador **no puede leer el contenido de las academias** (jugadores,
partidos, datos de salud): la plataforma no tiene acceso a él.

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

## Panel de uso
El detalle muestra **Uso** por servicio (Núcleo, Partidos, Deportistas): miembros, jugadores, jugadores activos, equipos,
temporadas, partidos, partidos en vivo, eventos de partido, sesiones de entreno, registros de asistencia, planes,
resultados de pruebas, lesiones y medidas corporales. Si un servicio no responde, un aviso "Sin datos de: ..." lo nombra y el
resto se sigue mostrando. Se guarda una instantánea por academia y día (02:30 UTC); el gráfico de evolución aún no está en la
aplicación.

---
Estado: redactada a partir de las pantallas implementadas, el contrato y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
