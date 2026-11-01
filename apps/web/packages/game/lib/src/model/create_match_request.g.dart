// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_match_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateMatchRequest extends CreateMatchRequest {
  @override
  final String teamId;
  @override
  final String opponentName;
  @override
  final HomeAway homeAway;
  @override
  final DateTime scheduledAt;
  @override
  final String? venue;
  @override
  final int? periodCount;
  @override
  final int? periodMinutes;

  factory _$CreateMatchRequest(
          [void Function(CreateMatchRequestBuilder)? updates]) =>
      (CreateMatchRequestBuilder()..update(updates))._build();

  _$CreateMatchRequest._(
      {required this.teamId,
      required this.opponentName,
      required this.homeAway,
      required this.scheduledAt,
      this.venue,
      this.periodCount,
      this.periodMinutes})
      : super._();
  @override
  CreateMatchRequest rebuild(
          void Function(CreateMatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateMatchRequestBuilder toBuilder() =>
      CreateMatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMatchRequest &&
        teamId == other.teamId &&
        opponentName == other.opponentName &&
        homeAway == other.homeAway &&
        scheduledAt == other.scheduledAt &&
        venue == other.venue &&
        periodCount == other.periodCount &&
        periodMinutes == other.periodMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, opponentName.hashCode);
    _$hash = $jc(_$hash, homeAway.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, venue.hashCode);
    _$hash = $jc(_$hash, periodCount.hashCode);
    _$hash = $jc(_$hash, periodMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateMatchRequest')
          ..add('teamId', teamId)
          ..add('opponentName', opponentName)
          ..add('homeAway', homeAway)
          ..add('scheduledAt', scheduledAt)
          ..add('venue', venue)
          ..add('periodCount', periodCount)
          ..add('periodMinutes', periodMinutes))
        .toString();
  }
}

class CreateMatchRequestBuilder
    implements Builder<CreateMatchRequest, CreateMatchRequestBuilder> {
  _$CreateMatchRequest? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _opponentName;
  String? get opponentName => _$this._opponentName;
  set opponentName(String? opponentName) => _$this._opponentName = opponentName;

  HomeAway? _homeAway;
  HomeAway? get homeAway => _$this._homeAway;
  set homeAway(HomeAway? homeAway) => _$this._homeAway = homeAway;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  String? _venue;
  String? get venue => _$this._venue;
  set venue(String? venue) => _$this._venue = venue;

  int? _periodCount;
  int? get periodCount => _$this._periodCount;
  set periodCount(int? periodCount) => _$this._periodCount = periodCount;

  int? _periodMinutes;
  int? get periodMinutes => _$this._periodMinutes;
  set periodMinutes(int? periodMinutes) =>
      _$this._periodMinutes = periodMinutes;

  CreateMatchRequestBuilder() {
    CreateMatchRequest._defaults(this);
  }

  CreateMatchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _opponentName = $v.opponentName;
      _homeAway = $v.homeAway;
      _scheduledAt = $v.scheduledAt;
      _venue = $v.venue;
      _periodCount = $v.periodCount;
      _periodMinutes = $v.periodMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMatchRequest other) {
    _$v = other as _$CreateMatchRequest;
  }

  @override
  void update(void Function(CreateMatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateMatchRequest build() => _build();

  _$CreateMatchRequest _build() {
    final _$result = _$v ??
        _$CreateMatchRequest._(
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'CreateMatchRequest', 'teamId'),
          opponentName: BuiltValueNullFieldError.checkNotNull(
              opponentName, r'CreateMatchRequest', 'opponentName'),
          homeAway: BuiltValueNullFieldError.checkNotNull(
              homeAway, r'CreateMatchRequest', 'homeAway'),
          scheduledAt: BuiltValueNullFieldError.checkNotNull(
              scheduledAt, r'CreateMatchRequest', 'scheduledAt'),
          venue: venue,
          periodCount: periodCount,
          periodMinutes: periodMinutes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
