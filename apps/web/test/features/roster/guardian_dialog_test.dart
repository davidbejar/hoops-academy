import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/roster/presentation/guardian_dialog.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/mock_backend.dart';
import '../../support/kit_harness.dart';
import '../../support/pump_helpers.dart';
import '../../support/server_pages.dart';
import 'players_test.dart' show coreWithPlayers;

const _guardians = '/api/core/guardians';

void main() {
  late FakeCore core;
  late MockBackend backend;

  setUp(() => core = coreWithPlayers());

  Future<void> openPlayer(
    WidgetTester tester, {
    Set<TenantRole>? roles,
    void Function(MockBackend backend)? prepare,
  }) async {
    final h = await pumpAs(
      tester,
      roles: roles ?? {TenantRole.admin},
      core: core,
      location: '/players/p1',
      prepare: prepare,
    );
    backend = h.backend;
  }

  /// The guardians the dialog created, as sent.
  List<Map<String, Object?>> created() => [
    for (final r in backend.requestsTo(_guardians, method: 'POST'))
      MockBackend.bodyOf(r),
  ];

  String? answeredPassword(String path) =>
      (backend.lastAnswer(path, method: 'POST')! as Map)['temporaryPassword']
          as String?;

  Future<void> fillGuardian(WidgetTester tester, {String? email}) async {
    await tapKey(tester, 'player-guardian-add');
    await enter(tester, 'guardian-given', 'Gala');
    await enter(tester, 'guardian-family', 'Ruiz');
    if (email != null) await enter(tester, 'guardian-email', email);
    await tapKey(tester, 'form-submit');
  }

  group('add a guardian from the player', () {
    testWidgets('with an e-mail: the temporary password is shown once', (
      tester,
    ) async {
      await openPlayer(tester);
      await fillGuardian(tester, email: 'gala@example.org');

      expect(created().single, {
        'playerId': 'p1',
        'givenName': 'Gala',
        'familyName': 'Ruiz',
        'email': 'gala@example.org',
      });
      final password = answeredPassword(_guardians)!;
      final dialog = find.byKey(const Key('temp-password-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(password)),
        findsOneWidget,
      );
      await tapKey(tester, 'temp-password-done');
      expect(find.text(password), findsNothing);
      expect(find.text('Gala Ruiz'), findsOneWidget); // the list was reloaded
      expect(find.text('Tutor añadido'), findsOneWidget);
    });

    testWidgets('an e-mail that already signs in: no dialog, only the note', (
      tester,
    ) async {
      await openPlayer(
        tester,
        prepare: (b) => b.core.loginsElsewhere.add('known@example.org'),
      );
      await fillGuardian(tester, email: 'known@example.org');

      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      expect(find.textContaining('contraseña actual'), findsOneWidget);
    });

    testWidgets('without an e-mail: no login, no dialog', (tester) async {
      await openPlayer(tester);
      await fillGuardian(tester);

      expect(created().single['email'], isNull);
      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      expect(find.text('Tutor añadido'), findsOneWidget);
      expect(find.textContaining('contraseña actual'), findsNothing);
    });

    testWidgets('names are required and a bad e-mail is refused', (
      tester,
    ) async {
      await openPlayer(tester);
      await tapKey(tester, 'player-guardian-add');
      await enter(tester, 'guardian-email', 'not-an-email');
      await tapKey(tester, 'form-submit');

      expect(created(), isEmpty);
      expect(find.byKey(const Key('guardian-given')), findsOneWidget);
    });

    testWidgets('a server error keeps the dialog open', (tester) async {
      // A deactivated member has the e-mail (the mock keeps none: injected).
      await openPlayer(
        tester,
        prepare: (b) => b.fail(
          _guardians,
          method: 'POST',
          status: 409,
          code: 'EMAIL_TAKEN',
        ),
      );
      await fillGuardian(tester, email: 'taken@example.org');

      expect(find.byKey(const Key('guardian-given')), findsOneWidget);
      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
    });

    testWidgets('a coach cannot add guardians', (tester) async {
      await openPlayer(tester, roles: {TenantRole.coach});
      expect(find.byKey(const Key('player-guardian-add')), findsNothing);
    });
  });

  group("a guardian's login", () {
    testWidgets('a guardian without a login gets a first one, shown once', (
      tester,
    ) async {
      await openPlayer(tester);
      await tapKey(tester, 'guardian-login-m2');

      const issue = '/api/core/members/m2/temporary-password';
      expect(backend.requestsTo(issue, method: 'POST'), hasLength(1));
      final password = answeredPassword(issue)!;
      final dialog = find.byKey(const Key('temp-password-dialog'));
      expect(
        find.descendant(of: dialog, matching: find.text(password)),
        findsOneWidget,
      );
      await tapKey(tester, 'temp-password-done');
      expect(find.text(password), findsNothing);
    });

    testWidgets('a guardian who signs in already has no login action', (
      tester,
    ) async {
      core.members.members[0] = core.members.members[0].rebuild(
        (b) => b..userId = 'u-m2',
      );
      await openPlayer(tester);
      expect(find.text('Pat Parent'), findsOneWidget);
      expect(find.byKey(const Key('guardian-login-m2')), findsNothing);
    });

    testWidgets('a guardian without an e-mail has no login action', (
      tester,
    ) async {
      core.members.members[0] = member(
        'm2',
        'Pat Parent',
        roles: {api.TenantRole.PARENT},
      ).rebuild((b) => b..email = null);
      await openPlayer(tester);
      expect(find.byKey(const Key('guardian-login-m2')), findsNothing);
    });

    testWidgets('the 101st guardian of the academy has the action too', (
      tester,
    ) async {
      final parent = member('g', 'Gil Parent', roles: {api.TenantRole.PARENT});
      final server = ServerPagesAdapter(
        count: 250,
        template:
            (api.standardSerializers.serializeWith(
                      api.Member.serializer,
                      parent,
                    )!
                    as Map)
                .cast(),
      );
      final client = api.HoopsCoreApi(
        dio: Dio(
          BaseOptions(
            baseUrl: 'http://mock',
            headers: {'Authorization': 'Bearer x'},
          ),
        )..httpClientAdapter = server,
        interceptors: [],
      );
      await pumpKit(
        tester,
        ProviderScope(
          overrides: [
            membersRepositoryProvider.overrideWithValue(
              ApiMembersRepository(client, 't'),
            ),
          ],
          child: const GuardianLoginButton(personId: 'g~100', name: 'Gil'),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guardian-login-g~100')), findsOneWidget);
    });
  });
}
