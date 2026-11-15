//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/fee_cadence.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fee_plan.g.dart';

/// FeePlan
///
/// Properties:
/// * [id]
/// * [name]
/// * [seasonId]
/// * [teamId] - The team whose players the plan charges; null for an age-category plan.
/// * [ageCategoryId] - The age category whose teams' players (of the plan's season) the plan charges; null for a team plan.
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [currency] - Alphabetic ISO 4217 code of the academy's currency.
/// * [cadence]
/// * [firstPeriod] - First period charged; null for SEASON plans.
/// * [lastPeriod] - Last period charged; null = to the end of the season (and for SEASON plans).
/// * [autoGenerate] - The daily job creates this plan's dues (unless archived).
/// * [archived]
/// * [hasDues] - Dues exist (then `firstPeriod` is fixed and the plan cannot be deleted).
/// * [createdAt]
/// * [updatedAt]
@BuiltValue()
abstract class FeePlan implements Built<FeePlan, FeePlanBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  /// The team whose players the plan charges; null for an age-category plan.
  @BuiltValueField(wireName: r'teamId')
  String? get teamId;

  /// The age category whose teams' players (of the plan's season) the plan charges; null for a team plan.
  @BuiltValueField(wireName: r'ageCategoryId')
  String? get ageCategoryId;

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// Alphabetic ISO 4217 code of the academy's currency.
  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'cadence')
  FeeCadence get cadence;
  // enum cadenceEnum {  MONTHLY,  QUARTERLY,  SEASON,  };

  /// First period charged; null for SEASON plans.
  @BuiltValueField(wireName: r'firstPeriod')
  String? get firstPeriod;

  /// Last period charged; null = to the end of the season (and for SEASON plans).
  @BuiltValueField(wireName: r'lastPeriod')
  String? get lastPeriod;

  /// The daily job creates this plan's dues (unless archived).
  @BuiltValueField(wireName: r'autoGenerate')
  bool get autoGenerate;

  @BuiltValueField(wireName: r'archived')
  bool get archived;

  /// Dues exist (then `firstPeriod` is fixed and the plan cannot be deleted).
  @BuiltValueField(wireName: r'hasDues')
  bool get hasDues;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  FeePlan._();

  factory FeePlan([void updates(FeePlanBuilder b)]) = _$FeePlan;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FeePlanBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FeePlan> get serializer => _$FeePlanSerializer();
}

class _$FeePlanSerializer implements PrimitiveSerializer<FeePlan> {
  @override
  final Iterable<Type> types = const [FeePlan, _$FeePlan];

  @override
  final String wireName = r'FeePlan';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FeePlan object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
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
    yield r'teamId';
    yield object.teamId == null ? null : serializers.serialize(
      object.teamId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'ageCategoryId';
    yield object.ageCategoryId == null ? null : serializers.serialize(
      object.ageCategoryId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    yield r'cadence';
    yield serializers.serialize(
      object.cadence,
      specifiedType: const FullType(FeeCadence),
    );
    yield r'firstPeriod';
    yield object.firstPeriod == null ? null : serializers.serialize(
      object.firstPeriod,
      specifiedType: const FullType.nullable(String),
    );
    yield r'lastPeriod';
    yield object.lastPeriod == null ? null : serializers.serialize(
      object.lastPeriod,
      specifiedType: const FullType.nullable(String),
    );
    yield r'autoGenerate';
    yield serializers.serialize(
      object.autoGenerate,
      specifiedType: const FullType(bool),
    );
    yield r'archived';
    yield serializers.serialize(
      object.archived,
      specifiedType: const FullType(bool),
    );
    yield r'hasDues';
    yield serializers.serialize(
      object.hasDues,
      specifiedType: const FullType(bool),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FeePlan object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FeePlanBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
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
            specifiedType: const FullType(bool),
          ) as bool;
          result.autoGenerate = valueDes;
          break;
        case r'archived':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.archived = valueDes;
          break;
        case r'hasDues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasDues = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FeePlan deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FeePlanBuilder();
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
