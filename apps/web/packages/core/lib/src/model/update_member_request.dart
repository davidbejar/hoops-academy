//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_member_request.g.dart';

/// UpdateMemberRequest
///
/// Properties:
/// * [givenName] 
/// * [familyName] 
/// * [email] 
/// * [phone] 
/// * [birthDate] 
/// * [gender] 
/// * [locale] 
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateMemberRequest implements Built<UpdateMemberRequest, UpdateMemberRequestBuilder> {
  @BuiltValueField(wireName: r'givenName')
  String? get givenName;

  @BuiltValueField(wireName: r'familyName')
  String? get familyName;

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

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateMemberRequestClearEnum>? get clear;
  // enum clearEnum {  email,  phone,  birthDate,  gender,  };

  UpdateMemberRequest._();

  factory UpdateMemberRequest([void updates(UpdateMemberRequestBuilder b)]) = _$UpdateMemberRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateMemberRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateMemberRequest> get serializer => _$UpdateMemberRequestSerializer();
}

class _$UpdateMemberRequestSerializer implements PrimitiveSerializer<UpdateMemberRequest> {
  @override
  final Iterable<Type> types = const [UpdateMemberRequest, _$UpdateMemberRequest];

  @override
  final String wireName = r'UpdateMemberRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateMemberRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.givenName != null) {
      yield r'givenName';
      yield serializers.serialize(
        object.givenName,
        specifiedType: const FullType(String),
      );
    }
    if (object.familyName != null) {
      yield r'familyName';
      yield serializers.serialize(
        object.familyName,
        specifiedType: const FullType(String),
      );
    }
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
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateMemberRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateMemberRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateMemberRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.familyName = valueDes;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateMemberRequestClearEnum)]),
          ) as BuiltSet<UpdateMemberRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateMemberRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateMemberRequestBuilder();
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


class UpdateMemberRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'email')
  static const UpdateMemberRequestClearEnum email = _$updateMemberRequestClearEnum_email;
  @BuiltValueEnumConst(wireName: r'phone')
  static const UpdateMemberRequestClearEnum phone = _$updateMemberRequestClearEnum_phone;
  @BuiltValueEnumConst(wireName: r'birthDate')
  static const UpdateMemberRequestClearEnum birthDate = _$updateMemberRequestClearEnum_birthDate;
  @BuiltValueEnumConst(wireName: r'gender')
  static const UpdateMemberRequestClearEnum gender = _$updateMemberRequestClearEnum_gender;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateMemberRequestClearEnum unknownDefaultOpenApi = _$updateMemberRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateMemberRequestClearEnum> get serializer => _$updateMemberRequestClearEnumSerializer;

  const UpdateMemberRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateMemberRequestClearEnum> get values => _$updateMemberRequestClearEnumValues;
  static UpdateMemberRequestClearEnum valueOf(String name) => _$updateMemberRequestClearEnumValueOf(name);
}

