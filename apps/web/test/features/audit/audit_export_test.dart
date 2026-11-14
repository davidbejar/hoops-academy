import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/audit/application/audit_providers.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/export_overrides.dart';
import '../../support/fake_audit.dart';
import '../../support/fake_export.dart';
import '../../support/fake_platform.dart';
import '../../support/fake_repos.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

const _button = Key('audit-export');
final _icon = find.descendant(
  of: find.byKey(_button),
  matching: find.byType(IconButton),
);

Future<Harness> _academy(
  WidgetTester tester,
  FakeAuditRepository repo,
  FakeFileDownloader downloader,
) => pumpAs(
  tester,
  roles: {TenantRole.admin},
  core: FakeCore(),
  location: '/admin/activity',
  overrides: [...repo.overrides, ...exportOverrides(downloader)],
);

Future<Harness> _platform(
  WidgetTester tester,
  FakeAuditRepository repo,
  FakeFileDownloader downloader,
  String location,
) async {
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: true)),
    core: FakeCore(),
    platform: FakePlatform(
      repo: FakePlatformRepository(tenants: [tenantOf('t-a', 'Club Norte')]),
    ),
    extraOverrides: [...repo.overrides, ...exportOverrides(downloader)],
  );
  await h.pump(tester, size: const Size(1024, 900));
  await h.go(tester, location);
  return h;
}

void main() {
  group('academy audit trail', () {
    testWidgets('exports the trail with the filters of the screen', (
      tester,
    ) async {
      final repo = FakeAuditRepository();
      final downloader = FakeFileDownloader();
      final h = await _academy(tester, repo, downloader);
      h.container
          .read(auditQueryProvider(const AuditScope.academy()).notifier)
          .setActions({api.AuditAction.memberPeriodInvited});
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      final (tenant, query, language) = repo.academyExports.single;
      expect(tenant, isNotNull);
      expect(query.actions, {api.AuditAction.memberPeriodInvited});
      expect(language, 'es');
      expect(
        downloader.saved.single.fileName,
        'hoops-role-test-audit-20261110.csv',
      );
      expect(downloader.saved.single.bytes, repo.csv);
    });

    testWidgets('more than 10,000 rows asks to narrow the range', (
      tester,
    ) async {
      final repo = FakeAuditRepository()
        ..exportFailure = const AppError(
          kind: AppErrorKind.validation,
          status: 422,
          code: 'EXPORT_TOO_LARGE',
        );
      final downloader = FakeFileDownloader();
      await _academy(tester, repo, downloader);

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
      final h = await _academy(
        tester,
        FakeAuditRepository(),
        FakeFileDownloader(),
      );
      h.online.add(false);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(_icon).onPressed, isNull);
    });
  });

  group('platform audit trail', () {
    testWidgets('exports every academy', (tester) async {
      final repo = FakeAuditRepository();
      final downloader = FakeFileDownloader();
      await _platform(tester, repo, downloader, '/app-admin/activity');

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      final (tenant, _, language) = repo.platformExports.single;
      expect(tenant, isNull);
      expect(language, 'es');
      expect(
        downloader.saved.single.fileName,
        'hoops-platform-audit-20261110.csv',
      );
    });

    testWidgets('narrows to the academy of its detail page', (tester) async {
      final repo = FakeAuditRepository();
      await _platform(
        tester,
        repo,
        FakeFileDownloader(),
        '/app-admin/academies/t-a/activity',
      );

      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();

      expect(repo.platformExports.single.$1, 't-a');
    });
  });
}
