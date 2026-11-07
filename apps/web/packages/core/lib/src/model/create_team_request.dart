//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/gender_policy.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_team_request.g.dart';

/// CreateTeamRequest
///
/// Properties:
/// * [seasonId]
/// * [name]
/// * [alias]
/// * [ageCategoryId]
/// * [genderPolicy]
@BuiltValue()
abstract class CreateTeamRequest
    implements Built<CreateTeamRequest, CreateTeamRequestBuilder> {
  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'alias')
  String? get alias;

  @BuiltValueField(wireName: r'ageCategoryId')
  String get ageCategoryId;

  @BuiltValueField(wireName: r'genderPolicy')
  GenderPolicy get genderPolicy;
  // enum genderPolicyEnum {  MALE,  FEMALE,  MIXED,  };

  CreateTeamRequest._();

  factory CreateTeamRequest([void updates(CreateTeamRequestBuilder b)]) =
      _$CreateTeamRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTeamRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTeamRequest> get serializer =>
      _$CreateTeamRequestSerializer();
}

class _$CreateTeamRequestSerializer
    implements PrimitiveSerializer<CreateTeamRequest> {
  @override
  final Iterable<Type> types = const [CreateTeamRequest, _$CreateTeamRequest];

  @override
  final String wireName = r'CreateTeamRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTeamRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.alias != null) {
      yield r'alias';
      yield serializers.serialize(
        object.alias,
        specifiedType: const FullType(String),
      );
    }
    yield r'ageCategoryId';
    yield serializers.serialize(
      object.ageCategoryId,
      specifiedType: const FullType(String),
    );
    yield r'genderPolicy';
    yield serializers.serialize(
      object.genderPolicy,
      specifiedType: const FullType(GenderPolicy),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTeamRequest object, {
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
    required CreateTeamRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
            specifiedType: const FullType(String),
          ) as String;
          result.ageCategoryId = valueDes;
          break;
        case r'genderPolicy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GenderPolicy),
          ) as GenderPolicy;
          result.genderPolicy = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTeamRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTeamRequestBuilder();
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
