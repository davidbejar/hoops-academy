// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tenant_profile_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTenantProfileRequestClearEnum
    _$updateTenantProfileRequestClearEnum_contactEmail =
    const UpdateTenantProfileRequestClearEnum._('contactEmail');
const UpdateTenantProfileRequestClearEnum
    _$updateTenantProfileRequestClearEnum_websiteUrl =
    const UpdateTenantProfileRequestClearEnum._('websiteUrl');
const UpdateTenantProfileRequestClearEnum
    _$updateTenantProfileRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTenantProfileRequestClearEnum._('unknownDefaultOpenApi');

UpdateTenantProfileRequestClearEnum
    _$updateTenantProfileRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'contactEmail':
      return _$updateTenantProfileRequestClearEnum_contactEmail;
    case 'websiteUrl':
      return _$updateTenantProfileRequestClearEnum_websiteUrl;
    case 'unknownDefaultOpenApi':
      return _$updateTenantProfileRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTenantProfileRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTenantProfileRequestClearEnum>
    _$updateTenantProfileRequestClearEnumValues = BuiltSet<
        UpdateTenantProfileRequestClearEnum>(const <UpdateTenantProfileRequestClearEnum>[
  _$updateTenantProfileRequestClearEnum_contactEmail,
  _$updateTenantProfileRequestClearEnum_websiteUrl,
  _$updateTenantProfileRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTenantProfileRequestClearEnum>
    _$updateTenantProfileRequestClearEnumSerializer =
    _$UpdateTenantProfileRequestClearEnumSerializer();

class _$UpdateTenantProfileRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTenantProfileRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'contactEmail': 'contactEmail',
    'websiteUrl': 'websiteUrl',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'contactEmail': 'contactEmail',
    'websiteUrl': 'websiteUrl',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdateTenantProfileRequestClearEnum
  ];
  @override
  final String wireName = 'UpdateTenantProfileRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateTenantProfileRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTenantProfileRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTenantProfileRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTenantProfileRequest extends UpdateTenantProfileRequest {
  @override
  final String? name;
  @override
  final String? timezone;
  @override
  final Locale? defaultLocale;
  @override
  final String? contactEmail;
  @override
  final String? websiteUrl;
  @override
  final BuiltSet<UpdateTenantProfileRequestClearEnum>? clear;

  factory _$UpdateTenantProfileRequest(
          [void Function(UpdateTenantProfileRequestBuilder)? updates]) =>
      (UpdateTenantProfileRequestBuilder()..update(updates))._build();

  _$UpdateTenantProfileRequest._(
      {this.name,
      this.timezone,
      this.defaultLocale,
      this.contactEmail,
      this.websiteUrl,
      this.clear})
      : super._();
  @override
  UpdateTenantProfileRequest rebuild(
          void Function(UpdateTenantProfileRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTenantProfileRequestBuilder toBuilder() =>
      UpdateTenantProfileRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTenantProfileRequest &&
        name == other.name &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        contactEmail == other.contactEmail &&
        websiteUrl == other.websiteUrl &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, contactEmail.hashCode);
    _$hash = $jc(_$hash, websiteUrl.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTenantProfileRequest')
          ..add('name', name)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('contactEmail', contactEmail)
          ..add('websiteUrl', websiteUrl)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTenantProfileRequestBuilder
    implements
        Builder<UpdateTenantProfileRequest, UpdateTenantProfileRequestBuilder> {
  _$UpdateTenantProfileRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  Locale? _defaultLocale;
  Locale? get defaultLocale => _$this._defaultLocale;
  set defaultLocale(Locale? defaultLocale) =>
      _$this._defaultLocale = defaultLocale;

  String? _contactEmail;
  String? get contactEmail => _$this._contactEmail;
  set contactEmail(String? contactEmail) => _$this._contactEmail = contactEmail;

  String? _websiteUrl;
  String? get websiteUrl => _$this._websiteUrl;
  set websiteUrl(String? websiteUrl) => _$this._websiteUrl = websiteUrl;

  SetBuilder<UpdateTenantProfileRequestClearEnum>? _clear;
  SetBuilder<UpdateTenantProfileRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTenantProfileRequestClearEnum>();
  set clear(SetBuilder<UpdateTenantProfileRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTenantProfileRequestBuilder() {
    UpdateTenantProfileRequest._defaults(this);
  }

  UpdateTenantProfileRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _contactEmail = $v.contactEmail;
      _websiteUrl = $v.websiteUrl;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTenantProfileRequest other) {
    _$v = other as _$UpdateTenantProfileRequest;
  }

  @override
  void update(void Function(UpdateTenantProfileRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTenantProfileRequest build() => _build();

  _$UpdateTenantProfileRequest _build() {
    _$UpdateTenantProfileRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTenantProfileRequest._(
            name: name,
            timezone: timezone,
            defaultLocale: defaultLocale,
            contactEmail: contactEmail,
            websiteUrl: websiteUrl,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateTenantProfileRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
