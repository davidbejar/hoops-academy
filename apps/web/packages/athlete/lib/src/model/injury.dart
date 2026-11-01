//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/injury_status.dart';
import 'package:hoops_athlete_api/src/model/injury_severity.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:hoops_athlete_api/src/model/audit_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'injury.g.dart';

/// Injury
///
/// Properties:
/// * [recordedBy] 
/// * [recordedAt] 
/// * [id] 
/// * [playerId] 
/// * [occurredOn] 
/// * [bodyPart] 
/// * [severity] 
/// * [description] 
/// * [expectedReturnOn] 
/// * [actualReturnOn] 
/// * [status] 
@BuiltValue()
abstract class Injury implements AuditInfo, Built<Injury, InjuryBuilder> {
  @BuiltValueField(wireName: r'severity')
  InjurySeverity get severity;
  // enum severityEnum {  MINOR,  MODERATE,  SEVERE,  };

  @BuiltValueField(wireName: r'expectedReturnOn')
  Date? get expectedReturnOn;

  @BuiltValueField(wireName: r'actualReturnOn')
  Date? get actualReturnOn;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'occurredOn')
  Date get occurredOn;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'bodyPart')
  String get bodyPart;

  @BuiltValueField(wireName: r'status')
  InjuryStatus get status;
  // enum statusEnum {  OPEN,  RECOVERED,  };

  Injury._();

  factory Injury([void updates(InjuryBuilder b)]) = _$Injury;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InjuryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Injury> get serializer => _$InjurySerializer();
}

class _$InjurySerializer implements PrimitiveSerializer<Injury> {
  @override
  final Iterable<Type> types = const [Injury, _$Injury];

  @override
  final String wireName = r'Injury';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Injury object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'severity';
    yield serializers.serialize(
      object.severity,
      specifiedType: const FullType(InjurySeverity),
    );
    if (object.expectedReturnOn != null) {
      yield r'expectedReturnOn';
      yield serializers.serialize(
        object.expectedReturnOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    yield r'recordedBy';
    yield serializers.serialize(
      object.recordedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'recordedAt';
    yield serializers.serialize(
      object.recordedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.actualReturnOn != null) {
      yield r'actualReturnOn';
      yield serializers.serialize(
        object.actualReturnOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'occurredOn';
    yield serializers.serialize(
      object.occurredOn,
      specifiedType: const FullType(Date),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'bodyPart';
    yield serializers.serialize(
      object.bodyPart,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(InjuryStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Injury object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required InjuryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'severity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InjurySeverity),
          ) as InjurySeverity;
          result.severity = valueDes;
          break;
        case r'expectedReturnOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.expectedReturnOn = valueDes;
          break;
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.recordedBy.replace(valueDes);
          break;
        case r'recordedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAt = valueDes;
          break;
        case r'actualReturnOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.actualReturnOn = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'occurredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.occurredOn = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'bodyPart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.bodyPart = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InjuryStatus),
          ) as InjuryStatus;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Injury deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InjuryBuilder();
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


