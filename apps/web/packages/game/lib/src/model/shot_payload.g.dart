// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shot_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ShotPayloadPointsEnum _$shotPayloadPointsEnum_number1 =
    const ShotPayloadPointsEnum._('number1');
const ShotPayloadPointsEnum _$shotPayloadPointsEnum_number2 =
    const ShotPayloadPointsEnum._('number2');
const ShotPayloadPointsEnum _$shotPayloadPointsEnum_number3 =
    const ShotPayloadPointsEnum._('number3');
const ShotPayloadPointsEnum _$shotPayloadPointsEnum_unknownDefaultOpenApi =
    const ShotPayloadPointsEnum._('unknownDefaultOpenApi');

ShotPayloadPointsEnum _$shotPayloadPointsEnumValueOf(String name) {
  switch (name) {
    case 'number1':
      return _$shotPayloadPointsEnum_number1;
    case 'number2':
      return _$shotPayloadPointsEnum_number2;
    case 'number3':
      return _$shotPayloadPointsEnum_number3;
    case 'unknownDefaultOpenApi':
      return _$shotPayloadPointsEnum_unknownDefaultOpenApi;
    default:
      return _$shotPayloadPointsEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ShotPayloadPointsEnum> _$shotPayloadPointsEnumValues =
    BuiltSet<ShotPayloadPointsEnum>(const <ShotPayloadPointsEnum>[
  _$shotPayloadPointsEnum_number1,
  _$shotPayloadPointsEnum_number2,
  _$shotPayloadPointsEnum_number3,
  _$shotPayloadPointsEnum_unknownDefaultOpenApi,
]);

Serializer<ShotPayloadPointsEnum> _$shotPayloadPointsEnumSerializer =
    _$ShotPayloadPointsEnumSerializer();

class _$ShotPayloadPointsEnumSerializer
    implements PrimitiveSerializer<ShotPayloadPointsEnum> {
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
  final Iterable<Type> types = const <Type>[ShotPayloadPointsEnum];
  @override
  final String wireName = 'ShotPayloadPointsEnum';

  @override
  Object serialize(Serializers serializers, ShotPayloadPointsEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ShotPayloadPointsEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ShotPayloadPointsEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ShotPayload extends ShotPayload {
  @override
  final ShotPayloadPointsEnum points;
  @override
  final bool made;

  factory _$ShotPayload([void Function(ShotPayloadBuilder)? updates]) =>
      (ShotPayloadBuilder()..update(updates))._build();

  _$ShotPayload._({required this.points, required this.made}) : super._();
  @override
  ShotPayload rebuild(void Function(ShotPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShotPayloadBuilder toBuilder() => ShotPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShotPayload && points == other.points && made == other.made;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, points.hashCode);
    _$hash = $jc(_$hash, made.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShotPayload')
          ..add('points', points)
          ..add('made', made))
        .toString();
  }
}

class ShotPayloadBuilder implements Builder<ShotPayload, ShotPayloadBuilder> {
  _$ShotPayload? _$v;

  ShotPayloadPointsEnum? _points;
  ShotPayloadPointsEnum? get points => _$this._points;
  set points(ShotPayloadPointsEnum? points) => _$this._points = points;

  bool? _made;
  bool? get made => _$this._made;
  set made(bool? made) => _$this._made = made;

  ShotPayloadBuilder() {
    ShotPayload._defaults(this);
  }

  ShotPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _points = $v.points;
      _made = $v.made;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShotPayload other) {
    _$v = other as _$ShotPayload;
  }

  @override
  void update(void Function(ShotPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShotPayload build() => _build();

  _$ShotPayload _build() {
    final _$result = _$v ??
        _$ShotPayload._(
          points: BuiltValueNullFieldError.checkNotNull(
              points, r'ShotPayload', 'points'),
          made: BuiltValueNullFieldError.checkNotNull(
              made, r'ShotPayload', 'made'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
