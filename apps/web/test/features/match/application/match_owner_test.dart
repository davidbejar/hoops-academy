import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/auth_providers.dart';
import 'package:hoops_app/core/auth/auth_service.dart';
import 'package:hoops_app/core/auth/signed_in_email.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

import '../data/match_store_test.dart' show memoryStore, tenant, me;

String jwt(Map<String, Object?> claims) {
  String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o)));
  return '${enc({'alg': 'none'})}.${enc(claims)}.sig';
}

class _TokenAuth implements AuthService {
  _TokenAuth(this.token);
  String? token;
  @override
  AuthStatus get status => AuthStatus.authenticated;
  @override
  Stream<AuthStatus> get statusChanges => const Stream.empty();
  @override
  Future<String?> accessToken() async => token;
  @override
  Future<void> init() async {}
  @override
  Future<void> login() async {}
  @override
  Future<void> logout({bool endSession = true}) async {}
  @override
  Future<bool> refresh() async => true;
  @override
  Future<void> expireSession() async {}
}

void main() {
  test('subjectFromAccessToken reads sub, null for non-JWTs', () {
    expect(subjectFromAccessToken(jwt({'sub': 'u1'})), 'u1');
    expect(subjectFromAccessToken(jwt({'email': 'a@b.c'})), isNull);
    expect(subjectFromAccessToken('mock-access-token'), isNull);
    expect(subjectFromAccessToken(null), isNull);
  });

  test('a different sub signing in finds an empty offline DB', () async {
    final store = memoryStore();
    addTearDown(store.close);
    final auth = _TokenAuth(jwt({'sub': 'sub-a'}));
    ProviderContainer open() => ProviderContainer(
      overrides: [
        matchStoreProvider.overrideWithValue(store),
        authServiceProvider.overrideWithValue(auth),
      ],
    );

    final first = open();
    await first.read(matchOwnerProvider.future);
    await store.record(
      tenantId: tenant,
      personId: me,
      matchId: 'm1',
      period: 1,
      clockSecondsRemaining: 600,
      build: PeriodStart.new,
    );
    first.dispose();

    final same = open();
    await same.read(matchOwnerProvider.future);
    expect(await store.unsyncedTotal(), 1, reason: 'same user: kept');
    same.dispose();

    auth.token = jwt({'sub': 'sub-b'});
    final other = open();
    addTearDown(other.dispose);
    await other.read(matchOwnerProvider.future);
    expect(await store.unsyncedTotal(), 0, reason: 'other user: wiped');
  });
}
