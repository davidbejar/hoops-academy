//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/api_util.dart';
import 'package:hoops_athlete_api/src/model/body_measurement.dart';
import 'package:hoops_athlete_api/src/model/body_measurement_input.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/problem.dart';
import 'package:hoops_athlete_api/src/model/update_body_measurement_request.dart';

class BodyMeasurementsApi {

  final Dio _dio;

  final Serializers _serializers;

  const BodyMeasurementsApi(this._dio, this._serializers);

  /// Record height and/or weight
  /// At least one of &#x60;heightCm&#x60; / &#x60;weightKg&#x60; (422); one measurement per player and day (409). 409 &#x60;SEASON_ENDED&#x60; for a coach whose only relation to the player is a team of an ended season (ADR-0042). Authz: ADMIN; team staff; PARENT (linked).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [bodyMeasurementInput] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BodyMeasurement] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BodyMeasurement>> createBodyMeasurement({ 
    required String xTenantId,
    required BodyMeasurementInput bodyMeasurementInput,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/athlete/body-measurements';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-Tenant-Id': xTenantId,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(BodyMeasurementInput);
      _bodyData = _serializers.serialize(bodyMeasurementInput, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BodyMeasurement? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BodyMeasurement),
      ) as BodyMeasurement;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BodyMeasurement>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Delete a measurement
  /// 409 &#x60;SEASON_ENDED&#x60; for a coach whose only relation to the player is a team of an ended season (ADR-0042). Authz: ADMIN; team staff; PARENT (linked).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [measurementId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> deleteBodyMeasurement({ 
    required String xTenantId,
    required String measurementId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/athlete/body-measurements/{measurementId}'.replaceAll('{' r'measurementId' '}', encodeQueryParameter(_serializers, measurementId, const FullType(String)).toString());
    final _options = Options(
      method: r'DELETE',
      headers: <String, dynamic>{
        r'X-Tenant-Id': xTenantId,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Height / weight history of a player (measuredOn ascending)
  /// Former staff of an ended season: records dated on or before its last day (ADR-0042). Authz: ADMIN; team staff; PARENT (linked); PLAYER (self).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [playerId] 
  /// * [from] - Inclusive lower bound (calendar date in the tenant's time zone).
  /// * [to] - Inclusive upper bound (calendar date in the tenant's time zone).
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BuiltList<BodyMeasurement>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BuiltList<BodyMeasurement>>> listBodyMeasurements({ 
    required String xTenantId,
    required String playerId,
    Date? from,
    Date? to,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/athlete/body-measurements';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        r'X-Tenant-Id': xTenantId,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'playerId': encodeQueryParameter(_serializers, playerId, const FullType(String)),
      if (from != null) r'from': encodeQueryParameter(_serializers, from, const FullType(Date)),
      if (to != null) r'to': encodeQueryParameter(_serializers, to, const FullType(Date)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BuiltList<BodyMeasurement>? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BuiltList, [FullType(BodyMeasurement)]),
      ) as BuiltList<BodyMeasurement>;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BuiltList<BodyMeasurement>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Correct a measurement
  /// 409 &#x60;SEASON_ENDED&#x60; for a coach whose only relation to the player is a team of an ended season (ADR-0042). Authz: ADMIN; team staff; PARENT (linked).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [measurementId] 
  /// * [updateBodyMeasurementRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BodyMeasurement] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BodyMeasurement>> updateBodyMeasurement({ 
    required String xTenantId,
    required String measurementId,
    required UpdateBodyMeasurementRequest updateBodyMeasurementRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/athlete/body-measurements/{measurementId}'.replaceAll('{' r'measurementId' '}', encodeQueryParameter(_serializers, measurementId, const FullType(String)).toString());
    final _options = Options(
      method: r'PATCH',
      headers: <String, dynamic>{
        r'X-Tenant-Id': xTenantId,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(UpdateBodyMeasurementRequest);
      _bodyData = _serializers.serialize(updateBodyMeasurementRequest, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BodyMeasurement? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BodyMeasurement),
      ) as BodyMeasurement;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BodyMeasurement>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
