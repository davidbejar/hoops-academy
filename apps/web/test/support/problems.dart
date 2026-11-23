import 'package:dio/dio.dart';

/// A Problem+JSON failure as the Dio layer throws it (`code` is the machine-readable business code).
DioException problem(int status, String code) {
  final request = RequestOptions(path: '/platform');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: {
        'status': status,
        'code': code,
        'detail': 'English server detail that must never be shown',
      },
    ),
  );
}
