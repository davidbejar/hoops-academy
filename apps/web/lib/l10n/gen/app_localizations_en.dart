// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hoops Academy';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Sign in with your academy account';

  @override
  String get signOut => 'Sign out';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get offlineBanner => 'You are offline. Data may be out of date.';

  @override
  String get mockModeBanner => 'Demo mode: sample data, no server';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navTeams => 'Teams';

  @override
  String get navMatches => 'Matches';

  @override
  String get navTraining => 'Training';

  @override
  String get navPlayers => 'Players';

  @override
  String get navMyPlayers => 'My players';

  @override
  String get navMe => 'Me';

  @override
  String get navPlatform => 'Platform';

  @override
  String placeholderModule(String module) {
    return '$module: coming soon';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get languageName_es => 'Español';

  @override
  String get languageName_en => 'English';

  @override
  String get languageName_id => 'Bahasa Indonesia';

  @override
  String get academy => 'Academy';

  @override
  String get switchAcademy => 'Switch academy';

  @override
  String get chooseAcademyTitle => 'Choose your academy';

  @override
  String get chooseAcademySubtitle =>
      'You belong to several academies. Which one do you want to work with?';

  @override
  String rolesInAcademy(String roles) {
    return 'Roles: $roles';
  }

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleAssistantCoach => 'Assistant coach';

  @override
  String get roleParent => 'Parent';

  @override
  String get rolePlayer => 'Player';

  @override
  String get noAccessTitle => 'No access to any academy';

  @override
  String get noAccessBody =>
      'Your account does not belong to any academy yet. Ask an administrator to invite you.';

  @override
  String get profileLoadFailed => 'We could not load your profile';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String get errorTimeout =>
      'The server is taking too long to respond. Try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to do this.';

  @override
  String get errorNotFound => 'We could not find what you are looking for.';

  @override
  String get errorConflict => 'The data has changed. Refresh and try again.';

  @override
  String get errorValidation => 'Please check the data you entered.';

  @override
  String get errorServer => 'The server had a problem. Please try again later.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String errorReference(String traceId) {
    return 'Reference: $traceId';
  }

  @override
  String get emptyTitle => 'Nothing here yet';
}
