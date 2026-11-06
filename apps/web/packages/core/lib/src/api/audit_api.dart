//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/api_util.dart';
import 'package:hoops_core_api/src/model/audit_action.dart';
import 'package:hoops_core_api/src/model/audit_event_page.dart';
import 'package:hoops_core_api/src/model/problem.dart';

class AuditApi {

  final Dio _dio;

  final Serializers _serializers;

  const AuditApi(this._dio, this._serializers);

  /// The academy&#39;s audit trail
  /// Administrative actions recorded in this academy (by its members, by the super admin and by the platform&#39;s background jobs), newest first. Actor and target names are resolved at read time while the person, player or academy still exists; metadata never holds personal data (&#x60;docs/domain/audit-events.md&#x60;). The super admin is masked: a PLATFORM actor carries no &#x60;subject&#x60;, &#x60;personId&#x60; or &#x60;displayName&#x60; (the web shows \&quot;Platform administrator\&quot;); the metadata, such as the &#x60;reason&#x60; of &#x60;tenant.suspended&#x60;, is unchanged. &#x60;from&#x60; must be before &#x60;to&#x60; (400). Retention: none in v1 (a purge job is a v2 item); rows are append-only. Authz: ADMIN. 
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [from] - Inclusive lower bound on `at`.
  /// * [to] - Exclusive upper bound on `at`.
  /// * [action] - One or several actions (`?action=member.invited&action=member.updated`); any action when absent.
  /// * [page] - 0-based page index.
  /// * [size] - Page size.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AuditEventPage] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AuditEventPage>> listAuditEvents({ 
    required String xTenantId,
    DateTime? from,
    DateTime? to,
    BuiltList<AuditAction>? action,
    int? page = 0,
    int? size = 50,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/core/audit-events';
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
      if (from != null) r'from': encodeQueryParameter(_serializers, from, const FullType(DateTime)),
      if (to != null) r'to': encodeQueryParameter(_serializers, to, const FullType(DateTime)),
      if (action != null) r'action': encodeCollectionQueryParameter<AuditAction>(_serializers, action, const FullType(BuiltList, [FullType(AuditAction)]), format: ListFormat.multi,),
      if (page != null) r'page': encodeQueryParameter(_serializers, page, const FullType(int)),
      if (size != null) r'size': encodeQueryParameter(_serializers, size, const FullType(int)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AuditEventPage? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(AuditEventPage),
      ) as AuditEventPage;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AuditEventPage>(
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
