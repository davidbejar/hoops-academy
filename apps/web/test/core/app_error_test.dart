import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';

DioException _dioError(int status, Object? data, {String? contentType}) {
  final req = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: data,
      headers: Headers.fromMap({
        Headers.contentTypeHeader: [contentType ?? 'application/problem+json'],
      }),
    ),
  );
}

void main() {
  group('AppError.fromDioException', () {
    test('reads a Problem sent as bytes (a binary download that failed)', () {
      final error = AppError.fromDioException(
        _dioError(
          422,
          Uint8List.fromList(
            utf8.encode('{"title":"Too large","code":"EXPORT_TOO_LARGE"}'),
          ),
        ),
      );
      expect(error.kind, AppErrorKind.validation);
      expect(error.code, 'EXPORT_TOO_LARGE');
      expect(error.title, 'Too large');
    });

    test('bytes that are not JSON keep the status only', () {
      final error = AppError.fromDioException(
        _dioError(500, Uint8List.fromList([0xff, 0x00])),
      );
      expect(error.kind, AppErrorKind.server);
      expect(error.code, isNull);
    });

    test(
      'maps a Problem+JSON body to code, detail, traceId and violations',
      () {
        final error = AppError.fromDioException(
          _dioError(422, {
            'type': 'urn:hoops:problem:validation',
            'title': 'Validation failed',
            'status': 422,
            'detail': 'name must not be blank',
            'traceId': 'abc123',
            'code': 'PLAYER_INELIGIBLE',
            'violations': [
              {
                'field': 'name',
                'code': 'NotBlank',
                'message': 'must not be blank',
              },
            ],
          }),
        );

        expect(error.kind, AppErrorKind.validation);
        expect(error.status, 422);
        expect(error.title, 'Validation failed');
        expect(error.detail, 'name must not be blank');
        expect(error.code, 'PLAYER_INELIGIBLE');
        expect(error.traceId, 'abc123');
        expect(error.violations, hasLength(1));
        expect(error.violations.single.field, 'name');
        expect(error.violations.single.message, 'must not be blank');
      },
    );

    test('maps status codes to kinds', () {
      expect(
        AppError.fromDioException(_dioError(401, null)).kind,
        AppErrorKind.unauthorized,
      );
      expect(
        AppError.fromDioException(_dioError(403, null)).kind,
        AppErrorKind.forbidden,
      );
      expect(
        AppError.fromDioException(_dioError(404, null)).kind,
        AppErrorKind.notFound,
      );
      expect(
        AppError.fromDioException(_dioError(409, null)).kind,
        AppErrorKind.conflict,
      );
      expect(
        AppError.fromDioException(_dioError(400, null)).kind,
        AppErrorKind.validation,
      );
      expect(
        AppError.fromDioException(
          _dioError(502, '<html>bad gateway</html>', contentType: 'text/html'),
        ).kind,
        AppErrorKind.server,
      );
    });

    test('tolerates a non-Problem body (nginx html) without throwing', () {
      final error = AppError.fromDioException(
        _dioError(502, '<html>Bad Gateway</html>', contentType: 'text/html'),
      );
      expect(error.status, 502);
      expect(error.detail, isNull);
      expect(error.traceId, isNull);
    });

    test('maps connection failures to network and timeouts to timeout', () {
      final req = RequestOptions(path: '/x');
      expect(
        AppError.fromDioException(
          DioException.connectionError(requestOptions: req, reason: 'down'),
        ).kind,
        AppErrorKind.network,
      );
      expect(
        AppError.fromDioException(
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: req,
          ),
        ).kind,
        AppErrorKind.timeout,
      );
    });

    test('returns the wrapped AppError unchanged', () {
      const original = AppError(kind: AppErrorKind.forbidden, status: 403);
      final req = RequestOptions(path: '/x');
      expect(
        AppError.fromDioException(
          DioException(requestOptions: req, error: original),
        ),
        same(original),
      );
    });
  });
}
