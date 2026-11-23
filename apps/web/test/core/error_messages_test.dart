import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/ui/app_error_view.dart';
import 'package:hoops_app/features/admin/presentation/member_error_text.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

AppError _coded(String code, {int status = 409}) =>
    AppError(kind: AppErrorKind.conflict, status: status, code: code);

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  // One table for every business code the services answer (WEB-08): the
  // message no longer depends on whether a screen remembered to pass errorText.
  final table = <String, String>{
    'SEASON_ENDED': l.errorSeasonEnded,
    'DUE_NOT_OPEN': l.financeErrorDueNotOpen,
    'CURRENCY_LOCKED': l.financeErrorCurrencyLocked,
    'UNKNOWN_CURRENCY': l.financeErrorUnknownCurrency,
    'CURRENCY_NOT_SET': l.financeErrorCurrencyNotSet,
    'FEE_PLAN_HAS_DUES': l.financeErrorFeePlanHasDues,
    'FEE_PLAN_ARCHIVED': l.financeErrorFeePlanArchived,
    'PAID_ON_IN_FUTURE': l.financeErrorPaidOnInFuture,
    'PAYMENT_ALREADY_VOIDED': l.financeErrorPaymentAlreadyVoided,
    'PERIOD_OUTSIDE_PLAN': l.financeErrorPeriodOutsidePlan,
    'PERIOD_OUTSIDE_SEASON': l.financeErrorPeriodOutsideSeason,
    'TOO_MANY_DUES': l.financeErrorTooManyDues,
    'TEAM_NOT_IN_SEASON': l.financeErrorTeamNotInSeason,
    'CONCURRENT_MODIFICATION': l.financeErrorConcurrentModification,
    'LOGIN_SHARED': l.memberErrorLoginShared,
    'LOGIN_REQUIRES_EMAIL': l.memberErrorLoginRequiresEmail,
    'EMAIL_TAKEN': l.adminErrorEmailTaken,
    'INVITATION_NOT_PENDING': l.adminErrorInvitationNotPending,
    'IDENTITY_PROVIDER_UNAVAILABLE': l.adminErrorIdentityProvider,
    'LAST_ADMIN': l.adminLastAdminNote,
    'LOGIN_ALREADY_MEMBER': l.adminErrorLoginAlreadyMember,
    'TENANT_WITHDRAWN': l.adminsWithdrawn,
    'REQUEST_NOT_PENDING': l.academyRequestErrorNotPending,
    'ACADEMY_NAME_TAKEN': l.academyRequestErrorNameTaken,
    'SLUG_TAKEN': l.academyRequestErrorSlugTaken,
    'EXERCISE_ARCHIVED': l.exerciseArchivedError,
    'EXERCISE_IS_GLOBAL': l.exerciseIsGlobal,
  };

  for (final MapEntry(key: code, value: text) in table.entries) {
    test('$code has its own message', () {
      expect(_coded(code).message(l), text);
      expect(text, isNot(l.errorConflict));
    });
  }

  test('a code nobody knows gets the message of its kind', () {
    expect(_coded('SOMETHING_NEW').message(l), l.errorConflict);
    expect(const AppError(kind: AppErrorKind.server).message(l), l.errorServer);
  });

  test('501 is "not available yet" whatever the screen', () {
    const error = AppError(kind: AppErrorKind.server, status: 501);
    expect(error.message(l), l.financeNotYetAvailable);
  });

  group('members have their own words for two codes', () {
    test('EMAIL_TAKEN and INVITATION_NOT_PENDING', () {
      expect(
        memberErrorText(_coded('EMAIL_TAKEN'), l),
        l.memberErrorEmailTaken,
      );
      expect(
        memberErrorText(_coded('INVITATION_NOT_PENDING'), l),
        l.memberErrorNotPending,
      );
    });

    test('every other code goes through the shared table', () {
      expect(
        memberErrorText(_coded('LOGIN_SHARED'), l),
        l.memberErrorLoginShared,
      );
      expect(memberErrorText(_coded('NOPE'), l), l.errorConflict);
    });
  });
}
