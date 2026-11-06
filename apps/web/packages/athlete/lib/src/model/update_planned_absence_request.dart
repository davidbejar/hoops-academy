//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_planned_absence_request.g.dart';

/// UpdatePlannedAbsenceRequest
///
/// Properties:
/// * [fromDate]
/// * [toDate]
/// * [reason]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdatePlannedAbsenceRequest implements Built<UpdatePlannedAbsenceRequest, UpdatePlannedAbsenceRequestBuilder> {
  @BuiltValueField(wireName: r'fromDate')
  Date? get fromDate;

  @BuiltValueField(wireName: r'toDate')
  Date? get toDate;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdatePlannedAbsenceRequestClearEnum>? get clear;
  // enum clearEnum {  reason,  };

  UpdatePlannedAbsenceRequest._();

  factory UpdatePlannedAbsenceRequest([void updates(UpdatePlannedAbsenceRequestBuilder b)]) = _$UpdatePlannedAbsenceRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePlannedAbsenceRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePlannedAbsenceRequest> get serializer => _$UpdatePlannedAbsenceRequestSerializer();
}

class _$UpdatePlannedAbsenceRequestSerializer implements PrimitiveSerializer<UpdatePlannedAbsenceRequest> {
  @override
  final Iterable<Type> types = const [UpdatePlannedAbsenceRequest, _$UpdatePlannedAbsenceRequest];

  @override
  final String wireName = r'UpdatePlannedAbsenceRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePlannedAbsenceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fromDate != null) {
      yield r'fromDate';
      yield serializers.serialize(
        object.fromDate,
        specifiedType: const FullType(Date),
      );
    }
    if (object.toDate != null) {
      yield r'toDate';
      yield serializers.serialize(
        object.toDate,
        specifiedType: const FullType(Date),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdatePlannedAbsenceRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePlannedAbsenceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePlannedAbsenceRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fromDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.fromDate = valueDes;
          break;
        case r'toDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdatePlannedAbsenceRequestClearEnum)]),
          ) as BuiltSet<UpdatePlannedAbsenceRequestClearEnum>?;
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
  UpdatePlannedAbsenceRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePlannedAbsenceRequestBuilder();
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


class UpdatePlannedAbsenceRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'reason')
  static const UpdatePlannedAbsenceRequestClearEnum reason = _$updatePlannedAbsenceRequestClearEnum_reason;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdatePlannedAbsenceRequestClearEnum unknownDefaultOpenApi = _$updatePlannedAbsenceRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdatePlannedAbsenceRequestClearEnum> get serializer => _$updatePlannedAbsenceRequestClearEnumSerializer;

  const UpdatePlannedAbsenceRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdatePlannedAbsenceRequestClearEnum> get values => _$updatePlannedAbsenceRequestClearEnumValues;
  static UpdatePlannedAbsenceRequestClearEnum valueOf(String name) => _$updatePlannedAbsenceRequestClearEnumValueOf(name);
}
