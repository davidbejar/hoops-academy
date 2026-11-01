// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebound_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReboundPayloadKindEnum _$reboundPayloadKindEnum_OFFENSIVE =
    const ReboundPayloadKindEnum._('OFFENSIVE');
const ReboundPayloadKindEnum _$reboundPayloadKindEnum_DEFENSIVE =
    const ReboundPayloadKindEnum._('DEFENSIVE');
const ReboundPayloadKindEnum _$reboundPayloadKindEnum_unknownDefaultOpenApi =
    const ReboundPayloadKindEnum._('unknownDefaultOpenApi');

ReboundPayloadKindEnum _$reboundPayloadKindEnumValueOf(String name) {
  switch (name) {
    case 'OFFENSIVE':
      return _$reboundPayloadKindEnum_OFFENSIVE;
    case 'DEFENSIVE':
      return _$reboundPayloadKindEnum_DEFENSIVE;
    case 'unknownDefaultOpenApi':
      return _$reboundPayloadKindEnum_unknownDefaultOpenApi;
    default:
      return _$reboundPayloadKindEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ReboundPayloadKindEnum> _$reboundPayloadKindEnumValues =
    BuiltSet<ReboundPayloadKindEnum>(const <ReboundPayloadKindEnum>[
  _$reboundPayloadKindEnum_OFFENSIVE,
  _$reboundPayloadKindEnum_DEFENSIVE,
  _$reboundPayloadKindEnum_unknownDefaultOpenApi,
]);

Serializer<ReboundPayloadKindEnum> _$reboundPayloadKindEnumSerializer =
    _$ReboundPayloadKindEnumSerializer();

class _$ReboundPayloadKindEnumSerializer
    implements PrimitiveSerializer<ReboundPayloadKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OFFENSIVE': 'OFFENSIVE',
    'DEFENSIVE': 'DEFENSIVE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OFFENSIVE': 'OFFENSIVE',
    'DEFENSIVE': 'DEFENSIVE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ReboundPayloadKindEnum];
  @override
  final String wireName = 'ReboundPayloadKindEnum';

  @override
  Object serialize(Serializers serializers, ReboundPayloadKindEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ReboundPayloadKindEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ReboundPayloadKindEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ReboundPayload extends ReboundPayload {
  @override
  final ReboundPayloadKindEnum kind;

  factory _$ReboundPayload([void Function(ReboundPayloadBuilder)? updates]) =>
      (ReboundPayloadBuilder()..update(updates))._build();

  _$ReboundPayload._({required this.kind}) : super._();
  @override
  ReboundPayload rebuild(void Function(ReboundPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReboundPayloadBuilder toBuilder() => ReboundPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReboundPayload && kind == other.kind;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReboundPayload')..add('kind', kind))
        .toString();
  }
}

class ReboundPayloadBuilder
    implements Builder<ReboundPayload, ReboundPayloadBuilder> {
  _$ReboundPayload? _$v;

  ReboundPayloadKindEnum? _kind;
  ReboundPayloadKindEnum? get kind => _$this._kind;
  set kind(ReboundPayloadKindEnum? kind) => _$this._kind = kind;

  ReboundPayloadBuilder() {
    ReboundPayload._defaults(this);
  }

  ReboundPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReboundPayload other) {
    _$v = other as _$ReboundPayload;
  }

  @override
  void update(void Function(ReboundPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReboundPayload build() => _build();

  _$ReboundPayload _build() {
    final _$result = _$v ??
        _$ReboundPayload._(
          kind: BuiltValueNullFieldError.checkNotNull(
              kind, r'ReboundPayload', 'kind'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
