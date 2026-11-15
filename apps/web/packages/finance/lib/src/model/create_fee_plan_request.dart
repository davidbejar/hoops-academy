//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/fee_cadence.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_fee_plan_request.g.dart';

/// CreateFeePlanRequest
///
/// Properties:
/// * [name]
/// * [seasonId]
/// * [teamId] - Exactly one of `teamId` and `ageCategoryId`.
/// * [ageCategoryId]
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [cadence]
/// * [firstPeriod] - A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
/// * [lastPeriod] - A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
/// * [autoGenerate]
@BuiltValue()
abstract class CreateFeePlanRequest implements Built<CreateFeePlanRequest, CreateFeePlanRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  /// Exactly one of `teamId` and `ageCategoryId`.
  @BuiltValueField(wireName: r'teamId')
  String? get teamId;

  @BuiltValueField(wireName: r'ageCategoryId')
  String? get ageCategoryId;

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'cadence')
  FeeCadence get cadence;
  // enum cadenceEnum {  MONTHLY,  QUARTERLY,  SEASON,  };

  /// A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
  @BuiltValueField(wireName: r'firstPeriod')
  String? get firstPeriod;

  /// A calendar month `YYYY-MM` (MONTHLY plans) or a calendar quarter `YYYY-Qn` (QUARTERLY plans).
  @BuiltValueField(wireName: r'lastPeriod')
  String? get lastPeriod;

  @BuiltValueField(wireName: r'autoGenerate')
  bool? get autoGenerate;

  CreateFeePlanRequest._();

  factory CreateFeePlanRequest([void updates(CreateFeePlanRequestBuilder b)]) = _$CreateFeePlanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateFeePlanRequestBuilder b) => b
      ..autoGenerate = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateFeePlanRequest> get serializer => _$CreateFeePlanRequestSerializer();
}

class _$CreateFeePlanRequestSerializer implements PrimitiveSerializer<CreateFeePlanRequest> {
  @override
  final Iterable<Type> types = const [CreateFeePlanRequest, _$CreateFeePlanRequest];

  @override
  final String wireName = r'CreateFeePlanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateFeePlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    if (object.teamId != null) {
      yield r'teamId';
      yield serializers.serialize(
        object.teamId,
        specifiedType: const FullType(String),
      );
    }
    if (object.ageCategoryId != null) {
      yield r'ageCategoryId';
      yield serializers.serialize(
        object.ageCategoryId,
        specifiedType: const FullType(String),
      );
    }
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'cadence';
    yield serializers.serialize(
      object.cadence,
      specifiedType: const FullType(FeeCadence),
    );
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
        specifiedType: const FullType(String),
      );
    }
    if (object.autoGenerate != null) {
      yield r'autoGenerate';
      yield serializers.serialize(
        object.autoGenerate,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateFeePlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateFeePlanRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.teamId = valueDes;
          break;
        case r'ageCategoryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ageCategoryId = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        case r'cadence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FeeCadence),
          ) as FeeCadence;
          result.cadence = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateFeePlanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateFeePlanRequestBuilder();
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
