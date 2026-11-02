//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant.g.dart';

/// Tenant
///
/// Properties:
/// * [id]
/// * [slug]
/// * [name]
/// * [status]
/// * [timezone] - IANA time zone id.
/// * [defaultLocale]
/// * [createdAt]
/// * [suspendedAt]
/// * [withdrawnAt]
/// * [retainUntil] - For WITHDRAWN tenants, the date until which data is retained.
@BuiltValue(instantiable: false)
abstract class Tenant  {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'status')
  TenantStatus get status;
  // enum statusEnum {  ACTIVE,  SUSPENDED,  WITHDRAWN,  };

  /// IANA time zone id.
  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'suspendedAt')
  DateTime? get suspendedAt;

  @BuiltValueField(wireName: r'withdrawnAt')
  DateTime? get withdrawnAt;

  /// For WITHDRAWN tenants, the date until which data is retained.
  @BuiltValueField(wireName: r'retainUntil')
  Date? get retainUntil;

  @BuiltValueSerializer(custom: true)
  static Serializer<Tenant> get serializer => _$TenantSerializer();
}

class _$TenantSerializer implements PrimitiveSerializer<Tenant> {
  @override
  final Iterable<Type> types = const [Tenant];

  @override
  final String wireName = r'Tenant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Tenant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TenantStatus),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'defaultLocale';
    yield serializers.serialize(
      object.defaultLocale,
      specifiedType: const FullType(Locale),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.suspendedAt != null) {
      yield r'suspendedAt';
      yield serializers.serialize(
        object.suspendedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.withdrawnAt != null) {
      yield r'withdrawnAt';
      yield serializers.serialize(
        object.withdrawnAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.retainUntil != null) {
      yield r'retainUntil';
      yield serializers.serialize(
        object.retainUntil,
        specifiedType: const FullType.nullable(Date),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Tenant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  Tenant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($Tenant)) as $Tenant;
  }
}


/// a concrete implementation of [Tenant], since [Tenant] is not instantiable
@BuiltValue(instantiable: true)
abstract class $Tenant implements Tenant, Built<$Tenant, $TenantBuilder> {
  $Tenant._();

  factory $Tenant([void Function($TenantBuilder)? updates]) = _$$Tenant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($TenantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$Tenant> get serializer => _$$TenantSerializer();
}

class _$$TenantSerializer implements PrimitiveSerializer<$Tenant> {
  @override
  final Iterable<Type> types = const [$Tenant, _$$Tenant];

  @override
  final String wireName = r'$Tenant';

  @override
  Object serialize(
    Serializers serializers,
    $Tenant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(Tenant))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantStatus),
          ) as TenantStatus;
          result.status = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'defaultLocale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Locale),
          ) as Locale;
          result.defaultLocale = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'suspendedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.suspendedAt = valueDes;
          break;
        case r'withdrawnAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.withdrawnAt = valueDes;
          break;
        case r'retainUntil':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.retainUntil = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $Tenant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $TenantBuilder();
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
