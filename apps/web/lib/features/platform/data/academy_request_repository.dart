import '../../../core/api/api.dart' as api;

/// The super admin's academy requests (`/platform/academy-requests`, ADR-0044).
abstract class AcademyRequestRepository {
  /// Newest first; at most 200 per status (the workbench shows one status at a time).
  Future<List<api.AcademyRequest>> list(api.AcademyRequestStatus status);

  /// Creates the academy; the result carries the first administrator's temporary password once (ADR-0024).
  Future<api.AcademyRequestAccepted> accept(
    String requestId,
    api.AcceptAcademyRequest request,
  );

  Future<api.AcademyRequest> reject(String requestId, String reason);
}

class ApiAcademyRequestRepository implements AcademyRequestRepository {
  ApiAcademyRequestRepository(api.HoopsCoreApi client)
    : _api = client.getAcademyRequestsApi();

  final api.AcademyRequestsApi _api;

  @override
  Future<List<api.AcademyRequest>> list(
    api.AcademyRequestStatus status,
  ) async => (await _api.listAcademyRequests(
    status: status,
    size: 200,
  )).data!.items.toList();

  @override
  Future<api.AcademyRequestAccepted> accept(
    String requestId,
    api.AcceptAcademyRequest request,
  ) async => (await _api.acceptAcademyRequest(
    requestId: requestId,
    acceptAcademyRequest: request,
  )).data!;

  @override
  Future<api.AcademyRequest> reject(String requestId, String reason) async =>
      (await _api.rejectAcademyRequest(
        requestId: requestId,
        rejectAcademyRequest: api.RejectAcademyRequest(
          (b) => b.reason = reason,
        ),
      )).data!;
}
