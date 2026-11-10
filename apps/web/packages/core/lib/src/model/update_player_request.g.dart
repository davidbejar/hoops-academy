// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePlayerRequestClearEnum
    _$updatePlayerRequestClearEnum_preferredJerseyNumber =
    const UpdatePlayerRequestClearEnum._('preferredJerseyNumber');
const UpdatePlayerRequestClearEnum
    _$updatePlayerRequestClearEnum_unknownDefaultOpenApi =
    const UpdatePlayerRequestClearEnum._('unknownDefaultOpenApi');

UpdatePlayerRequestClearEnum _$updatePlayerRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'preferredJerseyNumber':
      return _$updatePlayerRequestClearEnum_preferredJerseyNumber;
    case 'unknownDefaultOpenApi':
      return _$updatePlayerRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updatePlayerRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdatePlayerRequestClearEnum>
    _$updatePlayerRequestClearEnumValues =
    BuiltSet<UpdatePlayerRequestClearEnum>(const <UpdatePlayerRequestClearEnum>[
  _$updatePlayerRequestClearEnum_preferredJerseyNumber,
  _$updatePlayerRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdatePlayerRequestClearEnum>
    _$updatePlayerRequestClearEnumSerializer =
    _$UpdatePlayerRequestClearEnumSerializer();

class _$UpdatePlayerRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdatePlayerRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'preferredJerseyNumber': 'preferredJerseyNumber',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'preferredJerseyNumber': 'preferredJerseyNumber',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdatePlayerRequestClearEnum];
  @override
  final String wireName = 'UpdatePlayerRequestClearEnum';

  @override
  Object serialize(Serializers serializers, UpdatePlayerRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdatePlayerRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdatePlayerRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdatePlayerRequest extends UpdatePlayerRequest {
  @override
  final String? preferredJerseyNumber;
  @override
  final BuiltSet<UpdatePlayerRequestClearEnum>? clear;

  factory _$UpdatePlayerRequest(
          [void Function(UpdatePlayerRequestBuilder)? updates]) =>
      (UpdatePlayerRequestBuilder()..update(updates))._build();

  _$UpdatePlayerRequest._({this.preferredJerseyNumber, this.clear}) : super._();
  @override
  UpdatePlayerRequest rebuild(
          void Function(UpdatePlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePlayerRequestBuilder toBuilder() =>
      UpdatePlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePlayerRequest &&
        preferredJerseyNumber == other.preferredJerseyNumber &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, preferredJerseyNumber.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePlayerRequest')
          ..add('preferredJerseyNumber', preferredJerseyNumber)
          ..add('clear', clear))
        .toString();
  }
}

class UpdatePlayerRequestBuilder
    implements Builder<UpdatePlayerRequest, UpdatePlayerRequestBuilder> {
  _$UpdatePlayerRequest? _$v;

  String? _preferredJerseyNumber;
  String? get preferredJerseyNumber => _$this._preferredJerseyNumber;
  set preferredJerseyNumber(String? preferredJerseyNumber) =>
      _$this._preferredJerseyNumber = preferredJerseyNumber;

  SetBuilder<UpdatePlayerRequestClearEnum>? _clear;
  SetBuilder<UpdatePlayerRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdatePlayerRequestClearEnum>();
  set clear(SetBuilder<UpdatePlayerRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdatePlayerRequestBuilder() {
    UpdatePlayerRequest._defaults(this);
  }

  UpdatePlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _preferredJerseyNumber = $v.preferredJerseyNumber;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePlayerRequest other) {
    _$v = other as _$UpdatePlayerRequest;
  }

  @override
  void update(void Function(UpdatePlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePlayerRequest build() => _build();

  _$UpdatePlayerRequest _build() {
    _$UpdatePlayerRequest _$result;
    try {
      _$result = _$v ??
          _$UpdatePlayerRequest._(
            preferredJerseyNumber: preferredJerseyNumber,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdatePlayerRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
