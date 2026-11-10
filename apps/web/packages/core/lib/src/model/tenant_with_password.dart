//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_with_password.g.dart';

/// The onboarded tenant and the temporary password of the first administrator's new login.
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
/// * [temporaryPassword] - Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password). 
@BuiltValue()
abstract class TenantWithPassword implements Built<TenantWithPassword, TenantWithPasswordBuilder> {
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

  /// Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password). 
  @BuiltValueField(wireName: r'temporaryPassword')
  String? get temporaryPassword;

  TenantWithPassword._();

  factory TenantWithPassword([void updates(TenantWithPasswordBuilder b)]) = _$TenantWithPassword;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantWithPasswordBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantWithPassword> get serializer => _$TenantWithPasswordSerializer();
}

class _$TenantWithPasswordSerializer implements PrimitiveSerializer<TenantWithPassword> {
  @override
  final Iterable<Type> types = const [TenantWithPassword, _$TenantWithPassword];

  @override
  final String wireName = r'TenantWithPassword';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantWithPassword object, {
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
    if (object.temporaryPassword != null) {
      yield r'temporaryPassword';
      yield serializers.serialize(
        object.temporaryPassword,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantWithPassword object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantWithPasswordBuilder result,
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
        case r'temporaryPassword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.temporaryPassword = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantWithPassword deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantWithPasswordBuilder();
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


