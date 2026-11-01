// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_logo.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TenantLogoContentTypeEnum _$tenantLogoContentTypeEnum_imageSlashPng =
    const TenantLogoContentTypeEnum._('imageSlashPng');
const TenantLogoContentTypeEnum _$tenantLogoContentTypeEnum_imageSlashJpeg =
    const TenantLogoContentTypeEnum._('imageSlashJpeg');
const TenantLogoContentTypeEnum _$tenantLogoContentTypeEnum_imageSlashWebp =
    const TenantLogoContentTypeEnum._('imageSlashWebp');
const TenantLogoContentTypeEnum
    _$tenantLogoContentTypeEnum_unknownDefaultOpenApi =
    const TenantLogoContentTypeEnum._('unknownDefaultOpenApi');

TenantLogoContentTypeEnum _$tenantLogoContentTypeEnumValueOf(String name) {
  switch (name) {
    case 'imageSlashPng':
      return _$tenantLogoContentTypeEnum_imageSlashPng;
    case 'imageSlashJpeg':
      return _$tenantLogoContentTypeEnum_imageSlashJpeg;
    case 'imageSlashWebp':
      return _$tenantLogoContentTypeEnum_imageSlashWebp;
    case 'unknownDefaultOpenApi':
      return _$tenantLogoContentTypeEnum_unknownDefaultOpenApi;
    default:
      return _$tenantLogoContentTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<TenantLogoContentTypeEnum> _$tenantLogoContentTypeEnumValues =
    BuiltSet<TenantLogoContentTypeEnum>(const <TenantLogoContentTypeEnum>[
  _$tenantLogoContentTypeEnum_imageSlashPng,
  _$tenantLogoContentTypeEnum_imageSlashJpeg,
  _$tenantLogoContentTypeEnum_imageSlashWebp,
  _$tenantLogoContentTypeEnum_unknownDefaultOpenApi,
]);

Serializer<TenantLogoContentTypeEnum> _$tenantLogoContentTypeEnumSerializer =
    _$TenantLogoContentTypeEnumSerializer();

class _$TenantLogoContentTypeEnumSerializer
    implements PrimitiveSerializer<TenantLogoContentTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'imageSlashPng': 'image/png',
    'imageSlashJpeg': 'image/jpeg',
    'imageSlashWebp': 'image/webp',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'image/png': 'imageSlashPng',
    'image/jpeg': 'imageSlashJpeg',
    'image/webp': 'imageSlashWebp',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TenantLogoContentTypeEnum];
  @override
  final String wireName = 'TenantLogoContentTypeEnum';

  @override
  Object serialize(Serializers serializers, TenantLogoContentTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TenantLogoContentTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TenantLogoContentTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TenantLogo extends TenantLogo {
  @override
  final TenantLogoContentTypeEnum contentType;
  @override
  final int sizeBytes;
  @override
  final String etag;
  @override
  final DateTime updatedAt;

  factory _$TenantLogo([void Function(TenantLogoBuilder)? updates]) =>
      (TenantLogoBuilder()..update(updates))._build();

  _$TenantLogo._(
      {required this.contentType,
      required this.sizeBytes,
      required this.etag,
      required this.updatedAt})
      : super._();
  @override
  TenantLogo rebuild(void Function(TenantLogoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantLogoBuilder toBuilder() => TenantLogoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantLogo &&
        contentType == other.contentType &&
        sizeBytes == other.sizeBytes &&
        etag == other.etag &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contentType.hashCode);
    _$hash = $jc(_$hash, sizeBytes.hashCode);
    _$hash = $jc(_$hash, etag.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantLogo')
          ..add('contentType', contentType)
          ..add('sizeBytes', sizeBytes)
          ..add('etag', etag)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class TenantLogoBuilder implements Builder<TenantLogo, TenantLogoBuilder> {
  _$TenantLogo? _$v;

  TenantLogoContentTypeEnum? _contentType;
  TenantLogoContentTypeEnum? get contentType => _$this._contentType;
  set contentType(TenantLogoContentTypeEnum? contentType) =>
      _$this._contentType = contentType;

  int? _sizeBytes;
  int? get sizeBytes => _$this._sizeBytes;
  set sizeBytes(int? sizeBytes) => _$this._sizeBytes = sizeBytes;

  String? _etag;
  String? get etag => _$this._etag;
  set etag(String? etag) => _$this._etag = etag;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  TenantLogoBuilder() {
    TenantLogo._defaults(this);
  }

  TenantLogoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contentType = $v.contentType;
      _sizeBytes = $v.sizeBytes;
      _etag = $v.etag;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantLogo other) {
    _$v = other as _$TenantLogo;
  }

  @override
  void update(void Function(TenantLogoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantLogo build() => _build();

  _$TenantLogo _build() {
    final _$result = _$v ??
        _$TenantLogo._(
          contentType: BuiltValueNullFieldError.checkNotNull(
              contentType, r'TenantLogo', 'contentType'),
          sizeBytes: BuiltValueNullFieldError.checkNotNull(
              sizeBytes, r'TenantLogo', 'sizeBytes'),
          etag: BuiltValueNullFieldError.checkNotNull(
              etag, r'TenantLogo', 'etag'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'TenantLogo', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
