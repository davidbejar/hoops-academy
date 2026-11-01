import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'interceptors.dart';
import 'mock_api_adapter.dart';
import 'request_context.dart';

/// The single configured [Dio]. Generated clients reuse it (their own default
/// interceptors are disabled), so every call gets the same headers and error
/// mapping.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authServiceProvider);
  final context = ref.watch(requestContextProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json, application/problem+json'},
    ),
  );
  if (config.mockApi) dio.httpClientAdapter = MockApiAdapter();
  dio.interceptors.addAll(
    buildInterceptors(
      dio: dio,
      accessToken: auth.accessToken,
      refresh: auth.refresh,
      onSessionExpired: () => auth.expireSession(),
      tenantId: () => context.tenantId,
      languageCode: () => context.languageCode,
    ),
  );
  return dio;
});
