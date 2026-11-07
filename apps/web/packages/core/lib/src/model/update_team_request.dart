//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/gender_policy.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_team_request.g.dart';

/// UpdateTeamRequest
///
/// Properties:
/// * [name]
/// * [alias]
/// * [ageCategoryId]
/// * [genderPolicy]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTeamRequest
    implements Built<UpdateTeamRequest, UpdateTeamRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'alias')
  String? get alias;

  @BuiltValueField(wireName: r'ageCategoryId')
  String? get ageCategoryId;

  @BuiltValueField(wireName: r'genderPolicy')
  GenderPolicy? get genderPolicy;
  // enum genderPolicyEnum {  MALE,  FEMALE,  MIXED,  };

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTeamRequestClearEnum>? get clear;
  // enum clearEnum {  alias,  };

  UpdateTeamRequest._();

  factory UpdateTeamRequest([void updates(UpdateTeamRequestBuilder b)]) =
      _$UpdateTeamRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTeamRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTeamRequest> get serializer =>
      _$UpdateTeamRequestSerializer();
}

class _$UpdateTeamRequestSerializer
    implements PrimitiveSerializer<UpdateTeamRequest> {
  @override
  final Iterable<Type> types = const [UpdateTeamRequest, _$UpdateTeamRequest];

  @override
  final String wireName = r'UpdateTeamRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTeamRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.alias != null) {
      yield r'alias';
      yield serializers.serialize(
        object.alias,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.ageCategoryId != null) {
      yield r'ageCategoryId';
      yield serializers.serialize(
        object.ageCategoryId,
        specifiedType: const FullType(String),
      );
    }
    if (object.genderPolicy != null) {
      yield r'genderPolicy';
      yield serializers.serialize(
        object.genderPolicy,
        specifiedType: const FullType(GenderPolicy),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType:
            const FullType(BuiltSet, [FullType(UpdateTeamRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTeamRequest object, {
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
    required UpdateTeamRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'alias':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.alias = valueDes;
          break;
        case r'ageCategoryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ageCategoryId = valueDes;
          break;
        case r'genderPolicy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(GenderPolicy),
          ) as GenderPolicy?;
          if (valueDes == null) continue;
          result.genderPolicy = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(
                BuiltSet, [FullType(UpdateTeamRequestClearEnum)]),
          ) as BuiltSet<UpdateTeamRequestClearEnum>?;
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
  UpdateTeamRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTeamRequestBuilder();
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

class UpdateTeamRequestClearEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'alias')
  static const UpdateTeamRequestClearEnum alias =
      _$updateTeamRequestClearEnum_alias;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTeamRequestClearEnum unknownDefaultOpenApi =
      _$updateTeamRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTeamRequestClearEnum> get serializer =>
      _$updateTeamRequestClearEnumSerializer;

  const UpdateTeamRequestClearEnum._(String name) : super(name);

  static BuiltSet<UpdateTeamRequestClearEnum> get values =>
      _$updateTeamRequestClearEnumValues;
  static UpdateTeamRequestClearEnum valueOf(String name) =>
      _$updateTeamRequestClearEnumValueOf(name);
}
