//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'planned_absence_input.g.dart';

/// PlannedAbsenceInput
///
/// Properties:
/// * [playerId] 
/// * [fromDate] 
/// * [toDate] - Inclusive.
/// * [reason] 
@BuiltValue(instantiable: false)
abstract class PlannedAbsenceInput  {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'fromDate')
  Date get fromDate;

  /// Inclusive.
  @BuiltValueField(wireName: r'toDate')
  Date get toDate;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlannedAbsenceInput> get serializer => _$PlannedAbsenceInputSerializer();
}

class _$PlannedAbsenceInputSerializer implements PrimitiveSerializer<PlannedAbsenceInput> {
  @override
  final Iterable<Type> types = const [PlannedAbsenceInput];

  @override
  final String wireName = r'PlannedAbsenceInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlannedAbsenceInput object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    PlannedAbsenceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  PlannedAbsenceInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($PlannedAbsenceInput)) as $PlannedAbsenceInput;
  }
}


/// a concrete implementation of [PlannedAbsenceInput], since [PlannedAbsenceInput] is not instantiable
@BuiltValue(instantiable: true)
abstract class $PlannedAbsenceInput implements PlannedAbsenceInput, Built<$PlannedAbsenceInput, $PlannedAbsenceInputBuilder> {
  $PlannedAbsenceInput._();

  factory $PlannedAbsenceInput([void Function($PlannedAbsenceInputBuilder)? updates]) = _$$PlannedAbsenceInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($PlannedAbsenceInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$PlannedAbsenceInput> get serializer => _$$PlannedAbsenceInputSerializer();
}

class _$$PlannedAbsenceInputSerializer implements PrimitiveSerializer<$PlannedAbsenceInput> {
  @override
  final Iterable<Type> types = const [$PlannedAbsenceInput, _$$PlannedAbsenceInput];

  @override
  final String wireName = r'$PlannedAbsenceInput';

  @override
  Object serialize(
    Serializers serializers,
    $PlannedAbsenceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(PlannedAbsenceInput))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlannedAbsenceInputBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $PlannedAbsenceInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $PlannedAbsenceInputBuilder();
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

