//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:hoops_core_api/src/api_util.dart';
import 'package:hoops_core_api/src/model/academy_request.dart';
import 'package:hoops_core_api/src/model/academy_request_accepted.dart';
import 'package:hoops_core_api/src/model/academy_request_page.dart';
import 'package:hoops_core_api/src/model/academy_request_received.dart';
import 'package:hoops_core_api/src/model/academy_request_status.dart';
import 'package:hoops_core_api/src/model/accept_academy_request.dart';
import 'package:hoops_core_api/src/model/problem.dart';
import 'package:hoops_core_api/src/model/reject_academy_request.dart';
import 'package:hoops_core_api/src/model/submit_academy_request.dart';

class AcademyRequestsApi {
  final Dio _dio;

  final Serializers _serializers;

  const AcademyRequestsApi(this._dio, this._serializers);

  /// Accept a pending request and create the academy with the requester as its first ADMIN
  /// Runs &#x60;createTenant&#x60; with the request&#39;s academy name and e-mail plus the slug, time zone, default language and the administrator&#39;s names given here (ADR-0044). The requester becomes the first ADMIN whatever role they asked with. A new login gets a temporary password, returned once in &#x60;temporaryPassword&#x60; (ADR-0024); an existing login is linked and gets none. The requester then receives an e-mail in the request&#39;s language with the sign-in address and their login (never the password); &#x60;request.notifiedAt&#x60; stays null when it could not be sent. Audit: &#x60;tenant.request_accepted&#x60; in the new academy&#39;s trail. 409 &#x60;REQUEST_NOT_PENDING&#x60; (already decided), &#x60;SLUG_TAKEN&#x60;, &#x60;ACADEMY_NAME_TAKEN&#x60; (an academy got the name meanwhile); 502 when Keycloak fails (the request stays pending). Authz: super_admin.
  ///
  /// Parameters:
  /// * [requestId]
  /// * [acceptAcademyRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AcademyRequestAccepted] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AcademyRequestAccepted>> acceptAcademyRequest({
    required String requestId,
    required AcceptAcademyRequest acceptAcademyRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/platform/academy-requests/{requestId}:accept'.replaceAll(
        '{' r'requestId' '}',
        encodeQueryParameter(_serializers, requestId, const FullType(String))
            .toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
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
      const _type = FullType(AcceptAcademyRequest);
      _bodyData =
          _serializers.serialize(acceptAcademyRequest, specifiedType: _type);
    } catch (error, stackTrace) {
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

    AcademyRequestAccepted? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AcademyRequestAccepted),
            ) as AcademyRequestAccepted;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AcademyRequestAccepted>(
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

  /// List academy requests (the super admin&#39;s workbench)
  /// Newest first; &#x60;status&#x60; filters. Authz: super_admin.
  ///
  /// Parameters:
  /// * [status]
  /// * [page] - 0-based page index.
  /// * [size] - Page size.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AcademyRequestPage] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AcademyRequestPage>> listAcademyRequests({
    AcademyRequestStatus? status,
    int? page = 0,
    int? size = 50,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/platform/academy-requests';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
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
      if (status != null)
        r'status': encodeQueryParameter(
            _serializers, status, const FullType(AcademyRequestStatus)),
      if (page != null)
        r'page': encodeQueryParameter(_serializers, page, const FullType(int)),
      if (size != null)
        r'size': encodeQueryParameter(_serializers, size, const FullType(int)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AcademyRequestPage? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AcademyRequestPage),
            ) as AcademyRequestPage;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AcademyRequestPage>(
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

  /// Reject a pending request with a reason (e-mailed to the requester)
  /// Records the decision (who, when, the reason) on the request and e-mails the reason to the requester in the request&#39;s language; &#x60;notifiedAt&#x60; stays null when the e-mail could not be sent (the decision stands). No academy exists, so there is no academy audit row: the request row is the record (ADR-0044). 409 &#x60;REQUEST_NOT_PENDING&#x60;. Authz: super_admin.
  ///
  /// Parameters:
  /// * [requestId]
  /// * [rejectAcademyRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AcademyRequest] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AcademyRequest>> rejectAcademyRequest({
    required String requestId,
    required RejectAcademyRequest rejectAcademyRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/platform/academy-requests/{requestId}:reject'.replaceAll(
        '{' r'requestId' '}',
        encodeQueryParameter(_serializers, requestId, const FullType(String))
            .toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
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
      const _type = FullType(RejectAcademyRequest);
      _bodyData =
          _serializers.serialize(rejectAcademyRequest, specifiedType: _type);
    } catch (error, stackTrace) {
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

    AcademyRequest? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AcademyRequest),
            ) as AcademyRequest;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AcademyRequest>(
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

  /// Request a new academy (public, no sign-in)
  /// The landing page&#39;s invitation request (decision 51 and 58, ADR-0044). Anyone may ask for a new academy as its future administrator, a coach or a parent (players never request); on acceptance the requester becomes the academy&#39;s first ADMIN. No sign-in, no &#x60;X-Tenant-Id&#x60;. Rate-limited per client IP at the gateway (429 from the gateway, without a Problem body).  The answer never tells whether the e-mail already signs in, already asked or was dropped: every accepted body gets the same &#x60;202&#x60;. Silently dropped (still &#x60;202&#x60;): a filled honeypot &#x60;website&#x60;, and a fourth pending request of the same e-mail. Nothing is e-mailed on submission (the endpoint can never be used to send mail to a third party). The academy name must be free: 409 &#x60;ACADEMY_NAME_TAKEN&#x60; when an academy or a pending or accepted request already has it (compared trimmed, inner spaces collapsed, case-insensitive). Authz: anonymous (the only public operation of the platform).
  ///
  /// Parameters:
  /// * [submitAcademyRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AcademyRequestReceived] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AcademyRequestReceived>> submitAcademyRequest({
    required SubmitAcademyRequest submitAcademyRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/platform/academy-requests';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(SubmitAcademyRequest);
      _bodyData =
          _serializers.serialize(submitAcademyRequest, specifiedType: _type);
    } catch (error, stackTrace) {
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

    AcademyRequestReceived? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AcademyRequestReceived),
            ) as AcademyRequestReceived;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AcademyRequestReceived>(
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
