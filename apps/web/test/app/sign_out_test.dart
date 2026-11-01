import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/auth_service.dart';
import 'package:hoops_app/core/auth/mock_auth_service.dart';
import 'package:hoops_app/core/http/request_context.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/core/session/session_providers.dart';
import 'package:hoops_app/core/tenancy/tenant_selection.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

final _member = membershipWithRoles({TenantRole.admin});

/// Records how the app asked to end the session and what the offline store
/// looked like at that moment (the wipe must come first).
class RecordingAuth extends MockAuthService {
  RecordingAuth({required this.storeEmpty}) : super(initial: AuthStatus.authenticated);
  final Future<bool> Function() storeEmpty;
  final List<bool> endSessionFlags = [];
  final List<bool> storeWasEmpty = [];

  @override
  Future<void> logout({bool endSession = true}) async {
    endSessionFlags.add(endSession);
    storeWasEmpty.add(await storeEmpty());
    await super.logout(endSession: endSession);
  }
}

Future<void> _recordEvent(Harness h) => h.game.store.record(
  tenantId: _member.tenantId,
  personId: 'person-me',
  matchId: 'm1',
  period: 1,
  clockSecondsRemaining: 600,
  build: PeriodStart.new,
);

Future<Harness> _pump(WidgetTester tester, {Map<String, Object> prefs = const {}, bool unsynced = false}) async {
  late Harness h;
  final auth = RecordingAuth(storeEmpty: () async => (await h.game.store.unsyncedTotal()) == 0);
  h = Harness(
    me: FakeMeRepository(userWith([_member])),
    auth: auth,
    prefs: {'hoops.selectedTenantId': _member.tenantId, ...prefs},
  );
  await tester.runAsync(() async {
    if (unsynced) await _recordEvent(h);
    await h.game.store.saveMatchJson(tenantId: _member.tenantId, matchId: 'm1', teamId: 't', json: '{}');
  });
  await h.pump(tester);
  return h;
}

Future<void> _tapSignOut(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('sign-out-button')));
  await tester.tap(find.byKey(const Key('sign-out-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sign-out wipes selection, request context and the offline DB before ending the IdP session', (tester) async {
    final h = await _pump(tester);
    expect(h.container.read(activeTenantIdProvider), _member.tenantId);

    await _tapSignOut(tester);

    expect(find.byKey(const Key('signout-warning')), findsNothing, reason: 'nothing unsynced: no dialog');
    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(h.container.read(selectedTenantIdProvider), isNull);
    expect(h.prefs.getString('hoops.selectedTenantId'), isNull);
    expect(h.container.read(requestContextProvider).tenantId, isNull);
    expect(await tester.runAsync(() => h.game.store.matchJson('m1')), isNull);
    final auth = h.auth as RecordingAuth;
    expect(auth.endSessionFlags, [true]);
    expect(auth.storeWasEmpty, [true]);
  });

  testWidgets('offline: the local sign-out completes and the end-session redirect is skipped', (tester) async {
    final h = await _pump(tester);
    h.online.add(false);
    await tester.pumpAndSettle();

    await _tapSignOut(tester);

    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect((h.auth as RecordingAuth).endSessionFlags, [false]);
    expect(await tester.runAsync(() => h.game.store.matchJson('m1')), isNull);
  });

  testWidgets('unsynced events: the user is warned and can cancel', (tester) async {
    final h = await _pump(tester, unsynced: true);

    await _tapSignOut(tester);
    expect(find.byKey(const Key('signout-warning')), findsOneWidget);
    expect(find.textContaining('1'), findsWidgets);

    await tester.tap(find.byKey(const Key('signout-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signout-warning')), findsNothing);
    expect(h.auth.status, AuthStatus.authenticated);
    expect(await tester.runAsync(() => h.game.store.unsyncedTotal()), 1);
    expect((h.auth as RecordingAuth).endSessionFlags, isEmpty);
  });

  testWidgets('unsynced events: confirming discards them and signs out', (tester) async {
    final h = await _pump(tester, unsynced: true);

    await _tapSignOut(tester);
    await tester.tap(find.byKey(const Key('signout-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(await tester.runAsync(() => h.game.store.unsyncedTotal()), 0);
  });

  for (final (code, word) in [('es', 'sin sincronizar'), ('en', 'not synced'), ('id', 'belum disinkronkan')]) {
    testWidgets('warning is localized ($code)', (tester) async {
      await _pump(tester, unsynced: true, prefs: {'hoops.locale': code});
      await _tapSignOut(tester);
      final text = tester.widget<Text>(find.byKey(const Key('signout-warning-body'))).data!;
      expect(text.toLowerCase(), contains(word));
    });
  }
}
