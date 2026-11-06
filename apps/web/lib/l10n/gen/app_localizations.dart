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

  /// No description provided for @notMemberTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no eres miembro de ninguna academia'**
  String get notMemberTitle;

  /// No description provided for @notMemberBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no eres miembro de ninguna academia. Pide a un administrador de la academia que te añada con este correo: {email}'**
  String notMemberBody(String email);

  /// No description provided for @notMemberBodyNoEmail.
  ///
  /// In es, this message translates to:
  /// **'Todavía no eres miembro de ninguna academia. Pide a un administrador de la academia que te añada con el correo con el que has iniciado sesión.'**
  String get notMemberBodyNoEmail;

  /// No description provided for @timesShownIn.
  ///
  /// In es, this message translates to:
  /// **'Las horas se muestran en la zona horaria de la academia: {zone}'**
  String timesShownIn(String zone);

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

  /// No description provided for @statusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get statusRejected;

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

  /// No description provided for @matchListEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay partidos'**
  String get matchListEmpty;

  /// No description provided for @matchAllTeams.
  ///
  /// In es, this message translates to:
  /// **'Todos los equipos'**
  String get matchAllTeams;

  /// No description provided for @matchTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get matchTeam;

  /// No description provided for @matchStatusScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get matchStatusScheduled;

  /// No description provided for @matchStatusLive.
  ///
  /// In es, this message translates to:
  /// **'En juego'**
  String get matchStatusLive;

  /// No description provided for @matchStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get matchStatusFinished;

  /// No description provided for @matchStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get matchStatusCancelled;

  /// No description provided for @matchVs.
  ///
  /// In es, this message translates to:
  /// **'vs {opponent}'**
  String matchVs(String opponent);

  /// No description provided for @matchHome.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get matchHome;

  /// No description provided for @matchAway.
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get matchAway;

  /// No description provided for @matchUs.
  ///
  /// In es, this message translates to:
  /// **'Nosotros'**
  String get matchUs;

  /// No description provided for @matchCachedData.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: datos guardados en este dispositivo'**
  String get matchCachedData;

  /// No description provided for @matchNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo partido'**
  String get matchNew;

  /// No description provided for @matchOpponent.
  ///
  /// In es, this message translates to:
  /// **'Rival'**
  String get matchOpponent;

  /// No description provided for @matchDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get matchDate;

  /// No description provided for @matchCreated.
  ///
  /// In es, this message translates to:
  /// **'Partido creado'**
  String get matchCreated;

  /// No description provided for @matchEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar partido'**
  String get matchEdit;

  /// No description provided for @matchVenue.
  ///
  /// In es, this message translates to:
  /// **'Pabellón'**
  String get matchVenue;

  /// No description provided for @matchTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get matchTime;

  /// No description provided for @matchPeriodCount.
  ///
  /// In es, this message translates to:
  /// **'Periodos'**
  String get matchPeriodCount;

  /// No description provided for @matchPeriodMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos por periodo'**
  String get matchPeriodMinutes;

  /// No description provided for @matchUpdated.
  ///
  /// In es, this message translates to:
  /// **'Partido actualizado'**
  String get matchUpdated;

  /// No description provided for @matchSetup.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get matchSetup;

  /// No description provided for @matchSetupHint.
  ///
  /// In es, this message translates to:
  /// **'Elige jugadores, titulares y dorsales'**
  String get matchSetupHint;

  /// No description provided for @matchStarter.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get matchStarter;

  /// No description provided for @matchJersey.
  ///
  /// In es, this message translates to:
  /// **'Dorsal'**
  String get matchJersey;

  /// No description provided for @matchSetupSaved.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria guardada'**
  String get matchSetupSaved;

  /// No description provided for @matchSetupNoPlayers.
  ///
  /// In es, this message translates to:
  /// **'El equipo no tiene jugadores'**
  String get matchSetupNoPlayers;

  /// No description provided for @matchSetupNeedStarter.
  ///
  /// In es, this message translates to:
  /// **'Marca al menos un titular'**
  String get matchSetupNeedStarter;

  /// No description provided for @matchSetupSummary.
  ///
  /// In es, this message translates to:
  /// **'{selected} convocados · {starters} titulares'**
  String matchSetupSummary(int selected, int starters);

  /// No description provided for @matchSetupAction.
  ///
  /// In es, this message translates to:
  /// **'Preparar convocatoria'**
  String get matchSetupAction;

  /// No description provided for @matchNoRoster.
  ///
  /// In es, this message translates to:
  /// **'Este partido aún no tiene convocatoria'**
  String get matchNoRoster;

  /// No description provided for @matchTabCourt.
  ///
  /// In es, this message translates to:
  /// **'Pista'**
  String get matchTabCourt;

  /// No description provided for @matchTabLog.
  ///
  /// In es, this message translates to:
  /// **'Jugadas'**
  String get matchTabLog;

  /// No description provided for @matchTabBox.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get matchTabBox;

  /// No description provided for @matchPeriodShort.
  ///
  /// In es, this message translates to:
  /// **'P{period}'**
  String matchPeriodShort(int period);

  /// No description provided for @matchOvertimeShort.
  ///
  /// In es, this message translates to:
  /// **'PR{number}'**
  String matchOvertimeShort(int number);

  /// No description provided for @matchBeforeStart.
  ///
  /// In es, this message translates to:
  /// **'Sin empezar'**
  String get matchBeforeStart;

  /// No description provided for @matchStartPeriod.
  ///
  /// In es, this message translates to:
  /// **'Iniciar {period}'**
  String matchStartPeriod(String period);

  /// No description provided for @matchEndPeriod.
  ///
  /// In es, this message translates to:
  /// **'Terminar {period}'**
  String matchEndPeriod(String period);

  /// No description provided for @matchClockStart.
  ///
  /// In es, this message translates to:
  /// **'Poner en marcha el reloj'**
  String get matchClockStart;

  /// No description provided for @matchClockPause.
  ///
  /// In es, this message translates to:
  /// **'Parar el reloj'**
  String get matchClockPause;

  /// No description provided for @matchClockMinus.
  ///
  /// In es, this message translates to:
  /// **'Restar 10 segundos'**
  String get matchClockMinus;

  /// No description provided for @matchClockPlus.
  ///
  /// In es, this message translates to:
  /// **'Sumar 10 segundos'**
  String get matchClockPlus;

  /// No description provided for @matchOnCourt.
  ///
  /// In es, this message translates to:
  /// **'En pista'**
  String get matchOnCourt;

  /// No description provided for @matchBench.
  ///
  /// In es, this message translates to:
  /// **'Banquillo'**
  String get matchBench;

  /// No description provided for @matchOpponentPoints.
  ///
  /// In es, this message translates to:
  /// **'Rival +{points}'**
  String matchOpponentPoints(int points);

  /// No description provided for @matchTimeoutOwn.
  ///
  /// In es, this message translates to:
  /// **'Tiempo muerto'**
  String get matchTimeoutOwn;

  /// No description provided for @matchTimeoutOpponent.
  ///
  /// In es, this message translates to:
  /// **'Tiempo muerto rival'**
  String get matchTimeoutOpponent;

  /// No description provided for @matchUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get matchUndo;

  /// No description provided for @matchUndone.
  ///
  /// In es, this message translates to:
  /// **'Última jugada anulada'**
  String get matchUndone;

  /// No description provided for @matchNothingToUndo.
  ///
  /// In es, this message translates to:
  /// **'Nada que deshacer'**
  String get matchNothingToUndo;

  /// No description provided for @matchSubFor.
  ///
  /// In es, this message translates to:
  /// **'Entra {name} por…'**
  String matchSubFor(String name);

  /// No description provided for @matchStatsFor.
  ///
  /// In es, this message translates to:
  /// **'Estadística de {name}'**
  String matchStatsFor(String name);

  /// No description provided for @matchRecorded.
  ///
  /// In es, this message translates to:
  /// **'{action} · {name}'**
  String matchRecorded(String action, String name);

  /// No description provided for @matchAction2ptMade.
  ///
  /// In es, this message translates to:
  /// **'2 PT ✓'**
  String get matchAction2ptMade;

  /// No description provided for @matchAction2ptMissed.
  ///
  /// In es, this message translates to:
  /// **'2 PT ✗'**
  String get matchAction2ptMissed;

  /// No description provided for @matchAction3ptMade.
  ///
  /// In es, this message translates to:
  /// **'3 PT ✓'**
  String get matchAction3ptMade;

  /// No description provided for @matchAction3ptMissed.
  ///
  /// In es, this message translates to:
  /// **'3 PT ✗'**
  String get matchAction3ptMissed;

  /// No description provided for @matchActionFtMade.
  ///
  /// In es, this message translates to:
  /// **'TL ✓'**
  String get matchActionFtMade;

  /// No description provided for @matchActionFtMissed.
  ///
  /// In es, this message translates to:
  /// **'TL ✗'**
  String get matchActionFtMissed;

  /// No description provided for @matchActionAssist.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get matchActionAssist;

  /// No description provided for @matchActionOreb.
  ///
  /// In es, this message translates to:
  /// **'Rebote ofensivo'**
  String get matchActionOreb;

  /// No description provided for @matchActionDreb.
  ///
  /// In es, this message translates to:
  /// **'Rebote defensivo'**
  String get matchActionDreb;

  /// No description provided for @matchActionSteal.
  ///
  /// In es, this message translates to:
  /// **'Robo'**
  String get matchActionSteal;

  /// No description provided for @matchActionBlock.
  ///
  /// In es, this message translates to:
  /// **'Tapón'**
  String get matchActionBlock;

  /// No description provided for @matchActionTurnover.
  ///
  /// In es, this message translates to:
  /// **'Pérdida'**
  String get matchActionTurnover;

  /// No description provided for @matchActionFoulPersonal.
  ///
  /// In es, this message translates to:
  /// **'Falta personal'**
  String get matchActionFoulPersonal;

  /// No description provided for @matchActionFoulTechnical.
  ///
  /// In es, this message translates to:
  /// **'Falta técnica'**
  String get matchActionFoulTechnical;

  /// No description provided for @matchActionFoulUnsportsmanlike.
  ///
  /// In es, this message translates to:
  /// **'Antideportiva'**
  String get matchActionFoulUnsportsmanlike;

  /// No description provided for @matchEvPeriodStart.
  ///
  /// In es, this message translates to:
  /// **'Empieza {period}'**
  String matchEvPeriodStart(String period);

  /// No description provided for @matchEvPeriodEnd.
  ///
  /// In es, this message translates to:
  /// **'Termina {period}'**
  String matchEvPeriodEnd(String period);

  /// No description provided for @matchEvSubIn.
  ///
  /// In es, this message translates to:
  /// **'Entra {name}'**
  String matchEvSubIn(String name);

  /// No description provided for @matchEvSubOut.
  ///
  /// In es, this message translates to:
  /// **'Sale {name}'**
  String matchEvSubOut(String name);

  /// No description provided for @matchEvVoid.
  ///
  /// In es, this message translates to:
  /// **'Anula: {target}'**
  String matchEvVoid(String target);

  /// No description provided for @matchEvVoidUnknown.
  ///
  /// In es, this message translates to:
  /// **'Anula una jugada'**
  String get matchEvVoidUnknown;

  /// No description provided for @matchEvNote.
  ///
  /// In es, this message translates to:
  /// **'Nota: {text}'**
  String matchEvNote(String text);

  /// No description provided for @matchSyncPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get matchSyncPending;

  /// No description provided for @matchSyncSent.
  ///
  /// In es, this message translates to:
  /// **'Enviando'**
  String get matchSyncSent;

  /// No description provided for @matchSyncDone.
  ///
  /// In es, this message translates to:
  /// **'Sincronizada'**
  String get matchSyncDone;

  /// No description provided for @matchSyncRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada: {reason}'**
  String matchSyncRejected(String reason);

  /// No description provided for @matchVoided.
  ///
  /// In es, this message translates to:
  /// **'Anulada'**
  String get matchVoided;

  /// No description provided for @matchRecordedBy.
  ///
  /// In es, this message translates to:
  /// **'por {name}'**
  String matchRecordedBy(String name);

  /// No description provided for @matchReasonSchema.
  ///
  /// In es, this message translates to:
  /// **'datos no válidos'**
  String get matchReasonSchema;

  /// No description provided for @matchReasonNotAuthorized.
  ///
  /// In es, this message translates to:
  /// **'sin permiso'**
  String get matchReasonNotAuthorized;

  /// No description provided for @matchReasonCancelled.
  ///
  /// In es, this message translates to:
  /// **'partido cancelado'**
  String get matchReasonCancelled;

  /// No description provided for @matchReasonSeqConflict.
  ///
  /// In es, this message translates to:
  /// **'conflicto de secuencia'**
  String get matchReasonSeqConflict;

  /// No description provided for @matchReasonOther.
  ///
  /// In es, this message translates to:
  /// **'rechazada por el servidor'**
  String get matchReasonOther;

  /// No description provided for @matchVoidEvent.
  ///
  /// In es, this message translates to:
  /// **'Anular'**
  String get matchVoidEvent;

  /// No description provided for @matchVoidConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Anular esta jugada? Se registrará una anulación.'**
  String get matchVoidConfirm;

  /// No description provided for @matchDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get matchDiscard;

  /// No description provided for @matchDiscardConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar esta jugada rechazada? No se enviará más.'**
  String get matchDiscardConfirm;

  /// No description provided for @matchUnsynced.
  ///
  /// In es, this message translates to:
  /// **'{count} sin sincronizar'**
  String matchUnsynced(int count);

  /// No description provided for @matchRejectedCount.
  ///
  /// In es, this message translates to:
  /// **'{count} rechazadas'**
  String matchRejectedCount(int count);

  /// No description provided for @matchSyncPausedAuth.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión de nuevo para sincronizar; los datos se conservan'**
  String get matchSyncPausedAuth;

  /// No description provided for @matchSyncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get matchSyncing;

  /// No description provided for @matchParentMode.
  ///
  /// In es, this message translates to:
  /// **'Modo familia: solo tus jugadores'**
  String get matchParentMode;

  /// No description provided for @matchReadOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo lectura'**
  String get matchReadOnly;

  /// No description provided for @matchStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar partido'**
  String get matchStart;

  /// No description provided for @matchFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar partido'**
  String get matchFinish;

  /// No description provided for @matchFinishConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar el partido? Las correcciones seguirán siendo posibles.'**
  String get matchFinishConfirm;

  /// No description provided for @matchColMin.
  ///
  /// In es, this message translates to:
  /// **'MIN'**
  String get matchColMin;

  /// No description provided for @matchColPts.
  ///
  /// In es, this message translates to:
  /// **'PTS'**
  String get matchColPts;

  /// No description provided for @matchColReb.
  ///
  /// In es, this message translates to:
  /// **'REB'**
  String get matchColReb;

  /// No description provided for @matchColAst.
  ///
  /// In es, this message translates to:
  /// **'AST'**
  String get matchColAst;

  /// No description provided for @matchColStl.
  ///
  /// In es, this message translates to:
  /// **'ROB'**
  String get matchColStl;

  /// No description provided for @matchColBlk.
  ///
  /// In es, this message translates to:
  /// **'TAP'**
  String get matchColBlk;

  /// No description provided for @matchColTov.
  ///
  /// In es, this message translates to:
  /// **'PÉR'**
  String get matchColTov;

  /// No description provided for @matchColPf.
  ///
  /// In es, this message translates to:
  /// **'FP'**
  String get matchColPf;

  /// No description provided for @matchColFg.
  ///
  /// In es, this message translates to:
  /// **'TC'**
  String get matchColFg;

  /// No description provided for @matchCol3p.
  ///
  /// In es, this message translates to:
  /// **'T3'**
  String get matchCol3p;

  /// No description provided for @matchColFt.
  ///
  /// In es, this message translates to:
  /// **'TL'**
  String get matchColFt;

  /// No description provided for @matchTotals.
  ///
  /// In es, this message translates to:
  /// **'Total equipo'**
  String get matchTotals;

  /// No description provided for @matchPeriodScores.
  ///
  /// In es, this message translates to:
  /// **'Parciales'**
  String get matchPeriodScores;

  /// No description provided for @matchWarnings.
  ///
  /// In es, this message translates to:
  /// **'{count} avisos de coherencia (corrige con Anular)'**
  String matchWarnings(int count);

  /// No description provided for @matchCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar resultado'**
  String get matchCopy;

  /// No description provided for @matchCopied.
  ///
  /// In es, this message translates to:
  /// **'Resultado copiado'**
  String get matchCopied;

  /// No description provided for @matchShareLine.
  ///
  /// In es, this message translates to:
  /// **'{name}: {points} pts, {rebounds} reb, {assists} ast'**
  String matchShareLine(String name, int points, int rebounds, int assists);

  /// No description provided for @seasonStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de temporada'**
  String get seasonStatsTitle;

  /// No description provided for @seasonStatsGames.
  ///
  /// In es, this message translates to:
  /// **'{played} partidos · {started} de titular'**
  String seasonStatsGames(int played, int started);

  /// No description provided for @seasonStatsAverages.
  ///
  /// In es, this message translates to:
  /// **'Promedios por partido'**
  String get seasonStatsAverages;

  /// No description provided for @seasonStatsTotals.
  ///
  /// In es, this message translates to:
  /// **'Totales'**
  String get seasonStatsTotals;

  /// No description provided for @seasonStatsMatches.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get seasonStatsMatches;

  /// No description provided for @seasonStatsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin partidos en esta temporada'**
  String get seasonStatsEmpty;

  /// No description provided for @seasonStatsPoints.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get seasonStatsPoints;

  /// No description provided for @seasonStatsRebounds.
  ///
  /// In es, this message translates to:
  /// **'Rebotes'**
  String get seasonStatsRebounds;

  /// No description provided for @seasonStatsAssists.
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get seasonStatsAssists;

  /// No description provided for @seasonStatsMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get seasonStatsMinutes;

  /// No description provided for @seasonStatsSeason.
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get seasonStatsSeason;

  /// No description provided for @trainingTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenamientos'**
  String get trainingTitle;

  /// No description provided for @trainingWeekOf.
  ///
  /// In es, this message translates to:
  /// **'Semana del {range}'**
  String trainingWeekOf(String range);

  /// No description provided for @trainingToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get trainingToday;

  /// No description provided for @trainingPrevWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana anterior'**
  String get trainingPrevWeek;

  /// No description provided for @trainingNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana siguiente'**
  String get trainingNextWeek;

  /// No description provided for @trainingAllTeams.
  ///
  /// In es, this message translates to:
  /// **'Todos los equipos'**
  String get trainingAllTeams;

  /// No description provided for @trainingNoSessions.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamientos esta semana'**
  String get trainingNoSessions;

  /// No description provided for @trainingNoSessionsDay.
  ///
  /// In es, this message translates to:
  /// **'Sin sesiones'**
  String get trainingNoSessionsDay;

  /// No description provided for @trainingMenuPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes'**
  String get trainingMenuPlans;

  /// No description provided for @trainingMenuSchedules.
  ///
  /// In es, this message translates to:
  /// **'Horarios'**
  String get trainingMenuSchedules;

  /// No description provided for @trainingMenuAbsences.
  ///
  /// In es, this message translates to:
  /// **'Ausencias'**
  String get trainingMenuAbsences;

  /// No description provided for @trainingMenuAssignments.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones'**
  String get trainingMenuAssignments;

  /// No description provided for @sessionStatusPlanned.
  ///
  /// In es, this message translates to:
  /// **'Prevista'**
  String get sessionStatusPlanned;

  /// No description provided for @sessionStatusDone.
  ///
  /// In es, this message translates to:
  /// **'Realizada'**
  String get sessionStatusDone;

  /// No description provided for @sessionStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get sessionStatusCancelled;

  /// No description provided for @sessionDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión de entrenamiento'**
  String get sessionDetailTitle;

  /// No description provided for @sessionTimeRange.
  ///
  /// In es, this message translates to:
  /// **'{start} – {end}'**
  String sessionTimeRange(String end, String start);

  /// No description provided for @sessionLocation.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get sessionLocation;

  /// No description provided for @sessionNoLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin lugar indicado'**
  String get sessionNoLocation;

  /// No description provided for @sessionPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get sessionPlan;

  /// No description provided for @sessionNoPlan.
  ///
  /// In es, this message translates to:
  /// **'Sin plan asignado'**
  String get sessionNoPlan;

  /// No description provided for @sessionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar sesión'**
  String get sessionEdit;

  /// No description provided for @sessionUpdated.
  ///
  /// In es, this message translates to:
  /// **'Sesión actualizada'**
  String get sessionUpdated;

  /// No description provided for @sessionNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get sessionNotes;

  /// No description provided for @sessionCancelReasonLine.
  ///
  /// In es, this message translates to:
  /// **'Cancelada: {reason}'**
  String sessionCancelReasonLine(String reason);

  /// No description provided for @sessionNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva sesión'**
  String get sessionNew;

  /// No description provided for @sessionTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get sessionTeam;

  /// No description provided for @sessionDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get sessionDate;

  /// No description provided for @sessionStartTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get sessionStartTime;

  /// No description provided for @sessionDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración (min)'**
  String get sessionDuration;

  /// No description provided for @sessionDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String sessionDurationMinutes(int minutes);

  /// No description provided for @sessionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar sesión'**
  String get sessionCancel;

  /// No description provided for @sessionCancelReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo de la cancelación'**
  String get sessionCancelReason;

  /// No description provided for @sessionCreated.
  ///
  /// In es, this message translates to:
  /// **'Sesión creada'**
  String get sessionCreated;

  /// No description provided for @sessionCancelled.
  ///
  /// In es, this message translates to:
  /// **'Sesión cancelada'**
  String get sessionCancelled;

  /// No description provided for @attendanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get attendanceTitle;

  /// No description provided for @attendancePresent.
  ///
  /// In es, this message translates to:
  /// **'Presente'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get attendanceLate;

  /// No description provided for @attendanceAbsent.
  ///
  /// In es, this message translates to:
  /// **'Ausente'**
  String get attendanceAbsent;

  /// No description provided for @attendanceExcused.
  ///
  /// In es, this message translates to:
  /// **'Justificada'**
  String get attendanceExcused;

  /// No description provided for @attendanceMinutesLate.
  ///
  /// In es, this message translates to:
  /// **'Minutos de retraso'**
  String get attendanceMinutesLate;

  /// No description provided for @attendanceExpectedAbsent.
  ///
  /// In es, this message translates to:
  /// **'Ausencia prevista'**
  String get attendanceExpectedAbsent;

  /// No description provided for @attendanceInjured.
  ///
  /// In es, this message translates to:
  /// **'Lesionado'**
  String get attendanceInjured;

  /// No description provided for @attendanceNotRecorded.
  ///
  /// In es, this message translates to:
  /// **'Sin registrar'**
  String get attendanceNotRecorded;

  /// No description provided for @attendanceSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar asistencia'**
  String get attendanceSave;

  /// No description provided for @attendanceSaved.
  ///
  /// In es, this message translates to:
  /// **'Asistencia guardada'**
  String get attendanceSaved;

  /// No description provided for @attendanceEmpty.
  ///
  /// In es, this message translates to:
  /// **'El equipo no tiene jugadores'**
  String get attendanceEmpty;

  /// No description provided for @attendanceMinutesInvalid.
  ///
  /// In es, this message translates to:
  /// **'Minutos entre 1 y 180'**
  String get attendanceMinutesInvalid;

  /// No description provided for @scheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios de entrenamiento'**
  String get scheduleTitle;

  /// No description provided for @scheduleNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo horario'**
  String get scheduleNew;

  /// No description provided for @scheduleEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar horario'**
  String get scheduleEdit;

  /// No description provided for @scheduleEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay horarios'**
  String get scheduleEmpty;

  /// No description provided for @scheduleDay.
  ///
  /// In es, this message translates to:
  /// **'Día de la semana'**
  String get scheduleDay;

  /// No description provided for @scheduleTime.
  ///
  /// In es, this message translates to:
  /// **'Hora (HH:MM)'**
  String get scheduleTime;

  /// No description provided for @scheduleTimeInvalid.
  ///
  /// In es, this message translates to:
  /// **'Usa el formato HH:MM'**
  String get scheduleTimeInvalid;

  /// No description provided for @scheduleValidFrom.
  ///
  /// In es, this message translates to:
  /// **'Válido desde'**
  String get scheduleValidFrom;

  /// No description provided for @scheduleValidUntil.
  ///
  /// In es, this message translates to:
  /// **'Válido hasta'**
  String get scheduleValidUntil;

  /// No description provided for @scheduleNoEnd.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha de fin'**
  String get scheduleNoEnd;

  /// No description provided for @scheduleDatesInvalid.
  ///
  /// In es, this message translates to:
  /// **'La fecha final debe ser posterior a la inicial'**
  String get scheduleDatesInvalid;

  /// No description provided for @scheduleLine.
  ///
  /// In es, this message translates to:
  /// **'{day} {time} · {minutes} min'**
  String scheduleLine(String day, int minutes, String time);

  /// No description provided for @scheduleValidity.
  ///
  /// In es, this message translates to:
  /// **'Desde {from}'**
  String scheduleValidity(String from);

  /// No description provided for @scheduleValidityRange.
  ///
  /// In es, this message translates to:
  /// **'{from} a {to}'**
  String scheduleValidityRange(String from, String to);

  /// No description provided for @scheduleDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este horario? Se quitarán las sesiones futuras sin cambios.'**
  String get scheduleDeleteConfirm;

  /// No description provided for @dayMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get daySunday;

  /// No description provided for @absenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Ausencias previstas'**
  String get absenceTitle;

  /// No description provided for @absenceNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva ausencia'**
  String get absenceNew;

  /// No description provided for @absencePlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get absencePlayer;

  /// No description provided for @absenceFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get absenceFrom;

  /// No description provided for @absenceTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get absenceTo;

  /// No description provided for @absenceReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get absenceReason;

  /// No description provided for @absenceEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay ausencias previstas'**
  String get absenceEmpty;

  /// No description provided for @absenceDatesInvalid.
  ///
  /// In es, this message translates to:
  /// **'La fecha final no puede ser anterior a la inicial'**
  String get absenceDatesInvalid;

  /// No description provided for @absenceDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta ausencia?'**
  String get absenceDeleteConfirm;

  /// No description provided for @absenceRange.
  ///
  /// In es, this message translates to:
  /// **'{from} → {to}'**
  String absenceRange(String from, String to);

  /// No description provided for @absenceSaved.
  ///
  /// In es, this message translates to:
  /// **'Ausencia registrada'**
  String get absenceSaved;

  /// No description provided for @planLibraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Planes de entrenamiento'**
  String get planLibraryTitle;

  /// No description provided for @planTemplates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas'**
  String get planTemplates;

  /// No description provided for @planMine.
  ///
  /// In es, this message translates to:
  /// **'Mis planes'**
  String get planMine;

  /// No description provided for @planSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar planes'**
  String get planSearchHint;

  /// No description provided for @planEmptyTemplates.
  ///
  /// In es, this message translates to:
  /// **'No hay plantillas'**
  String get planEmptyTemplates;

  /// No description provided for @planEmptyMine.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay planes propios. Crea uno o usa una plantilla.'**
  String get planEmptyMine;

  /// No description provided for @planSummary.
  ///
  /// In es, this message translates to:
  /// **'{count} ejercicios · {minutes} min'**
  String planSummary(int count, int minutes);

  /// No description provided for @planNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo plan'**
  String get planNew;

  /// No description provided for @planName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del plan'**
  String get planName;

  /// No description provided for @planDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get planDescription;

  /// No description provided for @planUse.
  ///
  /// In es, this message translates to:
  /// **'Usar plantilla'**
  String get planUse;

  /// No description provided for @planCopied.
  ///
  /// In es, this message translates to:
  /// **'Plantilla copiada a tus planes'**
  String get planCopied;

  /// No description provided for @planTemplateReadOnly.
  ///
  /// In es, this message translates to:
  /// **'Plantilla de solo lectura: cópiala para editarla.'**
  String get planTemplateReadOnly;

  /// No description provided for @planItems.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios'**
  String get planItems;

  /// No description provided for @planNoItems.
  ///
  /// In es, this message translates to:
  /// **'Este plan aún no tiene ejercicios'**
  String get planNoItems;

  /// No description provided for @planItemAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicio'**
  String get planItemAdd;

  /// No description provided for @planItemEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar ejercicio'**
  String get planItemEdit;

  /// No description provided for @planItemTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get planItemTitle;

  /// No description provided for @planItemDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración (min)'**
  String get planItemDuration;

  /// No description provided for @planItemSets.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get planItemSets;

  /// No description provided for @planItemReps.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get planItemReps;

  /// No description provided for @planItemVideo.
  ///
  /// In es, this message translates to:
  /// **'Enlace de vídeo (https)'**
  String get planItemVideo;

  /// No description provided for @planItemVideoInvalid.
  ///
  /// In es, this message translates to:
  /// **'Debe empezar por https://'**
  String get planItemVideoInvalid;

  /// No description provided for @planItemSetsReps.
  ///
  /// In es, this message translates to:
  /// **'{sets} × {reps}'**
  String planItemSetsReps(int reps, int sets);

  /// No description provided for @planItemMoveUp.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get planItemMoveUp;

  /// No description provided for @planItemMoveDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar'**
  String get planItemMoveDown;

  /// No description provided for @planItemDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar este ejercicio?'**
  String get planItemDeleteConfirm;

  /// No description provided for @planDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este plan?'**
  String get planDeleteConfirm;

  /// No description provided for @planAssign.
  ///
  /// In es, this message translates to:
  /// **'Asignar'**
  String get planAssign;

  /// No description provided for @planWatchVideo.
  ///
  /// In es, this message translates to:
  /// **'Ver vídeo'**
  String get planWatchVideo;

  /// No description provided for @assignTitle.
  ///
  /// In es, this message translates to:
  /// **'Asignar plan'**
  String get assignTitle;

  /// No description provided for @assignTarget.
  ///
  /// In es, this message translates to:
  /// **'Destinatario'**
  String get assignTarget;

  /// No description provided for @assignToTeam.
  ///
  /// In es, this message translates to:
  /// **'Un equipo'**
  String get assignToTeam;

  /// No description provided for @assignToPlayer.
  ///
  /// In es, this message translates to:
  /// **'Un jugador'**
  String get assignToPlayer;

  /// No description provided for @assignDue.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite'**
  String get assignDue;

  /// No description provided for @assignDone.
  ///
  /// In es, this message translates to:
  /// **'Plan asignado'**
  String get assignDone;

  /// No description provided for @assignmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Planes asignados'**
  String get assignmentsTitle;

  /// No description provided for @assignmentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay planes asignados'**
  String get assignmentsEmpty;

  /// No description provided for @assignmentDue.
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String assignmentDue(String date);

  /// No description provided for @assignmentProgress.
  ///
  /// In es, this message translates to:
  /// **'{done} hechos · {partial} parciales · {notDone} no hechos'**
  String assignmentProgress(int done, int notDone, int partial);

  /// No description provided for @assignmentDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta asignación y sus marcas?'**
  String get assignmentDeleteConfirm;

  /// No description provided for @assignmentProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get assignmentProgressTitle;

  /// No description provided for @assignmentTeamTarget.
  ///
  /// In es, this message translates to:
  /// **'Equipo: {name}'**
  String assignmentTeamTarget(String name);

  /// No description provided for @assignmentPlayerTarget.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get assignmentPlayerTarget;

  /// No description provided for @completionDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get completionDone;

  /// No description provided for @completionPartial.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get completionPartial;

  /// No description provided for @completionNotDone.
  ///
  /// In es, this message translates to:
  /// **'No hecho'**
  String get completionNotDone;

  /// No description provided for @completionNone.
  ///
  /// In es, this message translates to:
  /// **'Sin marcar'**
  String get completionNone;

  /// No description provided for @completionComment.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get completionComment;

  /// No description provided for @completionMark.
  ///
  /// In es, this message translates to:
  /// **'Marcar'**
  String get completionMark;

  /// No description provided for @completionSaved.
  ///
  /// In es, this message translates to:
  /// **'Marca guardada'**
  String get completionSaved;

  /// No description provided for @healthTitle.
  ///
  /// In es, this message translates to:
  /// **'Salud y forma'**
  String get healthTitle;

  /// No description provided for @healthInjuries.
  ///
  /// In es, this message translates to:
  /// **'Lesiones'**
  String get healthInjuries;

  /// No description provided for @healthGrowth.
  ///
  /// In es, this message translates to:
  /// **'Crecimiento'**
  String get healthGrowth;

  /// No description provided for @healthTests.
  ///
  /// In es, this message translates to:
  /// **'Pruebas físicas'**
  String get healthTests;

  /// No description provided for @injuryNew.
  ///
  /// In es, this message translates to:
  /// **'Registrar lesión'**
  String get injuryNew;

  /// No description provided for @injuryBodyPart.
  ///
  /// In es, this message translates to:
  /// **'Zona del cuerpo'**
  String get injuryBodyPart;

  /// No description provided for @injurySeverity.
  ///
  /// In es, this message translates to:
  /// **'Gravedad'**
  String get injurySeverity;

  /// No description provided for @severityMinor.
  ///
  /// In es, this message translates to:
  /// **'Leve'**
  String get severityMinor;

  /// No description provided for @severityModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderada'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In es, this message translates to:
  /// **'Grave'**
  String get severitySevere;

  /// No description provided for @injuryOccurredOn.
  ///
  /// In es, this message translates to:
  /// **'Fecha de la lesión'**
  String get injuryOccurredOn;

  /// No description provided for @injuryExpectedReturn.
  ///
  /// In es, this message translates to:
  /// **'Regreso previsto'**
  String get injuryExpectedReturn;

  /// No description provided for @injuryDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get injuryDescription;

  /// No description provided for @injuryStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get injuryStatusOpen;

  /// No description provided for @injuryStatusRecovered.
  ///
  /// In es, this message translates to:
  /// **'Recuperada'**
  String get injuryStatusRecovered;

  /// No description provided for @injuryRecover.
  ///
  /// In es, this message translates to:
  /// **'Marcar recuperada'**
  String get injuryRecover;

  /// No description provided for @injuryRecoveredOn.
  ///
  /// In es, this message translates to:
  /// **'Fecha de regreso'**
  String get injuryRecoveredOn;

  /// No description provided for @injuryUpdateReturn.
  ///
  /// In es, this message translates to:
  /// **'Cambiar regreso previsto'**
  String get injuryUpdateReturn;

  /// No description provided for @injuryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin lesiones registradas'**
  String get injuryEmpty;

  /// No description provided for @injuryReturnLine.
  ///
  /// In es, this message translates to:
  /// **'Regreso previsto: {date}'**
  String injuryReturnLine(String date);

  /// No description provided for @injuryRecoveredLine.
  ///
  /// In es, this message translates to:
  /// **'Recuperada el {date}'**
  String injuryRecoveredLine(String date);

  /// No description provided for @injurySaved.
  ///
  /// In es, this message translates to:
  /// **'Lesión guardada'**
  String get injurySaved;

  /// No description provided for @injuryEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar lesión'**
  String get injuryEdit;

  /// No description provided for @injuryReturnBeforeInjury.
  ///
  /// In es, this message translates to:
  /// **'El regreso no puede ser anterior a la lesión'**
  String get injuryReturnBeforeInjury;

  /// No description provided for @availabilityAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get availabilityAvailable;

  /// No description provided for @availabilityInjured.
  ///
  /// In es, this message translates to:
  /// **'Lesionado: {bodyPart}'**
  String availabilityInjured(String bodyPart);

  /// No description provided for @growthHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura (cm)'**
  String get growthHeight;

  /// No description provided for @growthWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get growthWeight;

  /// No description provided for @growthEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar medida'**
  String get growthEdit;

  /// No description provided for @testEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar resultado'**
  String get testEdit;

  /// No description provided for @measurementDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta medida?'**
  String get measurementDeleteConfirm;

  /// No description provided for @resultDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este resultado?'**
  String get resultDeleteConfirm;

  /// No description provided for @absenceEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar ausencia'**
  String get absenceEdit;

  /// No description provided for @testTypeEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar tipo de prueba'**
  String get testTypeEdit;

  /// No description provided for @growthAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir medida'**
  String get growthAdd;

  /// No description provided for @growthMeasuredOn.
  ///
  /// In es, this message translates to:
  /// **'Fecha de la medida'**
  String get growthMeasuredOn;

  /// No description provided for @growthEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin medidas todavía'**
  String get growthEmpty;

  /// No description provided for @growthNeedOne.
  ///
  /// In es, this message translates to:
  /// **'Indica altura, peso o ambos'**
  String get growthNeedOne;

  /// No description provided for @growthShowTable.
  ///
  /// In es, this message translates to:
  /// **'Ver tabla'**
  String get growthShowTable;

  /// No description provided for @growthHideTable.
  ///
  /// In es, this message translates to:
  /// **'Ocultar tabla'**
  String get growthHideTable;

  /// No description provided for @growthDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta medida?'**
  String get growthDeleteConfirm;

  /// No description provided for @chartSummary.
  ///
  /// In es, this message translates to:
  /// **'Gráfico de {name}: {count} medidas, la última {value}'**
  String chartSummary(int count, String name, String value);

  /// No description provided for @chartNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos para el gráfico'**
  String get chartNoData;

  /// No description provided for @chartDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get chartDate;

  /// No description provided for @chartValue.
  ///
  /// In es, this message translates to:
  /// **'Valor'**
  String get chartValue;

  /// No description provided for @testAdd.
  ///
  /// In es, this message translates to:
  /// **'Registrar resultado'**
  String get testAdd;

  /// No description provided for @testType.
  ///
  /// In es, this message translates to:
  /// **'Prueba'**
  String get testType;

  /// No description provided for @testValue.
  ///
  /// In es, this message translates to:
  /// **'Valor'**
  String get testValue;

  /// No description provided for @testNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas (opcional)'**
  String get testNotes;

  /// No description provided for @testMeasuredOn.
  ///
  /// In es, this message translates to:
  /// **'Fecha de la prueba'**
  String get testMeasuredOn;

  /// No description provided for @bandPoor.
  ///
  /// In es, this message translates to:
  /// **'Muy bajo'**
  String get bandPoor;

  /// No description provided for @bandBelowAverage.
  ///
  /// In es, this message translates to:
  /// **'Bajo la media'**
  String get bandBelowAverage;

  /// No description provided for @bandAverage.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get bandAverage;

  /// No description provided for @bandAboveAverage.
  ///
  /// In es, this message translates to:
  /// **'Sobre la media'**
  String get bandAboveAverage;

  /// No description provided for @bandExcellent.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get bandExcellent;

  /// No description provided for @testExpectedBand.
  ///
  /// In es, this message translates to:
  /// **'Banda esperada: {band}'**
  String testExpectedBand(String band);

  /// No description provided for @testNoBand.
  ///
  /// In es, this message translates to:
  /// **'Sin norma para esta edad y género'**
  String get testNoBand;

  /// No description provided for @testReferencePending.
  ///
  /// In es, this message translates to:
  /// **'Referencia pendiente'**
  String get testReferencePending;

  /// No description provided for @testSavedBand.
  ///
  /// In es, this message translates to:
  /// **'Resultado guardado. Banda: {band}'**
  String testSavedBand(String band);

  /// No description provided for @testSavedNoBand.
  ///
  /// In es, this message translates to:
  /// **'Resultado guardado (sin norma aplicable)'**
  String get testSavedNoBand;

  /// No description provided for @testEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados de pruebas'**
  String get testEmpty;

  /// No description provided for @testChartLegend.
  ///
  /// In es, this message translates to:
  /// **'Bandas esperadas'**
  String get testChartLegend;

  /// No description provided for @testAtAge.
  ///
  /// In es, this message translates to:
  /// **'{age} años'**
  String testAtAge(int age);

  /// No description provided for @testResultLine.
  ///
  /// In es, this message translates to:
  /// **'{value} {unit}'**
  String testResultLine(String unit, String value);

  /// No description provided for @testDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este resultado?'**
  String get testDeleteConfirm;

  /// No description provided for @testTypesTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipos de prueba'**
  String get testTypesTitle;

  /// No description provided for @testTypeNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva prueba personalizada'**
  String get testTypeNew;

  /// No description provided for @testTypeCode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get testTypeCode;

  /// No description provided for @testTypeName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get testTypeName;

  /// No description provided for @testTypeUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get testTypeUnit;

  /// No description provided for @testTypeHigher.
  ///
  /// In es, this message translates to:
  /// **'Un valor mayor es mejor'**
  String get testTypeHigher;

  /// No description provided for @testTypeGlobal.
  ///
  /// In es, this message translates to:
  /// **'Global'**
  String get testTypeGlobal;

  /// No description provided for @testTypeCustom.
  ///
  /// In es, this message translates to:
  /// **'De la academia'**
  String get testTypeCustom;

  /// No description provided for @testTypesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay tipos de prueba'**
  String get testTypesEmpty;

  /// No description provided for @testTypeHigherYes.
  ///
  /// In es, this message translates to:
  /// **'Más es mejor'**
  String get testTypeHigherYes;

  /// No description provided for @testTypeHigherNo.
  ///
  /// In es, this message translates to:
  /// **'Menos es mejor'**
  String get testTypeHigherNo;

  /// No description provided for @testTypeDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el tipo de prueba {name}? Sus normas de la academia también se eliminan.'**
  String testTypeDeleteConfirm(String name);

  /// No description provided for @testTypeDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tipo de prueba eliminado'**
  String get testTypeDeleted;

  /// No description provided for @testTypeHasResults.
  ///
  /// In es, this message translates to:
  /// **'Este tipo de prueba tiene resultados y no se puede eliminar'**
  String get testTypeHasResults;

  /// No description provided for @normsTitle.
  ///
  /// In es, this message translates to:
  /// **'Normas de referencia'**
  String get normsTitle;

  /// No description provided for @normsScopeEffective.
  ///
  /// In es, this message translates to:
  /// **'Efectivas'**
  String get normsScopeEffective;

  /// No description provided for @normsScopeGlobal.
  ///
  /// In es, this message translates to:
  /// **'Globales'**
  String get normsScopeGlobal;

  /// No description provided for @normsScopeTenant.
  ///
  /// In es, this message translates to:
  /// **'De la academia'**
  String get normsScopeTenant;

  /// No description provided for @normNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva norma'**
  String get normNew;

  /// No description provided for @normEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar norma'**
  String get normEdit;

  /// No description provided for @normGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get normGender;

  /// No description provided for @normMinAge.
  ///
  /// In es, this message translates to:
  /// **'Edad mínima'**
  String get normMinAge;

  /// No description provided for @normMaxAge.
  ///
  /// In es, this message translates to:
  /// **'Edad máxima'**
  String get normMaxAge;

  /// No description provided for @normBand.
  ///
  /// In es, this message translates to:
  /// **'Banda'**
  String get normBand;

  /// No description provided for @normMinValue.
  ///
  /// In es, this message translates to:
  /// **'Valor mínimo'**
  String get normMinValue;

  /// No description provided for @normMaxValue.
  ///
  /// In es, this message translates to:
  /// **'Valor máximo'**
  String get normMaxValue;

  /// No description provided for @normSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get normSource;

  /// No description provided for @normAges.
  ///
  /// In es, this message translates to:
  /// **'{min}–{max} años'**
  String normAges(int max, int min);

  /// No description provided for @normValues.
  ///
  /// In es, this message translates to:
  /// **'{low} a {high}'**
  String normValues(String low, String high);

  /// No description provided for @normValuesFrom.
  ///
  /// In es, this message translates to:
  /// **'desde {low}'**
  String normValuesFrom(String low);

  /// No description provided for @normValuesUpTo.
  ///
  /// In es, this message translates to:
  /// **'hasta {high}'**
  String normValuesUpTo(String high);

  /// No description provided for @normGlobalReadOnly.
  ///
  /// In es, this message translates to:
  /// **'Global (solo lectura)'**
  String get normGlobalReadOnly;

  /// No description provided for @normOverride.
  ///
  /// In es, this message translates to:
  /// **'Propia de la academia'**
  String get normOverride;

  /// No description provided for @normEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay normas con este filtro'**
  String get normEmpty;

  /// No description provided for @normDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta norma?'**
  String get normDeleteConfirm;

  /// No description provided for @normAgesInvalid.
  ///
  /// In es, this message translates to:
  /// **'La edad máxima debe ser mayor o igual que la mínima'**
  String get normAgesInvalid;

  /// No description provided for @normAllTests.
  ///
  /// In es, this message translates to:
  /// **'Todas las pruebas'**
  String get normAllTests;

  /// No description provided for @healthMenuTests.
  ///
  /// In es, this message translates to:
  /// **'Tipos de prueba'**
  String get healthMenuTests;

  /// No description provided for @healthMenuNorms.
  ///
  /// In es, this message translates to:
  /// **'Normas'**
  String get healthMenuNorms;

  /// No description provided for @meTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil deportivo'**
  String get meTitle;

  /// No description provided for @meSeasonStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de la temporada'**
  String get meSeasonStats;

  /// No description provided for @meUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos entrenamientos'**
  String get meUpcoming;

  /// No description provided for @meNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No hay entrenamientos próximos'**
  String get meNoUpcoming;

  /// No description provided for @meTabTraining.
  ///
  /// In es, this message translates to:
  /// **'Entrenos'**
  String get meTabTraining;

  /// No description provided for @meTabPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes'**
  String get meTabPlans;

  /// No description provided for @meNoPlayer.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta aún no está vinculada a un jugador'**
  String get meNoPlayer;

  /// No description provided for @myPlayersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis jugadores'**
  String get myPlayersTitle;

  /// No description provided for @myPlayersEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes jugadores vinculados'**
  String get myPlayersEmpty;

  /// No description provided for @profilePlatform.
  ///
  /// In es, this message translates to:
  /// **'Consola de plataforma'**
  String get profilePlatform;

  /// No description provided for @mePlansEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin planes asignados'**
  String get mePlansEmpty;

  /// No description provided for @platformTitle.
  ///
  /// In es, this message translates to:
  /// **'Plataforma'**
  String get platformTitle;

  /// No description provided for @platformSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o identificador'**
  String get platformSearchHint;

  /// No description provided for @platformEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay academias con este filtro'**
  String get platformEmpty;

  /// No description provided for @platformNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva academia'**
  String get platformNew;

  /// No description provided for @tenantName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la academia'**
  String get tenantName;

  /// No description provided for @tenantSlug.
  ///
  /// In es, this message translates to:
  /// **'Identificador (slug)'**
  String get tenantSlug;

  /// No description provided for @tenantSlugInvalid.
  ///
  /// In es, this message translates to:
  /// **'Solo minúsculas, números y guiones (3-50)'**
  String get tenantSlugInvalid;

  /// No description provided for @tenantTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get tenantTimezone;

  /// No description provided for @tenantLocale.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get tenantLocale;

  /// No description provided for @tenantAdminEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo del primer administrador'**
  String get tenantAdminEmail;

  /// No description provided for @tenantAdminGivenName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del administrador'**
  String get tenantAdminGivenName;

  /// No description provided for @tenantAdminFamilyName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos del administrador'**
  String get tenantAdminFamilyName;

  /// No description provided for @tenantStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get tenantStatusActive;

  /// No description provided for @tenantStatusSuspended.
  ///
  /// In es, this message translates to:
  /// **'Suspendida'**
  String get tenantStatusSuspended;

  /// No description provided for @tenantStatusWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Retirada'**
  String get tenantStatusWithdrawn;

  /// No description provided for @tenantCreated.
  ///
  /// In es, this message translates to:
  /// **'Academia creada'**
  String get tenantCreated;

  /// No description provided for @tenantSuspend.
  ///
  /// In es, this message translates to:
  /// **'Suspender'**
  String get tenantSuspend;

  /// No description provided for @tenantWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get tenantWithdraw;

  /// No description provided for @tenantReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get tenantReactivate;

  /// No description provided for @tenantReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get tenantReason;

  /// No description provided for @tenantSuspendTitle.
  ///
  /// In es, this message translates to:
  /// **'Suspender la academia'**
  String get tenantSuspendTitle;

  /// No description provided for @tenantWithdrawTitle.
  ///
  /// In es, this message translates to:
  /// **'Retirar la academia'**
  String get tenantWithdrawTitle;

  /// No description provided for @tenantWithdrawWarning.
  ///
  /// In es, this message translates to:
  /// **'Al retirar una academia comienza el plazo de conservación de datos.'**
  String get tenantWithdrawWarning;

  /// No description provided for @tenantUpdated.
  ///
  /// In es, this message translates to:
  /// **'Estado actualizado'**
  String get tenantUpdated;

  /// No description provided for @tenantCreatedOn.
  ///
  /// In es, this message translates to:
  /// **'Creada el {date}'**
  String tenantCreatedOn(String date);

  /// No description provided for @tenantRetainUntil.
  ///
  /// In es, this message translates to:
  /// **'Datos conservados hasta {date}'**
  String tenantRetainUntil(String date);

  /// No description provided for @usageTitle.
  ///
  /// In es, this message translates to:
  /// **'Uso'**
  String get usageTitle;

  /// No description provided for @usageUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de: {services}'**
  String usageUnavailable(String services);

  /// No description provided for @usageLastActivity.
  ///
  /// In es, this message translates to:
  /// **'Última actividad: {date}'**
  String usageLastActivity(String date);

  /// No description provided for @usageTrendTitle.
  ///
  /// In es, this message translates to:
  /// **'Evolución del uso'**
  String get usageTrendTitle;

  /// No description provided for @usageTrendEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay datos de uso'**
  String get usageTrendEmpty;

  /// No description provided for @usageFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el uso'**
  String get usageFailed;

  /// No description provided for @usageServiceCore.
  ///
  /// In es, this message translates to:
  /// **'Núcleo'**
  String get usageServiceCore;

  /// No description provided for @usageServiceGame.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get usageServiceGame;

  /// No description provided for @usageServiceAthlete.
  ///
  /// In es, this message translates to:
  /// **'Deportistas'**
  String get usageServiceAthlete;

  /// No description provided for @usageCounter_members.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get usageCounter_members;

  /// No description provided for @usageCounter_players.
  ///
  /// In es, this message translates to:
  /// **'Jugadores'**
  String get usageCounter_players;

  /// No description provided for @usageCounter_activePlayers.
  ///
  /// In es, this message translates to:
  /// **'Jugadores activos'**
  String get usageCounter_activePlayers;

  /// No description provided for @usageCounter_teams.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get usageCounter_teams;

  /// No description provided for @usageCounter_seasons.
  ///
  /// In es, this message translates to:
  /// **'Temporadas'**
  String get usageCounter_seasons;

  /// No description provided for @usageCounter_matches.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get usageCounter_matches;

  /// No description provided for @usageCounter_liveMatches.
  ///
  /// In es, this message translates to:
  /// **'Partidos en vivo'**
  String get usageCounter_liveMatches;

  /// No description provided for @usageCounter_matchEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos de partido'**
  String get usageCounter_matchEvents;

  /// No description provided for @usageCounter_matchEventsLast30Days.
  ///
  /// In es, this message translates to:
  /// **'Eventos (30 días)'**
  String get usageCounter_matchEventsLast30Days;

  /// No description provided for @usageCounter_trainingSessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones de entreno'**
  String get usageCounter_trainingSessions;

  /// No description provided for @usageCounter_attendanceRecords.
  ///
  /// In es, this message translates to:
  /// **'Registros de asistencia'**
  String get usageCounter_attendanceRecords;

  /// No description provided for @usageCounter_trainingPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes'**
  String get usageCounter_trainingPlans;

  /// No description provided for @usageCounter_physicalTestResults.
  ///
  /// In es, this message translates to:
  /// **'Resultados de pruebas'**
  String get usageCounter_physicalTestResults;

  /// No description provided for @usageCounter_injuries.
  ///
  /// In es, this message translates to:
  /// **'Lesiones'**
  String get usageCounter_injuries;

  /// No description provided for @usageCounter_bodyMeasurements.
  ///
  /// In es, this message translates to:
  /// **'Medidas corporales'**
  String get usageCounter_bodyMeasurements;

  /// No description provided for @signOutUnsyncedTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay eventos sin sincronizar'**
  String get signOutUnsyncedTitle;

  /// No description provided for @signOutUnsyncedBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Hay 1 evento de partido sin sincronizar} other{Hay {count} eventos de partido sin sincronizar}} en este dispositivo. Si cierras sesión ahora se perderán para siempre. Conéctate y espera a que se sincronicen, o cierra sesión y descártalos.'**
  String signOutUnsyncedBody(int count);

  /// No description provided for @signOutAnyway.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión y descartar'**
  String get signOutAnyway;

  /// No description provided for @updateAvailable.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión disponible'**
  String get updateAvailable;

  /// No description provided for @updateReload.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get updateReload;

  /// No description provided for @adminsTitle.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get adminsTitle;

  /// No description provided for @adminsAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir administrador'**
  String get adminsAdd;

  /// No description provided for @adminsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Esta academia no tiene administradores activos'**
  String get adminsEmpty;

  /// No description provided for @adminsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los administradores'**
  String get adminsLoadFailed;

  /// No description provided for @adminInvitationAccepted.
  ///
  /// In es, this message translates to:
  /// **'Invitación aceptada'**
  String get adminInvitationAccepted;

  /// No description provided for @adminOtherRoles.
  ///
  /// In es, this message translates to:
  /// **'También: {roles}'**
  String adminOtherRoles(String roles);

  /// No description provided for @adminEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar administrador'**
  String get adminEdit;

  /// No description provided for @adminRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar administrador'**
  String get adminRemove;

  /// No description provided for @adminAddHint.
  ///
  /// In es, this message translates to:
  /// **'Si ya hay un miembro activo con este correo, pasa a ser administrador y conserva su nombre. Si no, se crea su acceso y verás una contraseña temporal para entregársela; no se envía ningún correo.'**
  String get adminAddHint;

  /// No description provided for @adminAddSubmit.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get adminAddSubmit;

  /// No description provided for @adminEditEmailNote.
  ///
  /// In es, this message translates to:
  /// **'El correo es también el acceso de la persona: si lo cambias, entrará con la nueva dirección y mantiene su contraseña.'**
  String get adminEditEmailNote;

  /// No description provided for @adminRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar a {name} como administrador? Se elimina el rol de administrador; los demás roles se mantienen.'**
  String adminRemoveConfirm(String name);

  /// No description provided for @adminRemoveSubmit.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get adminRemoveSubmit;

  /// No description provided for @adminLastAdminNote.
  ///
  /// In es, this message translates to:
  /// **'Una academia necesita al menos un administrador. Añade otro administrador antes de quitar a este.'**
  String get adminLastAdminNote;

  /// No description provided for @adminAdded.
  ///
  /// In es, this message translates to:
  /// **'Administrador añadido'**
  String get adminAdded;

  /// No description provided for @adminUpdated.
  ///
  /// In es, this message translates to:
  /// **'Administrador actualizado'**
  String get adminUpdated;

  /// No description provided for @adminRemoved.
  ///
  /// In es, this message translates to:
  /// **'Administrador quitado'**
  String get adminRemoved;

  /// No description provided for @adminsWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'La academia está retirada: sus administradores ya no se pueden consultar ni modificar.'**
  String get adminsWithdrawn;

  /// No description provided for @adminErrorEmailTaken.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya lo usa otra persona o cuenta'**
  String get adminErrorEmailTaken;

  /// No description provided for @adminErrorLoginAlreadyMember.
  ///
  /// In es, this message translates to:
  /// **'Esa cuenta de acceso ya pertenece a otro miembro de esta academia'**
  String get adminErrorLoginAlreadyMember;

  /// No description provided for @adminErrorIdentityProvider.
  ///
  /// In es, this message translates to:
  /// **'El servicio de acceso no está disponible. Inténtalo de nuevo en unos minutos.'**
  String get adminErrorIdentityProvider;

  /// No description provided for @adminErrorInvitationNotPending.
  ///
  /// In es, this message translates to:
  /// **'La invitación ya no está pendiente'**
  String get adminErrorInvitationNotPending;

  /// No description provided for @tempPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña temporal'**
  String get tempPasswordTitle;

  /// No description provided for @tempPasswordFor.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de {person}'**
  String tempPasswordFor(String person);

  /// No description provided for @tempPasswordLoginWith.
  ///
  /// In es, this message translates to:
  /// **'Correo de acceso: {email}'**
  String tempPasswordLoginWith(String email);

  /// No description provided for @tempPasswordShareHint.
  ///
  /// In es, this message translates to:
  /// **'Entrégasela a la persona por un canal privado. No se envía ningún correo.'**
  String get tempPasswordShareHint;

  /// No description provided for @tempPasswordShownOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo se muestra ahora: no se guarda y no se puede volver a ver. Si se pierde, genera una nueva mientras la persona no haya entrado.'**
  String get tempPasswordShownOnce;

  /// No description provided for @tempPasswordFirstSignIn.
  ///
  /// In es, this message translates to:
  /// **'En su primer acceso entra con su correo y esta contraseña, y debe elegir la suya.'**
  String get tempPasswordFirstSignIn;

  /// No description provided for @tempPasswordCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar contraseña'**
  String get tempPasswordCopy;

  /// No description provided for @tempPasswordCopied.
  ///
  /// In es, this message translates to:
  /// **'Contraseña copiada'**
  String get tempPasswordCopied;

  /// No description provided for @tempPasswordDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get tempPasswordDone;

  /// No description provided for @tempPasswordExistingLogin.
  ///
  /// In es, this message translates to:
  /// **'Ya tenía una cuenta: entra con su contraseña actual.'**
  String get tempPasswordExistingLogin;

  /// No description provided for @tempPasswordIssue.
  ///
  /// In es, this message translates to:
  /// **'Generar nueva contraseña temporal'**
  String get tempPasswordIssue;

  /// Chip on a pending member or administrator whose temporary password was not used in time (the login is disabled until a new one is generated, ADR-0028)
  ///
  /// In es, this message translates to:
  /// **'Contraseña temporal caducada'**
  String get tempPasswordExpired;

  /// No description provided for @memberAdded.
  ///
  /// In es, this message translates to:
  /// **'Miembro añadido'**
  String get memberAdded;

  /// No description provided for @memberInviteHint.
  ///
  /// In es, this message translates to:
  /// **'No se envía ningún correo: al crear su acceso verás una contraseña temporal para entregársela a la persona.'**
  String get memberInviteHint;

  /// No description provided for @memberErrorNotPending.
  ///
  /// In es, this message translates to:
  /// **'Esta persona ya entró o la invitación ya no está pendiente'**
  String get memberErrorNotPending;

  /// No description provided for @memberErrorLoginShared.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta de acceso se usa también en otra academia: solo la administración de la plataforma puede generar su contraseña'**
  String get memberErrorLoginShared;

  /// No description provided for @playerEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Con correo, el jugador tendrá acceso: verás una contraseña temporal para entregársela.'**
  String get playerEmailHint;

  /// No description provided for @adminActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get adminActivity;

  /// No description provided for @platformActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad de las academias'**
  String get platformActivity;

  /// No description provided for @auditTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get auditTitle;

  /// No description provided for @auditAnyTime.
  ///
  /// In es, this message translates to:
  /// **'Cualquier fecha'**
  String get auditAnyTime;

  /// No description provided for @auditClearRange.
  ///
  /// In es, this message translates to:
  /// **'Quitar fechas'**
  String get auditClearRange;

  /// No description provided for @auditAllActions.
  ///
  /// In es, this message translates to:
  /// **'Todas las acciones'**
  String get auditAllActions;

  /// No description provided for @auditSelectedActions.
  ///
  /// In es, this message translates to:
  /// **'{count} acciones'**
  String auditSelectedActions(int count);

  /// No description provided for @auditFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por acción'**
  String get auditFilterTitle;

  /// No description provided for @auditApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get auditApply;

  /// No description provided for @auditEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay actividad con este filtro'**
  String get auditEmpty;

  /// No description provided for @auditPageOf.
  ///
  /// In es, this message translates to:
  /// **'Página {page} de {pages}'**
  String auditPageOf(int page, int pages);

  /// No description provided for @auditPreviousPage.
  ///
  /// In es, this message translates to:
  /// **'Página anterior'**
  String get auditPreviousPage;

  /// No description provided for @auditNextPage.
  ///
  /// In es, this message translates to:
  /// **'Página siguiente'**
  String get auditNextPage;

  /// No description provided for @auditByActor.
  ///
  /// In es, this message translates to:
  /// **'Por {actor}'**
  String auditByActor(String actor);

  /// No description provided for @auditActorSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get auditActorSystem;

  /// No description provided for @auditActorPlatform.
  ///
  /// In es, this message translates to:
  /// **'Administrador de la plataforma'**
  String get auditActorPlatform;

  /// No description provided for @auditActorMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro de la academia'**
  String get auditActorMember;

  /// No description provided for @auditTargetPerson.
  ///
  /// In es, this message translates to:
  /// **'Persona'**
  String get auditTargetPerson;

  /// No description provided for @auditTargetPlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador/a'**
  String get auditTargetPlayer;

  /// No description provided for @auditTargetTenant.
  ///
  /// In es, this message translates to:
  /// **'Academia'**
  String get auditTargetTenant;

  /// No description provided for @auditTargetApprovalRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get auditTargetApprovalRequest;

  /// No description provided for @auditTargetGuardianLink.
  ///
  /// In es, this message translates to:
  /// **'Vínculo familiar'**
  String get auditTargetGuardianLink;

  /// No description provided for @auditActionAdminAdded.
  ///
  /// In es, this message translates to:
  /// **'Administrador añadido'**
  String get auditActionAdminAdded;

  /// No description provided for @auditActionAdminRemoved.
  ///
  /// In es, this message translates to:
  /// **'Administrador retirado'**
  String get auditActionAdminRemoved;

  /// No description provided for @auditActionAdminTemporaryPasswordIssued.
  ///
  /// In es, this message translates to:
  /// **'Contraseña temporal de administrador generada'**
  String get auditActionAdminTemporaryPasswordIssued;

  /// No description provided for @auditActionAdminUpdated.
  ///
  /// In es, this message translates to:
  /// **'Administrador editado'**
  String get auditActionAdminUpdated;

  /// No description provided for @auditActionApprovalCancelled.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get auditActionApprovalCancelled;

  /// No description provided for @auditActionGuardianLinkCreated.
  ///
  /// In es, this message translates to:
  /// **'Vínculo familiar creado'**
  String get auditActionGuardianLinkCreated;

  /// No description provided for @auditActionGuardianLinkRemoved.
  ///
  /// In es, this message translates to:
  /// **'Vínculo familiar eliminado'**
  String get auditActionGuardianLinkRemoved;

  /// No description provided for @auditActionMemberDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Miembro desactivado'**
  String get auditActionMemberDeactivated;

  /// No description provided for @auditActionMemberInvitationAccepted.
  ///
  /// In es, this message translates to:
  /// **'Primer inicio de sesión'**
  String get auditActionMemberInvitationAccepted;

  /// No description provided for @auditActionMemberInvited.
  ///
  /// In es, this message translates to:
  /// **'Miembro invitado'**
  String get auditActionMemberInvited;

  /// No description provided for @auditActionMemberLoginEmailChanged.
  ///
  /// In es, this message translates to:
  /// **'Correo de acceso cambiado'**
  String get auditActionMemberLoginEmailChanged;

  /// No description provided for @auditActionMemberRolesReplaced.
  ///
  /// In es, this message translates to:
  /// **'Roles cambiados'**
  String get auditActionMemberRolesReplaced;

  /// No description provided for @auditActionMemberTemporaryPasswordExpired.
  ///
  /// In es, this message translates to:
  /// **'Contraseña temporal caducada'**
  String get auditActionMemberTemporaryPasswordExpired;

  /// No description provided for @auditActionMemberTemporaryPasswordIssued.
  ///
  /// In es, this message translates to:
  /// **'Contraseña temporal generada'**
  String get auditActionMemberTemporaryPasswordIssued;

  /// No description provided for @auditActionMemberUpdated.
  ///
  /// In es, this message translates to:
  /// **'Miembro editado'**
  String get auditActionMemberUpdated;

  /// No description provided for @auditActionPlayerApproved.
  ///
  /// In es, this message translates to:
  /// **'Jugador aprobado'**
  String get auditActionPlayerApproved;

  /// No description provided for @auditActionPlayerRejected.
  ///
  /// In es, this message translates to:
  /// **'Jugador rechazado'**
  String get auditActionPlayerRejected;

  /// No description provided for @auditActionPlayerRequested.
  ///
  /// In es, this message translates to:
  /// **'Alta de jugador solicitada'**
  String get auditActionPlayerRequested;

  /// No description provided for @auditActionPlayerWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Jugador dado de baja'**
  String get auditActionPlayerWithdrawn;

  /// No description provided for @auditActionTenantCreated.
  ///
  /// In es, this message translates to:
  /// **'Academia creada'**
  String get auditActionTenantCreated;

  /// No description provided for @auditActionTenantLogoRemoved.
  ///
  /// In es, this message translates to:
  /// **'Logo eliminado'**
  String get auditActionTenantLogoRemoved;

  /// No description provided for @auditActionTenantLogoReplaced.
  ///
  /// In es, this message translates to:
  /// **'Logo cambiado'**
  String get auditActionTenantLogoReplaced;

  /// No description provided for @auditActionTenantMasterDataChanged.
  ///
  /// In es, this message translates to:
  /// **'Datos de la academia cambiados por la plataforma'**
  String get auditActionTenantMasterDataChanged;

  /// No description provided for @auditActionTenantProfileChanged.
  ///
  /// In es, this message translates to:
  /// **'Perfil de la academia cambiado'**
  String get auditActionTenantProfileChanged;

  /// No description provided for @auditActionTenantReactivated.
  ///
  /// In es, this message translates to:
  /// **'Academia reactivada'**
  String get auditActionTenantReactivated;

  /// No description provided for @auditActionTenantSettingsChanged.
  ///
  /// In es, this message translates to:
  /// **'Ajustes cambiados'**
  String get auditActionTenantSettingsChanged;

  /// No description provided for @auditActionTenantSuspended.
  ///
  /// In es, this message translates to:
  /// **'Academia suspendida'**
  String get auditActionTenantSuspended;

  /// No description provided for @auditActionTenantWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Academia dada de baja'**
  String get auditActionTenantWithdrawn;
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
