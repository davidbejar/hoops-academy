import 'package:dio/dio.dart';

/// Coarse classification the UI branches on (and localises).
enum AppErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  unknown,
}

class AppViolation {
  const AppViolation({this.field, this.code, required this.message});

  final String? field;
  final String? code;
  final String message;
}

/// The single error type the presentation layer sees. Built once from a
/// Problem+JSON (RFC 9457) response or a transport failure.
class AppError implements Exception {
  const AppError({
    required this.kind,
    this.status,
    this.title,
    this.detail,
    this.code,
    this.traceId,
    this.violations = const [],
  });

  final AppErrorKind kind;
  final int? status;
  final String? title;
  final String? detail;

  /// Machine-readable business code (e.g. `PLAYER_INELIGIBLE`), if any.
  final String? code;
  final String? traceId;
  final List<AppViolation> violations;

  /// Normalises anything thrown by the data layer.
  factory AppError.of(Object error) {
    if (error is AppError) return error;
    if (error is DioException) return AppError.fromDioException(error);
    return const AppError(kind: AppErrorKind.unknown);
  }

  factory AppError.fromDioException(DioException e) {
    final wrapped = e.error;
    if (wrapped is AppError) return wrapped;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AppError(kind: AppErrorKind.timeout);
      case DioExceptionType.connectionError:
        return const AppError(kind: AppErrorKind.network);
      case DioExceptionType.badResponse:
        return AppError.fromResponse(e.response);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const AppError(kind: AppErrorKind.unknown);
    }
  }

  factory AppError.fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final body = response?.data;
    final json = body is Map ? body : const <dynamic, dynamic>{};
    final rawViolations = json['violations'];
    return AppError(
      kind: _kindFor(status),
      status: status,
      title: json['title'] as String?,
      detail: json['detail'] as String?,
      code: json['code'] as String?,
      traceId: json['traceId'] as String?,
      violations: [
        if (rawViolations is List)
          for (final v in rawViolations)
            if (v is Map && v['message'] is String)
              AppViolation(
                field: v['field'] as String?,
                code: v['code'] as String?,
                message: v['message'] as String,
              ),
      ],
    );
  }

  static AppErrorKind _kindFor(int? status) {
    if (status == null) return AppErrorKind.unknown;
    if (status == 401) return AppErrorKind.unauthorized;
    if (status == 403) return AppErrorKind.forbidden;
    if (status == 404) return AppErrorKind.notFound;
    if (status == 409) return AppErrorKind.conflict;
    if (status == 400 || status == 422) return AppErrorKind.validation;
    if (status >= 500) return AppErrorKind.server;
    return AppErrorKind.unknown;
  }

  @override
  String toString() =>
      'AppError($kind, status: $status, code: $code, traceId: $traceId)';
}
