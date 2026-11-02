# Guía del administrador

Idiomas: Español · [English](admin.en.md) · [Bahasa Indonesia](admin.id.md)

Inicias sesión con tu dirección de correo electrónico y tu contraseña.

Eres **Administrador** de una academia. Configuras la academia, invitas a personas, creas temporadas y equipos y
decides sobre las solicitudes de jugadores. Los nombres de menú son los que muestra la aplicación en español.

## Moverse por la aplicación
- Inicia sesión con tu correo y la contraseña temporal que te dio el administrador de la plataforma; la primera vez
  Keycloak te pide elegir tu propia contraseña (al menos 12 caracteres). No se envía correo de invitación (ADR-0024).
- Barra inferior en el móvil (barra lateral en pantallas anchas): **Admin**, **Equipos**, **Partidos**, **Entrenos**,
  **Jugadores**.
- Toca el logo o el nombre de la academia en la barra superior para **Cambiar de academia** si perteneces a varias.
- **Perfil** (barra superior): **Idioma** (Español, English, Bahasa Indonesia) y **Cerrar sesión**.

## 1. Perfil de la academia y logo
**Admin > Perfil de la academia.**
- Nombre, **Zona horaria** (p. ej. Europe/Madrid) e **Idioma por defecto**.
- **Regla de edad** y **Niveles máximos de categoría superior**: véase el apartado 7.
- **Logo**: **Elegir imagen** y después **Subir logo**. PNG, JPEG o WebP, máximo 512 KB. **Quitar logo** lo elimina.
  El logo aparece en la barra superior de todos los miembros.

## 2. Miembros e invitaciones
**Admin > Miembros.** Busca por nombre o correo.
1. **Invitar**: nombre, apellidos, correo y al menos un **Rol** (Administrador, Entrenador, Entrenador asistente,
   Familia, Jugador). Una persona puede tener varios roles.
2. No se envía ningún correo. Si la persona aún no tenía acceso, se te muestra **una sola vez su contraseña temporal**:
   entrégala en privado (en persona, por teléfono o por una mensajería de confianza; nunca en el mismo mensaje que el
   correo). Entra con su correo y esa contraseña y después tiene que elegir la suya. Si ese correo ya tiene acceso (p. ej.
   es miembro de otra academia), no hay contraseña temporal: usa la que ya tiene. Hasta su primer inicio de sesión
   figura como **Invitación pendiente**. Mientras siga pendiente y no haya elegido contraseña, puedes generarle una
   **nueva contraseña temporal** (sustituye a la anterior; se rechaza si el acceso se usa también en otra academia:
   pídeselo al administrador de la plataforma).
3. **Editar roles** cambia los roles. **Desactivar** retira el acceso (la persona se conserva y aparece como **Inactivo**).
4. **Cambiar el correo** de un miembro con acceso cambia también su dirección de inicio de sesión: desde ese momento
   entra con el correo nuevo; no se envía ningún correo y la contraseña no cambia. Si la persona pertenece también a
   otra academia, el cambio se rechaza ("usado en otra academia"): pídeselo al administrador de la plataforma. A un
   miembro con acceso no se le puede quitar el correo.

## 3. Tutores (familias)
Abre un miembro con el rol **Familia**. En **Jugadores vinculados** usa **Vincular jugador** y elige al hijo o hija;
el vínculo se quita con la acción de quitar. Una familia solo ve y edita datos de los jugadores vinculados. Los vínculos
solo se editan para miembros con el rol Familia: invita primero a la persona.

## 4. Temporadas y categorías de edad
- **Admin > Temporadas > Nueva temporada**: nombre, inicio, fin y **Año de referencia** (lo usa la regla por año de
  nacimiento). Las temporadas de una academia no pueden solaparse.
- **Admin > Categorías de edad**: código, nombre, **Edad máxima** (vacío = sin límite) y **Orden**. U8 a U18 y SENIOR se
  crean automáticamente y se pueden editar. Al cambiar una categoría se revisan todas las asignaciones.

## 5. Equipos y cuerpo técnico
Pestaña **Equipos**, elige la temporada y pulsa **Nuevo equipo**: nombre, alias (opcional), **Categoría** y
**Política de género** (Masculino, Femenino, Mixto). Dentro de un equipo:
- **Cuerpo técnico > Añadir entrenador**: elige un miembro y la función (entrenador o asistente). La autoridad de un
  entrenador sobre un equipo procede de figurar aquí.
- **Plantilla > Asignar jugador**: busca al jugador. La aplicación indica **Elegible**, **Juega en categoría superior (+n)**
  o **No elegible** con los motivos (demasiado mayor, supera el máximo de niveles, política de género, falta fecha de
  nacimiento o género, jugador no activo). Un jugador no elegible no se puede asignar. Indica el **Dorsal** al asignar;
  **Cambiar dorsal** y **Quitar de la plantilla** están en cada fila.

## 6. Jugadores y aprobaciones
Pestaña **Jugadores**: filtros **Estado** (Activo, Sin equipo válido, Pendiente de aprobación, Baja), **Equipo**,
**Categoría** y buscador.
- **Nuevo jugador**: nombre, apellidos, fecha de nacimiento, género (obligatorios), correo y equipo inicial opcionales.
  Como administrador el jugador se crea al instante. Con correo, además recibe un acceso: su contraseña temporal se
  muestra una vez, como en una invitación.
- Un jugador sin equipo válido aparece como **Sin equipo válido** hasta que se le asigna uno.
- Ficha del jugador: datos básicos, categoría natural, equipos, tutores, **Asignar a un equipo** (solo equipos
  elegibles), salud, **Estadísticas de la temporada** y **Dar de baja**.
- **Admin > Solicitudes pendientes**: los entrenadores piden altas y bajas. **Aprobar** (nota opcional) o **Rechazar**
  (nota obligatoria). Aprobar un alta puede fallar si el jugador no es elegible para el equipo elegido; la solicitud
  queda entonces pendiente. Aprobar a un jugador con correo le crea un acceso; su contraseña temporal se muestra una vez.

## 7. Ajustes: regla de edad, categoría superior, idioma
**Admin > Perfil de la academia**
- **Regla de edad**: **Por año de nacimiento** (por defecto: año de referencia de la temporada menos año de nacimiento)
  o **Por fecha de nacimiento** (años cumplidos hoy).
- **Niveles máximos de categoría superior**: cuántas categorías por encima de la natural puede jugar un jugador. Vacío
  significa sin límite.
- **Idioma por defecto**: se usa para quien no haya elegido el suyo.
Al guardar un cambio de regla de edad o de límite se reevalúan todas las asignaciones. No se borra nada: las que dejan de
cumplir se marcan **Ya no es elegible** y se abre un caso de elegibilidad.

## 8. Casos de elegibilidad y cambio de temporada
**Admin > Casos de elegibilidad** muestra los casos abiertos (jugador, equipo invalidado, motivo). Para cada uno:
**Reasignar** (elige un equipo elegible), **Quitar del equipo** o **Descartar caso**.

**Cambio de temporada**: **Admin > Temporadas > Pasar a nueva temporada** en la temporada que termina.
1. Decide si **Copiar el cuerpo técnico** y **Copiar las plantillas**.
2. **Ejecutar cambio de temporada**. El resultado muestra los equipos copiados, los **Jugadores sin equipo válido** (por
   ejemplo quienes se han hecho mayores) y los casos abiertos.
3. **Ir a los casos de elegibilidad** y resuélvelos. Con la regla por año de nacimiento, el cambio de temporada es
   cuando aparecen casi todos; con la regla por fecha de nacimiento también los detecta la revisión nocturna.

## 9. Pruebas físicas y normas
Los iconos de la lista de jugadores abren **Tipos de prueba** y **Normas**. Las normas globales son de solo lectura;
añade filas **Propia de la academia** para sustituirlas. Los valores con **Referencia pendiente** son provisionales, no
normas publicadas: sustitúyelos antes de usar las bandas para tomar decisiones (véase `docs/domain/norms.md`).

---
Estado: redactada a partir de las pantallas implementadas y los ficheros de traducción; aún no contrastada con un recorrido manual en navegador.
Los textos sobre la contraseña temporal describen el comportamiento del servidor de WP24; las pantallas que la muestran llegan con WP25.
