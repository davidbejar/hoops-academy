import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import '../../support/fake_repos.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/mock_backend.dart';
import '../../support/platform_seed.dart';

const _requestsPath = '/platform/academy-requests';

/// Four requests, and Club Norte (`t-a`), the academy of the accepted one.
MockBackend _requests() => MockBackend()
  ..seedTenants([tenantOf('t-a', 'Club Norte')])
  ..seedAcademyRequests([
    academyRequestOf('r-1', 'Escuela de Baloncesto Valle'),
    academyRequestOf(
      'r-2',
      'Hoops Bali',
      name: null,
      email: 'admin@hoopsbali.example',
      role: api.AcademyRequestRole.ADMIN,
      locale: api.ApiLocale.id,
    ),
    academyRequestOf(
      'r-3',
      'Futsal Friends',
      status: api.AcademyRequestStatus.REJECTED,
      reason: 'Solo baloncesto',
      notified: false,
    ),
    academyRequestOf(
      'r-4',
      'Club Norte',
      status: api.AcademyRequestStatus.ACCEPTED,
      tenantId: 't-a',
    ),
  ]);

Future<Harness> _pump(
  WidgetTester tester,
  MockBackend backend, {
  bool superAdmin = true,
  String location = '/app-admin/requests',
}) async {
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: superAdmin)),
    core: FakeCore(),
    backend: backend,
  );
  await h.pump(tester, size: const Size(390, 1400));
  await h.go(tester, location);
  return h;
}

Future<void> tapKey2(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

void main() {
  testWidgets('the application admin hub opens the requests', (tester) async {
    await _pump(tester, _requests(), location: '/app-admin');
    await tapKey2(tester, 'app-admin-requests');
    expect(find.text('Solicitudes de academia'), findsOneWidget);
    expect(find.text('Escuela de Baloncesto Valle'), findsOneWidget);
  });

  testWidgets('pending requests with requester, role and date', (tester) async {
    await _pump(tester, _requests());
    expect(_in('request-r-1', 'Lucía Pérez · lucia@valle.example'), findsOne);
    expect(_in('request-r-1', 'Entrenador'), findsOneWidget);
    expect(_in('request-r-1', 'Solicitada el 5 nov 2026'), findsOneWidget);
    expect(_in('request-r-2', 'admin@hoopsbali.example'), findsOneWidget);
    expect(_in('request-r-2', 'Administrador de la academia'), findsOne);
    expect(find.text('Futsal Friends'), findsNothing);
    expect(find.text('Club Norte'), findsNothing);
  });

  testWidgets('rejected requests show the reason and an unsent e-mail', (
    tester,
  ) async {
    await _pump(tester, _requests());
    await tapKey2(tester, 'requests-REJECTED');
    expect(find.text('Futsal Friends'), findsOneWidget);
    expect(find.text('Motivo: Solo baloncesto'), findsOneWidget);
    expect(find.byKey(const Key('request-mail-missing-r-3')), findsOneWidget);
    expect(find.byKey(const Key('request-accept-r-3')), findsNothing);
  });

  testWidgets('an accepted request links to its academy', (tester) async {
    await _pump(tester, _requests());
    await tapKey2(tester, 'requests-ACCEPTED');
    expect(find.byKey(const Key('request-mail-missing-r-4')), findsNothing);
    await tapKey2(tester, 'request-open-r-4');
    expect(find.text('Club Norte'), findsWidgets);
    expect(find.text('Solicitudes de academia'), findsNothing);
  });

  testWidgets('empty and error with retry', (tester) async {
    final backend = MockBackend()..fail(_requestsPath);
    await _pump(tester, backend);
    expect(find.text('Reintentar'), findsOneWidget);
    backend.heal();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No hay solicitudes aquí'), findsOneWidget);
  });

  testWidgets('only the super admin reaches the workbench', (tester) async {
    final backend = _requests();
    await _pump(tester, backend, superAdmin: false);
    expect(find.text('Escuela de Baloncesto Valle'), findsNothing);
    expect(
      backend.requestsTo(_requestsPath),
      isEmpty,
      reason: 'nothing is even loaded',
    );
  });

  testWidgets('accept proposes the request\'s data, creates the academy and '
      'shows the temporary password once', (tester) async {
    final backend = _requests();
    await _pump(tester, backend);
    await tapKey2(tester, 'request-accept-r-1');

    String text(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(text('accept-slug'), 'escuela-de-baloncesto-valle');
    expect(text('accept-given'), 'Lucía');
    expect(text('accept-family'), 'Pérez');
    expect(text('accept-timezone'), 'Europe/Madrid');
    expect(find.text('lucia@valle.example'), findsWidgets);
    await tester.enterText(find.byKey(const Key('accept-slug')), 'valle');
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar').last);
    await tester.pumpAndSettle();

    const accept = '$_requestsPath/r-1:accept';
    final sent = backend.lastBody(accept);
    expect(sent['slug'], 'valle');
    expect(sent['defaultLocale'], 'es');
    final admin = sent['firstAdmin']! as Map;
    expect(admin['givenName'], 'Lucía');
    expect(admin['locale'], 'es');
    final password =
        (backend.lastAnswer(accept, method: 'POST')!
                as Map)['temporaryPassword']
            as String;
    expect(find.text(password), findsOneWidget);
    await tester.tap(find.byKey(const Key('temp-password-done')));
    await tester.pumpAndSettle();
    expect(find.text(password), findsNothing);
    expect(
      find.text('Escuela de Baloncesto Valle'),
      findsNothing,
      reason: 'no longer pending',
    );
  });

  testWidgets('a nameless request leaves the names to fill in', (tester) async {
    final backend = _requests();
    await _pump(tester, backend);
    await tapKey2(tester, 'request-accept-r-2');
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar').last);
    await tester.pumpAndSettle();
    expect(backend.requestsTo(RegExp(':accept\$'), method: 'POST'), isEmpty);
    expect(find.text('Campo obligatorio'), findsNWidgets(2));
  });

  testWidgets('a taken identifier keeps the form open with a clear message', (
    tester,
  ) async {
    // The proposed identifier belongs to another academy: the server says 409.
    final backend = _requests()
      ..seedTenants([
        tenantOf('t-v', 'Otra Valle', slug: 'escuela-de-baloncesto-valle'),
      ]);
    await _pump(tester, backend);
    await tapKey2(tester, 'request-accept-r-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar').last);
    await tester.pumpAndSettle();
    expect(find.text('Este identificador ya está en uso'), findsOneWidget);
    expect(find.byKey(const Key('accept-slug')), findsOneWidget);
  });

  testWidgets('reject needs a reason and sends it', (tester) async {
    final backend = _requests();
    await _pump(tester, backend);
    await tapKey2(tester, 'request-reject-r-2');
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar').last);
    await tester.pumpAndSettle();
    expect(backend.requestsTo(RegExp(':reject\$'), method: 'POST'), isEmpty);
    expect(find.text('Campo obligatorio'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reject-reason')),
      ' Solo academias de baloncesto. ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar').last);
    await tester.pumpAndSettle();
    expect(
      backend.lastBody('$_requestsPath/r-2:reject')['reason'],
      'Solo academias de baloncesto.',
    );
    expect(find.text('Solicitud rechazada'), findsOneWidget);
    expect(find.text('Hoops Bali'), findsNothing);
  });

  testWidgets('a request decided meanwhile says so', (tester) async {
    final backend = _requests();
    await _pump(tester, backend);
    // Another super admin accepts it while this one is reading.
    backend.platform.academyRequests.firstWhere(
      (r) => r['id'] == 'r-1',
    )['status'] = 'ACCEPTED';
    await tapKey2(tester, 'request-reject-r-1');
    await tester.enterText(find.byKey(const Key('reject-reason')), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar').last);
    await tester.pumpAndSettle();
    expect(find.text('Esta solicitud ya se ha decidido'), findsOneWidget);
  });
}
