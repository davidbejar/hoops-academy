import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/application/audit_providers.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';
import 'package:hoops_app/features/audit/presentation/audit_labels.dart';
import 'package:hoops_app/features/audit/presentation/audit_log_screen.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

import '../../support/fake_audit.dart';
import '../../support/fake_platform.dart';
import '../../support/fake_repos.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

List<AuditEntry> _trail() => [
  auditEntry(
    'e1',
    api.AuditAction.memberPeriodInvited,
    at: DateTime.utc(2026, 11, 3, 9, 30),
  ),
  auditEntry(
    'e2',
    api.AuditAction.memberPeriodTemporaryPasswordExpired,
    actorKind: api.AuditActorKind.SYSTEM,
    actorName: null,
    targetName: null,
  ),
  auditEntry(
    'e3',
    api.AuditAction.adminPeriodAdded,
    actorKind: api.AuditActorKind.PLATFORM,
    actorSubject:
        null, // masked by the server for an academy (core 2.6.0, WP38)
    actorName: null,
    targetName: 'Ana Ruiz',
  ),
  auditEntry(
    'e4',
    api.AuditAction.tenantPeriodProfileChanged,
    targetType: api.AuditTargetType.tenant,
    targetName: 'Club Norte',
  ),
];

Future<Harness> _pumpAcademy(
  WidgetTester tester,
  FakeAuditRepository repo, {
  Set<TenantRole> roles = const {TenantRole.admin},
  bool settle = true,
  Size size = const Size(360, 780),
}) => pumpAs(
  tester,
  roles: roles,
  core: FakeCore(),
  location: '/admin/activity',
  settle: settle,
  size: size,
  overrides: repo.overrides,
);

Future<Harness> _pumpPlatform(
  WidgetTester tester,
  FakeAuditRepository repo,
  String location, {
  bool superAdmin = true,
}) async {
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: superAdmin)),
    core: FakeCore(),
    platform: FakePlatform(
      repo: FakePlatformRepository(tenants: [tenantOf('t-a', 'Club Norte')]),
    ),
    extraOverrides: repo.overrides,
  );
  await h.pump(tester, size: const Size(1024, 900));
  await h.go(tester, location);
  return h;
}

void main() {
  group('academy activity', () {
    testWidgets('the admin hub links to it', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: '/admin',
        overrides: FakeAuditRepository().overrides,
      );
      await tester.tap(find.byKey(const Key('admin-activity')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audit-log')), findsOneWidget);
    });

    testWidgets('loading', (tester) async {
      await _pumpAcademy(
        tester,
        FakeAuditRepository()..hang = true,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final repo = FakeAuditRepository(_trail())..failWith = StateError('x');
      await _pumpAcademy(tester, repo);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      repo.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Miembro invitado'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _pumpAcademy(tester, FakeAuditRepository());
      expect(find.text('No hay actividad con este filtro'), findsOneWidget);
    });

    testWidgets(
      'populated: localized action, target, actor (names, system, platform) and time',
      (tester) async {
        final repo = FakeAuditRepository(_trail());
        await _pumpAcademy(tester, repo, size: const Size(360, 1200));
        Finder inTile(String id, String text) => find.descendant(
          of: find.byKey(Key('audit-$id')),
          matching: find.textContaining(text),
        );
        expect(inTile('e1', 'Miembro invitado'), findsOneWidget);
        expect(inTile('e1', 'Leo Gil'), findsOneWidget);
        expect(inTile('e1', 'Por Ana Ruiz'), findsOneWidget);
        expect(inTile('e2', 'Contraseña temporal caducada'), findsOneWidget);
        expect(inTile('e2', 'Por Sistema'), findsOneWidget);
        expect(
          inTile('e2', 'Persona'),
          findsOneWidget,
          reason: 'an unnamed target shows its type',
        );
        expect(
          inTile('e3', 'Por Administrador de la plataforma'),
          findsOneWidget,
        );
        expect(inTile('e4', 'Club Norte'), findsOneWidget);
        expect(
          repo.academyQueries.single.$1,
          isNotNull,
          reason: 'scoped to the active academy',
        );
      },
    );

    testWidgets(
      'filtering by actions asks the server and resets to the first page',
      (tester) async {
        final repo = FakeAuditRepository(_trail());
        await _pumpAcademy(tester, repo, size: const Size(360, 1200));
        await tester.tap(find.byKey(const Key('audit-actions')));
        await tester.pumpAndSettle();
        for (final wire in ['member.invited', 'tenant.profile_changed']) {
          await tester.ensureVisible(find.byKey(Key('audit-action-$wire')));
          await tester.tap(find.byKey(Key('audit-action-$wire')));
          await tester.pump();
        }
        await tester.tap(find.byKey(const Key('audit-actions-apply')));
        await tester.pumpAndSettle();
        expect(repo.academyQueries.last.$2.actions, {
          api.AuditAction.memberPeriodInvited,
          api.AuditAction.tenantPeriodProfileChanged,
        });
        expect(find.byKey(const Key('audit-e1')), findsOneWidget);
        expect(find.byKey(const Key('audit-e2')), findsNothing);
        expect(find.text('2 acciones'), findsOneWidget);

        await tester.tap(find.byKey(const Key('audit-actions')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('audit-actions-clear')));
        await tester.pumpAndSettle();
        expect(repo.academyQueries.last.$2.actions, isEmpty);
        expect(find.text('Todas las acciones'), findsOneWidget);
      },
    );

    testWidgets('paging moves through the server pages', (tester) async {
      final many = [
        for (var i = 0; i < AuditQuery.pageSize + 3; i++)
          auditEntry('m$i', api.AuditAction.memberPeriodUpdated),
      ];
      final repo = FakeAuditRepository(many);
      await _pumpAcademy(tester, repo);
      expect(find.text('Página 1 de 2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('audit-prev')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('audit-next')));
      await tester.pumpAndSettle();
      expect(repo.academyQueries.last.$2.page, 1);
      expect(find.text('Página 2 de 2'), findsOneWidget);
      expect(find.byKey(Key('audit-m${AuditQuery.pageSize}')), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('audit-next')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('audit-prev')));
      await tester.pumpAndSettle();
      expect(repo.academyQueries.last.$2.page, 0);
    });

    testWidgets(
      'a date range is sent as UTC instants of local day starts, to exclusive',
      (tester) async {
        final repo = FakeAuditRepository(_trail());
        final h = await _pumpAcademy(tester, repo);
        h.container
            .read(auditQueryProvider(const AuditScope.academy()).notifier)
            .setRange(DateTime(2026, 11, 1), DateTime(2026, 11, 3));
        await tester.pumpAndSettle();
        final q = repo.academyQueries.last.$2;
        expect(q.fromInstant, DateTime(2026, 11, 1).toUtc());
        expect(q.toInstant, DateTime(2026, 11, 4).toUtc());
        expect(q.fromInstant!.isUtc, isTrue);
        expect(find.byKey(const Key('audit-range-clear')), findsOneWidget);
        await tester.tap(find.byKey(const Key('audit-range-clear')));
        await tester.pumpAndSettle();
        expect(repo.academyQueries.last.$2.fromInstant, isNull);
      },
    );

    testWidgets('the date button opens the range picker', (tester) async {
      final repo = FakeAuditRepository(_trail());
      // Wide: the picker's own header overflows with the square test font at phone width.
      await _pumpAcademy(tester, repo, size: const Size(1024, 900));
      await tester.tap(find.byKey(const Key('audit-range')));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('non-admins have no activity entry in the hub', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        core: FakeCore(),
        location: '/admin',
        overrides: FakeAuditRepository().overrides,
      );
      expect(find.byKey(const Key('admin-activity')), findsNothing);
    });
  });

  group('platform activity', () {
    testWidgets(
      'lists every academy with its name and opens from the console',
      (tester) async {
        final repo = FakeAuditRepository([
          auditEntry(
            'p1',
            api.AuditAction.tenantPeriodSuspended,
            targetType: api.AuditTargetType.tenant,
            targetName: 'Club Norte',
            actorKind: api.AuditActorKind.PLATFORM,
            actorName: null,
            tenantId: 't-a',
            tenantName: 'Club Norte',
          ),
          auditEntry(
            'p2',
            api.AuditAction.memberPeriodInvited,
            tenantId: 't-b',
            tenantName: 'Academia Sur',
          ),
        ]);
        await _pumpPlatform(tester, repo, '/app-admin');
        await tester.tap(find.byKey(const Key('app-admin-activity')));
        await tester.pumpAndSettle();
        expect(repo.platformQueries.last.$1, isNull);
        expect(
          find.descendant(
            of: find.byKey(const Key('audit-p2')),
            matching: find.textContaining('Academia Sur'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('audit-p1')),
            matching: find.textContaining('Academia suspendida'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('one academy from its detail page', (tester) async {
      final repo = FakeAuditRepository([
        auditEntry(
          'p1',
          api.AuditAction.adminPeriodAdded,
          tenantId: 't-a',
          tenantName: 'Club Norte',
        ),
      ]);
      await _pumpPlatform(tester, repo, '/platform/t-a');
      await tester.tap(find.byKey(const Key('tenant-activity')));
      await tester.pumpAndSettle();
      expect(repo.platformQueries.last.$1, 't-a');
      expect(find.byKey(const Key('audit-p1')), findsOneWidget);
    });

    testWidgets('is forbidden without super_admin', (tester) async {
      final repo = FakeAuditRepository();
      await _pumpPlatform(
        tester,
        repo,
        '/platform/activity',
        superAdmin: false,
      );
      expect(find.byKey(const Key('audit-log')), findsNothing);
      expect(repo.platformQueries, isEmpty);
    });
  });

  group('labels', () {
    const platformActor = {
      'es': 'Administrador de la plataforma',
      'en': 'Platform administrator',
      'id': 'Administrator platform',
    };
    for (final MapEntry(key: code, value: label) in platformActor.entries) {
      testWidgets('a masked platform actor reads "$label" in $code (WP38)', (
        tester,
      ) async {
        final entry = auditEntry(
          'm1',
          api.AuditAction.tenantPeriodSuspended,
          actorKind: api.AuditActorKind.PLATFORM,
          actorSubject: null,
          actorName: null,
          targetType: api.AuditTargetType.tenant,
          targetName: 'Club Norte',
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: AuditEntryTile(entry: entry)),
          ),
        );
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(code));
        expect(find.textContaining(l.auditByActor(label)), findsOneWidget);
      });
    }

    for (final locale in AppLocalizations.supportedLocales) {
      test('one distinct label per action in ${locale.languageCode}', () {
        final l = lookupAppLocalizations(locale);
        expect(
          auditActions,
          hasLength(api.AuditAction.values.length - 1),
          reason: 'all but the unknown fallback',
        );
        final labels = [for (final a in auditActions) a.label(l)];
        expect(labels.where((s) => s.trim().isEmpty), isEmpty);
        expect(labels.toSet(), hasLength(auditActions.length));
        expect(labels, isNot(contains(contains('.'))), reason: 'no wire names');
        for (final a in auditActions) {
          expect(
            a.label(l),
            isNot(anyOf(a.name, auditWireName(a))),
            reason: '${auditWireName(a)} has no label of its own',
          );
        }
      });
    }
  });
}
