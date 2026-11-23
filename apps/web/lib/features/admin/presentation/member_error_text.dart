import '../../../core/errors/app_error.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The words for a failed member action. Two codes read differently here than
/// elsewhere (the person is a member of this academy, not an administrator
/// account); every other code goes through the shared table of
/// [AppErrorMessage].
String memberErrorText(Object error, AppLocalizations l) {
  final e = AppError.of(error);
  return switch (e.code) {
    'INVITATION_NOT_PENDING' => l.memberErrorNotPending,
    'EMAIL_TAKEN' => l.memberErrorEmailTaken,
    _ => e.message(l),
  };
}
