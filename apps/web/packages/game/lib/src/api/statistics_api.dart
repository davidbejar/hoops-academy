//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'dart:typed_data';
import 'package:hoops_game_api/src/api_util.dart';
import 'package:hoops_game_api/src/model/box_score.dart';
import 'package:hoops_game_api/src/model/player_season_stats.dart';
import 'package:hoops_game_api/src/model/problem.dart';

class StatisticsApi {

  final Dio _dio;

  final Serializers _serializers;

  const StatisticsApi(this._dio, this._serializers);

  /// Box score projection of a match
  /// Authz: ADMIN and team staff see all players; PARENT sees linked players&#39; lines; PLAYER sees own line (team totals always visible).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [matchId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BoxScore] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BoxScore>> getBoxScore({
    required String xTenantId,
    required String matchId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/game/matches/{matchId}/box-score'.replaceAll('{' r'matchId' '}', encodeQueryParameter(_serializers, matchId, const FullType(String)).toString());
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

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BoxScore? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BoxScore),
      ) as BoxScore;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BoxScore>(
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

  /// The match sheet (header, score, score by period, box score) as a PDF
  /// The box score of &#x60;getBoxScore&#x60; printed as a match sheet (decisions 89 and 90, ADR-0048 amendment of WP117): the academy, the team and the opponent, home or away, the day and time in the academy&#39;s time zone, the venue and the status, the score, the score by period (overtimes after &#x60;periodCount&#x60;), the team totals and one line per player **the caller sees in &#x60;getBoxScore&#x60;** (roster order, jersey, starter, every &#x60;StatLine&#x60; figure). No projection warnings. Labels in the language of &#x60;Accept-Language&#x60; (&#x60;es&#x60;, &#x60;en&#x60;, &#x60;id&#x60;; else &#x60;en&#x60;).  game loads the match and its box score, sends them to the internal &#x60;pdf-service&#x60; with its own client-credentials token and returns the file: &#x60;Content-Disposition: attachment; filename&#x3D;\&quot;hoops-&lt;academy&gt;-match-sheet-&lt;team&gt;-&lt;opponent&gt;-&lt;yyyyMMdd&gt;.pdf\&quot;&#x60; (ADR-0048 pattern, today in the academy&#39;s zone) and &#x60;Cache-Control: no-store&#x60;. Not audited (the box score it prints is a read every member has; the audit trail is core&#39;s and records the roster and audit exports). Online only: when &#x60;pdf-service&#x60; cannot be reached, is not configured, or fails, 503 Problem &#x60;UPSTREAM_UNAVAILABLE&#x60; (safe to retry; nothing of the sheet is logged).  Authz: every member of the academy, as &#x60;getBoxScore&#x60;: ADMIN and staff of the match&#39;s team (also its former staff once the season has ended, ADR-0042) get every player&#39;s line; anybody else the lines of their linked players (PARENT) and their own (PLAYER), with the team-level figures; non-members 404.
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [matchId]
  /// * [acceptLanguage] - Language of the sheet's labels (RFC 9110 list, e.g. `id, en;q=0.8`): the first of `es`, `en`, `id` in preference order (`in` counts as `id`, `q=0` refuses); absent, `*` or unsupported = `en`. Names are printed as stored.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Uint8List] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Uint8List>> getMatchSheetPdf({
    required String xTenantId,
    required String matchId,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/game/matches/{matchId}/box-score:pdf'.replaceAll('{' r'matchId' '}', encodeQueryParameter(_serializers, matchId, const FullType(String)).toString());
    final _options = Options(
      method: r'GET',
      responseType: ResponseType.bytes,
      headers: <String, dynamic>{
        r'X-Tenant-Id': xTenantId,
        if (acceptLanguage != null) r'Accept-Language': acceptLanguage,
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

    Uint8List? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : rawResponse as Uint8List;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Uint8List>(
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

  /// A player&#39;s statistics over a season (FINISHED and LIVE matches)
  /// Authz: ADMIN; team staff; PARENT (linked); PLAYER (self).
  ///
  /// Parameters:
  /// * [xTenantId] - Tenant (academy) the request acts on; chosen in the tenant switcher fed by `GET /api/core/me`.
  /// * [playerId]
  /// * [seasonId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PlayerSeasonStats] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PlayerSeasonStats>> getPlayerSeasonStats({
    required String xTenantId,
    required String playerId,
    required String seasonId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/game/players/{playerId}/season-stats'.replaceAll('{' r'playerId' '}', encodeQueryParameter(_serializers, playerId, const FullType(String)).toString());
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
      r'seasonId': encodeQueryParameter(_serializers, seasonId, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PlayerSeasonStats? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(PlayerSeasonStats),
      ) as PlayerSeasonStats;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PlayerSeasonStats>(
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
