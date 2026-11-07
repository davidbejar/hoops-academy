//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_logo.g.dart';

/// TenantLogo
///
/// Properties:
/// * [contentType]
/// * [sizeBytes]
/// * [etag]
/// * [updatedAt]
@BuiltValue()
abstract class TenantLogo implements Built<TenantLogo, TenantLogoBuilder> {
  @BuiltValueField(wireName: r'contentType')
  TenantLogoContentTypeEnum get contentType;
  // enum contentTypeEnum {  image/png,  image/jpeg,  image/webp,  };

  @BuiltValueField(wireName: r'sizeBytes')
  int get sizeBytes;

  @BuiltValueField(wireName: r'etag')
  String get etag;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  TenantLogo._();

  factory TenantLogo([void updates(TenantLogoBuilder b)]) = _$TenantLogo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantLogoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantLogo> get serializer => _$TenantLogoSerializer();
}

class _$TenantLogoSerializer implements PrimitiveSerializer<TenantLogo> {
  @override
  final Iterable<Type> types = const [TenantLogo, _$TenantLogo];

  @override
  final String wireName = r'TenantLogo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantLogo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'contentType';
    yield serializers.serialize(
      object.contentType,
      specifiedType: const FullType(TenantLogoContentTypeEnum),
    );
    yield r'sizeBytes';
    yield serializers.serialize(
      object.sizeBytes,
      specifiedType: const FullType(int),
    );
    yield r'etag';
    yield serializers.serialize(
      object.etag,
      specifiedType: const FullType(String),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantLogo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantLogoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'contentType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantLogoContentTypeEnum),
          ) as TenantLogoContentTypeEnum;
          result.contentType = valueDes;
          break;
        case r'sizeBytes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sizeBytes = valueDes;
          break;
        case r'etag':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etag = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantLogo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantLogoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class TenantLogoContentTypeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'image/png')
  static const TenantLogoContentTypeEnum imageSlashPng =
      _$tenantLogoContentTypeEnum_imageSlashPng;
  @BuiltValueEnumConst(wireName: r'image/jpeg')
  static const TenantLogoContentTypeEnum imageSlashJpeg =
      _$tenantLogoContentTypeEnum_imageSlashJpeg;
  @BuiltValueEnumConst(wireName: r'image/webp')
  static const TenantLogoContentTypeEnum imageSlashWebp =
      _$tenantLogoContentTypeEnum_imageSlashWebp;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TenantLogoContentTypeEnum unknownDefaultOpenApi =
      _$tenantLogoContentTypeEnum_unknownDefaultOpenApi;

  static Serializer<TenantLogoContentTypeEnum> get serializer =>
      _$tenantLogoContentTypeEnumSerializer;

  const TenantLogoContentTypeEnum._(String name) : super(name);

  static BuiltSet<TenantLogoContentTypeEnum> get values =>
      _$tenantLogoContentTypeEnumValues;
  static TenantLogoContentTypeEnum valueOf(String name) =>
      _$tenantLogoContentTypeEnumValueOf(name);
}
