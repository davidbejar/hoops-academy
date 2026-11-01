import '../../../core/api/api.dart' as api;

/// Approval requests (`/api/core/approval-requests`). The server scopes the
/// list: ADMIN sees everything, COACH only their own requests.
abstract class ApprovalsRepository {
  Future<List<api.ApprovalRequest>> list({api.ApprovalStatus? status});
  Future<api.ApprovalRequest> approve(String id, {String? note});
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
  Future<List<api.ApprovalRequest>> list({api.ApprovalStatus? status}) async =>
      (await _api.listApprovalRequests(
        xTenantId: _t,
        status: status,
        size: 100,
      )).data!.items.toList();

  @override
  Future<api.ApprovalRequest> approve(String id, {String? note}) async =>
      (await _api.approveApprovalRequest(
        xTenantId: _t,
        approvalRequestId: id,
        approvalDecisionRequest: _note(note),
      )).data!;

  @override
  Future<api.ApprovalRequest> reject(String id, {required String note}) async =>
      (await _api.rejectApprovalRequest(
        xTenantId: _t,
        approvalRequestId: id,
        approvalDecisionRequest: _note(note),
      )).data!;

  @override
  Future<api.ApprovalRequest> cancel(String id) async =>
      (await _api.cancelApprovalRequest(
        xTenantId: _t,
        approvalRequestId: id,
      )).data!;
}
