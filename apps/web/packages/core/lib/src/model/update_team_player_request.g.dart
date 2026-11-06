// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_team_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTeamPlayerRequestClearEnum
    _$updateTeamPlayerRequestClearEnum_jerseyNumber =
    const UpdateTeamPlayerRequestClearEnum._('jerseyNumber');
const UpdateTeamPlayerRequestClearEnum
    _$updateTeamPlayerRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTeamPlayerRequestClearEnum._('unknownDefaultOpenApi');

UpdateTeamPlayerRequestClearEnum _$updateTeamPlayerRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'jerseyNumber':
      return _$updateTeamPlayerRequestClearEnum_jerseyNumber;
    case 'unknownDefaultOpenApi':
      return _$updateTeamPlayerRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTeamPlayerRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTeamPlayerRequestClearEnum>
    _$updateTeamPlayerRequestClearEnumValues = BuiltSet<
        UpdateTeamPlayerRequestClearEnum>(const <UpdateTeamPlayerRequestClearEnum>[
  _$updateTeamPlayerRequestClearEnum_jerseyNumber,
  _$updateTeamPlayerRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTeamPlayerRequestClearEnum>
    _$updateTeamPlayerRequestClearEnumSerializer =
    _$UpdateTeamPlayerRequestClearEnumSerializer();

class _$UpdateTeamPlayerRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTeamPlayerRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'jerseyNumber': 'jerseyNumber',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'jerseyNumber': 'jerseyNumber',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTeamPlayerRequestClearEnum];
  @override
  final String wireName = 'UpdateTeamPlayerRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateTeamPlayerRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTeamPlayerRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTeamPlayerRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTeamPlayerRequest extends UpdateTeamPlayerRequest {
  @override
  final String? jerseyNumber;
  @override
  final BuiltSet<UpdateTeamPlayerRequestClearEnum>? clear;

  factory _$UpdateTeamPlayerRequest(
          [void Function(UpdateTeamPlayerRequestBuilder)? updates]) =>
      (UpdateTeamPlayerRequestBuilder()..update(updates))._build();

  _$UpdateTeamPlayerRequest._({this.jerseyNumber, this.clear}) : super._();
  @override
  UpdateTeamPlayerRequest rebuild(
          void Function(UpdateTeamPlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTeamPlayerRequestBuilder toBuilder() =>
      UpdateTeamPlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTeamPlayerRequest &&
        jerseyNumber == other.jerseyNumber &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTeamPlayerRequest')
          ..add('jerseyNumber', jerseyNumber)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTeamPlayerRequestBuilder
    implements
        Builder<UpdateTeamPlayerRequest, UpdateTeamPlayerRequestBuilder> {
  _$UpdateTeamPlayerRequest? _$v;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  SetBuilder<UpdateTeamPlayerRequestClearEnum>? _clear;
  SetBuilder<UpdateTeamPlayerRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTeamPlayerRequestClearEnum>();
  set clear(SetBuilder<UpdateTeamPlayerRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTeamPlayerRequestBuilder() {
    UpdateTeamPlayerRequest._defaults(this);
  }

  UpdateTeamPlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jerseyNumber = $v.jerseyNumber;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTeamPlayerRequest other) {
    _$v = other as _$UpdateTeamPlayerRequest;
  }

  @override
  void update(void Function(UpdateTeamPlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTeamPlayerRequest build() => _build();

  _$UpdateTeamPlayerRequest _build() {
    _$UpdateTeamPlayerRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTeamPlayerRequest._(
            jerseyNumber: jerseyNumber,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateTeamPlayerRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
