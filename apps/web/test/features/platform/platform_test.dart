import 'dart:async';

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

  group('administrators', () {
    const lastAdminNote = 'Una academia necesita al menos un administrador. Añade otro administrador antes de quitar a este.';
    const withdrawnNote = 'La academia está retirada: sus administradores ya no se pueden consultar ni modificar.';

    FakePlatformRepository repoWith(List<api.TenantAdmin> admins, {List<api.Tenant>? tenants}) =>
        FakePlatformRepository(tenants: tenants ?? _repo().list, admins: {'t-a': admins});

    final ana = adminOf('p-ana', 'Ana', 'Ruiz', email: 'ana@example.org', otherRoles: {api.TenantRole.COACH});
    final bea = adminOf('p-bea', 'Bea', 'Soto', email: 'bea@example.org', status: api.InvitationStatus.PENDING);

    testWidgets('lists name, e-mail, invitation status and the other roles', (tester) async {
      await _pumpPlatform(tester, repoWith([ana, bea]), location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('admins-section')), findsOneWidget);
      expect(find.text('Administradores'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('ana@example.org'), findsOneWidget);
      expect(find.text('Bea Soto'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('admin-p-ana')), matching: find.text('Invitación aceptada')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('admin-p-bea')), matching: find.text('Invitación pendiente')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('admin-p-ana')), matching: find.textContaining('Entrenador')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('admin-p-bea')), matching: find.textContaining('También')), findsNothing);
    });

    testWidgets('loading shows a spinner inside the section only', (tester) async {
      final repo = repoWith([ana])..adminsGate = Completer<void>();
      await _pumpPlatform(tester, repo, location: '/platform/t-a', settle: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('admins-loading')), findsOneWidget);
      expect(find.byKey(const Key('tenant-suspend')), findsOneWidget);
    });

    testWidgets('list error keeps the tenant visible and retries', (tester) async {
      final repo = repoWith([ana])..adminsListFails = StateError('x');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('admins-error')), findsOneWidget);
      expect(find.byKey(const Key('tenant-suspend')), findsOneWidget);
      repo.adminsListFails = null;
      await tapKey2(tester, 'admins-retry');
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.byKey(const Key('admins-error')), findsNothing);
    });

    testWidgets('add: explains promotion vs invitation, validates, sends trimmed values with the academy locale', (tester) async {
      final repo = repoWith([ana]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-add');
      expect(find.textContaining('pasa a ser administrador'), findsOneWidget);
      expect(find.textContaining('invitación por correo'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('admin-email')), 'nope');
      await tapKey2(tester, 'form-submit');
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(repo.addedAdmin, isNull);
      await tester.enterText(find.byKey(const Key('admin-email')), '  cris@example.org ');
      await tester.enterText(find.byKey(const Key('admin-given')), ' Cris ');
      await tester.enterText(find.byKey(const Key('admin-family')), 'Mora');
      await tapKey2(tester, 'form-submit');
      final r = repo.addedAdmin!;
      expect((r.email, r.givenName, r.familyName, r.locale), ('cris@example.org', 'Cris', 'Mora', api.ApiLocale.es));
      expect(find.byKey(const Key('admin-new-1')), findsOneWidget);
      expect(find.text('Invitación enviada'), findsOneWidget);
    });

    testWidgets('add: a server conflict is explained by its code and keeps the dialog open', (tester) async {
      final repo = repoWith([ana])..adminMutationFails = problem(409, 'EMAIL_TAKEN');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-add');
      await tester.enterText(find.byKey(const Key('admin-email')), 'ana@example.org');
      await tester.enterText(find.byKey(const Key('admin-given')), 'Ana');
      await tester.enterText(find.byKey(const Key('admin-family')), 'Ruiz');
      await tapKey2(tester, 'form-submit');
      expect(find.text('Ese correo ya lo usa otra persona o cuenta'), findsOneWidget);
      expect(find.textContaining('English server detail'), findsNothing);
      expect(find.byKey(const Key('admin-email')), findsOneWidget);
    });

    testWidgets('add: identity provider outage gets its own message', (tester) async {
      final repo = repoWith([ana])..adminMutationFails = problem(502, 'IDENTITY_PROVIDER_UNAVAILABLE');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-add');
      await tester.enterText(find.byKey(const Key('admin-email')), 'x@example.org');
      await tester.enterText(find.byKey(const Key('admin-given')), 'X');
      await tester.enterText(find.byKey(const Key('admin-family')), 'Y');
      await tapKey2(tester, 'form-submit');
      expect(find.textContaining('servicio de acceso no está disponible'), findsOneWidget);
    });

    testWidgets('edit: names only send no e-mail; the dialog warns that the e-mail is the login', (tester) async {
      final repo = repoWith([ana, bea]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-edit-p-ana');
      expect(find.textContaining('verificar la nueva dirección'), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byKey(const Key('admin-email'))).controller!.text, 'ana@example.org');
      await tester.enterText(find.byKey(const Key('admin-given')), 'Anita');
      await tapKey2(tester, 'form-submit');
      expect(repo.updatedAdminId, 'p-ana');
      expect((repo.updatedAdmin!.givenName, repo.updatedAdmin!.familyName, repo.updatedAdmin!.email), ('Anita', null, null));
      expect(find.text('Anita Ruiz'), findsOneWidget);
    });

    testWidgets('edit: a changed e-mail is validated and sent', (tester) async {
      final repo = repoWith([ana, bea]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-edit-p-bea');
      await tester.enterText(find.byKey(const Key('admin-email')), 'bad');
      await tapKey2(tester, 'form-submit');
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(repo.updatedAdmin, isNull);
      await tester.enterText(find.byKey(const Key('admin-email')), 'bea.soto@example.org');
      await tapKey2(tester, 'form-submit');
      expect(repo.updatedAdmin!.email, 'bea.soto@example.org');
      expect(find.text('bea.soto@example.org'), findsOneWidget);
    });

    testWidgets('edit without changes closes without calling the server', (tester) async {
      final repo = repoWith([ana, bea]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-edit-p-ana');
      await tapKey2(tester, 'form-submit');
      expect(repo.updatedAdmin, isNull);
      expect(find.byKey(const Key('admin-given')), findsNothing);
    });

    testWidgets('remove asks for confirmation (other roles stay) and drops the row', (tester) async {
      final repo = repoWith([ana, bea]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-remove-p-ana');
      expect(find.textContaining('Los demás roles se mantienen'), findsOneWidget);
      await tapKey2(tester, 'dialog-cancel');
      expect(repo.removedAdmins, isEmpty);
      await tapKey2(tester, 'admin-remove-p-ana');
      await tapKey2(tester, 'dialog-confirm');
      expect(repo.removedAdmins, ['p-ana']);
      expect(find.text('Ana Ruiz'), findsNothing);
      expect(find.text('Administrador quitado'), findsOneWidget);
    });

    testWidgets('resend is offered for pending administrators only', (tester) async {
      final repo = repoWith([ana, bea]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('admin-resend-p-ana')), findsNothing);
      await tapKey2(tester, 'admin-resend-p-bea');
      expect(repo.resentInvitations, ['p-bea']);
      expect(find.text('Invitación reenviada'), findsOneWidget);
    });

    testWidgets('resend: a stale invitation state is reported by its code', (tester) async {
      final repo = repoWith([ana, bea])..adminMutationFails = problem(409, 'INVITATION_NOT_PENDING');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-resend-p-bea');
      expect(find.text('La invitación ya no está pendiente'), findsOneWidget);
    });

    testWidgets('the only administrator cannot be removed: action disabled and the row explains why', (tester) async {
      final repo = repoWith([ana]);
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(tester.widget<IconButton>(find.byKey(const Key('admin-remove-p-ana'))).onPressed, isNull);
      expect(find.byKey(const Key('admin-last-note')), findsOneWidget);
      expect(find.text(lastAdminNote), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin-remove-p-ana')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialog-confirm')), findsNothing);
      expect(repo.removedAdmins, isEmpty);
      // The other actions stay available.
      expect(tester.widget<IconButton>(find.byKey(const Key('admin-edit-p-ana'))).onPressed, isNotNull);
    });

    testWidgets('with two administrators remove is enabled and no explanation shows', (tester) async {
      await _pumpPlatform(tester, repoWith([ana, bea]), location: '/platform/t-a', size: const Size(360, 1800));
      expect(tester.widget<IconButton>(find.byKey(const Key('admin-remove-p-ana'))).onPressed, isNotNull);
      expect(find.byKey(const Key('admin-last-note')), findsNothing);
    });

    testWidgets('removing down to one administrator disables the last one', (tester) async {
      await _pumpPlatform(tester, repoWith([ana, bea]), location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-remove-p-bea');
      await tapKey2(tester, 'dialog-confirm');
      expect(tester.widget<IconButton>(find.byKey(const Key('admin-remove-p-ana'))).onPressed, isNull);
      expect(find.text(lastAdminNote), findsOneWidget);
    });

    testWidgets('a server 409 LAST_ADMIN shows the same localised message, never the English detail', (tester) async {
      final repo = repoWith([ana, bea])..adminMutationFails = problem(409, 'LAST_ADMIN');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      await tapKey2(tester, 'admin-remove-p-ana');
      await tapKey2(tester, 'dialog-confirm');
      expect(find.text(lastAdminNote), findsOneWidget); // the snack bar (no row note: two admins are listed)
      expect(find.textContaining('English server detail'), findsNothing);
      expect(find.text('Ana Ruiz'), findsOneWidget);
    });

    for (final (code, expected) in [
      ('en', 'An academy needs at least one administrator. Add another administrator first.'),
      ('id', 'Sebuah akademi memerlukan setidaknya satu administrator. Tambahkan administrator lain terlebih dahulu.'),
    ]) {
      testWidgets('the last-administrator explanation is localised ($code)', (tester) async {
        final h = Harness(
          me: FakeMeRepository(userWith(const [], superAdmin: true)),
          core: FakeCore(),
          platform: FakePlatform(repo: repoWith([ana])),
          prefs: {'hoops.locale': code},
        );
        await h.pump(tester, size: const Size(360, 1800));
        await h.go(tester, '/platform/t-a');
        expect(find.text(expected), findsOneWidget);
      });
    }

    testWidgets('a withdrawn academy shows a note instead of the section, without calling the server', (tester) async {
      final repo = _repo();
      await _pumpPlatform(tester, repo, location: '/platform/t-c', size: const Size(360, 1800));
      expect(find.byKey(const Key('admins-withdrawn')), findsOneWidget);
      expect(find.text(withdrawnNote), findsOneWidget);
      expect(find.byKey(const Key('admin-add')), findsNothing);
      expect(find.byKey(const Key('admins-error')), findsNothing);
      expect(repo.calls, isNot(contains('admins')));
    });

    testWidgets('a 409 TENANT_WITHDRAWN on the list (stale status) shows the note, not an error screen', (tester) async {
      final repo = repoWith([ana])..adminsListFails = problem(409, 'TENANT_WITHDRAWN');
      await _pumpPlatform(tester, repo, location: '/platform/t-a', size: const Size(360, 1800));
      expect(find.byKey(const Key('admins-withdrawn')), findsOneWidget);
      expect(find.byKey(const Key('admins-error')), findsNothing);
      expect(find.byKey(const Key('admin-add')), findsNothing);
    });

    testWidgets('a suspended academy is still managed', (tester) async {
      final repo = FakePlatformRepository(tenants: _repo().list, admins: {'t-b': [ana, bea]});
      await _pumpPlatform(tester, repo, location: '/platform/t-b', size: const Size(360, 1800));
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.byKey(const Key('admin-add')), findsOneWidget);
    });

    testWidgets('long names, e-mails and roles do not overflow at 360 px', (tester) async {
      final long = adminOf('p-long', 'Maximiliano-Alejandro', 'Fernández de la Vega y Montenegro', email: 'maximiliano.alejandro.fernandez.de.la.vega@academia-de-baloncesto-internacional.example.org', otherRoles: {api.TenantRole.COACH, api.TenantRole.PARENT, api.TenantRole.ASSISTANT_COACH});
      await _pumpPlatform(tester, repoWith([long, ana]), location: '/platform/t-a', size: const Size(360, 1800));
      expect(tester.takeException(), isNull);
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
