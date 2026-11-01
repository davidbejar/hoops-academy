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
