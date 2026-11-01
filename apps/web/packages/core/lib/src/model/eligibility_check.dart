//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/eligibility_result.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/age_category.dart';
import 'package:hoops_core_api/src/model/eligibility_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_check.g.dart';

/// EligibilityCheck
///
/// Properties:
/// * [playerId] 
/// * [teamId] 
/// * [asOf] 
/// * [result] 
/// * [playUpLevels] - Set when result = PLAY_UP.
/// * [reasons] - Non-empty iff result = INELIGIBLE.
/// * [age] - Age computed with the tenant's age rule (null when the birth date is missing).
/// * [naturalCategory] 
@BuiltValue()
abstract class EligibilityCheck implements Built<EligibilityCheck, EligibilityCheckBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'asOf')
  Date get asOf;

  @BuiltValueField(wireName: r'result')
  EligibilityResult get result;
  // enum resultEnum {  ELIGIBLE,  PLAY_UP,  INELIGIBLE,  };

  /// Set when result = PLAY_UP.
  @BuiltValueField(wireName: r'playUpLevels')
  int? get playUpLevels;

  /// Non-empty iff result = INELIGIBLE.
  @BuiltValueField(wireName: r'reasons')
  BuiltList<EligibilityReason> get reasons;

  /// Age computed with the tenant's age rule (null when the birth date is missing).
  @BuiltValueField(wireName: r'age')
  int? get age;

  @BuiltValueField(wireName: r'naturalCategory')
  AgeCategory? get naturalCategory;

  EligibilityCheck._();

  factory EligibilityCheck([void updates(EligibilityCheckBuilder b)]) = _$EligibilityCheck;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EligibilityCheckBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EligibilityCheck> get serializer => _$EligibilityCheckSerializer();
}

class _$EligibilityCheckSerializer implements PrimitiveSerializer<EligibilityCheck> {
  @override
  final Iterable<Type> types = const [EligibilityCheck, _$EligibilityCheck];

  @override
  final String wireName = r'EligibilityCheck';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EligibilityCheck object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'asOf';
    yield serializers.serialize(
      object.asOf,
      specifiedType: const FullType(Date),
    );
    yield r'result';
    yield serializers.serialize(
      object.result,
      specifiedType: const FullType(EligibilityResult),
    );
    if (object.playUpLevels != null) {
      yield r'playUpLevels';
      yield serializers.serialize(
        object.playUpLevels,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'reasons';
    yield serializers.serialize(
      object.reasons,
      specifiedType: const FullType(BuiltList, [FullType(EligibilityReason)]),
    );
    if (object.age != null) {
      yield r'age';
      yield serializers.serialize(
        object.age,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.naturalCategory != null) {
      yield r'naturalCategory';
      yield serializers.serialize(
        object.naturalCategory,
        specifiedType: const FullType.nullable(AgeCategory),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EligibilityCheck object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EligibilityCheckBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'asOf':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.asOf = valueDes;
          break;
        case r'result':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EligibilityResult),
          ) as EligibilityResult;
          result.result = valueDes;
          break;
        case r'playUpLevels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.playUpLevels = valueDes;
          break;
        case r'reasons':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(EligibilityReason)]),
          ) as BuiltList<EligibilityReason>;
          result.reasons.replace(valueDes);
          break;
        case r'age':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.age = valueDes;
          break;
        case r'naturalCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AgeCategory),
          ) as AgeCategory?;
          if (valueDes == null) continue;
          result.naturalCategory.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EligibilityCheck deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EligibilityCheckBuilder();
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


