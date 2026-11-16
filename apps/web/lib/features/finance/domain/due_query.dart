import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

const _keep = Object();

/// The filters and the page of the dues list (`GET /api/finance/dues`).
class DueQuery {
  const DueQuery({
    this.planId,
    this.teamId,
    this.period,
    this.status,
    this.page = 0,
    this.size = defaultSize,
  });

  static const defaultSize = 25;

  final String? planId;
  final String? teamId;
  final String? period;
  final fin.DueStatus? status;
  final int page;
  final int size;

  bool get hasFilter =>
      planId != null || teamId != null || period != null || status != null;

  /// A copy with the given values; pass `null` to clear a filter. Changing a
  /// filter goes back to the first page unless [page] is given.
  DueQuery copyWith({
    Object? planId = _keep,
    Object? teamId = _keep,
    Object? period = _keep,
    Object? status = _keep,
    int? page,
  }) {
    final filtered =
        planId != _keep ||
        teamId != _keep ||
        period != _keep ||
        status != _keep;
    return DueQuery(
      planId: identical(planId, _keep) ? this.planId : planId as String?,
      teamId: identical(teamId, _keep) ? this.teamId : teamId as String?,
      period: identical(period, _keep) ? this.period : period as String?,
      status: identical(status, _keep) ? this.status : status as fin.DueStatus?,
      page: page ?? (filtered ? 0 : this.page),
      size: size,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DueQuery &&
      other.planId == planId &&
      other.teamId == teamId &&
      other.period == period &&
      other.status == status &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(planId, teamId, period, status, page, size);
}
