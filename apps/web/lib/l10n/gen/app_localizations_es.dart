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
}
