// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opponent_score_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OpponentScorePayloadPointsEnum _$opponentScorePayloadPointsEnum_number1 =
    const OpponentScorePayloadPointsEnum._('number1');
const OpponentScorePayloadPointsEnum _$opponentScorePayloadPointsEnum_number2 =
    const OpponentScorePayloadPointsEnum._('number2');
const OpponentScorePayloadPointsEnum _$opponentScorePayloadPointsEnum_number3 =
    const OpponentScorePayloadPointsEnum._('number3');
const OpponentScorePayloadPointsEnum
    _$opponentScorePayloadPointsEnum_unknownDefaultOpenApi =
    const OpponentScorePayloadPointsEnum._('unknownDefaultOpenApi');

OpponentScorePayloadPointsEnum _$opponentScorePayloadPointsEnumValueOf(
    String name) {
  switch (name) {
    case 'number1':
      return _$opponentScorePayloadPointsEnum_number1;
    case 'number2':
      return _$opponentScorePayloadPointsEnum_number2;
    case 'number3':
      return _$opponentScorePayloadPointsEnum_number3;
    case 'unknownDefaultOpenApi':
      return _$opponentScorePayloadPointsEnum_unknownDefaultOpenApi;
    default:
      return _$opponentScorePayloadPointsEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<OpponentScorePayloadPointsEnum>
    _$opponentScorePayloadPointsEnumValues = BuiltSet<
        OpponentScorePayloadPointsEnum>(const <OpponentScorePayloadPointsEnum>[
  _$opponentScorePayloadPointsEnum_number1,
  _$opponentScorePayloadPointsEnum_number2,
  _$opponentScorePayloadPointsEnum_number3,
  _$opponentScorePayloadPointsEnum_unknownDefaultOpenApi,
]);

Serializer<OpponentScorePayloadPointsEnum>
    _$opponentScorePayloadPointsEnumSerializer =
    _$OpponentScorePayloadPointsEnumSerializer();

class _$OpponentScorePayloadPointsEnumSerializer
    implements PrimitiveSerializer<OpponentScorePayloadPointsEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number1': 1,
    'number2': 2,
    'number3': 3,
    'unknownDefaultOpenApi': 11184809,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    1: 'number1',
    2: 'number2',
    3: 'number3',
    11184809: 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[OpponentScorePayloadPointsEnum];
  @override
  final String wireName = 'OpponentScorePayloadPointsEnum';

  @override
  Object serialize(
          Serializers serializers, OpponentScorePayloadPointsEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OpponentScorePayloadPointsEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OpponentScorePayloadPointsEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OpponentScorePayload extends OpponentScorePayload {
  @override
  final OpponentScorePayloadPointsEnum points;

  factory _$OpponentScorePayload(
          [void Function(OpponentScorePayloadBuilder)? updates]) =>
      (OpponentScorePayloadBuilder()..update(updates))._build();

  _$OpponentScorePayload._({required this.points}) : super._();
  @override
  OpponentScorePayload rebuild(
          void Function(OpponentScorePayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OpponentScorePayloadBuilder toBuilder() =>
      OpponentScorePayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OpponentScorePayload && points == other.points;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, points.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OpponentScorePayload')
          ..add('points', points))
        .toString();
  }
}

class OpponentScorePayloadBuilder
    implements Builder<OpponentScorePayload, OpponentScorePayloadBuilder> {
  _$OpponentScorePayload? _$v;

  OpponentScorePayloadPointsEnum? _points;
  OpponentScorePayloadPointsEnum? get points => _$this._points;
  set points(OpponentScorePayloadPointsEnum? points) => _$this._points = points;

  OpponentScorePayloadBuilder() {
    OpponentScorePayload._defaults(this);
  }

  OpponentScorePayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _points = $v.points;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OpponentScorePayload other) {
    _$v = other as _$OpponentScorePayload;
  }

  @override
  void update(void Function(OpponentScorePayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OpponentScorePayload build() => _build();

  _$OpponentScorePayload _build() {
    final _$result = _$v ??
        _$OpponentScorePayload._(
          points: BuiltValueNullFieldError.checkNotNull(
              points, r'OpponentScorePayload', 'points'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
