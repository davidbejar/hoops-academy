//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/injury_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/injury_severity.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_injury_request.g.dart';

/// UpdateInjuryRequest
///
/// Properties:
/// * [occurredOn]
/// * [bodyPart]
/// * [severity]
/// * [description]
/// * [expectedReturnOn]
/// * [actualReturnOn]
/// * [status]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateInjuryRequest implements Built<UpdateInjuryRequest, UpdateInjuryRequestBuilder> {
  @BuiltValueField(wireName: r'occurredOn')
  Date? get occurredOn;

  @BuiltValueField(wireName: r'bodyPart')
  String? get bodyPart;

  @BuiltValueField(wireName: r'severity')
  InjurySeverity? get severity;
  // enum severityEnum {  MINOR,  MODERATE,  SEVERE,  };

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'expectedReturnOn')
  Date? get expectedReturnOn;

  @BuiltValueField(wireName: r'actualReturnOn')
  Date? get actualReturnOn;

  @BuiltValueField(wireName: r'status')
  InjuryStatus? get status;
  // enum statusEnum {  OPEN,  RECOVERED,  };

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateInjuryRequestClearEnum>? get clear;
  // enum clearEnum {  description,  expectedReturnOn,  actualReturnOn,  };

  UpdateInjuryRequest._();

  factory UpdateInjuryRequest([void updates(UpdateInjuryRequestBuilder b)]) = _$UpdateInjuryRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateInjuryRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateInjuryRequest> get serializer => _$UpdateInjuryRequestSerializer();
}

class _$UpdateInjuryRequestSerializer implements PrimitiveSerializer<UpdateInjuryRequest> {
  @override
  final Iterable<Type> types = const [UpdateInjuryRequest, _$UpdateInjuryRequest];

  @override
  final String wireName = r'UpdateInjuryRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateInjuryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.occurredOn != null) {
      yield r'occurredOn';
      yield serializers.serialize(
        object.occurredOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.bodyPart != null) {
      yield r'bodyPart';
      yield serializers.serialize(
        object.bodyPart,
        specifiedType: const FullType(String),
      );
    }
    if (object.severity != null) {
      yield r'severity';
      yield serializers.serialize(
        object.severity,
        specifiedType: const FullType(InjurySeverity),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.expectedReturnOn != null) {
      yield r'expectedReturnOn';
      yield serializers.serialize(
        object.expectedReturnOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    if (object.actualReturnOn != null) {
      yield r'actualReturnOn';
      yield serializers.serialize(
        object.actualReturnOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(InjuryStatus),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateInjuryRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateInjuryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateInjuryRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'occurredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.occurredOn = valueDes;
          break;
        case r'bodyPart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.bodyPart = valueDes;
          break;
        case r'severity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(InjurySeverity),
          ) as InjurySeverity?;
          if (valueDes == null) continue;
          result.severity = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'expectedReturnOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.expectedReturnOn = valueDes;
          break;
        case r'actualReturnOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.actualReturnOn = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(InjuryStatus),
          ) as InjuryStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateInjuryRequestClearEnum)]),
          ) as BuiltSet<UpdateInjuryRequestClearEnum>?;
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
  UpdateInjuryRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateInjuryRequestBuilder();
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


class UpdateInjuryRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'description')
  static const UpdateInjuryRequestClearEnum description = _$updateInjuryRequestClearEnum_description;
  @BuiltValueEnumConst(wireName: r'expectedReturnOn')
  static const UpdateInjuryRequestClearEnum expectedReturnOn = _$updateInjuryRequestClearEnum_expectedReturnOn;
  @BuiltValueEnumConst(wireName: r'actualReturnOn')
  static const UpdateInjuryRequestClearEnum actualReturnOn = _$updateInjuryRequestClearEnum_actualReturnOn;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateInjuryRequestClearEnum unknownDefaultOpenApi = _$updateInjuryRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateInjuryRequestClearEnum> get serializer => _$updateInjuryRequestClearEnumSerializer;

  const UpdateInjuryRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateInjuryRequestClearEnum> get values => _$updateInjuryRequestClearEnumValues;
  static UpdateInjuryRequestClearEnum valueOf(String name) => _$updateInjuryRequestClearEnumValueOf(name);
}
