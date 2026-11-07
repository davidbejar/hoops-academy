// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request_received.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcademyRequestReceivedStatusEnum
    _$academyRequestReceivedStatusEnum_RECEIVED =
    const AcademyRequestReceivedStatusEnum._('RECEIVED');
const AcademyRequestReceivedStatusEnum
    _$academyRequestReceivedStatusEnum_unknownDefaultOpenApi =
    const AcademyRequestReceivedStatusEnum._('unknownDefaultOpenApi');

AcademyRequestReceivedStatusEnum _$academyRequestReceivedStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'RECEIVED':
      return _$academyRequestReceivedStatusEnum_RECEIVED;
    case 'unknownDefaultOpenApi':
      return _$academyRequestReceivedStatusEnum_unknownDefaultOpenApi;
    default:
      return _$academyRequestReceivedStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<AcademyRequestReceivedStatusEnum>
    _$academyRequestReceivedStatusEnumValues = BuiltSet<
        AcademyRequestReceivedStatusEnum>(const <AcademyRequestReceivedStatusEnum>[
  _$academyRequestReceivedStatusEnum_RECEIVED,
  _$academyRequestReceivedStatusEnum_unknownDefaultOpenApi,
]);

Serializer<AcademyRequestReceivedStatusEnum>
    _$academyRequestReceivedStatusEnumSerializer =
    _$AcademyRequestReceivedStatusEnumSerializer();

class _$AcademyRequestReceivedStatusEnumSerializer
    implements PrimitiveSerializer<AcademyRequestReceivedStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'RECEIVED': 'RECEIVED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'RECEIVED': 'RECEIVED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AcademyRequestReceivedStatusEnum];
  @override
  final String wireName = 'AcademyRequestReceivedStatusEnum';

  @override
  Object serialize(
          Serializers serializers, AcademyRequestReceivedStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcademyRequestReceivedStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcademyRequestReceivedStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AcademyRequestReceived extends AcademyRequestReceived {
  @override
  final AcademyRequestReceivedStatusEnum status;

  factory _$AcademyRequestReceived(
          [void Function(AcademyRequestReceivedBuilder)? updates]) =>
      (AcademyRequestReceivedBuilder()..update(updates))._build();

  _$AcademyRequestReceived._({required this.status}) : super._();
  @override
  AcademyRequestReceived rebuild(
          void Function(AcademyRequestReceivedBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcademyRequestReceivedBuilder toBuilder() =>
      AcademyRequestReceivedBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcademyRequestReceived && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcademyRequestReceived')
          ..add('status', status))
        .toString();
  }
}

class AcademyRequestReceivedBuilder
    implements Builder<AcademyRequestReceived, AcademyRequestReceivedBuilder> {
  _$AcademyRequestReceived? _$v;

  AcademyRequestReceivedStatusEnum? _status;
  AcademyRequestReceivedStatusEnum? get status => _$this._status;
  set status(AcademyRequestReceivedStatusEnum? status) =>
      _$this._status = status;

  AcademyRequestReceivedBuilder() {
    AcademyRequestReceived._defaults(this);
  }

  AcademyRequestReceivedBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcademyRequestReceived other) {
    _$v = other as _$AcademyRequestReceived;
  }

  @override
  void update(void Function(AcademyRequestReceivedBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcademyRequestReceived build() => _build();

  _$AcademyRequestReceived _build() {
    final _$result = _$v ??
        _$AcademyRequestReceived._(
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AcademyRequestReceived', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
