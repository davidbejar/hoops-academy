//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'planned_absence.g.dart';

/// PlannedAbsence
///
/// Properties:
/// * [playerId]
/// * [fromDate]
/// * [toDate] - Inclusive.
/// * [reason]
/// * [recordedBy]
/// * [recordedAt]
/// * [id]
@BuiltValue()
abstract class PlannedAbsence implements Built<PlannedAbsence, PlannedAbsenceBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'fromDate')
  Date get fromDate;

  /// Inclusive.
  @BuiltValueField(wireName: r'toDate')
  Date get toDate;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  @BuiltValueField(wireName: r'recordedBy')
  PersonRef get recordedBy;

  @BuiltValueField(wireName: r'recordedAt')
  DateTime get recordedAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  PlannedAbsence._();

  factory PlannedAbsence([void updates(PlannedAbsenceBuilder b)]) = _$PlannedAbsence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlannedAbsenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlannedAbsence> get serializer => _$PlannedAbsenceSerializer();
}

class _$PlannedAbsenceSerializer implements PrimitiveSerializer<PlannedAbsence> {
  @override
  final Iterable<Type> types = const [PlannedAbsence, _$PlannedAbsence];

  @override
  final String wireName = r'PlannedAbsence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlannedAbsence object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'fromDate';
    yield serializers.serialize(
      object.fromDate,
      specifiedType: const FullType(Date),
    );
    yield r'toDate';
    yield serializers.serialize(
      object.toDate,
      specifiedType: const FullType(Date),
    );
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
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
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlannedAbsence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlannedAbsenceBuilder result,
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
        case r'fromDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.fromDate = valueDes;
          break;
        case r'toDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.toDate = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlannedAbsence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlannedAbsenceBuilder();
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
