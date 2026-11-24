import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/platform/presentation/platform_users_screen.dart';

import 'package:hoops_app/core/mock/mock_query.dart';

import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/mock_backend.dart';
import '../../support/platform_seed.dart';
import '../../support/pump_helpers.dart';
import '../../support/core_seed.dart' show FakeCore;

/// The Users area of the application admin (WP99): every login with its
/// memberships per academy, search with debounce, paging.
MockBackend _repo({int extra = 0}) {
  final backend = MockBackend()
    ..seedTenants([
      tenantOf('t-a', 'Hangtuah'),
      tenantOf('t-b', 'Dewa United', status: api.TenantStatus.SUSPENDED),
    ]);
  backend.seedLogins([
    platformUserOf(
      'u-1',
      'ana@example.org',
      memberships: [
        userMembership(
          't-a',
          'Hangtuah',
          given: 'Ana',
          family: 'García',
          roles: {api.TenantRole.ADMIN, api.TenantRole.COACH},
        ),
        userMembership(
          't-b',
          'Dewa United',
          given: 'Ana',
          family: 'García',
          roles: {api.TenantRole.PARENT},
          active: false,
          status: api.TenantStatus.SUSPENDED,
        ),
      ],
    ),
    platformUserOf('u-2', 'solo@example.org'),
    platformUserOf(
      'u-3',
      null,
      memberships: [
        userMembership('t-a', 'Hangtuah', given: 'Budi', family: 'Santoso'),
      ],
    ),
    for (var i = 0; i < extra; i++) platformUserOf('x-$i', 'extra$i@x.org'),
  ]);
  return backend;
}

/// The user-list requests the screen sent: search text and page.
List<({String? query, int page})> _userRequests(MockBackend backend) => [
  for (final r in backend.requestsTo('/platform/users'))
    (
      query: MockQuery(r.queryParameters).text('q'),
      page: MockQuery(r.queryParameters).integer('page', 0),
    ),
];

Future<Harness> _pump(
  WidgetTester tester,
  MockBackend backend, {
  bool superAdmin = true,
  Size size = const Size(360, 1400),
}) async {
  final h = Harness(
    me: FakeMeRepository(
      userWith(
        superAdmin
            ? const []
            : [
                membershipWithRoles({TenantRole.coach}),
              ],
        superAdmin: superAdmin,
      ),
    ),
    core: FakeCore(),
    backend: backend,
  );
  await h.pump(tester, size: size);
  await h.go(tester, '/app-admin/users');
  return h;
}

void main() {
  testWidgets('lists each login with its memberships, roles and e-mail', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(find.byKey(const Key('user-u-1')), findsOneWidget);
    expect(find.text('ana@example.org'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('user-u-1-t-a')),
        matching: find.text('Hangtuah'),
      ),
      findsOneWidget,
    );
    expect(find.text('Administrador, Entrenador'), findsOneWidget);
    // A login in two academies: both rows, with the state of the second.
    expect(find.byKey(const Key('user-u-1-t-b')), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
    expect(find.text('Suspendida'), findsOneWidget);
  });

  testWidgets('a login without membership or e-mail still shows', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(find.text('No pertenece a ninguna academia'), findsOneWidget);
    expect(find.text('Sin correo'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('a membership opens that academy in the application admin', (
    tester,
  ) async {
    final h = await _pump(tester, _repo());

    await tapKey(tester, 'user-u-1-t-b');

    expect(
      h.container.read(routerProvider).state.uri.path,
      '/app-admin/academies/t-b',
    );
  });

  group('search', () {
    testWidgets('waits for typing to pause, then asks for the query', (
      tester,
    ) async {
      final backend = _repo();
      await _pump(tester, backend);
      expect(_userRequests(backend).last.query, isNull);
      final before = _userRequests(backend).length;

      await tester.enterText(find.byKey(const Key('users-search')), 'ana');
      await tester.pump(usersSearchDebounce - const Duration(milliseconds: 50));
      expect(_userRequests(backend).length, before, reason: 'still typing');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_userRequests(backend).last, (query: 'ana', page: 0));
      expect(find.byKey(const Key('user-u-1')), findsOneWidget);
      expect(find.byKey(const Key('user-u-2')), findsNothing);
    });

    testWidgets('typing quickly sends one request for the last text', (
      tester,
    ) async {
      final backend = _repo();
      await _pump(tester, backend);
      final before = _userRequests(backend).length;

      for (final text in ['b', 'bu', 'bud', 'budi']) {
        await tester.enterText(find.byKey(const Key('users-search')), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(usersSearchDebounce);
      await tester.pumpAndSettle();

      expect(_userRequests(backend).length, before + 1);
      expect(_userRequests(backend).last.query, 'budi');
    });

    testWidgets('one character is not searched (the server wants two)', (
      tester,
    ) async {
      final backend = _repo();
      await _pump(tester, backend);

      await tester.enterText(find.byKey(const Key('users-search')), 'a');
      await tester.pump(usersSearchDebounce);
      await tester.pumpAndSettle();

      expect(_userRequests(backend).every((r) => r.query == null), isTrue);
      expect(find.text('Escribe al menos 2 caracteres'), findsOneWidget);
    });

    testWidgets('no match says so', (tester) async {
      await _pump(tester, _repo());

      await tester.enterText(find.byKey(const Key('users-search')), 'zzz');
      await tester.pump(usersSearchDebounce);
      await tester.pumpAndSettle();

      expect(find.text('Ningún usuario coincide'), findsOneWidget);
    });

    testWidgets('a new search starts again at the first page', (tester) async {
      final backend = _repo(extra: 40);
      await _pump(tester, backend);
      await tapKey(tester, 'users-next');
      expect(_userRequests(backend).last.page, 1);

      await tester.enterText(find.byKey(const Key('users-search')), 'extra');
      await tester.pump(usersSearchDebounce);
      await tester.pumpAndSettle();

      expect(_userRequests(backend).last, (query: 'extra', page: 0));
    });
  });

  group('paging', () {
    testWidgets('a short list has no pager', (tester) async {
      await _pump(tester, _repo());
      expect(find.byKey(const Key('users-next')), findsNothing);
    });

    testWidgets('next and previous move through the pages', (tester) async {
      final backend = _repo(extra: 40);
      await _pump(tester, backend);

      expect(find.text('Página 1 de 2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('users-previous')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'users-next');
      expect(find.text('Página 2 de 2'), findsOneWidget);
      expect(_userRequests(backend).last.page, 1);
      await tapKey(tester, 'users-previous');
      expect(_userRequests(backend).last.page, 0);
    });
  });

  testWidgets('a failing list offers a retry', (tester) async {
    final backend = _repo()..fail('/platform/users');
    await _pump(tester, backend);

    expect(find.byKey(const Key('retry-button')), findsOneWidget);
    backend.heal();
    await tapKey(tester, 'retry-button');
    expect(find.byKey(const Key('user-u-1')), findsOneWidget);
  });

  testWidgets('only a super admin: a coach is sent to the own menu, no call', (
    tester,
  ) async {
    final backend = _repo();
    final h = await _pump(tester, backend, superAdmin: false);

    expect(h.container.read(routerProvider).state.uri.path, '/teams');
    expect(backend.requestsTo(RegExp('^/platform/'), method: null), isEmpty);
  });
}
