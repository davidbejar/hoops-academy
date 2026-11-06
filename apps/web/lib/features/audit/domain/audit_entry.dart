import '../../../core/api/api.dart' as api;

/// One row of the audit trail as the screens show it: the academy list (`AuditEvent`) and the platform list
/// (`PlatformAuditEvent`, which adds the academy) map to this one model.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.action,
    required this.actorKind,
    required this.targetType,
    required this.targetId,
    this.actorSubject,
    this.actorName,
    this.targetName,
    this.tenantId,
    this.tenantName,
  });

  final String id;
  final DateTime at;
  final api.AuditAction action;
  final api.AuditActorKind actorKind;
  /// Null when the server masks the actor (the super admin seen from an academy, core 2.6.0).
  final String? actorSubject;
  final String? actorName;
  final api.AuditTargetType targetType;
  final String targetId;
  final String? targetName;

  /// Set on the platform list only.
  final String? tenantId;
  final String? tenantName;
}

/// One page of the trail (0-based [page]).
class AuditPage {
  const AuditPage({required this.items, required this.page, required this.totalPages, required this.totalElements});

  final List<AuditEntry> items;
  final int page;
  final int totalPages;
  final int totalElements;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

/// What the user asked for: a range of local calendar days (both inclusive), some actions (none = all), a page.
class AuditQuery {
  const AuditQuery({this.fromDay, this.toDay, this.actions = const {}, this.page = 0});

  static const pageSize = 50;

  final DateTime? fromDay;
  final DateTime? toDay;
  final Set<api.AuditAction> actions;
  final int page;

  /// Start of [fromDay] in the device's time zone, as a UTC instant (the API's inclusive `from`).
  DateTime? get fromInstant => fromDay == null ? null : _startOf(fromDay!).toUtc();

  /// Start of the day after [toDay] (the API's `to` is exclusive), as a UTC instant.
  DateTime? get toInstant => toDay == null ? null : _startOf(toDay!).add(const Duration(days: 1)).toUtc();

  bool get hasRange => fromDay != null && toDay != null;

  AuditQuery withRange(DateTime? from, DateTime? to) => AuditQuery(fromDay: from, toDay: to, actions: actions);

  AuditQuery withActions(Set<api.AuditAction> value) =>
      AuditQuery(fromDay: fromDay, toDay: toDay, actions: Set.unmodifiable(value));

  AuditQuery atPage(int value) => AuditQuery(fromDay: fromDay, toDay: toDay, actions: actions, page: value);

  static DateTime _startOf(DateTime day) => DateTime(day.year, day.month, day.day);
}
