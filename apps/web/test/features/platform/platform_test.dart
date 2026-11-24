import 'package:built_collection/built_collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/core_seed.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/mock_backend.dart';
import '../../support/platform_seed.dart';
import '../../support/pump_helpers.dart';

const _tenants = '/platform/tenants';
const _norte = '/platform/tenants/t-a';
const _admins = '/platform/tenants/t-a/admins';

final _academies = [
  tenantOf('t-a', 'Club Norte'),
  tenantOf('t-b', 'Academia Sur', status: api.TenantStatus.SUSPENDED),
  tenantOf('t-c', 'Liceo Viejo', status: api.TenantStatus.WITHDRAWN),
];

/// The platform with three academies: active, suspended and withdrawn.
MockBackend _backend() => MockBackend()..seedTenants(_academies);

/// The temporary password the mock answered the last POST to [path] with.
String _passwordFrom(MockBackend backend, String path) =>
    (backend.lastAnswer(path, method: 'POST')! as Map)['temporaryPassword']
        as String;

Future<Harness> _pumpPlatform(
  WidgetTester tester,
  MockBackend backend, {
  String location = '/platform',
  bool settle = true,
  Size? size,
}) async {
  return pumpAsSuperAdmin(
    tester,
    backend: backend,
    location: location,
    size: size ?? const Size(360, 1200),
    settle: settle,
  );
}

api.TenantUsage _usage({
  List<api.TenantUsageUnavailableServicesEnum> unavailable = const [],
}) => api.TenantUsage(
  (b) => b
    ..tenantId = 't-a'
    ..collectedAt = DateTime.utc(2026, 11, 1)
    ..services.replace([
      usageReport('core', {
        'members': 12,
        'players': 80,
        'teams': 6,
        'newCounter': 3,
      }),
      usageReport('athlete', {'trainingSessions': 240, 'injuries': 4}),
    ])
    ..unavailableServices = ListBuilder(unavailable),
);

void main() {
  group('tenants list', () {
    testWidgets('loading', (tester) async {
      // Start on a tenant page (a spinner would never settle on the home route), then open the console.
      final h = Harness(
        me: FakeMeRepository(
          userWith([
            membershipWithRoles({TenantRole.admin}),
          ], superAdmin: true),
        ),
        prefs: {'hoops.selectedTenantId': membershipWithRoles({}).tenantId},
        core: athleteCore(),
        backend: _backend()..hang(_tenants),
      );
      await h.pump(tester);
      await h.goAndPump(tester, '/platform');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final backend = _backend()..fail(_tenants);
      await _pumpPlatform(tester, backend);
      expect(find.text('Reintentar'), findsOneWidget);
      backend.heal();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Club Norte'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _pumpPlatform(tester, MockBackend());
      expect(find.text('No hay academias con este filtro'), findsOneWidget);
    });

    testWidgets(
      'populated with a status chip (label, not colour alone) per tenant',
      (tester) async {
        await _pumpPlatform(tester, _backend());
        expect(find.text('Club Norte'), findsOneWidget);
        expect(find.text('club-norte'), findsOneWidget);
        Finder chip(String id, String label) => find.descendant(
          of: find.byKey(Key('tenant-$id')),
          matching: find.text(label),
        );
        expect(chip('t-a', 'Activa'), findsOneWidget);
        expect(chip('t-b', 'Suspendida'), findsOneWidget);
        expect(chip('t-c', 'Retirada'), findsOneWidget);
      },
    );

    testWidgets('status filter and search go to the server', (tester) async {
      final backend = _backend();
      await _pumpPlatform(tester, backend);
      await tapKey2(tester, 'status-SUSPENDED');
      expect(backend.lastQuery(_tenants).text('status'), 'SUSPENDED');
      expect(find.text('Academia Sur'), findsOneWidget);
      expect(find.text('Club Norte'), findsNothing);
      await tapKey2(tester, 'status-all');
      await tester.enterText(find.byKey(const Key('tenant-search')), 'liceo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(backend.lastQuery(_tenants).text('q'), 'liceo');
      expect(find.text('Liceo Viejo'), findsOneWidget);
    });

    testWidgets(
      'create: validates slug and e-mail, then sends the first admin',
      (tester) async {
        final backend = _backend();
        await _pumpPlatform(tester, backend);
        await tapKey2(tester, 'tenant-new');
        await tester.enterText(
          find.byKey(const Key('tenant-name')),
          'Nueva Academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-slug')),
          'Bad Slug!',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-email')),
          'nope',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-given')),
          'Ada',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-family')),
          'Lovelace',
        );
        await tapKey2(tester, 'form-submit');
        expect(
          find.text('Solo minúsculas, números y guiones (3-50)'),
          findsOneWidget,
        );
        expect(find.text('Introduce un correo válido'), findsOneWidget);
        expect(backend.requestsTo(_tenants, method: 'POST'), isEmpty);
        await tester.enterText(
          find.byKey(const Key('tenant-slug')),
          'nueva-academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-email')),
          'ada@example.org',
        );
        await tapKey2(tester, 'tenant-locale');
        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();
        await tapKey2(tester, 'form-submit');
        final c = backend.lastBody(_tenants);
        expect(
          (c['slug'], c['name'], c['timezone'], c['defaultLocale']),
          ('nueva-academia', 'Nueva Academia', 'Europe/Madrid', 'en'),
        );
        final first = c['firstAdmin']! as Map;
        expect(
          (first['email'], first['givenName'], first['familyName']),
          ('ada@example.org', 'Ada', 'Lovelace'),
        );
        final password = _passwordFrom(backend, _tenants);
        // The first administrator's login is new: its temporary password is shown once, for the creator to pass on.
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          password,
        );
        expect(find.textContaining('ada@example.org'), findsOneWidget);
        await tapKey2(tester, 'temp-password-done');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.text(password), findsNothing);
        expect(find.text('Nueva Academia'), findsOneWidget);
      },
    );

    testWidgets(
      'create: a first admin who already has a login gets no dialog, only the note to use their password',
      (tester) async {
        // Ada already signs in to another academy: her login is linked.
        final backend = _backend()
          ..seedLogins([platformUserOf('u-ada', 'ada@example.org')]);
        await _pumpPlatform(tester, backend);
        await tapKey2(tester, 'tenant-new');
        await tester.enterText(
          find.byKey(const Key('tenant-name')),
          'Nueva Academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-slug')),
          'nueva-academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-email')),
          'ada@example.org',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-given')),
          'Ada',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-family')),
          'Lovelace',
        );
        await tapKey2(tester, 'form-submit');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.textContaining('contraseña actual'), findsOneWidget);
        expect(find.text('Nueva Academia'), findsOneWidget);
      },
    );

    testWidgets(
      'create: a failure keeps the form open and shows no password dialog',
      (tester) async {
        final backend = _backend()
          ..fail(
            _tenants,
            method: 'POST',
            status: 502,
            code: 'IDENTITY_PROVIDER_UNAVAILABLE',
          );
        await _pumpPlatform(tester, backend);
        await tapKey2(tester, 'tenant-new');
        await tester.enterText(
          find.byKey(const Key('tenant-name')),
          'Nueva Academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-slug')),
          'nueva-academia',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-email')),
          'ada@example.org',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-given')),
          'Ada',
        );
        await tester.enterText(
          find.byKey(const Key('tenant-admin-family')),
          'Lovelace',
        );
        await tapKey2(tester, 'form-submit');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.byKey(const Key('tenant-name')), findsOneWidget);
      },
    );
  });

  group('tenant detail and usage', () {
    testWidgets(
      'ACTIVE offers suspend and withdraw; suspend needs a reason and flips the chip',
      (tester) async {
        final backend = _backend();
        await _pumpPlatform(tester, backend, location: '/platform/t-a');
        expect(find.byKey(const Key('tenant-reactivate')), findsNothing);
        await tapKey2(tester, 'tenant-suspend');
        await tapKey2(tester, 'dialog-confirm');
        expect(find.text('Campo obligatorio'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('note-field')), 'Impago');
        await tapKey2(tester, 'dialog-confirm');
        expect(backend.lastBody('$_norte/suspend')['reason'], 'Impago');
        expect(find.text('Suspendida'), findsOneWidget);
        expect(find.byKey(const Key('tenant-reactivate')), findsOneWidget);
        expect(find.byKey(const Key('tenant-suspend')), findsNothing);
      },
    );

    testWidgets('reactivate a suspended tenant', (tester) async {
      final backend = _backend();
      await _pumpPlatform(tester, backend, location: '/platform/t-b');
      await tapKey2(tester, 'tenant-reactivate');
      await tapKey2(tester, 'dialog-confirm');
      expect(backend.tenantNow('t-b')['status'], 'ACTIVE');
      expect(find.text('Activa'), findsOneWidget);
    });

    testWidgets(
      'withdraw is terminal: no actions afterwards, and warns about retention',
      (tester) async {
        final backend = _backend();
        await _pumpPlatform(tester, backend, location: '/platform/t-a');
        await tapKey2(tester, 'tenant-withdraw');
        expect(find.textContaining('plazo de conservación'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('note-field')), 'Cierre');
        await tapKey2(tester, 'dialog-confirm');
        expect(backend.tenantNow('t-a')['status'], 'WITHDRAWN');
        expect(find.byKey(const Key('tenant-withdraw')), findsNothing);
        expect(find.byKey(const Key('tenant-suspend')), findsNothing);
      },
    );

    testWidgets(
      'usage dashboard: counters per service (known keys localised, unknown shown raw) and bars',
      (tester) async {
        final backend = _backend()..seedUsage('t-a', _usage());
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        expect(find.byKey(const Key('usage-core')), findsOneWidget);
        expect(find.byKey(const Key('usage-athlete')), findsOneWidget);
        expect(find.text('Miembros'), findsOneWidget);
        expect(find.text('Sesiones de entreno'), findsOneWidget);
        expect(find.text('newCounter'), findsOneWidget);
        expect(find.byKey(const Key('counter-players')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('counter-players'))).data,
          '80',
        );
        expect(find.byKey(const Key('usage-unavailable')), findsNothing);
      },
    );

    api.TenantUsageSnapshot snap(int day, int players, {int members = 10}) =>
        api.TenantUsageSnapshot(
          (b) => b
            ..date = api.Date(2026, 11, day)
            ..collectedAt = DateTime.utc(2026, 11, day, 3)
            ..services.replace([
              usageReport('core', {'players': players, 'members': members}),
            ]),
        );

    testWidgets(
      'usage trend: a line chart of the chosen counter over the snapshots',
      (tester) async {
        final backend = _backend()
          ..seedUsage('t-a', _usage())
          ..seedUsageHistory('t-a', [snap(1, 60), snap(2, 70), snap(3, 80)]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 2400),
        );
        expect(find.byKey(const Key('usage-trend')), findsOneWidget);
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.byKey(const Key('usage-trend-counter')), findsOneWidget);
        expect(backend.requestsTo('$_norte/usage/history'), isNotEmpty);
      },
    );

    testWidgets('usage trend: empty history says so', (tester) async {
      final backend = _backend()
        ..seedUsage('t-a', _usage())
        ..seedUsageHistory('t-a', []);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 2400),
      );
      expect(find.byKey(const Key('usage-trend-empty')), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('usage trend: loading and error with retry', (tester) async {
      final backend = _backend()
        ..seedUsage('t-a', _usage())
        ..fail('$_norte/usage/history');
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 2400),
      );
      expect(find.byKey(const Key('usage-trend-error')), findsOneWidget);
      backend
        ..heal()
        ..seedUsageHistory('t-a', [snap(1, 60)]);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('usage-trend-error')),
          matching: find.byKey(const Key('retry-button')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('unavailableServices shows the notice naming the services', (
      tester,
    ) async {
      final backend = _backend()
        ..seedUsage(
          't-a',
          _usage(unavailable: [api.TenantUsageUnavailableServicesEnum.game]),
        );
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      expect(find.byKey(const Key('usage-unavailable')), findsOneWidget);
      expect(find.textContaining('Sin datos de: Partidos'), findsOneWidget);
    });

    testWidgets('a usage failure does not hide the tenant', (tester) async {
      final backend = _backend()..fail('$_norte/usage');
      await _pumpPlatform(tester, backend, location: '/platform/t-a');
      expect(find.text('club-norte'), findsOneWidget);
      expect(find.byKey(const Key('usage-failed')), findsOneWidget);
    });

    testWidgets('tenant lookup error shows retry', (tester) async {
      final backend = _backend()..fail(_norte);
      await _pumpPlatform(tester, backend, location: '/platform/t-a');
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('administrators', () {
    const lastAdminNote =
        'Una academia necesita al menos un administrador. Añade otro administrador antes de quitar a este.';
    const withdrawnNote =
        'La academia está retirada: sus administradores ya no se pueden consultar ni modificar.';

    /// The three academies, Club Norte (`t-a`) with [admins].
    MockBackend repoWith(List<api.TenantAdmin> admins) =>
        _backend()..seedAdmins('t-a', admins);

    final ana = adminOf(
      'p-ana',
      'Ana',
      'Ruiz',
      email: 'ana@example.org',
      otherRoles: {api.TenantRole.COACH},
    );
    final bea = adminOf(
      'p-bea',
      'Bea',
      'Soto',
      email: 'bea@example.org',
      status: api.InvitationStatus.PENDING,
    );

    testWidgets('lists name, e-mail, invitation status and the other roles', (
      tester,
    ) async {
      await _pumpPlatform(
        tester,
        repoWith([ana, bea]),
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      expect(find.byKey(const Key('admins-section')), findsOneWidget);
      expect(find.text('Administradores'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('ana@example.org'), findsOneWidget);
      expect(find.text('Bea Soto'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-p-ana')),
          matching: find.text('Invitación aceptada'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-p-bea')),
          matching: find.text('Invitación pendiente'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-p-ana')),
          matching: find.textContaining('Entrenador'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-p-bea')),
          matching: find.textContaining('También'),
        ),
        findsNothing,
      );
    });

    testWidgets('loading shows a spinner inside the section only', (
      tester,
    ) async {
      final backend = repoWith([ana])..hang(_admins);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('admins-loading')), findsOneWidget);
      expect(find.byKey(const Key('tenant-suspend')), findsOneWidget);
    });

    testWidgets('list error keeps the tenant visible and retries', (
      tester,
    ) async {
      final backend = repoWith([ana])..fail(_admins);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      expect(find.byKey(const Key('admins-error')), findsOneWidget);
      expect(find.byKey(const Key('tenant-suspend')), findsOneWidget);
      backend.heal();
      await tapKey2(tester, 'admins-retry');
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.byKey(const Key('admins-error')), findsNothing);
    });

    testWidgets(
      'add: explains promotion vs temporary password (no e-mail), validates, sends trimmed values with the academy locale',
      (tester) async {
        final backend = repoWith([ana]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-add');
        expect(find.textContaining('pasa a ser administrador'), findsOneWidget);
        expect(find.textContaining('contraseña temporal'), findsOneWidget);
        expect(find.textContaining('correo se envía'), findsNothing);
        expect(find.textContaining('invitación por correo'), findsNothing);
        await tester.enterText(find.byKey(const Key('admin-email')), 'nope');
        await tapKey2(tester, 'form-submit');
        expect(find.text('Introduce un correo válido'), findsOneWidget);
        expect(find.text('Campo obligatorio'), findsNWidgets(2));
        expect(backend.requestsTo(_admins, method: 'POST'), isEmpty);
        await tester.enterText(
          find.byKey(const Key('admin-email')),
          '  cris@example.org ',
        );
        await tester.enterText(find.byKey(const Key('admin-given')), ' Cris ');
        await tester.enterText(find.byKey(const Key('admin-family')), 'Mora');
        await tapKey2(tester, 'form-submit');
        final r = backend.lastBody(_admins);
        expect(
          (r['email'], r['givenName'], r['familyName'], r['locale']),
          ('cris@example.org', 'Cris', 'Mora', 'es'),
        );
        final added = backend.lastAnswer(_admins, method: 'POST')! as Map;
        final password = added['temporaryPassword'] as String;
        // New login: the temporary password is shown once; the list below never holds it.
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          password,
        );
        expect(find.textContaining('cris@example.org'), findsWidgets);
        await tapKey2(tester, 'temp-password-done');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.text(password), findsNothing);
        expect(find.byKey(Key('admin-${added['personId']}')), findsOneWidget);
        expect(find.textContaining('Invitación enviada'), findsNothing);
      },
    );

    testWidgets(
      'add: an existing login (promotion) gets no dialog; the note says to use the current password',
      (tester) async {
        // Cris already signs in to another academy: the login is linked.
        final backend = repoWith([ana])
          ..seedLogins([platformUserOf('u-cris', 'cris@example.org')]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-add');
        await tester.enterText(
          find.byKey(const Key('admin-email')),
          'cris@example.org',
        );
        await tester.enterText(find.byKey(const Key('admin-given')), 'Cris');
        await tester.enterText(find.byKey(const Key('admin-family')), 'Mora');
        await tapKey2(tester, 'form-submit');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.textContaining('Administrador añadido'), findsOneWidget);
        expect(find.textContaining('contraseña actual'), findsOneWidget);
        final added = backend.lastAnswer(_admins, method: 'POST')! as Map;
        expect(find.byKey(Key('admin-${added['personId']}')), findsOneWidget);
      },
    );

    testWidgets(
      'add: a server conflict is explained by its code and keeps the dialog open',
      (tester) async {
        // A deactivated member of the academy has the e-mail (the mock
        // keeps no deactivated members, so the 409 is injected).
        final backend = repoWith([ana])
          ..fail(_admins, method: 'POST', status: 409, code: 'EMAIL_TAKEN');
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-add');
        await tester.enterText(
          find.byKey(const Key('admin-email')),
          'ana@example.org',
        );
        await tester.enterText(find.byKey(const Key('admin-given')), 'Ana');
        await tester.enterText(find.byKey(const Key('admin-family')), 'Ruiz');
        await tapKey2(tester, 'form-submit');
        expect(
          find.text('Ese correo ya lo usa otra persona o cuenta'),
          findsOneWidget,
        );
        expect(find.textContaining('English server detail'), findsNothing);
        expect(find.byKey(const Key('admin-email')), findsOneWidget);
      },
    );

    testWidgets('add: identity provider outage gets its own message', (
      tester,
    ) async {
      final backend = repoWith([ana])
        ..fail(
          _admins,
          method: 'POST',
          status: 502,
          code: 'IDENTITY_PROVIDER_UNAVAILABLE',
        );
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      await tapKey2(tester, 'admin-add');
      await tester.enterText(
        find.byKey(const Key('admin-email')),
        'x@example.org',
      );
      await tester.enterText(find.byKey(const Key('admin-given')), 'X');
      await tester.enterText(find.byKey(const Key('admin-family')), 'Y');
      await tapKey2(tester, 'form-submit');
      expect(
        find.textContaining('servicio de acceso no está disponible'),
        findsOneWidget,
      );
    });

    testWidgets(
      'edit: names only send no e-mail; the dialog warns that the e-mail is the login',
      (tester) async {
        final backend = repoWith([ana, bea]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-edit-p-ana');
        expect(
          find.textContaining('entrará con la nueva dirección'),
          findsOneWidget,
        );
        expect(find.textContaining('verificar'), findsNothing);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('admin-email')))
              .controller!
              .text,
          'ana@example.org',
        );
        await tester.enterText(find.byKey(const Key('admin-given')), 'Anita');
        await tapKey2(tester, 'form-submit');
        final sent = backend.lastBody('$_admins/p-ana', method: 'PATCH');
        expect(
          (sent['givenName'], sent['familyName'], sent['email']),
          ('Anita', null, null),
        );
        expect(find.text('Anita Ruiz'), findsOneWidget);
      },
    );

    testWidgets('edit: a changed e-mail is validated and sent', (tester) async {
      final backend = repoWith([ana, bea]);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      await tapKey2(tester, 'admin-edit-p-bea');
      await tester.enterText(find.byKey(const Key('admin-email')), 'bad');
      await tapKey2(tester, 'form-submit');
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(backend.requestsTo(RegExp('/admins/'), method: 'PATCH'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('admin-email')),
        'bea.soto@example.org',
      );
      await tapKey2(tester, 'form-submit');
      expect(
        backend.lastBody('$_admins/p-bea', method: 'PATCH')['email'],
        'bea.soto@example.org',
      );
      expect(find.text('bea.soto@example.org'), findsOneWidget);
    });

    testWidgets('edit without changes closes without calling the server', (
      tester,
    ) async {
      final backend = repoWith([ana, bea]);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      await tapKey2(tester, 'admin-edit-p-ana');
      await tapKey2(tester, 'form-submit');
      expect(backend.requestsTo(RegExp('/admins/'), method: 'PATCH'), isEmpty);
      expect(find.byKey(const Key('admin-given')), findsNothing);
    });

    testWidgets(
      'remove asks for confirmation (other roles stay) and drops the row',
      (tester) async {
        final backend = repoWith([ana, bea]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-remove-p-ana');
        expect(find.textContaining('demás roles se mantienen'), findsOneWidget);
        await tapKey2(tester, 'dialog-cancel');
        expect(
          backend.requestsTo(RegExp('/admins/'), method: 'DELETE'),
          isEmpty,
        );
        await tapKey2(tester, 'admin-remove-p-ana');
        await tapKey2(tester, 'dialog-confirm');
        expect(
          backend
              .requestsTo(RegExp('/admins/'), method: 'DELETE')
              .map((r) => r.path),
          ['$_admins/p-ana'],
        );
        expect(find.text('Ana Ruiz'), findsNothing);
        expect(find.text('Administrador quitado'), findsOneWidget);
      },
    );

    testWidgets(
      'new temporary password is offered for pending administrators only',
      (tester) async {
        final backend = repoWith([ana, bea]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        expect(find.byKey(const Key('admin-issue-p-ana')), findsNothing);
        expect(
          find.byKey(const Key('admin-resend-p-bea')),
          findsNothing,
        ); // the old "resend invitation" is gone
        expect(
          find.byTooltip('Generar nueva contraseña temporal'),
          findsOneWidget,
        );
        await tapKey2(tester, 'admin-issue-p-bea');
        const issue = '$_admins/p-bea/temporary-password';
        expect(backend.requestsTo(issue, method: 'POST'), hasLength(1));
        final reissued = _passwordFrom(backend, issue);
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          reissued,
        );
        expect(find.textContaining('Bea Soto'), findsWidgets);
        expect(find.textContaining('bea@example.org'), findsWidgets);
        await tapKey2(tester, 'temp-password-done');
        expect(find.text(reissued), findsNothing);
      },
    );

    testWidgets(
      'an expired temporary password is labelled next to the re-issue button until a new one is issued',
      (tester) async {
        final cy = adminOf(
          'p-cy',
          'Cy',
          'Late',
          email: 'cy@example.org',
          status: api.InvitationStatus.PENDING,
          temporaryPassword: api.TemporaryPasswordStatus.EXPIRED,
        );
        final backend = repoWith([ana, bea, cy]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 2400),
        );
        expect(
          find.byKey(const Key('admin-password-expired-p-cy')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('admin-password-expired-p-bea')),
          findsNothing,
        );
        expect(find.text('Contraseña temporal caducada'), findsOneWidget);
        expect(find.byKey(const Key('admin-issue-p-cy')), findsOneWidget);
        await tapKey2(tester, 'admin-issue-p-cy');
        await tapKey2(tester, 'temp-password-done');
        expect(
          find.byKey(const Key('admin-password-expired-p-cy')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'a second re-issue shows the new password, never the previous one',
      (tester) async {
        final backend = repoWith([ana, bea]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        const issue = '$_admins/p-bea/temporary-password';
        await tapKey2(tester, 'admin-issue-p-bea');
        final first = _passwordFrom(backend, issue);
        await tapKey2(tester, 'temp-password-done');
        await tapKey2(tester, 'admin-issue-p-bea');
        final second = _passwordFrom(backend, issue);
        expect(second, isNot(first));
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          second,
        );
        expect(find.text(first), findsNothing);
      },
    );

    testWidgets('re-issue: a stale state is reported by its code, no dialog', (
      tester,
    ) async {
      final backend = repoWith([ana, bea]);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      // Bea signed in meanwhile: her invitation is no longer pending.
      backend.adminNow('t-a', 'p-bea')['invitationStatus'] = 'ACCEPTED';
      await tapKey2(tester, 'admin-issue-p-bea');
      expect(find.text('La invitación ya no está pendiente'), findsOneWidget);
      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
    });

    testWidgets(
      're-issue: an identity provider outage is explained and shows no dialog',
      (tester) async {
        final backend = repoWith([ana, bea])
          ..fail(
            '$_admins/p-bea/temporary-password',
            status: 502,
            code: 'IDENTITY_PROVIDER_UNAVAILABLE',
          );
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        await tapKey2(tester, 'admin-issue-p-bea');
        expect(
          find.textContaining('servicio de acceso no está disponible'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      },
    );

    testWidgets(
      'the only administrator cannot be removed: action disabled and the row explains why',
      (tester) async {
        final backend = repoWith([ana]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('admin-remove-p-ana')))
              .onPressed,
          isNull,
        );
        expect(find.byKey(const Key('admin-last-note')), findsOneWidget);
        expect(find.text(lastAdminNote), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('admin-remove-p-ana')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dialog-confirm')), findsNothing);
        expect(
          backend.requestsTo(RegExp('/admins/'), method: 'DELETE'),
          isEmpty,
        );
        // The other actions stay available.
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('admin-edit-p-ana')))
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'with two administrators remove is enabled and no explanation shows',
      (tester) async {
        await _pumpPlatform(
          tester,
          repoWith([ana, bea]),
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('admin-remove-p-ana')))
              .onPressed,
          isNotNull,
        );
        expect(find.byKey(const Key('admin-last-note')), findsNothing);
      },
    );

    testWidgets('removing down to one administrator disables the last one', (
      tester,
    ) async {
      await _pumpPlatform(
        tester,
        repoWith([ana, bea]),
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      await tapKey2(tester, 'admin-remove-p-bea');
      await tapKey2(tester, 'dialog-confirm');
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('admin-remove-p-ana')))
            .onPressed,
        isNull,
      );
      expect(find.text(lastAdminNote), findsOneWidget);
    });

    testWidgets(
      'a server 409 LAST_ADMIN shows the same localised message, never the English detail',
      (tester) async {
        final backend = repoWith([ana, bea]);
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        // Another super admin removed Bea meanwhile: Ana is the last one.
        backend.platform.admins['t-a']!.removeWhere(
          (a) => a['personId'] == 'p-bea',
        );
        await tapKey2(tester, 'admin-remove-p-ana');
        await tapKey2(tester, 'dialog-confirm');
        expect(
          find.text(lastAdminNote),
          findsOneWidget,
        ); // the snack bar (no row note: two admins are listed)
        expect(find.textContaining('English server detail'), findsNothing);
        expect(find.text('Ana Ruiz'), findsOneWidget);
      },
    );

    for (final (code, expected) in [
      (
        'en',
        'An academy needs at least one administrator. Add another administrator first.',
      ),
      (
        'id',
        'Sebuah akademi memerlukan setidaknya satu administrator. Tambahkan administrator lain terlebih dahulu.',
      ),
    ]) {
      testWidgets('the last-administrator explanation is localised ($code)', (
        tester,
      ) async {
        final h = Harness(
          me: FakeMeRepository(userWith(const [], superAdmin: true)),
          core: FakeCore(),
          backend: repoWith([ana]),
          prefs: {'hoops.locale': code},
        );
        await h.pump(tester, size: const Size(360, 1800));
        await h.go(tester, '/platform/t-a');
        expect(find.text(expected), findsOneWidget);
      });
    }

    testWidgets(
      'a withdrawn academy shows a note instead of the section, without calling the server',
      (tester) async {
        final backend = _backend();
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-c',
          size: const Size(360, 1800),
        );
        expect(find.byKey(const Key('admins-withdrawn')), findsOneWidget);
        expect(find.text(withdrawnNote), findsOneWidget);
        expect(find.byKey(const Key('admin-add')), findsNothing);
        expect(find.byKey(const Key('admins-error')), findsNothing);
        expect(backend.requestsTo('/platform/tenants/t-c/admins'), isEmpty);
      },
    );

    testWidgets(
      'a 409 TENANT_WITHDRAWN on the list (stale status) shows the note, not an error screen',
      (tester) async {
        // Withdrawn after the page read the academy (stale status).
        final backend = repoWith([ana])
          ..fail(_admins, status: 409, code: 'TENANT_WITHDRAWN');
        await _pumpPlatform(
          tester,
          backend,
          location: '/platform/t-a',
          size: const Size(360, 1800),
        );
        expect(find.byKey(const Key('admins-withdrawn')), findsOneWidget);
        expect(find.byKey(const Key('admins-error')), findsNothing);
        expect(find.byKey(const Key('admin-add')), findsNothing);
      },
    );

    testWidgets('a suspended academy is still managed', (tester) async {
      final backend = _backend()..seedAdmins('t-b', [ana, bea]);
      await _pumpPlatform(
        tester,
        backend,
        location: '/platform/t-b',
        size: const Size(360, 1800),
      );
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.byKey(const Key('admin-add')), findsOneWidget);
    });

    testWidgets('long names, e-mails and roles do not overflow at 360 px', (
      tester,
    ) async {
      final long = adminOf(
        'p-long',
        'Maximiliano-Alejandro',
        'Fernández de la Vega y Montenegro',
        email: 'maximiliano.alejandro.fernandez.de.la.vega@academia-de-baloncesto-internacional.example.org',
        otherRoles: {
          api.TenantRole.COACH,
          api.TenantRole.PARENT,
          api.TenantRole.ASSISTANT_COACH,
        },
      );
      await _pumpPlatform(
        tester,
        repoWith([long, ana]),
        location: '/platform/t-a',
        size: const Size(360, 1800),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('access', () {
    testWidgets(
      'only super_admin: a COACH is redirected away from the console',
      (tester) async {
        final h = Harness(
          me: FakeMeRepository(
            userWith([
              membershipWithRoles({TenantRole.coach}),
            ]),
          ),
          core: athleteCore(),
          backend: _backend(),
        );
        await h.pump(tester);
        await h.go(tester, '/platform');
        expect(h.container.read(routerProvider).state.uri.path, '/teams');
        expect(find.byKey(const Key('tenant-new')), findsNothing);
      },
    );

    testWidgets('a super_admin that also has memberships can use the console', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(
          userWith([
            membershipWithRoles({TenantRole.admin}),
          ], superAdmin: true),
        ),
        prefs: {'hoops.selectedTenantId': membershipWithRoles({}).tenantId},
        core: athleteCore(),
        backend: _backend(),
      );
      await h.pump(tester);
      await h.go(tester, '/platform');
      expect(find.text('Club Norte'), findsOneWidget);
      // The old link opens the Academies area of the application admin.
      expect(
        h.container.read(routerProvider).state.uri.path,
        '/app-admin/academies',
      );
    });

    testWidgets('the platform API is never called for non super_admin users', (
      tester,
    ) async {
      final backend = _backend();
      final h = Harness(
        me: FakeMeRepository(
          userWith([
            membershipWithRoles({TenantRole.admin}),
          ]),
        ),
        core: athleteCore(),
        backend: backend,
      );
      await h.pump(tester);
      await h.go(tester, '/platform/t-a');
      expect(backend.requestsTo(RegExp('^/platform/'), method: null), isEmpty);
    });
  });
}

Future<void> tapKey2(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}
