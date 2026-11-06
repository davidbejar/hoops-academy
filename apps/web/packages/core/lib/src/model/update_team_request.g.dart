// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_team_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTeamRequestClearEnum _$updateTeamRequestClearEnum_alias =
    const UpdateTeamRequestClearEnum._('alias');
const UpdateTeamRequestClearEnum
    _$updateTeamRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTeamRequestClearEnum._('unknownDefaultOpenApi');

UpdateTeamRequestClearEnum _$updateTeamRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'alias':
      return _$updateTeamRequestClearEnum_alias;
    case 'unknownDefaultOpenApi':
      return _$updateTeamRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTeamRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTeamRequestClearEnum> _$updateTeamRequestClearEnumValues =
    BuiltSet<UpdateTeamRequestClearEnum>(const <UpdateTeamRequestClearEnum>[
  _$updateTeamRequestClearEnum_alias,
  _$updateTeamRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTeamRequestClearEnum> _$updateTeamRequestClearEnumSerializer =
    _$UpdateTeamRequestClearEnumSerializer();

class _$UpdateTeamRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTeamRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'alias': 'alias',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'alias': 'alias',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTeamRequestClearEnum];
  @override
  final String wireName = 'UpdateTeamRequestClearEnum';

  @override
  Object serialize(Serializers serializers, UpdateTeamRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTeamRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTeamRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTeamRequest extends UpdateTeamRequest {
  @override
  final String? name;
  @override
  final String? alias;
  @override
  final String? ageCategoryId;
  @override
  final GenderPolicy? genderPolicy;
  @override
  final BuiltSet<UpdateTeamRequestClearEnum>? clear;

  factory _$UpdateTeamRequest(
          [void Function(UpdateTeamRequestBuilder)? updates]) =>
      (UpdateTeamRequestBuilder()..update(updates))._build();

  _$UpdateTeamRequest._(
      {this.name,
      this.alias,
      this.ageCategoryId,
      this.genderPolicy,
      this.clear})
      : super._();
  @override
  UpdateTeamRequest rebuild(void Function(UpdateTeamRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTeamRequestBuilder toBuilder() =>
      UpdateTeamRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTeamRequest &&
        name == other.name &&
        alias == other.alias &&
        ageCategoryId == other.ageCategoryId &&
        genderPolicy == other.genderPolicy &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, alias.hashCode);
    _$hash = $jc(_$hash, ageCategoryId.hashCode);
    _$hash = $jc(_$hash, genderPolicy.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTeamRequest')
          ..add('name', name)
          ..add('alias', alias)
          ..add('ageCategoryId', ageCategoryId)
          ..add('genderPolicy', genderPolicy)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTeamRequestBuilder
    implements Builder<UpdateTeamRequest, UpdateTeamRequestBuilder> {
  _$UpdateTeamRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _alias;
  String? get alias => _$this._alias;
  set alias(String? alias) => _$this._alias = alias;

  String? _ageCategoryId;
  String? get ageCategoryId => _$this._ageCategoryId;
  set ageCategoryId(String? ageCategoryId) =>
      _$this._ageCategoryId = ageCategoryId;

  GenderPolicy? _genderPolicy;
  GenderPolicy? get genderPolicy => _$this._genderPolicy;
  set genderPolicy(GenderPolicy? genderPolicy) =>
      _$this._genderPolicy = genderPolicy;

  SetBuilder<UpdateTeamRequestClearEnum>? _clear;
  SetBuilder<UpdateTeamRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTeamRequestClearEnum>();
  set clear(SetBuilder<UpdateTeamRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTeamRequestBuilder() {
    UpdateTeamRequest._defaults(this);
  }

  UpdateTeamRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _alias = $v.alias;
      _ageCategoryId = $v.ageCategoryId;
      _genderPolicy = $v.genderPolicy;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTeamRequest other) {
    _$v = other as _$UpdateTeamRequest;
  }

  @override
  void update(void Function(UpdateTeamRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTeamRequest build() => _build();

  _$UpdateTeamRequest _build() {
    _$UpdateTeamRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTeamRequest._(
            name: name,
            alias: alias,
            ageCategoryId: ageCategoryId,
            genderPolicy: genderPolicy,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateTeamRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
