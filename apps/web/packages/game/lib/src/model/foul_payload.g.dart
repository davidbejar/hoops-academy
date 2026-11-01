// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foul_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FoulPayloadKindEnum _$foulPayloadKindEnum_PERSONAL =
    const FoulPayloadKindEnum._('PERSONAL');
const FoulPayloadKindEnum _$foulPayloadKindEnum_TECHNICAL =
    const FoulPayloadKindEnum._('TECHNICAL');
const FoulPayloadKindEnum _$foulPayloadKindEnum_UNSPORTSMANLIKE =
    const FoulPayloadKindEnum._('UNSPORTSMANLIKE');
const FoulPayloadKindEnum _$foulPayloadKindEnum_unknownDefaultOpenApi =
    const FoulPayloadKindEnum._('unknownDefaultOpenApi');

FoulPayloadKindEnum _$foulPayloadKindEnumValueOf(String name) {
  switch (name) {
    case 'PERSONAL':
      return _$foulPayloadKindEnum_PERSONAL;
    case 'TECHNICAL':
      return _$foulPayloadKindEnum_TECHNICAL;
    case 'UNSPORTSMANLIKE':
      return _$foulPayloadKindEnum_UNSPORTSMANLIKE;
    case 'unknownDefaultOpenApi':
      return _$foulPayloadKindEnum_unknownDefaultOpenApi;
    default:
      return _$foulPayloadKindEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<FoulPayloadKindEnum> _$foulPayloadKindEnumValues =
    BuiltSet<FoulPayloadKindEnum>(const <FoulPayloadKindEnum>[
  _$foulPayloadKindEnum_PERSONAL,
  _$foulPayloadKindEnum_TECHNICAL,
  _$foulPayloadKindEnum_UNSPORTSMANLIKE,
  _$foulPayloadKindEnum_unknownDefaultOpenApi,
]);

Serializer<FoulPayloadKindEnum> _$foulPayloadKindEnumSerializer =
    _$FoulPayloadKindEnumSerializer();

class _$FoulPayloadKindEnumSerializer
    implements PrimitiveSerializer<FoulPayloadKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PERSONAL': 'PERSONAL',
    'TECHNICAL': 'TECHNICAL',
    'UNSPORTSMANLIKE': 'UNSPORTSMANLIKE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PERSONAL': 'PERSONAL',
    'TECHNICAL': 'TECHNICAL',
    'UNSPORTSMANLIKE': 'UNSPORTSMANLIKE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[FoulPayloadKindEnum];
  @override
  final String wireName = 'FoulPayloadKindEnum';

  @override
  Object serialize(Serializers serializers, FoulPayloadKindEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FoulPayloadKindEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FoulPayloadKindEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$FoulPayload extends FoulPayload {
  @override
  final FoulPayloadKindEnum kind;

  factory _$FoulPayload([void Function(FoulPayloadBuilder)? updates]) =>
      (FoulPayloadBuilder()..update(updates))._build();

  _$FoulPayload._({required this.kind}) : super._();
  @override
  FoulPayload rebuild(void Function(FoulPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FoulPayloadBuilder toBuilder() => FoulPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FoulPayload && kind == other.kind;
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
    return (newBuiltValueToStringHelper(r'FoulPayload')..add('kind', kind))
        .toString();
  }
}

class FoulPayloadBuilder implements Builder<FoulPayload, FoulPayloadBuilder> {
  _$FoulPayload? _$v;

  FoulPayloadKindEnum? _kind;
  FoulPayloadKindEnum? get kind => _$this._kind;
  set kind(FoulPayloadKindEnum? kind) => _$this._kind = kind;

  FoulPayloadBuilder() {
    FoulPayload._defaults(this);
  }

  FoulPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FoulPayload other) {
    _$v = other as _$FoulPayload;
  }

  @override
  void update(void Function(FoulPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FoulPayload build() => _build();

  _$FoulPayload _build() {
    final _$result = _$v ??
        _$FoulPayload._(
          kind: BuiltValueNullFieldError.checkNotNull(
              kind, r'FoulPayload', 'kind'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
