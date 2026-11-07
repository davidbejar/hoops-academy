import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/platform/data/academy_request_repository.dart';

import '../admin/api_repositories_test.dart' show clientWith;

Map<String, Object?> requestJson({String status = 'PENDING'}) => {
  'id': 'r-1',
  'status': status,
  'name': 'Lucía Pérez',
  'email': 'lucia@valle.example',
  'role': 'COACH',
  'academyName': 'Valle',
  'locale': 'es',
  'requestedAt': '2026-11-06T09:00:00Z',
};

void main() {
  test('lists one status, newest first, up to 200', () async {
    final (client, adapter) = clientWith(
      (_) => {
        'items': [requestJson()],
        'page': {'page': 0, 'size': 200, 'totalElements': 1, 'totalPages': 1},
      },
    );

    final list = await ApiAcademyRequestRepository(client)
        .list(api.AcademyRequestStatus.PENDING);

    expect(adapter.last!.path, '/platform/academy-requests');
    expect(adapter.last!.queryParameters['status'], 'PENDING');
    expect(adapter.last!.queryParameters['size'], 200);
    expect(adapter.last!.headers.containsKey('X-Tenant-Id'), isFalse);
    expect(list.single.academyName, 'Valle');
    expect(list.single.role, api.AcademyRequestRole.COACH);
  });

  test('accept posts the academy details to {id}:accept', () async {
    final (client, adapter) = clientWith(
      (_) => {
        'request': requestJson(status: 'ACCEPTED'),
        'tenant': {
          'id': 't-9',
          'slug': 'valle',
          'name': 'Valle',
          'status': 'ACTIVE',
          'timezone': 'Europe/Madrid',
          'defaultLocale': 'es',
          'createdAt': '2026-11-07T09:00:00Z',
        },
        'temporaryPassword': 'Tmp-Password-123',
      },
    );

    final accepted = await ApiAcademyRequestRepository(client).accept(
      'r-1',
      api.AcceptAcademyRequest(
        (b) => b
          ..slug = 'valle'
          ..timezone = 'Europe/Madrid'
          ..defaultLocale = api.ApiLocale.es
          ..firstAdmin.replace(
            api.AcceptedAdmin(
              (a) => a
                ..givenName = 'Lucía'
                ..familyName = 'Pérez',
            ),
          ),
      ),
    );

    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/platform/academy-requests/r-1:accept');
    expect(jsonDecode(utf8.decode(adapter.body!)), {
      'slug': 'valle',
      'timezone': 'Europe/Madrid',
      'defaultLocale': 'es',
      'firstAdmin': {'givenName': 'Lucía', 'familyName': 'Pérez'},
    });
    expect(accepted.tenant.id, 't-9');
    expect(accepted.temporaryPassword, 'Tmp-Password-123');
  });

  test('reject posts the reason to {id}:reject', () async {
    final (client, adapter) = clientWith(
      (_) => {...requestJson(status: 'REJECTED'), 'reason': 'Not basketball'},
    );

    final rejected = await ApiAcademyRequestRepository(client)
        .reject('r-1', 'Not basketball');

    expect(adapter.last!.path, '/platform/academy-requests/r-1:reject');
    expect(jsonDecode(utf8.decode(adapter.body!)), {
      'reason': 'Not basketball',
    });
    expect(rejected.status, api.AcademyRequestStatus.REJECTED);
  });
}
