//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/injury_severity.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_injury_request.g.dart';

/// CreateInjuryRequest
///
/// Properties:
/// * [playerId] 
/// * [occurredOn] 
/// * [bodyPart] 
/// * [severity] 
/// * [description] 
/// * [expectedReturnOn] - Must be ≥ occurredOn.
@BuiltValue()
abstract class CreateInjuryRequest implements Built<CreateInjuryRequest, CreateInjuryRequestBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'occurredOn')
  Date get occurredOn;

  @BuiltValueField(wireName: r'bodyPart')
  String get bodyPart;

  @BuiltValueField(wireName: r'severity')
  InjurySeverity get severity;
  // enum severityEnum {  MINOR,  MODERATE,  SEVERE,  };

  @BuiltValueField(wireName: r'description')
  String? get description;

  /// Must be ≥ occurredOn.
  @BuiltValueField(wireName: r'expectedReturnOn')
  Date? get expectedReturnOn;

  CreateInjuryRequest._();

  factory CreateInjuryRequest([void updates(CreateInjuryRequestBuilder b)]) = _$CreateInjuryRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateInjuryRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateInjuryRequest> get serializer => _$CreateInjuryRequestSerializer();
}

class _$CreateInjuryRequestSerializer implements PrimitiveSerializer<CreateInjuryRequest> {
  @override
  final Iterable<Type> types = const [CreateInjuryRequest, _$CreateInjuryRequest];

  @override
  final String wireName = r'CreateInjuryRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateInjuryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'occurredOn';
    yield serializers.serialize(
      object.occurredOn,
      specifiedType: const FullType(Date),
    );
    yield r'bodyPart';
    yield serializers.serialize(
      object.bodyPart,
      specifiedType: const FullType(String),
    );
    yield r'severity';
    yield serializers.serialize(
      object.severity,
      specifiedType: const FullType(InjurySeverity),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.expectedReturnOn != null) {
      yield r'expectedReturnOn';
      yield serializers.serialize(
        object.expectedReturnOn,
        specifiedType: const FullType(Date),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateInjuryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateInjuryRequestBuilder result,
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
        case r'occurredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.occurredOn = valueDes;
          break;
        case r'bodyPart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.bodyPart = valueDes;
          break;
        case r'severity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InjurySeverity),
          ) as InjurySeverity;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateInjuryRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateInjuryRequestBuilder();
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


