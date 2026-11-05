import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';

import '../admin/api_repositories_test.dart' show clientWith, tenant;

Map<String, Object?> _page(List<Map<String, Object?>> items) => {
  'items': items,
  'page': {'page': 1, 'size': 50, 'totalElements': 51, 'totalPages': 2},
};

Map<String, Object?> _event({Map<String, Object?> extra = const {}}) => {
  'id': 'e-1',
  'at': '2026-11-03T09:30:00Z',
  'action': 'member.invited',
  'actor': {'kind': 'PLATFORM', 'subject': 'root', 'personId': null, 'displayName': null},
  'target': {'type': 'person', 'id': 'p-1', 'displayName': 'Leo Gil'},
  'metadata': {'roles': ['COACH']},
  ...extra,
};

void main() {
  final query = AuditQuery(
    fromDay: DateTime(2026, 11, 1),
    toDay: DateTime(2026, 11, 3),
    actions: {api.AuditAction.memberPeriodInvited, api.AuditAction.tenantPeriodSuspended},
    page: 1,
  );

  test('the academy list sends the tenant, UTC bounds, every action and the page', () async {
    final (client, adapter) = clientWith((_) => _page([_event()]));

    final page = await ApiAuditRepository(client).academy(tenant, query);

    final request = adapter.last!;
    expect(request.path, '/api/core/audit-events');
    expect(request.headers['X-Tenant-Id'], tenant);
    expect(request.uri.queryParametersAll['action'], containsAll(['member.invited', 'tenant.suspended']));
    expect(DateTime.parse(request.uri.queryParameters['from']!), DateTime(2026, 11, 1).toUtc());
    expect(request.uri.queryParameters['from'], endsWith('Z'));
    expect(DateTime.parse(request.uri.queryParameters['to']!), DateTime(2026, 11, 4).toUtc());
    expect(request.uri.queryParameters['page'], '1');
    expect(request.uri.queryParameters['size'], '${AuditQuery.pageSize}');
    expect(page.page, 1);
    expect(page.totalPages, 2);
    expect(page.hasPrevious, isTrue);
    expect(page.hasNext, isFalse);
    final e = page.items.single;
    expect(e.action, api.AuditAction.memberPeriodInvited);
    expect(e.actorKind, api.AuditActorKind.PLATFORM);
    expect(e.actorName, isNull);
    expect(e.targetName, 'Leo Gil');
    expect(e.tenantName, isNull);
  });

  test('the platform list carries the academy and may narrow to one', () async {
    final (client, adapter) = clientWith(
      (_) => _page([_event(extra: {'tenantId': 't-a', 'tenantName': 'Club Norte'})]),
    );

    final page = await ApiAuditRepository(client).platform(const AuditQuery(), tenantId: 't-a');

    expect(adapter.last!.path, '/platform/audit-events');
    expect(adapter.last!.uri.queryParameters['tenantId'], 't-a');
    expect(adapter.last!.uri.queryParameters.containsKey('action'), isFalse);
    expect(adapter.last!.uri.queryParameters.containsKey('from'), isFalse);
    expect(page.items.single.tenantName, 'Club Norte');
    expect(page.items.single.tenantId, 't-a');
  });
}
