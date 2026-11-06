// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_match_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateMatchRequestClearEnum _$updateMatchRequestClearEnum_venue =
    const UpdateMatchRequestClearEnum._('venue');
const UpdateMatchRequestClearEnum
    _$updateMatchRequestClearEnum_unknownDefaultOpenApi =
    const UpdateMatchRequestClearEnum._('unknownDefaultOpenApi');

UpdateMatchRequestClearEnum _$updateMatchRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'venue':
      return _$updateMatchRequestClearEnum_venue;
    case 'unknownDefaultOpenApi':
      return _$updateMatchRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateMatchRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateMatchRequestClearEnum>
    _$updateMatchRequestClearEnumValues =
    BuiltSet<UpdateMatchRequestClearEnum>(const <UpdateMatchRequestClearEnum>[
  _$updateMatchRequestClearEnum_venue,
  _$updateMatchRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateMatchRequestClearEnum>
    _$updateMatchRequestClearEnumSerializer =
    _$UpdateMatchRequestClearEnumSerializer();

class _$UpdateMatchRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateMatchRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'venue': 'venue',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'venue': 'venue',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateMatchRequestClearEnum];
  @override
  final String wireName = 'UpdateMatchRequestClearEnum';

  @override
  Object serialize(Serializers serializers, UpdateMatchRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateMatchRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateMatchRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

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
  @override
  final BuiltSet<UpdateMatchRequestClearEnum>? clear;

  factory _$UpdateMatchRequest(
          [void Function(UpdateMatchRequestBuilder)? updates]) =>
      (UpdateMatchRequestBuilder()..update(updates))._build();

  _$UpdateMatchRequest._(
      {this.opponentName,
      this.homeAway,
      this.scheduledAt,
      this.venue,
      this.periodCount,
      this.periodMinutes,
      this.clear})
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
        periodMinutes == other.periodMinutes &&
        clear == other.clear;
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
    _$hash = $jc(_$hash, clear.hashCode);
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
          ..add('periodMinutes', periodMinutes)
          ..add('clear', clear))
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

  SetBuilder<UpdateMatchRequestClearEnum>? _clear;
  SetBuilder<UpdateMatchRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateMatchRequestClearEnum>();
  set clear(SetBuilder<UpdateMatchRequestClearEnum>? clear) =>
      _$this._clear = clear;

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
      _clear = $v.clear?.toBuilder();
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
    _$UpdateMatchRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateMatchRequest._(
            opponentName: opponentName,
            homeAway: homeAway,
            scheduledAt: scheduledAt,
            venue: venue,
            periodCount: periodCount,
            periodMinutes: periodMinutes,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateMatchRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
