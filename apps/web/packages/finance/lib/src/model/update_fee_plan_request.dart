//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_fee_plan_request.g.dart';

/// UpdateFeePlanRequest
///
/// Properties:
/// * [name]
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [firstPeriod] - A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
/// * [lastPeriod] - A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
/// * [autoGenerate]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateFeePlanRequest implements Built<UpdateFeePlanRequest, UpdateFeePlanRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int? get amountMinor;

  /// A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
  @BuiltValueField(wireName: r'firstPeriod')
  String? get firstPeriod;

  /// A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
  @BuiltValueField(wireName: r'lastPeriod')
  String? get lastPeriod;

  @BuiltValueField(wireName: r'autoGenerate')
  bool? get autoGenerate;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateFeePlanRequestClearEnum>? get clear;
  // enum clearEnum {  lastPeriod,  };

  UpdateFeePlanRequest._();

  factory UpdateFeePlanRequest([void updates(UpdateFeePlanRequestBuilder b)]) = _$UpdateFeePlanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateFeePlanRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateFeePlanRequest> get serializer => _$UpdateFeePlanRequestSerializer();
}

class _$UpdateFeePlanRequestSerializer implements PrimitiveSerializer<UpdateFeePlanRequest> {
  @override
  final Iterable<Type> types = const [UpdateFeePlanRequest, _$UpdateFeePlanRequest];

  @override
  final String wireName = r'UpdateFeePlanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateFeePlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.amountMinor != null) {
      yield r'amountMinor';
      yield serializers.serialize(
        object.amountMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.firstPeriod != null) {
      yield r'firstPeriod';
      yield serializers.serialize(
        object.firstPeriod,
        specifiedType: const FullType(String),
      );
    }
    if (object.lastPeriod != null) {
      yield r'lastPeriod';
      yield serializers.serialize(
        object.lastPeriod,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.autoGenerate != null) {
      yield r'autoGenerate';
      yield serializers.serialize(
        object.autoGenerate,
        specifiedType: const FullType(bool),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateFeePlanRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateFeePlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateFeePlanRequestBuilder result,
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
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.amountMinor = valueDes;
          break;
        case r'firstPeriod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.firstPeriod = valueDes;
          break;
        case r'lastPeriod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastPeriod = valueDes;
          break;
        case r'autoGenerate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.autoGenerate = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateFeePlanRequestClearEnum)]),
          ) as BuiltSet<UpdateFeePlanRequestClearEnum>?;
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
  UpdateFeePlanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateFeePlanRequestBuilder();
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


class UpdateFeePlanRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'lastPeriod')
  static const UpdateFeePlanRequestClearEnum lastPeriod = _$updateFeePlanRequestClearEnum_lastPeriod;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateFeePlanRequestClearEnum unknownDefaultOpenApi = _$updateFeePlanRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateFeePlanRequestClearEnum> get serializer => _$updateFeePlanRequestClearEnumSerializer;

  const UpdateFeePlanRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateFeePlanRequestClearEnum> get values => _$updateFeePlanRequestClearEnumValues;
  static UpdateFeePlanRequestClearEnum valueOf(String name) => _$updateFeePlanRequestClearEnumValueOf(name);
}
