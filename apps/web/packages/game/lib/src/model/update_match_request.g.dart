// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_match_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMatchRequest extends UpdateMatchRequest {
  @override
  final String? opponentName;
  @override
  final HomeAway? homeAway;
  @override
  final DateTime? scheduledAt;
  @override
  final String? venue;
  @override
  final int? periodCount;
  @override
  final int? periodMinutes;

  factory _$UpdateMatchRequest(
          [void Function(UpdateMatchRequestBuilder)? updates]) =>
      (UpdateMatchRequestBuilder()..update(updates))._build();

  _$UpdateMatchRequest._(
      {this.opponentName,
      this.homeAway,
      this.scheduledAt,
      this.venue,
      this.periodCount,
      this.periodMinutes})
      : super._();
  @override
  UpdateMatchRequest rebuild(
          void Function(UpdateMatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMatchRequestBuilder toBuilder() =>
      UpdateMatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMatchRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateMatchRequest')
          ..add('opponentName', opponentName)
          ..add('homeAway', homeAway)
          ..add('scheduledAt', scheduledAt)
          ..add('venue', venue)
          ..add('periodCount', periodCount)
          ..add('periodMinutes', periodMinutes))
        .toString();
  }
}

class UpdateMatchRequestBuilder
    implements Builder<UpdateMatchRequest, UpdateMatchRequestBuilder> {
  _$UpdateMatchRequest? _$v;

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

  UpdateMatchRequestBuilder() {
    UpdateMatchRequest._defaults(this);
  }

  UpdateMatchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(UpdateMatchRequest other) {
    _$v = other as _$UpdateMatchRequest;
  }

  @override
  void update(void Function(UpdateMatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMatchRequest build() => _build();

  _$UpdateMatchRequest _build() {
    final _$result = _$v ??
        _$UpdateMatchRequest._(
          opponentName: opponentName,
          homeAway: homeAway,
          scheduledAt: scheduledAt,
          venue: venue,
          periodCount: periodCount,
          periodMinutes: periodMinutes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
