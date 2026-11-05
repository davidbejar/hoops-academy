import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/signed_in_email.dart';
import 'package:hoops_app/core/errors/app_error.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('a 404 from /me shows the "not a member yet" state with the e-mail',
      (tester) async {
    final me = FakeMeRepository(
      userWith([tenantNorth]),
      error: const AppError(kind: AppErrorKind.notFound, status: 404),
    );
    final h = Harness(
      me: me,
      extraOverrides: [
        signedInEmailProvider.overrideWith((ref) async => 'ana@example.org'),
      ],
    );
    await h.pump(tester);

    expect(find.byKey(const Key('not-a-member')), findsOneWidget);
    expect(find.textContaining('ana@example.org'), findsOneWidget);
    expect(find.byKey(const Key('retry-button')), findsNothing);
    expect(find.byKey(const Key('splash-sign-out')), findsOneWidget);
  });

  test('emailFromAccessToken reads the e-mail claim of a JWT', () {
    String part(Object o) =>
        base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final token = '${part({})}.${part({'email': 'ana@example.org'})}.x';
    expect(emailFromAccessToken(token), 'ana@example.org');
    expect(emailFromAccessToken('mock-access-token'), isNull);
    expect(emailFromAccessToken(null), isNull);
  });
}
