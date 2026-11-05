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
  String get notMemberTitle => 'Todavía no eres miembro de ninguna academia';

  @override
  String notMemberBody(String email) {
    return 'Todavía no eres miembro de ninguna academia. Pide a un administrador de la academia que te añada con este correo: $email';
  }

  @override
  String get notMemberBodyNoEmail =>
      'Todavía no eres miembro de ninguna academia. Pide a un administrador de la academia que te añada con el correo con el que has iniciado sesión.';

  @override
  String timesShownIn(String zone) {
    return 'Las horas se muestran en la zona horaria de la academia: $zone';
  }

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
  String get statusRejected => 'Rechazado';

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

  @override
  String get matchListEmpty => 'No hay partidos';

  @override
  String get matchAllTeams => 'Todos los equipos';

  @override
  String get matchTeam => 'Equipo';

  @override
  String get matchStatusScheduled => 'Programado';

  @override
  String get matchStatusLive => 'En juego';

  @override
  String get matchStatusFinished => 'Finalizado';

  @override
  String get matchStatusCancelled => 'Cancelado';

  @override
  String matchVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchHome => 'Local';

  @override
  String get matchAway => 'Visitante';

  @override
  String get matchUs => 'Nosotros';

  @override
  String get matchCachedData =>
      'Sin conexión: datos guardados en este dispositivo';

  @override
  String get matchNew => 'Nuevo partido';

  @override
  String get matchOpponent => 'Rival';

  @override
  String get matchDate => 'Fecha';

  @override
  String get matchCreated => 'Partido creado';

  @override
  String get matchSetup => 'Convocatoria';

  @override
  String get matchSetupHint => 'Elige jugadores, titulares y dorsales';

  @override
  String get matchStarter => 'Titular';

  @override
  String get matchJersey => 'Dorsal';

  @override
  String get matchSetupSaved => 'Convocatoria guardada';

  @override
  String get matchSetupNoPlayers => 'El equipo no tiene jugadores';

  @override
  String get matchSetupNeedStarter => 'Marca al menos un titular';

  @override
  String matchSetupSummary(int selected, int starters) {
    return '$selected convocados · $starters titulares';
  }

  @override
  String get matchSetupAction => 'Preparar convocatoria';

  @override
  String get matchNoRoster => 'Este partido aún no tiene convocatoria';

  @override
  String get matchTabCourt => 'Pista';

  @override
  String get matchTabLog => 'Jugadas';

  @override
  String get matchTabBox => 'Estadísticas';

  @override
  String matchPeriodShort(int period) {
    return 'P$period';
  }

  @override
  String matchOvertimeShort(int number) {
    return 'PR$number';
  }

  @override
  String get matchBeforeStart => 'Sin empezar';

  @override
  String matchStartPeriod(String period) {
    return 'Iniciar $period';
  }

  @override
  String matchEndPeriod(String period) {
    return 'Terminar $period';
  }

  @override
  String get matchClockStart => 'Poner en marcha el reloj';

  @override
  String get matchClockPause => 'Parar el reloj';

  @override
  String get matchClockMinus => 'Restar 10 segundos';

  @override
  String get matchClockPlus => 'Sumar 10 segundos';

  @override
  String get matchOnCourt => 'En pista';

  @override
  String get matchBench => 'Banquillo';

  @override
  String matchOpponentPoints(int points) {
    return 'Rival +$points';
  }

  @override
  String get matchTimeoutOwn => 'Tiempo muerto';

  @override
  String get matchTimeoutOpponent => 'Tiempo muerto rival';

  @override
  String get matchUndo => 'Deshacer';

  @override
  String get matchUndone => 'Última jugada anulada';

  @override
  String get matchNothingToUndo => 'Nada que deshacer';

  @override
  String matchSubFor(String name) {
    return 'Entra $name por…';
  }

  @override
  String matchStatsFor(String name) {
    return 'Estadística de $name';
  }

  @override
  String matchRecorded(String action, String name) {
    return '$action · $name';
  }

  @override
  String get matchAction2ptMade => '2 PT ✓';

  @override
  String get matchAction2ptMissed => '2 PT ✗';

  @override
  String get matchAction3ptMade => '3 PT ✓';

  @override
  String get matchAction3ptMissed => '3 PT ✗';

  @override
  String get matchActionFtMade => 'TL ✓';

  @override
  String get matchActionFtMissed => 'TL ✗';

  @override
  String get matchActionAssist => 'Asistencia';

  @override
  String get matchActionOreb => 'Rebote ofensivo';

  @override
  String get matchActionDreb => 'Rebote defensivo';

  @override
  String get matchActionSteal => 'Robo';

  @override
  String get matchActionBlock => 'Tapón';

  @override
  String get matchActionTurnover => 'Pérdida';

  @override
  String get matchActionFoulPersonal => 'Falta personal';

  @override
  String get matchActionFoulTechnical => 'Falta técnica';

  @override
  String get matchActionFoulUnsportsmanlike => 'Antideportiva';

  @override
  String matchEvPeriodStart(String period) {
    return 'Empieza $period';
  }

  @override
  String matchEvPeriodEnd(String period) {
    return 'Termina $period';
  }

  @override
  String matchEvSubIn(String name) {
    return 'Entra $name';
  }

  @override
  String matchEvSubOut(String name) {
    return 'Sale $name';
  }

  @override
  String matchEvVoid(String target) {
    return 'Anula: $target';
  }

  @override
  String get matchEvVoidUnknown => 'Anula una jugada';

  @override
  String matchEvNote(String text) {
    return 'Nota: $text';
  }

  @override
  String get matchSyncPending => 'Pendiente';

  @override
  String get matchSyncSent => 'Enviando';

  @override
  String get matchSyncDone => 'Sincronizada';

  @override
  String matchSyncRejected(String reason) {
    return 'Rechazada: $reason';
  }

  @override
  String get matchVoided => 'Anulada';

  @override
  String matchRecordedBy(String name) {
    return 'por $name';
  }

  @override
  String get matchReasonSchema => 'datos no válidos';

  @override
  String get matchReasonNotAuthorized => 'sin permiso';

  @override
  String get matchReasonCancelled => 'partido cancelado';

  @override
  String get matchReasonSeqConflict => 'conflicto de secuencia';

  @override
  String get matchReasonOther => 'rechazada por el servidor';

  @override
  String get matchVoidEvent => 'Anular';

  @override
  String get matchVoidConfirm =>
      '¿Anular esta jugada? Se registrará una anulación.';

  @override
  String get matchDiscard => 'Descartar';

  @override
  String get matchDiscardConfirm =>
      '¿Descartar esta jugada rechazada? No se enviará más.';

  @override
  String matchUnsynced(int count) {
    return '$count sin sincronizar';
  }

  @override
  String matchRejectedCount(int count) {
    return '$count rechazadas';
  }

  @override
  String get matchSyncPausedAuth =>
      'Inicia sesión de nuevo para sincronizar; los datos se conservan';

  @override
  String get matchSyncing => 'Sincronizando…';

  @override
  String get matchParentMode => 'Modo familia: solo tus jugadores';

  @override
  String get matchReadOnly => 'Solo lectura';

  @override
  String get matchStart => 'Empezar partido';

  @override
  String get matchFinish => 'Finalizar partido';

  @override
  String get matchFinishConfirm =>
      '¿Finalizar el partido? Las correcciones seguirán siendo posibles.';

  @override
  String get matchColMin => 'MIN';

  @override
  String get matchColPts => 'PTS';

  @override
  String get matchColReb => 'REB';

  @override
  String get matchColAst => 'AST';

  @override
  String get matchColStl => 'ROB';

  @override
  String get matchColBlk => 'TAP';

  @override
  String get matchColTov => 'PÉR';

  @override
  String get matchColPf => 'FP';

  @override
  String get matchColFg => 'TC';

  @override
  String get matchCol3p => 'T3';

  @override
  String get matchColFt => 'TL';

  @override
  String get matchTotals => 'Total equipo';

  @override
  String get matchPeriodScores => 'Parciales';

  @override
  String matchWarnings(int count) {
    return '$count avisos de coherencia (corrige con Anular)';
  }

  @override
  String get matchCopy => 'Copiar resultado';

  @override
  String get matchCopied => 'Resultado copiado';

  @override
  String matchShareLine(String name, int points, int rebounds, int assists) {
    return '$name: $points pts, $rebounds reb, $assists ast';
  }

  @override
  String get seasonStatsTitle => 'Estadísticas de temporada';

  @override
  String seasonStatsGames(int played, int started) {
    return '$played partidos · $started de titular';
  }

  @override
  String get seasonStatsAverages => 'Promedios por partido';

  @override
  String get seasonStatsTotals => 'Totales';

  @override
  String get seasonStatsMatches => 'Partidos';

  @override
  String get seasonStatsEmpty => 'Sin partidos en esta temporada';

  @override
  String get seasonStatsPoints => 'Puntos';

  @override
  String get seasonStatsRebounds => 'Rebotes';

  @override
  String get seasonStatsAssists => 'Asistencias';

  @override
  String get seasonStatsMinutes => 'Minutos';

  @override
  String get seasonStatsSeason => 'Temporada';

  @override
  String get trainingTitle => 'Entrenamientos';

  @override
  String trainingWeekOf(String range) {
    return 'Semana del $range';
  }

  @override
  String get trainingToday => 'Hoy';

  @override
  String get trainingPrevWeek => 'Semana anterior';

  @override
  String get trainingNextWeek => 'Semana siguiente';

  @override
  String get trainingAllTeams => 'Todos los equipos';

  @override
  String get trainingNoSessions => 'No hay entrenamientos esta semana';

  @override
  String get trainingNoSessionsDay => 'Sin sesiones';

  @override
  String get trainingMenuPlans => 'Planes';

  @override
  String get trainingMenuSchedules => 'Horarios';

  @override
  String get trainingMenuAbsences => 'Ausencias';

  @override
  String get trainingMenuAssignments => 'Asignaciones';

  @override
  String get sessionStatusPlanned => 'Prevista';

  @override
  String get sessionStatusDone => 'Realizada';

  @override
  String get sessionStatusCancelled => 'Cancelada';

  @override
  String get sessionDetailTitle => 'Sesión de entrenamiento';

  @override
  String sessionTimeRange(String end, String start) {
    return '$start – $end';
  }

  @override
  String get sessionLocation => 'Lugar';

  @override
  String get sessionNoLocation => 'Sin lugar indicado';

  @override
  String get sessionPlan => 'Plan';

  @override
  String get sessionNoPlan => 'Sin plan asignado';

  @override
  String get sessionEdit => 'Editar sesión';

  @override
  String get sessionUpdated => 'Sesión actualizada';

  @override
  String get sessionNotes => 'Notas';

  @override
  String sessionCancelReasonLine(String reason) {
    return 'Cancelada: $reason';
  }

  @override
  String get sessionNew => 'Nueva sesión';

  @override
  String get sessionTeam => 'Equipo';

  @override
  String get sessionDate => 'Fecha';

  @override
  String get sessionStartTime => 'Hora de inicio';

  @override
  String get sessionDuration => 'Duración (min)';

  @override
  String sessionDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sessionCancel => 'Cancelar sesión';

  @override
  String get sessionCancelReason => 'Motivo de la cancelación';

  @override
  String get sessionCreated => 'Sesión creada';

  @override
  String get sessionCancelled => 'Sesión cancelada';

  @override
  String get attendanceTitle => 'Asistencia';

  @override
  String get attendancePresent => 'Presente';

  @override
  String get attendanceLate => 'Tarde';

  @override
  String get attendanceAbsent => 'Ausente';

  @override
  String get attendanceExcused => 'Justificada';

  @override
  String get attendanceMinutesLate => 'Minutos de retraso';

  @override
  String get attendanceExpectedAbsent => 'Ausencia prevista';

  @override
  String get attendanceInjured => 'Lesionado';

  @override
  String get attendanceNotRecorded => 'Sin registrar';

  @override
  String get attendanceSave => 'Guardar asistencia';

  @override
  String get attendanceSaved => 'Asistencia guardada';

  @override
  String get attendanceEmpty => 'El equipo no tiene jugadores';

  @override
  String get attendanceMinutesInvalid => 'Minutos entre 1 y 180';

  @override
  String get scheduleTitle => 'Horarios de entrenamiento';

  @override
  String get scheduleNew => 'Nuevo horario';

  @override
  String get scheduleEdit => 'Editar horario';

  @override
  String get scheduleEmpty => 'Aún no hay horarios';

  @override
  String get scheduleDay => 'Día de la semana';

  @override
  String get scheduleTime => 'Hora (HH:MM)';

  @override
  String get scheduleTimeInvalid => 'Usa el formato HH:MM';

  @override
  String get scheduleValidFrom => 'Válido desde';

  @override
  String get scheduleValidUntil => 'Válido hasta';

  @override
  String get scheduleNoEnd => 'Sin fecha de fin';

  @override
  String get scheduleDatesInvalid =>
      'La fecha final debe ser posterior a la inicial';

  @override
  String scheduleLine(String day, int minutes, String time) {
    return '$day $time · $minutes min';
  }

  @override
  String scheduleValidity(String from) {
    return 'Desde $from';
  }

  @override
  String scheduleValidityRange(String from, String to) {
    return '$from a $to';
  }

  @override
  String get scheduleDeleteConfirm =>
      '¿Eliminar este horario? Se quitarán las sesiones futuras sin cambios.';

  @override
  String get dayMonday => 'Lunes';

  @override
  String get dayTuesday => 'Martes';

  @override
  String get dayWednesday => 'Miércoles';

  @override
  String get dayThursday => 'Jueves';

  @override
  String get dayFriday => 'Viernes';

  @override
  String get daySaturday => 'Sábado';

  @override
  String get daySunday => 'Domingo';

  @override
  String get absenceTitle => 'Ausencias previstas';

  @override
  String get absenceNew => 'Nueva ausencia';

  @override
  String get absencePlayer => 'Jugador';

  @override
  String get absenceFrom => 'Desde';

  @override
  String get absenceTo => 'Hasta';

  @override
  String get absenceReason => 'Motivo (opcional)';

  @override
  String get absenceEmpty => 'No hay ausencias previstas';

  @override
  String get absenceDatesInvalid =>
      'La fecha final no puede ser anterior a la inicial';

  @override
  String get absenceDeleteConfirm => '¿Eliminar esta ausencia?';

  @override
  String absenceRange(String from, String to) {
    return '$from → $to';
  }

  @override
  String get absenceSaved => 'Ausencia registrada';

  @override
  String get planLibraryTitle => 'Planes de entrenamiento';

  @override
  String get planTemplates => 'Plantillas';

  @override
  String get planMine => 'Mis planes';

  @override
  String get planSearchHint => 'Buscar planes';

  @override
  String get planEmptyTemplates => 'No hay plantillas';

  @override
  String get planEmptyMine =>
      'Aún no hay planes propios. Crea uno o usa una plantilla.';

  @override
  String planSummary(int count, int minutes) {
    return '$count ejercicios · $minutes min';
  }

  @override
  String get planNew => 'Nuevo plan';

  @override
  String get planName => 'Nombre del plan';

  @override
  String get planDescription => 'Descripción (opcional)';

  @override
  String get planUse => 'Usar plantilla';

  @override
  String get planCopied => 'Plantilla copiada a tus planes';

  @override
  String get planTemplateReadOnly =>
      'Plantilla de solo lectura: cópiala para editarla.';

  @override
  String get planItems => 'Ejercicios';

  @override
  String get planNoItems => 'Este plan aún no tiene ejercicios';

  @override
  String get planItemAdd => 'Añadir ejercicio';

  @override
  String get planItemEdit => 'Editar ejercicio';

  @override
  String get planItemTitle => 'Título';

  @override
  String get planItemDuration => 'Duración (min)';

  @override
  String get planItemSets => 'Series';

  @override
  String get planItemReps => 'Repeticiones';

  @override
  String get planItemVideo => 'Enlace de vídeo (https)';

  @override
  String get planItemVideoInvalid => 'Debe empezar por https://';

  @override
  String planItemSetsReps(int reps, int sets) {
    return '$sets × $reps';
  }

  @override
  String get planItemMoveUp => 'Subir';

  @override
  String get planItemMoveDown => 'Bajar';

  @override
  String get planItemDeleteConfirm => '¿Quitar este ejercicio?';

  @override
  String get planDeleteConfirm => '¿Eliminar este plan?';

  @override
  String get planAssign => 'Asignar';

  @override
  String get planWatchVideo => 'Ver vídeo';

  @override
  String get assignTitle => 'Asignar plan';

  @override
  String get assignTarget => 'Destinatario';

  @override
  String get assignToTeam => 'Un equipo';

  @override
  String get assignToPlayer => 'Un jugador';

  @override
  String get assignDue => 'Fecha límite';

  @override
  String get assignDone => 'Plan asignado';

  @override
  String get assignmentsTitle => 'Planes asignados';

  @override
  String get assignmentsEmpty => 'No hay planes asignados';

  @override
  String assignmentDue(String date) {
    return 'Vence el $date';
  }

  @override
  String assignmentProgress(int done, int notDone, int partial) {
    return '$done hechos · $partial parciales · $notDone no hechos';
  }

  @override
  String get assignmentDeleteConfirm => '¿Quitar esta asignación y sus marcas?';

  @override
  String get assignmentProgressTitle => 'Progreso';

  @override
  String assignmentTeamTarget(String name) {
    return 'Equipo: $name';
  }

  @override
  String get assignmentPlayerTarget => 'Jugador';

  @override
  String get completionDone => 'Hecho';

  @override
  String get completionPartial => 'Parcial';

  @override
  String get completionNotDone => 'No hecho';

  @override
  String get completionNone => 'Sin marcar';

  @override
  String get completionComment => 'Comentario (opcional)';

  @override
  String get completionMark => 'Marcar';

  @override
  String get completionSaved => 'Marca guardada';

  @override
  String get healthTitle => 'Salud y forma';

  @override
  String get healthInjuries => 'Lesiones';

  @override
  String get healthGrowth => 'Crecimiento';

  @override
  String get healthTests => 'Pruebas físicas';

  @override
  String get injuryNew => 'Registrar lesión';

  @override
  String get injuryBodyPart => 'Zona del cuerpo';

  @override
  String get injurySeverity => 'Gravedad';

  @override
  String get severityMinor => 'Leve';

  @override
  String get severityModerate => 'Moderada';

  @override
  String get severitySevere => 'Grave';

  @override
  String get injuryOccurredOn => 'Fecha de la lesión';

  @override
  String get injuryExpectedReturn => 'Regreso previsto';

  @override
  String get injuryDescription => 'Descripción (opcional)';

  @override
  String get injuryStatusOpen => 'Abierta';

  @override
  String get injuryStatusRecovered => 'Recuperada';

  @override
  String get injuryRecover => 'Marcar recuperada';

  @override
  String get injuryRecoveredOn => 'Fecha de regreso';

  @override
  String get injuryUpdateReturn => 'Cambiar regreso previsto';

  @override
  String get injuryEmpty => 'Sin lesiones registradas';

  @override
  String injuryReturnLine(String date) {
    return 'Regreso previsto: $date';
  }

  @override
  String injuryRecoveredLine(String date) {
    return 'Recuperada el $date';
  }

  @override
  String get injurySaved => 'Lesión guardada';

  @override
  String get availabilityAvailable => 'Disponible';

  @override
  String availabilityInjured(String bodyPart) {
    return 'Lesionado: $bodyPart';
  }

  @override
  String get growthHeight => 'Altura (cm)';

  @override
  String get growthWeight => 'Peso (kg)';

  @override
  String get growthEdit => 'Editar medida';

  @override
  String get testEdit => 'Editar resultado';

  @override
  String get measurementDeleteConfirm => '¿Eliminar esta medida?';

  @override
  String get resultDeleteConfirm => '¿Eliminar este resultado?';

  @override
  String get growthAdd => 'Añadir medida';

  @override
  String get growthMeasuredOn => 'Fecha de la medida';

  @override
  String get growthEmpty => 'Sin medidas todavía';

  @override
  String get growthNeedOne => 'Indica altura, peso o ambos';

  @override
  String get growthShowTable => 'Ver tabla';

  @override
  String get growthHideTable => 'Ocultar tabla';

  @override
  String get growthDeleteConfirm => '¿Eliminar esta medida?';

  @override
  String chartSummary(int count, String name, String value) {
    return 'Gráfico de $name: $count medidas, la última $value';
  }

  @override
  String get chartNoData => 'Sin datos para el gráfico';

  @override
  String get chartDate => 'Fecha';

  @override
  String get chartValue => 'Valor';

  @override
  String get testAdd => 'Registrar resultado';

  @override
  String get testType => 'Prueba';

  @override
  String get testValue => 'Valor';

  @override
  String get testNotes => 'Notas (opcional)';

  @override
  String get testMeasuredOn => 'Fecha de la prueba';

  @override
  String get bandPoor => 'Muy bajo';

  @override
  String get bandBelowAverage => 'Bajo la media';

  @override
  String get bandAverage => 'Medio';

  @override
  String get bandAboveAverage => 'Sobre la media';

  @override
  String get bandExcellent => 'Excelente';

  @override
  String testExpectedBand(String band) {
    return 'Banda esperada: $band';
  }

  @override
  String get testNoBand => 'Sin norma para esta edad y género';

  @override
  String get testReferencePending => 'Referencia pendiente';

  @override
  String testSavedBand(String band) {
    return 'Resultado guardado. Banda: $band';
  }

  @override
  String get testSavedNoBand => 'Resultado guardado (sin norma aplicable)';

  @override
  String get testEmpty => 'Sin resultados de pruebas';

  @override
  String get testChartLegend => 'Bandas esperadas';

  @override
  String testAtAge(int age) {
    return '$age años';
  }

  @override
  String testResultLine(String unit, String value) {
    return '$value $unit';
  }

  @override
  String get testDeleteConfirm => '¿Eliminar este resultado?';

  @override
  String get testTypesTitle => 'Tipos de prueba';

  @override
  String get testTypeNew => 'Nueva prueba personalizada';

  @override
  String get testTypeCode => 'Código';

  @override
  String get testTypeName => 'Nombre';

  @override
  String get testTypeUnit => 'Unidad';

  @override
  String get testTypeHigher => 'Un valor mayor es mejor';

  @override
  String get testTypeGlobal => 'Global';

  @override
  String get testTypeCustom => 'De la academia';

  @override
  String get testTypesEmpty => 'No hay tipos de prueba';

  @override
  String get testTypeHigherYes => 'Más es mejor';

  @override
  String get testTypeHigherNo => 'Menos es mejor';

  @override
  String get normsTitle => 'Normas de referencia';

  @override
  String get normsScopeEffective => 'Efectivas';

  @override
  String get normsScopeGlobal => 'Globales';

  @override
  String get normsScopeTenant => 'De la academia';

  @override
  String get normNew => 'Nueva norma';

  @override
  String get normEdit => 'Editar norma';

  @override
  String get normGender => 'Género';

  @override
  String get normMinAge => 'Edad mínima';

  @override
  String get normMaxAge => 'Edad máxima';

  @override
  String get normBand => 'Banda';

  @override
  String get normMinValue => 'Valor mínimo';

  @override
  String get normMaxValue => 'Valor máximo';

  @override
  String get normSource => 'Fuente';

  @override
  String normAges(int max, int min) {
    return '$min–$max años';
  }

  @override
  String normValues(String low, String high) {
    return '$low a $high';
  }

  @override
  String normValuesFrom(String low) {
    return 'desde $low';
  }

  @override
  String normValuesUpTo(String high) {
    return 'hasta $high';
  }

  @override
  String get normGlobalReadOnly => 'Global (solo lectura)';

  @override
  String get normOverride => 'Propia de la academia';

  @override
  String get normEmpty => 'No hay normas con este filtro';

  @override
  String get normDeleteConfirm => '¿Eliminar esta norma?';

  @override
  String get normAgesInvalid =>
      'La edad máxima debe ser mayor o igual que la mínima';

  @override
  String get normAllTests => 'Todas las pruebas';

  @override
  String get healthMenuTests => 'Tipos de prueba';

  @override
  String get healthMenuNorms => 'Normas';

  @override
  String get meTitle => 'Mi perfil deportivo';

  @override
  String get meSeasonStats => 'Estadísticas de la temporada';

  @override
  String get meUpcoming => 'Próximos entrenamientos';

  @override
  String get meNoUpcoming => 'No hay entrenamientos próximos';

  @override
  String get meTabTraining => 'Entrenos';

  @override
  String get meTabPlans => 'Planes';

  @override
  String get meNoPlayer => 'Tu cuenta aún no está vinculada a un jugador';

  @override
  String get myPlayersTitle => 'Mis jugadores';

  @override
  String get myPlayersEmpty => 'No tienes jugadores vinculados';

  @override
  String get profilePlatform => 'Consola de plataforma';

  @override
  String get mePlansEmpty => 'Sin planes asignados';

  @override
  String get platformTitle => 'Plataforma';

  @override
  String get platformSearchHint => 'Buscar por nombre o identificador';

  @override
  String get platformEmpty => 'No hay academias con este filtro';

  @override
  String get platformNew => 'Nueva academia';

  @override
  String get tenantName => 'Nombre de la academia';

  @override
  String get tenantSlug => 'Identificador (slug)';

  @override
  String get tenantSlugInvalid => 'Solo minúsculas, números y guiones (3-50)';

  @override
  String get tenantTimezone => 'Zona horaria';

  @override
  String get tenantLocale => 'Idioma';

  @override
  String get tenantAdminEmail => 'Correo del primer administrador';

  @override
  String get tenantAdminGivenName => 'Nombre del administrador';

  @override
  String get tenantAdminFamilyName => 'Apellidos del administrador';

  @override
  String get tenantStatusActive => 'Activa';

  @override
  String get tenantStatusSuspended => 'Suspendida';

  @override
  String get tenantStatusWithdrawn => 'Retirada';

  @override
  String get tenantCreated => 'Academia creada';

  @override
  String get tenantSuspend => 'Suspender';

  @override
  String get tenantWithdraw => 'Retirar';

  @override
  String get tenantReactivate => 'Reactivar';

  @override
  String get tenantReason => 'Motivo';

  @override
  String get tenantSuspendTitle => 'Suspender la academia';

  @override
  String get tenantWithdrawTitle => 'Retirar la academia';

  @override
  String get tenantWithdrawWarning =>
      'Al retirar una academia comienza el plazo de conservación de datos.';

  @override
  String get tenantUpdated => 'Estado actualizado';

  @override
  String tenantCreatedOn(String date) {
    return 'Creada el $date';
  }

  @override
  String tenantRetainUntil(String date) {
    return 'Datos conservados hasta $date';
  }

  @override
  String get usageTitle => 'Uso';

  @override
  String usageUnavailable(String services) {
    return 'Sin datos de: $services';
  }

  @override
  String usageLastActivity(String date) {
    return 'Última actividad: $date';
  }

  @override
  String get usageTrendTitle => 'Evolución del uso';

  @override
  String get usageTrendEmpty => 'Todavía no hay datos de uso';

  @override
  String get usageFailed => 'No se pudo cargar el uso';

  @override
  String get usageServiceCore => 'Núcleo';

  @override
  String get usageServiceGame => 'Partidos';

  @override
  String get usageServiceAthlete => 'Deportistas';

  @override
  String get usageCounter_members => 'Miembros';

  @override
  String get usageCounter_players => 'Jugadores';

  @override
  String get usageCounter_activePlayers => 'Jugadores activos';

  @override
  String get usageCounter_teams => 'Equipos';

  @override
  String get usageCounter_seasons => 'Temporadas';

  @override
  String get usageCounter_matches => 'Partidos';

  @override
  String get usageCounter_liveMatches => 'Partidos en vivo';

  @override
  String get usageCounter_matchEvents => 'Eventos de partido';

  @override
  String get usageCounter_matchEventsLast30Days => 'Eventos (30 días)';

  @override
  String get usageCounter_trainingSessions => 'Sesiones de entreno';

  @override
  String get usageCounter_attendanceRecords => 'Registros de asistencia';

  @override
  String get usageCounter_trainingPlans => 'Planes';

  @override
  String get usageCounter_physicalTestResults => 'Resultados de pruebas';

  @override
  String get usageCounter_injuries => 'Lesiones';

  @override
  String get usageCounter_bodyMeasurements => 'Medidas corporales';

  @override
  String get signOutUnsyncedTitle => 'Hay eventos sin sincronizar';

  @override
  String signOutUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count eventos de partido sin sincronizar',
      one: 'Hay 1 evento de partido sin sincronizar',
    );
    return '$_temp0 en este dispositivo. Si cierras sesión ahora se perderán para siempre. Conéctate y espera a que se sincronicen, o cierra sesión y descártalos.';
  }

  @override
  String get signOutAnyway => 'Cerrar sesión y descartar';

  @override
  String get updateAvailable => 'Hay una nueva versión disponible';

  @override
  String get updateReload => 'Recargar';

  @override
  String get adminsTitle => 'Administradores';

  @override
  String get adminsAdd => 'Añadir administrador';

  @override
  String get adminsEmpty => 'Esta academia no tiene administradores activos';

  @override
  String get adminsLoadFailed => 'No se pudieron cargar los administradores';

  @override
  String get adminInvitationAccepted => 'Invitación aceptada';

  @override
  String adminOtherRoles(String roles) {
    return 'También: $roles';
  }

  @override
  String get adminEdit => 'Editar administrador';

  @override
  String get adminRemove => 'Quitar administrador';

  @override
  String get adminAddHint =>
      'Si ya hay un miembro activo con este correo, pasa a ser administrador y conserva su nombre. Si no, se crea su acceso y verás una contraseña temporal para entregársela; no se envía ningún correo.';

  @override
  String get adminAddSubmit => 'Añadir';

  @override
  String get adminEditEmailNote =>
      'El correo es también el acceso de la persona: si lo cambias, entrará con la nueva dirección y mantiene su contraseña.';

  @override
  String adminRemoveConfirm(String name) {
    return '¿Quitar a $name como administrador? Se elimina el rol de administrador; los demás roles se mantienen.';
  }

  @override
  String get adminRemoveSubmit => 'Quitar';

  @override
  String get adminLastAdminNote =>
      'Una academia necesita al menos un administrador. Añade otro administrador antes de quitar a este.';

  @override
  String get adminAdded => 'Administrador añadido';

  @override
  String get adminUpdated => 'Administrador actualizado';

  @override
  String get adminRemoved => 'Administrador quitado';

  @override
  String get adminsWithdrawn =>
      'La academia está retirada: sus administradores ya no se pueden consultar ni modificar.';

  @override
  String get adminErrorEmailTaken =>
      'Ese correo ya lo usa otra persona o cuenta';

  @override
  String get adminErrorLoginAlreadyMember =>
      'Esa cuenta de acceso ya pertenece a otro miembro de esta academia';

  @override
  String get adminErrorIdentityProvider =>
      'El servicio de acceso no está disponible. Inténtalo de nuevo en unos minutos.';

  @override
  String get adminErrorInvitationNotPending =>
      'La invitación ya no está pendiente';

  @override
  String get tempPasswordTitle => 'Contraseña temporal';

  @override
  String tempPasswordFor(String person) {
    return 'Cuenta de $person';
  }

  @override
  String tempPasswordLoginWith(String email) {
    return 'Correo de acceso: $email';
  }

  @override
  String get tempPasswordShareHint =>
      'Entrégasela a la persona por un canal privado. No se envía ningún correo.';

  @override
  String get tempPasswordShownOnce =>
      'Solo se muestra ahora: no se guarda y no se puede volver a ver. Si se pierde, genera una nueva mientras la persona no haya entrado.';

  @override
  String get tempPasswordFirstSignIn =>
      'En su primer acceso entra con su correo y esta contraseña, y debe elegir la suya.';

  @override
  String get tempPasswordCopy => 'Copiar contraseña';

  @override
  String get tempPasswordCopied => 'Contraseña copiada';

  @override
  String get tempPasswordDone => 'Hecho';

  @override
  String get tempPasswordExistingLogin =>
      'Ya tenía una cuenta: entra con su contraseña actual.';

  @override
  String get tempPasswordIssue => 'Generar nueva contraseña temporal';

  @override
  String get tempPasswordExpired => 'Contraseña temporal caducada';

  @override
  String get memberAdded => 'Miembro añadido';

  @override
  String get memberInviteHint =>
      'No se envía ningún correo: al crear su acceso verás una contraseña temporal para entregársela a la persona.';

  @override
  String get memberErrorNotPending =>
      'Esta persona ya entró o la invitación ya no está pendiente';

  @override
  String get memberErrorLoginShared =>
      'Esta cuenta de acceso se usa también en otra academia: solo la administración de la plataforma puede generar su contraseña';

  @override
  String get playerEmailHint =>
      'Con correo, el jugador tendrá acceso: verás una contraseña temporal para entregársela.';

  @override
  String get adminActivity => 'Actividad';

  @override
  String get platformActivity => 'Actividad de las academias';

  @override
  String get auditTitle => 'Actividad';

  @override
  String get auditAnyTime => 'Cualquier fecha';

  @override
  String get auditClearRange => 'Quitar fechas';

  @override
  String get auditAllActions => 'Todas las acciones';

  @override
  String auditSelectedActions(int count) {
    return '$count acciones';
  }

  @override
  String get auditFilterTitle => 'Filtrar por acción';

  @override
  String get auditApply => 'Aplicar';

  @override
  String get auditEmpty => 'No hay actividad con este filtro';

  @override
  String auditPageOf(int page, int pages) {
    return 'Página $page de $pages';
  }

  @override
  String get auditPreviousPage => 'Página anterior';

  @override
  String get auditNextPage => 'Página siguiente';

  @override
  String auditByActor(String actor) {
    return 'Por $actor';
  }

  @override
  String get auditActorSystem => 'Sistema';

  @override
  String get auditActorPlatform => 'Administración de la plataforma';

  @override
  String get auditActorMember => 'Miembro de la academia';

  @override
  String get auditTargetPerson => 'Persona';

  @override
  String get auditTargetPlayer => 'Jugador/a';

  @override
  String get auditTargetTenant => 'Academia';

  @override
  String get auditTargetApprovalRequest => 'Solicitud';

  @override
  String get auditTargetGuardianLink => 'Vínculo familiar';

  @override
  String get auditActionAdminAdded => 'Administrador añadido';

  @override
  String get auditActionAdminRemoved => 'Administrador retirado';

  @override
  String get auditActionAdminTemporaryPasswordIssued =>
      'Contraseña temporal de administrador generada';

  @override
  String get auditActionAdminUpdated => 'Administrador editado';

  @override
  String get auditActionApprovalCancelled => 'Solicitud cancelada';

  @override
  String get auditActionGuardianLinkCreated => 'Vínculo familiar creado';

  @override
  String get auditActionGuardianLinkRemoved => 'Vínculo familiar eliminado';

  @override
  String get auditActionMemberDeactivated => 'Miembro desactivado';

  @override
  String get auditActionMemberInvitationAccepted => 'Primer inicio de sesión';

  @override
  String get auditActionMemberInvited => 'Miembro invitado';

  @override
  String get auditActionMemberLoginEmailChanged => 'Correo de acceso cambiado';

  @override
  String get auditActionMemberRolesReplaced => 'Roles cambiados';

  @override
  String get auditActionMemberTemporaryPasswordExpired =>
      'Contraseña temporal caducada';

  @override
  String get auditActionMemberTemporaryPasswordIssued =>
      'Contraseña temporal generada';

  @override
  String get auditActionMemberUpdated => 'Miembro editado';

  @override
  String get auditActionPlayerApproved => 'Jugador aprobado';

  @override
  String get auditActionPlayerRejected => 'Jugador rechazado';

  @override
  String get auditActionPlayerRequested => 'Alta de jugador solicitada';

  @override
  String get auditActionPlayerWithdrawn => 'Jugador dado de baja';

  @override
  String get auditActionTenantCreated => 'Academia creada';

  @override
  String get auditActionTenantLogoRemoved => 'Logo eliminado';

  @override
  String get auditActionTenantLogoReplaced => 'Logo cambiado';

  @override
  String get auditActionTenantMasterDataChanged =>
      'Datos de la academia cambiados por la plataforma';

  @override
  String get auditActionTenantProfileChanged =>
      'Perfil de la academia cambiado';

  @override
  String get auditActionTenantReactivated => 'Academia reactivada';

  @override
  String get auditActionTenantSettingsChanged => 'Ajustes cambiados';

  @override
  String get auditActionTenantSuspended => 'Academia suspendida';

  @override
  String get auditActionTenantWithdrawn => 'Academia dada de baja';
}
