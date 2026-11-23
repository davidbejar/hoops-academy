import '../../../core/api/api.dart' as api;
import '../../../core/api/fetch_all.dart';

/// Approval requests (`/api/core/approval-requests`). The server scopes the
/// list: ADMIN sees everything, COACH only their own requests.
abstract class ApprovalsRepository {
  Future<List<api.ApprovalRequest>> list({api.ApprovalStatus? status});

  /// Approving a player request that creates a login returns its temporary password, once (ADR-0024).
  Future<api.ApprovalRequestWithPassword> approve(String id, {String? note});
  Future<api.ApprovalRequest> reject(String id, {required String note});
  Future<api.ApprovalRequest> cancel(String id);
}

class ApiApprovalsRepository implements ApprovalsRepository {
  ApiApprovalsRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getApprovalRequestsApi();

  final api.ApprovalRequestsApi _api;
  final String _t;

  api.ApprovalDecisionRequest _note(String? note) =>
      api.ApprovalDecisionRequest((b) => b.note = note);

  @override
  Future<List<api.ApprovalRequest>> list({api.ApprovalStatus? status}) =>
      fetchAll((page, size) async {
        final p = (await _api.listApprovalRequests(
          xTenantId: _t,
          status: status,
          page: page,
          size: size,
        )).data!;
        return (items: p.items, totalPages: p.page.totalPages);
      });

  @override
  Future<api.ApprovalRequestWithPassword> approve(
    String id, {
    String? note,
  }) async => (await _api.approveApprovalRequest(
    xTenantId: _t,
    approvalRequestId: id,
    approvalDecisionRequest: _note(note),
  )).data!;

  @override
  Future<api.ApprovalRequest> reject(String id, {required String note}) async =>
      (await _api.rejectApprovalRequest(
        xTenantId: _t,
        approvalRequestId: id,
        rejectApprovalRequest: api.RejectApprovalRequest((b) => b..note = note),
      )).data!;

  @override
  Future<api.ApprovalRequest> cancel(String id) async =>
      (await _api.cancelApprovalRequest(
        xTenantId: _t,
        approvalRequestId: id,
      )).data!;
}
