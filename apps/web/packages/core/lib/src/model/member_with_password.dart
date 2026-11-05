//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/invitation_status.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/temporary_password_status.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'member_with_password.g.dart';

/// A member and, when this call created or re-issued their login's password, that password.
///
/// Properties:
/// * [personId] 
/// * [userId] - Platform user (login) of the person; null for persons without login (e.g. young players).
/// * [givenName] 
/// * [familyName] 
/// * [displayName] 
/// * [email] 
/// * [phone] 
/// * [birthDate] 
/// * [gender] 
/// * [locale] 
/// * [roles] 
/// * [playerId] - Set when the member holds the PLAYER role.
/// * [active] 
/// * [invitationStatus] 
/// * [temporaryPasswordStatus] 
/// * [createdAt] 
/// * [temporaryPassword] - Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password). 
@BuiltValue()
abstract class MemberWithPassword implements Built<MemberWithPassword, MemberWithPasswordBuilder> {
  @BuiltValueField(wireName: r'personId')
  String get personId;

  /// Platform user (login) of the person; null for persons without login (e.g. young players).
  @BuiltValueField(wireName: r'userId')
  String? get userId;

  @BuiltValueField(wireName: r'givenName')
  String get givenName;

  @BuiltValueField(wireName: r'familyName')
  String get familyName;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'birthDate')
  Date? get birthDate;

  @BuiltValueField(wireName: r'gender')
  Gender? get gender;
  // enum genderEnum {  MALE,  FEMALE,  };

  @BuiltValueField(wireName: r'locale')
  Locale? get locale;
  // enum localeEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'roles')
  BuiltSet<TenantRole> get roles;

  /// Set when the member holds the PLAYER role.
  @BuiltValueField(wireName: r'playerId')
  String? get playerId;

  @BuiltValueField(wireName: r'active')
  bool get active;

  @BuiltValueField(wireName: r'invitationStatus')
  InvitationStatus get invitationStatus;
  // enum invitationStatusEnum {  NONE,  PENDING,  ACCEPTED,  };

  @BuiltValueField(wireName: r'temporaryPasswordStatus')
  TemporaryPasswordStatus get temporaryPasswordStatus;
  // enum temporaryPasswordStatusEnum {  ACTIVE,  EXPIRED,  NONE,  };

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  /// Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password). 
  @BuiltValueField(wireName: r'temporaryPassword')
  String? get temporaryPassword;

  MemberWithPassword._();

  factory MemberWithPassword([void updates(MemberWithPasswordBuilder b)]) = _$MemberWithPassword;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MemberWithPasswordBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MemberWithPassword> get serializer => _$MemberWithPasswordSerializer();
}

class _$MemberWithPasswordSerializer implements PrimitiveSerializer<MemberWithPassword> {
  @override
  final Iterable<Type> types = const [MemberWithPassword, _$MemberWithPassword];

  @override
  final String wireName = r'MemberWithPassword';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MemberWithPassword object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    if (object.userId != null) {
      yield r'userId';
      yield serializers.serialize(
        object.userId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'givenName';
    yield serializers.serialize(
      object.givenName,
      specifiedType: const FullType(String),
    );
    yield r'familyName';
    yield serializers.serialize(
      object.familyName,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.birthDate != null) {
      yield r'birthDate';
      yield serializers.serialize(
        object.birthDate,
        specifiedType: const FullType.nullable(Date),
      );
    }
    if (object.gender != null) {
      yield r'gender';
      yield serializers.serialize(
        object.gender,
        specifiedType: const FullType.nullable(Gender),
      );
    }
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(Locale),
      );
    }
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
    if (object.playerId != null) {
      yield r'playerId';
      yield serializers.serialize(
        object.playerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
    yield r'invitationStatus';
    yield serializers.serialize(
      object.invitationStatus,
      specifiedType: const FullType(InvitationStatus),
    );
    yield r'temporaryPasswordStatus';
    yield serializers.serialize(
      object.temporaryPasswordStatus,
      specifiedType: const FullType(TemporaryPasswordStatus),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
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
    MemberWithPassword object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MemberWithPasswordBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.userId = valueDes;
          break;
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.familyName = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.phone = valueDes;
          break;
        case r'birthDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.birthDate = valueDes;
          break;
        case r'gender':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Gender),
          ) as Gender?;
          if (valueDes == null) continue;
          result.gender = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Locale),
          ) as Locale?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.roles.replace(valueDes);
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.playerId = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'invitationStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InvitationStatus),
          ) as InvitationStatus;
          result.invitationStatus = valueDes;
          break;
        case r'temporaryPasswordStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TemporaryPasswordStatus),
          ) as TemporaryPasswordStatus;
          result.temporaryPasswordStatus = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
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
  MemberWithPassword deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MemberWithPasswordBuilder();
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


