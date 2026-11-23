import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/application/audit_providers.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/export_overrides.dart';
import '../../support/fake_export.dart';
import '../../support/fake_platform.dart';
import '../../support/fake_repos.dart';
import '../../support/harness.dart';
import '../../support/mock_backend.dart';
import '../../support/pump_helpers.dart';

const _academyExport = '/api/core/audit-events:export';
const _platformExport = '/platform/audit-events:export';

const _button = Key('audit-export');
final _icon = find.descendant(
  of: find.byKey(_button),
  matching: find.byType(IconButton),
);

Future<Harness> _academy(
  WidgetTester tester,
  MockBackend backend,
  FakeFileDownloader downloader,
) => pumpAs(
  tester,
  roles: {TenantRole.admin},
  core: FakeCore(),
  location: '/admin/activity',
  backend: backend,
  overrides: exportOverrides(downloader),
);

Future<Harness> _platform(
  WidgetTester tester,
  MockBackend backend,
  FakeFileDownloader downloader,
  String location,
) async {
  final club = tenantOf('t-a', 'Club Norte');
  backend.platform.tenants.add(coreJson(club));
  return pumpAsSuperAdmin(
    tester,
    platform: FakePlatformRepository(tenants: [club]),
    location: location,
    size: const Size(1024, 900),
    backend: backend,
    overrides: exportOverrides(downloader),
  );
}

void main() {
  group('academy audit trail', () {
    testWidgets('exports the trail with the filters of the screen', (
      tester,
    ) async {
      final backend = MockBackend();
      final downloader = FakeFileDownloader();
      final h = await _academy(tester, backend, downloader);
      h.container
          .read(auditQueryProvider(const AuditScope.academy()).notifier)
          .setActions({api.AuditAction.memberPeriodInvited});
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      final request = backend.requestsTo(_academyExport).single;
      expect(request.headers['X-Tenant-Id'], MockBackend.testTenantId);
      expect(backend.lastQuery(_academyExport).set('action'), {
        'member.invited',
      });
      expect(request.headers['Accept-Language'], 'es');
      expect(
        downloader.saved.single.fileName,
        'hoops-role-test-audit-20261110.csv',
      );
      expect(
        utf8.decode(downloader.saved.single.bytes),
        contains('Fecha,Acción'),
        reason: "the server's file, headers in the user's language",
      );
    });

    testWidgets('more than 10,000 rows asks to narrow the range', (
      tester,
    ) async {
      final backend = MockBackend()
        ..fail(_academyExport, status: 422, code: 'EXPORT_TOO_LARGE');
      final downloader = FakeFileDownloader();
      await _academy(tester, backend, downloader);

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(downloader.saved, isEmpty);
      expect(
        find.text(
          'Hay más de 10.000 filas: acota el rango de fechas o las acciones '
          'e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('offline the button is disabled', (tester) async {
      final h = await _academy(tester, MockBackend(), FakeFileDownloader());
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(_icon).onPressed, isNull);
    });
  });

  group('platform audit trail', () {
    testWidgets('exports every academy', (tester) async {
      final backend = MockBackend();
      final downloader = FakeFileDownloader();
      await _platform(tester, backend, downloader, '/app-admin/activity');

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      final request = backend.requestsTo(_platformExport).single;
      expect(backend.lastQuery(_platformExport).text('tenantId'), isNull);
      expect(request.headers['Accept-Language'], 'es');
      expect(
        downloader.saved.single.fileName,
        'hoops-platform-audit-20261110.csv',
      );
    });

    testWidgets('narrows to the academy of its detail page', (tester) async {
      final backend = MockBackend();
      await _platform(
        tester,
        backend,
        FakeFileDownloader(),
        '/app-admin/academies/t-a/activity',
      );

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(backend.lastQuery(_platformExport).text('tenantId'), 't-a');
    });
  });
}
