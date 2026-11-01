import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('id'),
  ];

  /// Nombre de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Hoops Academy'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Accede con tu cuenta de la academia'**
  String get signInSubtitle;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @signedInAs.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada como {name}'**
  String signedInAs(String name);

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Los datos pueden no estar actualizados.'**
  String get offlineBanner;

  /// No description provided for @mockModeBanner.
  ///
  /// In es, this message translates to:
  /// **'Modo demo: datos de ejemplo, sin servidor'**
  String get mockModeBanner;

  /// No description provided for @navAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navTeams.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get navTeams;

  /// No description provided for @navMatches.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get navMatches;

  /// No description provided for @navTraining.
  ///
  /// In es, this message translates to:
  /// **'Entrenos'**
  String get navTraining;

  /// No description provided for @navPlayers.
  ///
  /// In es, this message translates to:
  /// **'Jugadores'**
  String get navPlayers;

  /// No description provided for @navMyPlayers.
  ///
  /// In es, this message translates to:
  /// **'Mis jugadores'**
  String get navMyPlayers;

  /// No description provided for @navMe.
  ///
  /// In es, this message translates to:
  /// **'Yo'**
  String get navMe;

  /// No description provided for @navPlatform.
  ///
  /// In es, this message translates to:
  /// **'Plataforma'**
  String get navPlatform;

  /// No description provided for @placeholderModule.
  ///
  /// In es, this message translates to:
  /// **'{module}: próximamente'**
  String placeholderModule(String module);

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageName_es.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageName_es;

  /// No description provided for @languageName_en.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageName_en;

  /// No description provided for @languageName_id.
  ///
  /// In es, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageName_id;

  /// No description provided for @academy.
  ///
  /// In es, this message translates to:
  /// **'Academia'**
  String get academy;

  /// No description provided for @switchAcademy.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de academia'**
  String get switchAcademy;

  /// No description provided for @chooseAcademyTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu academia'**
  String get chooseAcademyTitle;

  /// No description provided for @chooseAcademySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Perteneces a varias academias. ¿Con cuál quieres trabajar?'**
  String get chooseAcademySubtitle;

  /// No description provided for @rolesInAcademy.
  ///
  /// In es, this message translates to:
  /// **'Roles: {roles}'**
  String rolesInAcademy(String roles);

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// No description provided for @roleCoach.
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get roleCoach;

  /// No description provided for @roleAssistantCoach.
  ///
  /// In es, this message translates to:
  /// **'Entrenador asistente'**
  String get roleAssistantCoach;

  /// No description provided for @roleParent.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get roleParent;

  /// No description provided for @rolePlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get rolePlayer;

  /// No description provided for @noAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a ninguna academia'**
  String get noAccessTitle;

  /// No description provided for @noAccessBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta aún no pertenece a ninguna academia. Pide a un administrador que te invite.'**
  String get noAccessBody;

  /// No description provided for @profileLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar tu perfil'**
  String get profileLoadFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión con el servidor. Revisa tu red e inténtalo de nuevo.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In es, this message translates to:
  /// **'El servidor tarda demasiado en responder. Inténtalo de nuevo.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Inicia sesión de nuevo.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para hacer esto.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hemos encontrado lo que buscas.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In es, this message translates to:
  /// **'Los datos han cambiado. Actualiza e inténtalo de nuevo.'**
  String get errorConflict;

  /// No description provided for @errorValidation.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos introducidos.'**
  String get errorValidation;

  /// No description provided for @errorServer.
  ///
  /// In es, this message translates to:
  /// **'El servidor ha tenido un problema. Inténtalo más tarde.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error inesperado.'**
  String get errorUnknown;

  /// No description provided for @errorReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia: {traceId}'**
  String errorReference(String traceId);

  /// No description provided for @emptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por aquí todavía'**
  String get emptyTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get remove;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @none.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get none;

  /// No description provided for @saved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get saved;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get fieldRequired;

  /// No description provided for @fieldInvalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido'**
  String get fieldInvalidNumber;

  /// No description provided for @fieldInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get fieldInvalidEmail;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @noteOptional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get noteOptional;

  /// No description provided for @noteRequired.
  ///
  /// In es, this message translates to:
  /// **'Nota (obligatoria)'**
  String get noteRequired;

  /// No description provided for @readOnlyHint.
  ///
  /// In es, this message translates to:
  /// **'Solo lectura: no tienes permiso para modificar esto.'**
  String get readOnlyHint;

  /// No description provided for @moreActions.
  ///
  /// In es, this message translates to:
  /// **'Más acciones'**
  String get moreActions;

  /// No description provided for @adminTitle.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get adminTitle;

  /// No description provided for @adminAcademyProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de la academia'**
  String get adminAcademyProfile;

  /// No description provided for @adminMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get adminMembers;

  /// No description provided for @adminSeasons.
  ///
  /// In es, this message translates to:
  /// **'Temporadas'**
  String get adminSeasons;

  /// No description provided for @adminAgeCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías de edad'**
  String get adminAgeCategories;

  /// No description provided for @adminApprovals.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes pendientes'**
  String get adminApprovals;

  /// No description provided for @adminCases.
  ///
  /// In es, this message translates to:
  /// **'Casos de elegibilidad'**
  String get adminCases;

  /// No description provided for @academyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la academia'**
  String get academyName;

  /// No description provided for @academyTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria (p. ej. Europe/Madrid)'**
  String get academyTimezone;

  /// No description provided for @academyAgeRule.
  ///
  /// In es, this message translates to:
  /// **'Regla de edad'**
  String get academyAgeRule;

  /// No description provided for @ageRuleBirthYear.
  ///
  /// In es, this message translates to:
  /// **'Por año de nacimiento'**
  String get ageRuleBirthYear;

  /// No description provided for @ageRuleBirthday.
  ///
  /// In es, this message translates to:
  /// **'Por fecha de nacimiento'**
  String get ageRuleBirthday;

  /// No description provided for @academyMaxPlayUp.
  ///
  /// In es, this message translates to:
  /// **'Niveles máximos de categoría superior'**
  String get academyMaxPlayUp;

  /// No description provided for @academyDefaultLocale.
  ///
  /// In es, this message translates to:
  /// **'Idioma por defecto'**
  String get academyDefaultLocale;

  /// No description provided for @logoTitle.
  ///
  /// In es, this message translates to:
  /// **'Logo'**
  String get logoTitle;

  /// No description provided for @logoHint.
  ///
  /// In es, this message translates to:
  /// **'PNG, JPEG o WebP, máximo 512 KB'**
  String get logoHint;

  /// No description provided for @logoChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir imagen'**
  String get logoChoose;

  /// No description provided for @logoUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir logo'**
  String get logoUpload;

  /// No description provided for @logoRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar logo'**
  String get logoRemove;

  /// No description provided for @logoRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el logo de la academia?'**
  String get logoRemoveConfirm;

  /// No description provided for @logoPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get logoPreview;

  /// No description provided for @logoNone.
  ///
  /// In es, this message translates to:
  /// **'Sin logo'**
  String get logoNone;

  /// No description provided for @logoUploaded.
  ///
  /// In es, this message translates to:
  /// **'Logo actualizado'**
  String get logoUploaded;

  /// No description provided for @logoRemoved.
  ///
  /// In es, this message translates to:
  /// **'Logo eliminado'**
  String get logoRemoved;

  /// No description provided for @logoErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen supera los 512 KB.'**
  String get logoErrorTooLarge;

  /// No description provided for @logoErrorWrongType.
  ///
  /// In es, this message translates to:
  /// **'Formato no válido: usa PNG, JPEG o WebP.'**
  String get logoErrorWrongType;

  /// No description provided for @logoErrorEmpty.
  ///
  /// In es, this message translates to:
  /// **'El archivo está vacío.'**
  String get logoErrorEmpty;

  /// No description provided for @membersSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o correo'**
  String get membersSearchHint;

  /// No description provided for @membersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay miembros'**
  String get membersEmpty;

  /// No description provided for @memberInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get memberInvite;

  /// No description provided for @memberInviteTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar a un miembro'**
  String get memberInviteTitle;

  /// No description provided for @memberGivenName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get memberGivenName;

  /// No description provided for @memberFamilyName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get memberFamilyName;

  /// No description provided for @memberEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get memberEmail;

  /// No description provided for @memberRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles'**
  String get memberRoles;

  /// No description provided for @memberRolesRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un rol'**
  String get memberRolesRequired;

  /// No description provided for @memberInvited.
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada'**
  String get memberInvited;

  /// No description provided for @memberEditRoles.
  ///
  /// In es, this message translates to:
  /// **'Editar roles'**
  String get memberEditRoles;

  /// No description provided for @memberDeactivate.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get memberDeactivate;

  /// No description provided for @memberDeactivateConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar a {name}? Perderá el acceso a la academia.'**
  String memberDeactivateConfirm(String name);

  /// No description provided for @memberDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Miembro desactivado'**
  String get memberDeactivated;

  /// No description provided for @memberInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get memberInactive;

  /// No description provided for @memberInvitationPending.
  ///
  /// In es, this message translates to:
  /// **'Invitación pendiente'**
  String get memberInvitationPending;

  /// No description provided for @memberGuardianLinks.
  ///
  /// In es, this message translates to:
  /// **'Jugadores vinculados'**
  String get memberGuardianLinks;

  /// No description provided for @memberGuardianNone.
  ///
  /// In es, this message translates to:
  /// **'Sin jugadores vinculados'**
  String get memberGuardianNone;

  /// No description provided for @memberGuardianAdd.
  ///
  /// In es, this message translates to:
  /// **'Vincular jugador'**
  String get memberGuardianAdd;

  /// No description provided for @memberGuardianRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el vínculo con {name}?'**
  String memberGuardianRemoveConfirm(String name);

  /// No description provided for @memberGuardianOnlyParents.
  ///
  /// In es, this message translates to:
  /// **'Los vínculos solo se editan para miembros con el rol Familia.'**
  String get memberGuardianOnlyParents;

  /// No description provided for @seasonsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay temporadas'**
  String get seasonsEmpty;

  /// No description provided for @seasonNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva temporada'**
  String get seasonNew;

  /// No description provided for @seasonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar temporada'**
  String get seasonEdit;

  /// No description provided for @seasonName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get seasonName;

  /// No description provided for @seasonStarts.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get seasonStarts;

  /// No description provided for @seasonEnds.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get seasonEnds;

  /// No description provided for @seasonReferenceYear.
  ///
  /// In es, this message translates to:
  /// **'Año de referencia (regla por año de nacimiento)'**
  String get seasonReferenceYear;

  /// No description provided for @seasonCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get seasonCurrent;

  /// No description provided for @seasonDatesInvalid.
  ///
  /// In es, this message translates to:
  /// **'La fecha de fin debe ser posterior a la de inicio'**
  String get seasonDatesInvalid;

  /// No description provided for @seasonRollover.
  ///
  /// In es, this message translates to:
  /// **'Pasar a nueva temporada'**
  String get seasonRollover;

  /// No description provided for @rolloverTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambio de temporada'**
  String get rolloverTitle;

  /// No description provided for @rolloverIntro.
  ///
  /// In es, this message translates to:
  /// **'Se creará la temporada siguiente a partir de {name}: se copian los equipos y se vuelven a comprobar los jugadores.'**
  String rolloverIntro(String name);

  /// No description provided for @rolloverCloneStaff.
  ///
  /// In es, this message translates to:
  /// **'Copiar el cuerpo técnico'**
  String get rolloverCloneStaff;

  /// No description provided for @rolloverClonePlayers.
  ///
  /// In es, this message translates to:
  /// **'Copiar las plantillas'**
  String get rolloverClonePlayers;

  /// No description provided for @rolloverConfirm.
  ///
  /// In es, this message translates to:
  /// **'Ejecutar cambio de temporada'**
  String get rolloverConfirm;

  /// No description provided for @rolloverDone.
  ///
  /// In es, this message translates to:
  /// **'Cambio de temporada completado'**
  String get rolloverDone;

  /// No description provided for @rolloverClonedTeams.
  ///
  /// In es, this message translates to:
  /// **'Equipos copiados: {count}'**
  String rolloverClonedTeams(String count);

  /// No description provided for @rolloverOrphansTitle.
  ///
  /// In es, this message translates to:
  /// **'Jugadores sin equipo válido'**
  String get rolloverOrphansTitle;

  /// No description provided for @rolloverNoOrphans.
  ///
  /// In es, this message translates to:
  /// **'Todos los jugadores siguen siendo elegibles.'**
  String get rolloverNoOrphans;

  /// No description provided for @rolloverOrphanLine.
  ///
  /// In es, this message translates to:
  /// **'{player} (antes: {team})'**
  String rolloverOrphanLine(String player, String team);

  /// No description provided for @rolloverGoToCases.
  ///
  /// In es, this message translates to:
  /// **'Ir a los casos de elegibilidad'**
  String get rolloverGoToCases;

  /// No description provided for @rolloverCasesOpened.
  ///
  /// In es, this message translates to:
  /// **'Casos abiertos: {count}'**
  String rolloverCasesOpened(String count);

  /// No description provided for @categoryNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get categoryEdit;

  /// No description provided for @categoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay categorías'**
  String get categoriesEmpty;

  /// No description provided for @categoryCode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get categoryCode;

  /// No description provided for @categoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryName;

  /// No description provided for @categoryMaxAge.
  ///
  /// In es, this message translates to:
  /// **'Edad máxima (vacío = sin límite)'**
  String get categoryMaxAge;

  /// No description provided for @categoryRank.
  ///
  /// In es, this message translates to:
  /// **'Orden'**
  String get categoryRank;

  /// No description provided for @categoryNoLimit.
  ///
  /// In es, this message translates to:
  /// **'Sin límite de edad'**
  String get categoryNoLimit;

  /// No description provided for @categoryUpTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta {age} años'**
  String categoryUpTo(String age);

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la categoría {name}?'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @teamsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay equipos en esta temporada'**
  String get teamsEmpty;

  /// No description provided for @teamsNoSeason.
  ///
  /// In es, this message translates to:
  /// **'Crea primero una temporada'**
  String get teamsNoSeason;

  /// No description provided for @teamsSeason.
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get teamsSeason;

  /// No description provided for @teamNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo equipo'**
  String get teamNew;

  /// No description provided for @teamEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar equipo'**
  String get teamEdit;

  /// No description provided for @teamName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get teamName;

  /// No description provided for @teamAlias.
  ///
  /// In es, this message translates to:
  /// **'Alias (opcional)'**
  String get teamAlias;

  /// No description provided for @teamCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get teamCategory;

  /// No description provided for @teamGenderPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de género'**
  String get teamGenderPolicy;

  /// No description provided for @genderPolicyMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get genderPolicyMale;

  /// No description provided for @genderPolicyFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get genderPolicyFemale;

  /// No description provided for @genderPolicyMixed.
  ///
  /// In es, this message translates to:
  /// **'Mixto'**
  String get genderPolicyMixed;

  /// No description provided for @teamPlayerCount.
  ///
  /// In es, this message translates to:
  /// **'{count} jugadores'**
  String teamPlayerCount(String count);

  /// No description provided for @teamStaff.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo técnico'**
  String get teamStaff;

  /// No description provided for @teamStaffAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir entrenador'**
  String get teamStaffAdd;

  /// No description provided for @teamStaffNone.
  ///
  /// In es, this message translates to:
  /// **'Sin cuerpo técnico'**
  String get teamStaffNone;

  /// No description provided for @teamStaffRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {name} del equipo?'**
  String teamStaffRemoveConfirm(String name);

  /// No description provided for @teamStaffPick.
  ///
  /// In es, this message translates to:
  /// **'Persona'**
  String get teamStaffPick;

  /// No description provided for @teamStaffRole.
  ///
  /// In es, this message translates to:
  /// **'Función'**
  String get teamStaffRole;

  /// No description provided for @teamRoster.
  ///
  /// In es, this message translates to:
  /// **'Plantilla'**
  String get teamRoster;

  /// No description provided for @teamRosterEmpty.
  ///
  /// In es, this message translates to:
  /// **'La plantilla está vacía'**
  String get teamRosterEmpty;

  /// No description provided for @rosterAssign.
  ///
  /// In es, this message translates to:
  /// **'Asignar jugador'**
  String get rosterAssign;

  /// No description provided for @rosterSearchPlayer.
  ///
  /// In es, this message translates to:
  /// **'Buscar jugador'**
  String get rosterSearchPlayer;

  /// No description provided for @rosterUnassign.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la plantilla'**
  String get rosterUnassign;

  /// No description provided for @rosterUnassignConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {name} de la plantilla?'**
  String rosterUnassignConfirm(String name);

  /// No description provided for @rosterJersey.
  ///
  /// In es, this message translates to:
  /// **'Dorsal'**
  String get rosterJersey;

  /// No description provided for @rosterJerseyEdit.
  ///
  /// In es, this message translates to:
  /// **'Cambiar dorsal'**
  String get rosterJerseyEdit;

  /// No description provided for @rosterAssigned.
  ///
  /// In es, this message translates to:
  /// **'Jugador asignado'**
  String get rosterAssigned;

  /// No description provided for @rosterInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ya no es elegible'**
  String get rosterInvalid;

  /// No description provided for @rosterEligibilityPending.
  ///
  /// In es, this message translates to:
  /// **'Comprobando elegibilidad…'**
  String get rosterEligibilityPending;

  /// No description provided for @eligibilityEligible.
  ///
  /// In es, this message translates to:
  /// **'Elegible'**
  String get eligibilityEligible;

  /// No description provided for @eligibilityPlayUp.
  ///
  /// In es, this message translates to:
  /// **'Juega en categoría superior (+{levels})'**
  String eligibilityPlayUp(String levels);

  /// No description provided for @eligibilityIneligible.
  ///
  /// In es, this message translates to:
  /// **'No elegible'**
  String get eligibilityIneligible;

  /// No description provided for @playUpBadge.
  ///
  /// In es, this message translates to:
  /// **'+{levels}'**
  String playUpBadge(String levels);

  /// No description provided for @reasonCategoryTooLow.
  ///
  /// In es, this message translates to:
  /// **'Es demasiado mayor para esta categoría'**
  String get reasonCategoryTooLow;

  /// No description provided for @reasonPlayUpLimit.
  ///
  /// In es, this message translates to:
  /// **'Supera el máximo de niveles de categoría superior'**
  String get reasonPlayUpLimit;

  /// No description provided for @reasonGenderPolicy.
  ///
  /// In es, this message translates to:
  /// **'No cumple la política de género del equipo'**
  String get reasonGenderPolicy;

  /// No description provided for @reasonMissingBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Falta la fecha de nacimiento'**
  String get reasonMissingBirthDate;

  /// No description provided for @reasonMissingGender.
  ///
  /// In es, this message translates to:
  /// **'Falta el género'**
  String get reasonMissingGender;

  /// No description provided for @reasonPlayerNotActive.
  ///
  /// In es, this message translates to:
  /// **'El jugador no está activo'**
  String get reasonPlayerNotActive;

  /// No description provided for @playersSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar jugador'**
  String get playersSearchHint;

  /// No description provided for @playersEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores con estos filtros'**
  String get playersEmpty;

  /// No description provided for @filterStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get filterStatus;

  /// No description provided for @filterTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get filterTeam;

  /// No description provided for @filterCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get filterCategory;

  /// No description provided for @filterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get filterClear;

  /// No description provided for @statusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get statusActive;

  /// No description provided for @statusOrphan.
  ///
  /// In es, this message translates to:
  /// **'Sin equipo válido'**
  String get statusOrphan;

  /// No description provided for @statusPendingApproval.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de aprobación'**
  String get statusPendingApproval;

  /// No description provided for @statusWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get statusWithdrawn;

  /// No description provided for @playerNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo jugador'**
  String get playerNew;

  /// No description provided for @playerNewRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitar nuevo jugador'**
  String get playerNewRequest;

  /// No description provided for @playerGivenName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get playerGivenName;

  /// No description provided for @playerFamilyName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get playerFamilyName;

  /// No description provided for @playerBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get playerBirthDate;

  /// No description provided for @playerBirthDateInvalid.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento no válida'**
  String get playerBirthDateInvalid;

  /// No description provided for @playerGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get playerGender;

  /// No description provided for @genderMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get genderFemale;

  /// No description provided for @playerEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo (opcional)'**
  String get playerEmail;

  /// No description provided for @playerInitialTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo inicial (opcional)'**
  String get playerInitialTeam;

  /// No description provided for @playerNote.
  ///
  /// In es, this message translates to:
  /// **'Nota para el administrador (opcional)'**
  String get playerNote;

  /// No description provided for @playerCreated.
  ///
  /// In es, this message translates to:
  /// **'Jugador creado'**
  String get playerCreated;

  /// No description provided for @playerRequestSent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada al administrador'**
  String get playerRequestSent;

  /// No description provided for @playerBasics.
  ///
  /// In es, this message translates to:
  /// **'Datos básicos'**
  String get playerBasics;

  /// No description provided for @playerNaturalCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría natural'**
  String get playerNaturalCategory;

  /// No description provided for @playerGuardians.
  ///
  /// In es, this message translates to:
  /// **'Tutores'**
  String get playerGuardians;

  /// No description provided for @playerNoGuardians.
  ///
  /// In es, this message translates to:
  /// **'Sin tutores vinculados'**
  String get playerNoGuardians;

  /// No description provided for @playerTeams.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get playerTeams;

  /// No description provided for @playerNoTeams.
  ///
  /// In es, this message translates to:
  /// **'Sin equipo'**
  String get playerNoTeams;

  /// No description provided for @playerAssignToTeam.
  ///
  /// In es, this message translates to:
  /// **'Asignar a un equipo'**
  String get playerAssignToTeam;

  /// No description provided for @playerNoEligibleTeams.
  ///
  /// In es, this message translates to:
  /// **'No hay equipos elegibles en la temporada'**
  String get playerNoEligibleTeams;

  /// No description provided for @playerWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Dar de baja'**
  String get playerWithdraw;

  /// No description provided for @playerWithdrawConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Dar de baja a {name}?'**
  String playerWithdrawConfirm(String name);

  /// No description provided for @playerWithdrawReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get playerWithdrawReason;

  /// No description provided for @playerWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Jugador dado de baja'**
  String get playerWithdrawn;

  /// No description provided for @playerWithdrawRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de baja enviada'**
  String get playerWithdrawRequested;

  /// No description provided for @approvalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get approvalsTitle;

  /// No description provided for @approvalsMine.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get approvalsMine;

  /// No description provided for @approvalsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes'**
  String get approvalsEmpty;

  /// No description provided for @approvalActionAdd.
  ///
  /// In es, this message translates to:
  /// **'Alta de jugador'**
  String get approvalActionAdd;

  /// No description provided for @approvalActionWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Baja de jugador'**
  String get approvalActionWithdraw;

  /// No description provided for @approvalStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get approvalStatusPending;

  /// No description provided for @approvalStatusApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobada'**
  String get approvalStatusApproved;

  /// No description provided for @approvalStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get approvalStatusRejected;

  /// No description provided for @approvalStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get approvalStatusCancelled;

  /// No description provided for @approvalRequestedBy.
  ///
  /// In es, this message translates to:
  /// **'Solicitada por {name}'**
  String approvalRequestedBy(String name);

  /// No description provided for @approvalApprove.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get approvalApprove;

  /// No description provided for @approvalReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get approvalReject;

  /// No description provided for @approvalCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get approvalCancel;

  /// No description provided for @approvalCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar esta solicitud?'**
  String get approvalCancelConfirm;

  /// No description provided for @approvalDecisionNote.
  ///
  /// In es, this message translates to:
  /// **'Nota de la decisión: {note}'**
  String approvalDecisionNote(String note);

  /// No description provided for @approvalApproved.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aprobada'**
  String get approvalApproved;

  /// No description provided for @approvalRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get approvalRejected;

  /// No description provided for @approvalCancelled.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get approvalCancelled;

  /// No description provided for @casesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay casos abiertos'**
  String get casesEmpty;

  /// No description provided for @caseTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo invalidado: {team}'**
  String caseTeam(String team);

  /// No description provided for @caseReassign.
  ///
  /// In es, this message translates to:
  /// **'Reasignar'**
  String get caseReassign;

  /// No description provided for @caseReassignTitle.
  ///
  /// In es, this message translates to:
  /// **'Reasignar a {player}'**
  String caseReassignTitle(String player);

  /// No description provided for @caseRemoveFromTeam.
  ///
  /// In es, this message translates to:
  /// **'Quitar del equipo'**
  String get caseRemoveFromTeam;

  /// No description provided for @caseDismiss.
  ///
  /// In es, this message translates to:
  /// **'Descartar caso'**
  String get caseDismiss;

  /// No description provided for @caseResolved.
  ///
  /// In es, this message translates to:
  /// **'Caso resuelto'**
  String get caseResolved;

  /// No description provided for @casePickTeam.
  ///
  /// In es, this message translates to:
  /// **'Elige el nuevo equipo'**
  String get casePickTeam;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
