import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_platform.dart';
import '../../support/fake_repos.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';

FakePlatformRepository _repo() => FakePlatformRepository(
  tenants: [
    tenantOf('t-a', 'Club Norte'),
    tenantOf('t-b', 'Academia Sur', status: api.TenantStatus.SUSPENDED),
    tenantOf('t-c', 'Liceo Viejo', status: api.TenantStatus.WITHDRAWN),
  ],
);

Future<Harness> _pumpPlatform(WidgetTester tester, FakePlatformRepository repo, {String location = '/platform', bool settle = true, Size? size}) async {
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: true)),
    core: FakeCore(),
    platform: FakePlatform(repo: repo),
  );
  await h.pump(tester, size: size ?? const Size(360, 1200));
  settle ? await h.go(tester, location) : await h.goAndPump(tester, location);
  return h;
}

api.TenantUsage _usage({List<api.TenantUsageUnavailableServicesEnum> unavailable = const []}) => api.TenantUsage(
  (b) => b
    ..tenantId = 't-a'
    ..collectedAt = DateTime.utc(2026, 11, 1)
    ..services.replace([
      usageReport('core', {'members': 12, 'players': 80, 'teams': 6, 'newCounter': 3}),
      usageReport('athlete', {'trainingSessions': 240, 'injuries': 4}),
    ])
    ..unavailableServices = ListBuilder(unavailable),
);

void main() {
  group('tenants list', () {
    testWidgets('loading', (tester) async {
      // Start on a tenant page (a spinner would never settle on the home route), then open the console.
      final h = Harness(
        me: FakeMeRepository(userWith([membershipWithRoles({TenantRole.admin})], superAdmin: true)),
        core: athleteCore(),
        platform: FakePlatform(repo: _repo()..hang = true),
      );
      await h.pump(tester);
      await h.goAndPump(tester, '/platform');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final repo = _repo()..failWith = StateError('x');
      await _pumpPlatform(tester, repo);
      expect(find.text('Reintentar'), findsOneWidget);
      repo.failWith = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Club Norte'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _pumpPlatform(tester, FakePlatformRepository());
      expect(find.text('No hay academias con este filtro'), findsOneWidget);
    });

    testWidgets('populated with a status chip (label, not colour alone) per tenant', (tester) async {
      await _pumpPlatform(tester, _repo());
      expect(find.text('Club Norte'), findsOneWidget);
      expect(find.text('club-norte'), findsOneWidget);
      Finder chip(String id, String label) => find.descendant(of: find.byKey(Key('tenant-$id')), matching: find.text(label));
      expect(chip('t-a', 'Activa'), findsOneWidget);
      expect(chip('t-b', 'Suspendida'), findsOneWidget);
      expect(chip('t-c', 'Retirada'), findsOneWidget);
    });

    testWidgets('status filter and search go to the repository', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo);
      await tapKey2(tester, 'status-SUSPENDED');
      expect(repo.lastStatusFilter, api.TenantStatus.SUSPENDED);
      expect(find.text('Academia Sur'), findsOneWidget);
      expect(find.text('Club Norte'), findsNothing);
      await tapKey2(tester, 'status-all');
      await tester.enterText(find.byKey(const Key('tenant-search')), 'liceo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.lastQuery, 'liceo');
      expect(find.text('Liceo Viejo'), findsOneWidget);
    });

    testWidgets('create: validates slug and e-mail, then sends the first admin', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo);
      await tapKey2(tester, 'tenant-new');
      await tester.enterText(find.byKey(const Key('tenant-name')), 'Nueva Academia');
      await tester.enterText(find.byKey(const Key('tenant-slug')), 'Bad Slug!');
      await tester.enterText(find.byKey(const Key('tenant-admin-email')), 'nope');
      await tester.enterText(find.byKey(const Key('tenant-admin-given')), 'Ada');
      await tester.enterText(find.byKey(const Key('tenant-admin-family')), 'Lovelace');
      await tapKey2(tester, 'form-submit');
      expect(find.text('Solo minúsculas, números y guiones (3-50)'), findsOneWidget);
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(repo.created, isNull);
      await tester.enterText(find.byKey(const Key('tenant-slug')), 'nueva-academia');
      await tester.enterText(find.byKey(const Key('tenant-admin-email')), 'ada@example.org');
      await tapKey2(tester, 'tenant-locale');
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tapKey2(tester, 'form-submit');
      final c = repo.created!;
      expect((c.slug, c.name, c.timezone, c.defaultLocale), ('nueva-academia', 'Nueva Academia', 'Europe/Madrid', api.ApiLocale.en));
      expect((c.firstAdmin.email, c.firstAdmin.givenName, c.firstAdmin.familyName), ('ada@example.org', 'Ada', 'Lovelace'));
      expect(find.text('Nueva Academia'), findsOneWidget);
    });
  });

  group('tenant detail and usage', () {
    testWidgets('ACTIVE offers suspend and withdraw; suspend needs a reason and flips the chip', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo, location: '/platform/t-a');
      expect(find.byKey(const Key('tenant-reactivate')), findsNothing);
      await tapKey2(tester, 'tenant-suspend');
      await tapKey2(tester, 'dialog-confirm');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('note-field')), 'Impago');
      await tapKey2(tester, 'dialog-confirm');
      expect(repo.lastReason, 'Impago');
      expect(find.text('Suspendida'), findsOneWidget);
      expect(find.byKey(const Key('tenant-reactivate')), findsOneWidget);
      expect(find.byKey(const Key('tenant-suspend')), findsNothing);
    });

    testWidgets('reactivate a suspended tenant', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo, location: '/platform/t-b');
      await tapKey2(tester, 'tenant-reactivate');
      await tapKey2(tester, 'dialog-confirm');
      expect(repo.list.firstWhere((t) => t.id == 't-b').status, api.TenantStatus.ACTIVE);
      expect(find.text('Activa'), findsOneWidget);
    });

    testWidgets('withdraw is terminal: no actions afterwards, and warns about retention', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo, location: '/platform/t-a');
      await tapKey2(tester, 'tenant-withdraw');
      expect(find.textContaining('plazo de conservación'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('note-field')), 'Cierre');
      await tapKey2(tester, 'dialog-confirm');
      expect(repo.list.first.status, api.TenantStatus.WITHDRAWN);
      expect(find.byKey(const Key('tenant-withdraw')), findsNothing);
      expect(find.byKey(const Key('tenant-suspend')), findsNothing);
    });

    testWidgets('usage dashboard: counters per service (known keys localised, unknown shown raw) and bars', (tester) async {
      final repo = _repo()..usageResult = _usage();
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('usage-core')), findsOneWidget);
      expect(find.byKey(const Key('usage-athlete')), findsOneWidget);
      expect(find.text('Miembros'), findsOneWidget);
      expect(find.text('Sesiones de entreno'), findsOneWidget);
      expect(find.text('newCounter'), findsOneWidget);
      expect(find.byKey(const Key('counter-players')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('counter-players'))).data, '80');
      expect(find.byKey(const Key('usage-unavailable')), findsNothing);
    });

    testWidgets('unavailableServices shows the notice naming the services', (tester) async {
      final repo = _repo()..usageResult = _usage(unavailable: [api.TenantUsageUnavailableServicesEnum.game]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('usage-unavailable')), findsOneWidget);
      expect(find.textContaining('Sin datos de: Partidos'), findsOneWidget);
    });

    testWidgets('a usage failure does not hide the tenant', (tester) async {
      final repo = _repo()..usageFails = true;
      await _pumpPlatform(tester, repo, location: '/platform/t-a');
      expect(find.text('club-norte'), findsOneWidget);
      expect(find.byKey(const Key('usage-failed')), findsOneWidget);
    });

    testWidgets('tenant lookup error shows retry', (tester) async {
      final repo = _repo()..failWith = StateError('x');
      await _pumpPlatform(tester, repo, location: '/platform/t-a');
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('access', () {
    testWidgets('only super_admin: a COACH is redirected away from the console', (tester) async {
      final h = Harness(
        me: FakeMeRepository(userWith([membershipWithRoles({TenantRole.coach})])),
        core: athleteCore(),
        platform: FakePlatform(repo: _repo()),
      );
      await h.pump(tester);
      await h.go(tester, '/platform');
      expect(h.container.read(routerProvider).state.uri.path, '/teams');
      expect(find.byKey(const Key('tenant-new')), findsNothing);
    });

    testWidgets('a super_admin that also has memberships can use the console', (tester) async {
      final h = Harness(
        me: FakeMeRepository(userWith([membershipWithRoles({TenantRole.admin})], superAdmin: true)),
        core: athleteCore(),
        platform: FakePlatform(repo: _repo()),
      );
      await h.pump(tester);
      await h.go(tester, '/platform');
      expect(find.text('Club Norte'), findsOneWidget);
      expect(h.container.read(routerProvider).state.uri.path, '/platform');
    });

    testWidgets('the platform repository is never called for non super_admin users', (tester) async {
      final repo = _repo();
      final h = Harness(
        me: FakeMeRepository(userWith([membershipWithRoles({TenantRole.admin})])),
        core: athleteCore(),
        platform: FakePlatform(repo: repo),
      );
      await h.pump(tester);
      await h.go(tester, '/platform/t-a');
      expect(repo.calls, isEmpty);
    });
  });
}

Future<void> tapKey2(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}
