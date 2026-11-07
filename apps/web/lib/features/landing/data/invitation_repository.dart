import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../domain/invitation_request.dart';

/// Sends the landing's invitation request (the platform's one public call,
/// ADR-0044). Never throws: every failure is an [InvitationOutcome].
abstract class InvitationRepository {
  Future<InvitationOutcome> send(InvitationRequest request);
}

class ApiInvitationRepository implements InvitationRepository {
  ApiInvitationRepository(api.HoopsCoreApi client)
    : _api = client.getAcademyRequestsApi();

  final api.AcademyRequestsApi _api;

  @override
  Future<InvitationOutcome> send(InvitationRequest request) async {
    final name = request.name.trim();
    try {
      await _api.submitAcademyRequest(
        submitAcademyRequest: api.SubmitAcademyRequest(
          (b) => b
            ..name = name.isEmpty ? null : name
            ..email = request.email.trim()
            ..role = _role(request.role!)
            ..academyName = request.academy.trim()
            ..locale = api.ApiLocale.valueOf(request.languageCode)
            ..website = request.website.isEmpty ? null : request.website,
        ),
      );
      return InvitationOutcome.sent;
    } on Object catch (e) {
      return AppError.of(e).code == 'ACADEMY_NAME_TAKEN'
          ? InvitationOutcome.academyTaken
          : InvitationOutcome.failed;
    }
  }

  static api.AcademyRequestRole _role(InvitationRole role) => switch (role) {
    InvitationRole.admin => api.AcademyRequestRole.ADMIN,
    InvitationRole.coach => api.AcademyRequestRole.COACH,
    InvitationRole.parent => api.AcademyRequestRole.PARENT,
  };
}
