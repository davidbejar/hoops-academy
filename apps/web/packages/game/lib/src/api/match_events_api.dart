//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:hoops_game_api/src/api_util.dart';
import 'package:hoops_game_api/src/model/match_event_batch.dart';
import 'package:hoops_game_api/src/model/match_event_batch_result.dart';
import 'package:hoops_game_api/src/model/match_event_feed.dart';
import 'package:hoops_game_api/src/model/problem.dart';

class MatchEventsApi {

  final Dio _dio;

  final Serializers _serializers;

  const MatchEventsApi(this._dio, this._serializers);

  /// Events stored after a server sequence number (merge feed for other devices)
  /// Ordered by &#x60;serverSeq&#x60; ascending. Includes voided events (with &#x60;voidedByEventId&#x60;).  Authz: any member who may view the match; **the feed is filtered per caller** (ADR-0030, security review F-01). ADMIN and staff (COACH / ASSISTANT_COACH) of the match&#39;s team read every event. Anybody else reads: - the **team-level** events: &#x60;PERIOD_START&#x60;, &#x60;PERIOD_END&#x60;, &#x60;OPPONENT_SCORE&#x60;, &#x60;TIMEOUT&#x60; and &#x60;NOTE&#x60; without   &#x60;playerId&#x60;; - the **player** events (&#x60;SHOT&#x60;, &#x60;ASSIST&#x60;, &#x60;REBOUND&#x60;, &#x60;TURNOVER&#x60;, &#x60;STEAL&#x60;, &#x60;BLOCK&#x60;, &#x60;FOUL&#x60;, &#x60;SUB_IN&#x60;, &#x60;SUB_OUT&#x60;,   &#x60;NOTE&#x60; with &#x60;playerId&#x60;) of their own player (PLAYER) or linked players (PARENT) only; - a &#x60;VOID&#x60; when the event it voids is visible to them (following VOID-of-VOID chains); a VOID of an event   unknown to the server is visible.  A filtered feed has gaps in &#x60;serverSeq&#x60;: page with &#x60;after&#x60; &#x3D; the last returned &#x60;serverSeq&#x60; (or &#x60;lastServerSeq&#x60; when &#x60;hasMore&#x60; is false), never assume consecutive numbers. A filtered caller cannot rebuild the team score from the feed; it reads score, period scores and team totals from &#x60;getBoxScore&#x60;.
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [matchId]
  /// * [after] - Return events with `serverSeq` > `after` (0 = from the beginning).
  /// * [limit]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MatchEventFeed] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MatchEventFeed>> listMatchEvents({
    required String xTenantId,
    required String matchId,
    int? after = 0,
    int? limit = 500,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/game/matches/{matchId}/events'.replaceAll('{' r'matchId' '}', encodeQueryParameter(_serializers, matchId, const FullType(String)).toString());
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
      if (after != null) r'after': encodeQueryParameter(_serializers, after, const FullType(int)),
      if (limit != null) r'limit': encodeQueryParameter(_serializers, limit, const FullType(int)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    MatchEventFeed? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(MatchEventFeed),
      ) as MatchEventFeed;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MatchEventFeed>(
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

  /// Sync a batch of match events (idempotent)
  /// Locks the match, appends new events, re-projects statistics and answers one result per submitted event, in request order. ACCEPTED: stored now (gets a &#x60;serverSeq&#x60;); DUPLICATE: an event with this &#x60;id&#x60; was already stored (its original &#x60;serverSeq&#x60; is returned) — safe to drop from the device queue; REJECTED: not stored, see &#x60;reason&#x60; (schema or authorization) — retrying unchanged will fail again. A REJECTED event never fails the batch: the server validates each event individually against &#x60;events/match-event.schema.json&#x60;. Whole-request errors: 400 (not a batch, or more than 500 events), 404 (unknown match). Once the season of the match&#39;s team has ended, an event whose &#x60;recordedAtClient&#x60; is after the season&#39;s last day (academy time zone) is REJECTED with &#x60;SEASON_ENDED&#x60; (ADR-0042); earlier events still sync.
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [matchId]
  /// * [matchEventBatch]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MatchEventBatchResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MatchEventBatchResult>> submitMatchEvents({
    required String xTenantId,
    required String matchId,
    required MatchEventBatch matchEventBatch,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/game/matches/{matchId}/events:batch'.replaceAll('{' r'matchId' '}', encodeQueryParameter(_serializers, matchId, const FullType(String)).toString());
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
      const _type = FullType(MatchEventBatch);
      _bodyData = _serializers.serialize(matchEventBatch, specifiedType: _type);

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

    MatchEventBatchResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(MatchEventBatchResult),
      ) as MatchEventBatchResult;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MatchEventBatchResult>(
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
