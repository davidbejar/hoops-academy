import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_error.dart';

const _retriedKey = 'hoops.retried';

/// Builds the interceptor chain, in order: locale (an explicit header wins), tenant, auth (bearer +
/// 401 refresh), Problem+JSON mapping. Dependencies are callbacks so the
/// chain is trivial to test and has no knowledge of Riverpod.
List<Interceptor> buildInterceptors({
  required Dio dio,
  required Future<String?> Function() accessToken,
  required Future<bool> Function() refresh,
  required void Function() onSessionExpired,
  required String? Function() tenantId,
  required String Function() languageCode,
}) => [
  _LocaleInterceptor(languageCode),
  _TenantInterceptor(tenantId),
  _AuthInterceptor(
    dio: dio,
    accessToken: accessToken,
    refresh: refresh,
    onSessionExpired: onSessionExpired,
  ),
  _ProblemInterceptor(),
];

class _LocaleInterceptor extends Interceptor {
  _LocaleInterceptor(this._languageCode);
  final String Function() _languageCode;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Dio runs the chain synchronously, i.e. while the calling provider may
    // still be building. One microtask later the app root has published the
    // current language/tenant into the request context.
    await Future<void>.microtask(() {});
    // A call that names its language (plan templates, which refetch on a
    // language switch before the app root has published it) keeps it.
    options.headers.putIfAbsent('Accept-Language', _languageCode);
    handler.next(options);
  }
}

/// Adds `X-Tenant-Id` for tenant-scoped paths. `/me` and `/platform` are
/// tenant-less by contract. A header set explicitly (generated clients pass it
/// as a required parameter) wins.
class _TenantInterceptor extends Interceptor {
  _TenantInterceptor(this._tenantId);
  final String? Function() _tenantId;

  static bool _isTenantless(String path) =>
      path.endsWith('/api/core/me') || path.contains('/platform/');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tenant = _tenantId();
    if (tenant != null &&
        !_isTenantless(options.path) &&
        !options.headers.containsKey('X-Tenant-Id')) {
      options.headers['X-Tenant-Id'] = tenant;
    }
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.dio,
    required this.accessToken,
    required this.refresh,
    required this.onSessionExpired,
  });

  final Dio dio;
  final Future<String?> Function() accessToken;
  final Future<bool> Function() refresh;
  final void Function() onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await accessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) return handler.next(err);

    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (alreadyRetried || !await refresh()) {
      onSessionExpired();
      return handler.next(err);
    }

    try {
      final retry = err.requestOptions..extra[_retriedKey] = true;
      handler.resolve(await dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

class _ProblemInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppError) return handler.next(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppError.fromDioException(err),
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }
}
