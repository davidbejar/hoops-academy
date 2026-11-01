// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Hoops Academy';

  @override
  String get loading => 'Cargando…';

  @override
  String get retry => 'Reintentar';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInSubtitle => 'Accede con tu cuenta de la academia';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String signedInAs(String name) {
    return 'Sesión iniciada como $name';
  }

  @override
  String get offlineBanner =>
      'Sin conexión. Los datos pueden no estar actualizados.';

  @override
  String get mockModeBanner => 'Modo demo: datos de ejemplo, sin servidor';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navTeams => 'Equipos';

  @override
  String get navMatches => 'Partidos';

  @override
  String get navTraining => 'Entrenos';

  @override
  String get navPlayers => 'Jugadores';

  @override
  String get navMyPlayers => 'Mis jugadores';

  @override
  String get navMe => 'Yo';

  @override
  String get navPlatform => 'Plataforma';

  @override
  String placeholderModule(String module) {
    return '$module: próximamente';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get languageName_es => 'Español';

  @override
  String get languageName_en => 'English';

  @override
  String get languageName_id => 'Bahasa Indonesia';

  @override
  String get academy => 'Academia';

  @override
  String get switchAcademy => 'Cambiar de academia';

  @override
  String get chooseAcademyTitle => 'Elige tu academia';

  @override
  String get chooseAcademySubtitle =>
      'Perteneces a varias academias. ¿Con cuál quieres trabajar?';

  @override
  String rolesInAcademy(String roles) {
    return 'Roles: $roles';
  }

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleCoach => 'Entrenador';

  @override
  String get roleAssistantCoach => 'Entrenador asistente';

  @override
  String get roleParent => 'Familia';

  @override
  String get rolePlayer => 'Jugador';

  @override
  String get noAccessTitle => 'Sin acceso a ninguna academia';

  @override
  String get noAccessBody =>
      'Tu cuenta aún no pertenece a ninguna academia. Pide a un administrador que te invite.';

  @override
  String get profileLoadFailed => 'No hemos podido cargar tu perfil';

  @override
  String get errorNetwork =>
      'No hay conexión con el servidor. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorTimeout =>
      'El servidor tarda demasiado en responder. Inténtalo de nuevo.';

  @override
  String get errorUnauthorized =>
      'Tu sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get errorForbidden => 'No tienes permiso para hacer esto.';

  @override
  String get errorNotFound => 'No hemos encontrado lo que buscas.';

  @override
  String get errorConflict =>
      'Los datos han cambiado. Actualiza e inténtalo de nuevo.';

  @override
  String get errorValidation => 'Revisa los datos introducidos.';

  @override
  String get errorServer =>
      'El servidor ha tenido un problema. Inténtalo más tarde.';

  @override
  String get errorUnknown => 'Ha ocurrido un error inesperado.';

  @override
  String errorReference(String traceId) {
    return 'Referencia: $traceId';
  }

  @override
  String get emptyTitle => 'Nada por aquí todavía';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get create => 'Crear';

  @override
  String get confirm => 'Confirmar';

  @override
  String get close => 'Cerrar';

  @override
  String get remove => 'Quitar';

  @override
  String get search => 'Buscar';

  @override
  String get all => 'Todos';

  @override
  String get none => 'Ninguno';

  @override
  String get saved => 'Cambios guardados';

  @override
  String get fieldRequired => 'Campo obligatorio';

  @override
  String get fieldInvalidNumber => 'Introduce un número válido';

  @override
  String get fieldInvalidEmail => 'Introduce un correo válido';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get noteOptional => 'Nota (opcional)';

  @override
  String get noteRequired => 'Nota (obligatoria)';

  @override
  String get readOnlyHint =>
      'Solo lectura: no tienes permiso para modificar esto.';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get adminTitle => 'Administración';

  @override
  String get adminAcademyProfile => 'Perfil de la academia';

  @override
  String get adminMembers => 'Miembros';

  @override
  String get adminSeasons => 'Temporadas';

  @override
  String get adminAgeCategories => 'Categorías de edad';

  @override
  String get adminApprovals => 'Solicitudes pendientes';

  @override
  String get adminCases => 'Casos de elegibilidad';

  @override
  String get academyName => 'Nombre de la academia';

  @override
  String get academyTimezone => 'Zona horaria (p. ej. Europe/Madrid)';

  @override
  String get academyAgeRule => 'Regla de edad';

  @override
  String get ageRuleBirthYear => 'Por año de nacimiento';

  @override
  String get ageRuleBirthday => 'Por fecha de nacimiento';

  @override
  String get academyMaxPlayUp => 'Niveles máximos de categoría superior';

  @override
  String get academyDefaultLocale => 'Idioma por defecto';

  @override
  String get logoTitle => 'Logo';

  @override
  String get logoHint => 'PNG, JPEG o WebP, máximo 512 KB';

  @override
  String get logoChoose => 'Elegir imagen';

  @override
  String get logoUpload => 'Subir logo';

  @override
  String get logoRemove => 'Quitar logo';

  @override
  String get logoRemoveConfirm => '¿Quitar el logo de la academia?';

  @override
  String get logoPreview => 'Vista previa';

  @override
  String get logoNone => 'Sin logo';

  @override
  String get logoUploaded => 'Logo actualizado';

  @override
  String get logoRemoved => 'Logo eliminado';

  @override
  String get logoErrorTooLarge => 'La imagen supera los 512 KB.';

  @override
  String get logoErrorWrongType => 'Formato no válido: usa PNG, JPEG o WebP.';

  @override
  String get logoErrorEmpty => 'El archivo está vacío.';

  @override
  String get membersSearchHint => 'Buscar por nombre o correo';

  @override
  String get membersEmpty => 'Aún no hay miembros';

  @override
  String get memberInvite => 'Invitar';

  @override
  String get memberInviteTitle => 'Invitar a un miembro';

  @override
  String get memberGivenName => 'Nombre';

  @override
  String get memberFamilyName => 'Apellidos';

  @override
  String get memberEmail => 'Correo electrónico';

  @override
  String get memberRoles => 'Roles';

  @override
  String get memberRolesRequired => 'Elige al menos un rol';

  @override
  String get memberInvited => 'Invitación enviada';

  @override
  String get memberEditRoles => 'Editar roles';

  @override
  String get memberDeactivate => 'Desactivar';

  @override
  String memberDeactivateConfirm(String name) {
    return '¿Desactivar a $name? Perderá el acceso a la academia.';
  }

  @override
  String get memberDeactivated => 'Miembro desactivado';

  @override
  String get memberInactive => 'Inactivo';

  @override
  String get memberInvitationPending => 'Invitación pendiente';

  @override
  String get memberGuardianLinks => 'Jugadores vinculados';

  @override
  String get memberGuardianNone => 'Sin jugadores vinculados';

  @override
  String get memberGuardianAdd => 'Vincular jugador';

  @override
  String memberGuardianRemoveConfirm(String name) {
    return '¿Quitar el vínculo con $name?';
  }

  @override
  String get memberGuardianOnlyParents =>
      'Los vínculos solo se editan para miembros con el rol Familia.';

  @override
  String get seasonsEmpty => 'Aún no hay temporadas';

  @override
  String get seasonNew => 'Nueva temporada';

  @override
  String get seasonEdit => 'Editar temporada';

  @override
  String get seasonName => 'Nombre';

  @override
  String get seasonStarts => 'Inicio';

  @override
  String get seasonEnds => 'Fin';

  @override
  String get seasonReferenceYear =>
      'Año de referencia (regla por año de nacimiento)';

  @override
  String get seasonCurrent => 'Actual';

  @override
  String get seasonDatesInvalid =>
      'La fecha de fin debe ser posterior a la de inicio';

  @override
  String get seasonRollover => 'Pasar a nueva temporada';

  @override
  String get rolloverTitle => 'Cambio de temporada';

  @override
  String rolloverIntro(String name) {
    return 'Se creará la temporada siguiente a partir de $name: se copian los equipos y se vuelven a comprobar los jugadores.';
  }

  @override
  String get rolloverCloneStaff => 'Copiar el cuerpo técnico';

  @override
  String get rolloverClonePlayers => 'Copiar las plantillas';

  @override
  String get rolloverConfirm => 'Ejecutar cambio de temporada';

  @override
  String get rolloverDone => 'Cambio de temporada completado';

  @override
  String rolloverClonedTeams(String count) {
    return 'Equipos copiados: $count';
  }

  @override
  String get rolloverOrphansTitle => 'Jugadores sin equipo válido';

  @override
  String get rolloverNoOrphans =>
      'Todos los jugadores siguen siendo elegibles.';

  @override
  String rolloverOrphanLine(String player, String team) {
    return '$player (antes: $team)';
  }

  @override
  String get rolloverGoToCases => 'Ir a los casos de elegibilidad';

  @override
  String rolloverCasesOpened(String count) {
    return 'Casos abiertos: $count';
  }

  @override
  String get categoryNew => 'Nueva categoría';

  @override
  String get categoryEdit => 'Editar categoría';

  @override
  String get categoriesEmpty => 'Aún no hay categorías';

  @override
  String get categoryCode => 'Código';

  @override
  String get categoryName => 'Nombre';

  @override
  String get categoryMaxAge => 'Edad máxima (vacío = sin límite)';

  @override
  String get categoryRank => 'Orden';

  @override
  String get categoryNoLimit => 'Sin límite de edad';

  @override
  String categoryUpTo(String age) {
    return 'Hasta $age años';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return '¿Eliminar la categoría $name?';
  }

  @override
  String get teamsEmpty => 'No hay equipos en esta temporada';

  @override
  String get teamsNoSeason => 'Crea primero una temporada';

  @override
  String get teamsSeason => 'Temporada';

  @override
  String get teamNew => 'Nuevo equipo';

  @override
  String get teamEdit => 'Editar equipo';

  @override
  String get teamName => 'Nombre';

  @override
  String get teamAlias => 'Alias (opcional)';

  @override
  String get teamCategory => 'Categoría';

  @override
  String get teamGenderPolicy => 'Política de género';

  @override
  String get genderPolicyMale => 'Masculino';

  @override
  String get genderPolicyFemale => 'Femenino';

  @override
  String get genderPolicyMixed => 'Mixto';

  @override
  String teamPlayerCount(String count) {
    return '$count jugadores';
  }

  @override
  String get teamStaff => 'Cuerpo técnico';

  @override
  String get teamStaffAdd => 'Añadir entrenador';

  @override
  String get teamStaffNone => 'Sin cuerpo técnico';

  @override
  String teamStaffRemoveConfirm(String name) {
    return '¿Quitar a $name del equipo?';
  }

  @override
  String get teamStaffPick => 'Persona';

  @override
  String get teamStaffRole => 'Función';

  @override
  String get teamRoster => 'Plantilla';

  @override
  String get teamRosterEmpty => 'La plantilla está vacía';

  @override
  String get rosterAssign => 'Asignar jugador';

  @override
  String get rosterSearchPlayer => 'Buscar jugador';

  @override
  String get rosterUnassign => 'Quitar de la plantilla';

  @override
  String rosterUnassignConfirm(String name) {
    return '¿Quitar a $name de la plantilla?';
  }

  @override
  String get rosterJersey => 'Dorsal';

  @override
  String get rosterJerseyEdit => 'Cambiar dorsal';

  @override
  String get rosterAssigned => 'Jugador asignado';

  @override
  String get rosterInvalid => 'Ya no es elegible';

  @override
  String get rosterEligibilityPending => 'Comprobando elegibilidad…';

  @override
  String get eligibilityEligible => 'Elegible';

  @override
  String eligibilityPlayUp(String levels) {
    return 'Juega en categoría superior (+$levels)';
  }

  @override
  String get eligibilityIneligible => 'No elegible';

  @override
  String playUpBadge(String levels) {
    return '+$levels';
  }

  @override
  String get reasonCategoryTooLow => 'Es demasiado mayor para esta categoría';

  @override
  String get reasonPlayUpLimit =>
      'Supera el máximo de niveles de categoría superior';

  @override
  String get reasonGenderPolicy => 'No cumple la política de género del equipo';

  @override
  String get reasonMissingBirthDate => 'Falta la fecha de nacimiento';

  @override
  String get reasonMissingGender => 'Falta el género';

  @override
  String get reasonPlayerNotActive => 'El jugador no está activo';

  @override
  String get playersSearchHint => 'Buscar jugador';

  @override
  String get playersEmpty => 'No hay jugadores con estos filtros';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterTeam => 'Equipo';

  @override
  String get filterCategory => 'Categoría';

  @override
  String get filterClear => 'Quitar filtros';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusOrphan => 'Sin equipo válido';

  @override
  String get statusPendingApproval => 'Pendiente de aprobación';

  @override
  String get statusWithdrawn => 'Baja';

  @override
  String get playerNew => 'Nuevo jugador';

  @override
  String get playerNewRequest => 'Solicitar nuevo jugador';

  @override
  String get playerGivenName => 'Nombre';

  @override
  String get playerFamilyName => 'Apellidos';

  @override
  String get playerBirthDate => 'Fecha de nacimiento';

  @override
  String get playerBirthDateInvalid => 'Fecha de nacimiento no válida';

  @override
  String get playerGender => 'Género';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get playerEmail => 'Correo (opcional)';

  @override
  String get playerInitialTeam => 'Equipo inicial (opcional)';

  @override
  String get playerNote => 'Nota para el administrador (opcional)';

  @override
  String get playerCreated => 'Jugador creado';

  @override
  String get playerRequestSent => 'Solicitud enviada al administrador';

  @override
  String get playerBasics => 'Datos básicos';

  @override
  String get playerNaturalCategory => 'Categoría natural';

  @override
  String get playerGuardians => 'Tutores';

  @override
  String get playerNoGuardians => 'Sin tutores vinculados';

  @override
  String get playerTeams => 'Equipos';

  @override
  String get playerNoTeams => 'Sin equipo';

  @override
  String get playerAssignToTeam => 'Asignar a un equipo';

  @override
  String get playerNoEligibleTeams =>
      'No hay equipos elegibles en la temporada';

  @override
  String get playerWithdraw => 'Dar de baja';

  @override
  String playerWithdrawConfirm(String name) {
    return '¿Dar de baja a $name?';
  }

  @override
  String get playerWithdrawReason => 'Motivo (opcional)';

  @override
  String get playerWithdrawn => 'Jugador dado de baja';

  @override
  String get playerWithdrawRequested => 'Solicitud de baja enviada';

  @override
  String get approvalsTitle => 'Solicitudes';

  @override
  String get approvalsMine => 'Mis solicitudes';

  @override
  String get approvalsEmpty => 'No hay solicitudes';

  @override
  String get approvalActionAdd => 'Alta de jugador';

  @override
  String get approvalActionWithdraw => 'Baja de jugador';

  @override
  String get approvalStatusPending => 'Pendiente';

  @override
  String get approvalStatusApproved => 'Aprobada';

  @override
  String get approvalStatusRejected => 'Rechazada';

  @override
  String get approvalStatusCancelled => 'Cancelada';

  @override
  String approvalRequestedBy(String name) {
    return 'Solicitada por $name';
  }

  @override
  String get approvalApprove => 'Aprobar';

  @override
  String get approvalReject => 'Rechazar';

  @override
  String get approvalCancel => 'Cancelar solicitud';

  @override
  String get approvalCancelConfirm => '¿Cancelar esta solicitud?';

  @override
  String approvalDecisionNote(String note) {
    return 'Nota de la decisión: $note';
  }

  @override
  String get approvalApproved => 'Solicitud aprobada';

  @override
  String get approvalRejected => 'Solicitud rechazada';

  @override
  String get approvalCancelled => 'Solicitud cancelada';

  @override
  String get casesEmpty => 'No hay casos abiertos';

  @override
  String caseTeam(String team) {
    return 'Equipo invalidado: $team';
  }

  @override
  String get caseReassign => 'Reasignar';

  @override
  String caseReassignTitle(String player) {
    return 'Reasignar a $player';
  }

  @override
  String get caseRemoveFromTeam => 'Quitar del equipo';

  @override
  String get caseDismiss => 'Descartar caso';

  @override
  String get caseResolved => 'Caso resuelto';

  @override
  String get casePickTeam => 'Elige el nuevo equipo';

  @override
  String get back => 'Atrás';
}
