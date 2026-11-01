// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeout_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TimeoutPayloadSideEnum _$timeoutPayloadSideEnum_OWN =
    const TimeoutPayloadSideEnum._('OWN');
const TimeoutPayloadSideEnum _$timeoutPayloadSideEnum_OPPONENT =
    const TimeoutPayloadSideEnum._('OPPONENT');
const TimeoutPayloadSideEnum _$timeoutPayloadSideEnum_unknownDefaultOpenApi =
    const TimeoutPayloadSideEnum._('unknownDefaultOpenApi');

TimeoutPayloadSideEnum _$timeoutPayloadSideEnumValueOf(String name) {
  switch (name) {
    case 'OWN':
      return _$timeoutPayloadSideEnum_OWN;
    case 'OPPONENT':
      return _$timeoutPayloadSideEnum_OPPONENT;
    case 'unknownDefaultOpenApi':
      return _$timeoutPayloadSideEnum_unknownDefaultOpenApi;
    default:
      return _$timeoutPayloadSideEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<TimeoutPayloadSideEnum> _$timeoutPayloadSideEnumValues =
    BuiltSet<TimeoutPayloadSideEnum>(const <TimeoutPayloadSideEnum>[
  _$timeoutPayloadSideEnum_OWN,
  _$timeoutPayloadSideEnum_OPPONENT,
  _$timeoutPayloadSideEnum_unknownDefaultOpenApi,
]);

Serializer<TimeoutPayloadSideEnum> _$timeoutPayloadSideEnumSerializer =
    _$TimeoutPayloadSideEnumSerializer();

class _$TimeoutPayloadSideEnumSerializer
    implements PrimitiveSerializer<TimeoutPayloadSideEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OWN': 'OWN',
    'OPPONENT': 'OPPONENT',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OWN': 'OWN',
    'OPPONENT': 'OPPONENT',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TimeoutPayloadSideEnum];
  @override
  final String wireName = 'TimeoutPayloadSideEnum';

  @override
  Object serialize(Serializers serializers, TimeoutPayloadSideEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TimeoutPayloadSideEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TimeoutPayloadSideEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TimeoutPayload extends TimeoutPayload {
  @override
  final TimeoutPayloadSideEnum side;

  factory _$TimeoutPayload([void Function(TimeoutPayloadBuilder)? updates]) =>
      (TimeoutPayloadBuilder()..update(updates))._build();

  _$TimeoutPayload._({required this.side}) : super._();
  @override
  TimeoutPayload rebuild(void Function(TimeoutPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TimeoutPayloadBuilder toBuilder() => TimeoutPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TimeoutPayload && side == other.side;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, side.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TimeoutPayload')..add('side', side))
        .toString();
  }
}

class TimeoutPayloadBuilder
    implements Builder<TimeoutPayload, TimeoutPayloadBuilder> {
  _$TimeoutPayload? _$v;

  TimeoutPayloadSideEnum? _side;
  TimeoutPayloadSideEnum? get side => _$this._side;
  set side(TimeoutPayloadSideEnum? side) => _$this._side = side;

  TimeoutPayloadBuilder() {
    TimeoutPayload._defaults(this);
  }

  TimeoutPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _side = $v.side;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TimeoutPayload other) {
    _$v = other as _$TimeoutPayload;
  }

  @override
  void update(void Function(TimeoutPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TimeoutPayload build() => _build();

  _$TimeoutPayload _build() {
    final _$result = _$v ??
        _$TimeoutPayload._(
          side: BuiltValueNullFieldError.checkNotNull(
              side, r'TimeoutPayload', 'side'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
