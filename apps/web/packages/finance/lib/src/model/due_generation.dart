//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/generated_due.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'due_generation.g.dart';

/// DueGeneration
///
/// Properties:
/// * [feePlanId]
/// * [period] - A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
/// * [periodStart]
/// * [periodEnd]
/// * [preview]
/// * [created] - Dues created (in a preview, that would be created).
/// * [existing] - Dues of the period that already existed and were left as they are.
/// * [dues] - The dues created (or that would be), ordered by player name.
@BuiltValue()
abstract class DueGeneration implements Built<DueGeneration, DueGenerationBuilder> {
  @BuiltValueField(wireName: r'feePlanId')
  String get feePlanId;

  /// A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
  @BuiltValueField(wireName: r'period')
  String get period;

  @BuiltValueField(wireName: r'periodStart')
  Date get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  Date get periodEnd;

  @BuiltValueField(wireName: r'preview')
  bool get preview;

  /// Dues created (in a preview, that would be created).
  @BuiltValueField(wireName: r'created')
  int get created;

  /// Dues of the period that already existed and were left as they are.
  @BuiltValueField(wireName: r'existing')
  int get existing;

  /// The dues created (or that would be), ordered by player name.
  @BuiltValueField(wireName: r'dues')
  BuiltList<GeneratedDue> get dues;

  DueGeneration._();

  factory DueGeneration([void updates(DueGenerationBuilder b)]) = _$DueGeneration;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DueGenerationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DueGeneration> get serializer => _$DueGenerationSerializer();
}

class _$DueGenerationSerializer implements PrimitiveSerializer<DueGeneration> {
  @override
  final Iterable<Type> types = const [DueGeneration, _$DueGeneration];

  @override
  final String wireName = r'DueGeneration';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DueGeneration object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'feePlanId';
    yield serializers.serialize(
      object.feePlanId,
      specifiedType: const FullType(String),
    );
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(String),
    );
    yield r'periodStart';
    yield serializers.serialize(
      object.periodStart,
      specifiedType: const FullType(Date),
    );
    yield r'periodEnd';
    yield serializers.serialize(
      object.periodEnd,
      specifiedType: const FullType(Date),
    );
    yield r'preview';
    yield serializers.serialize(
      object.preview,
      specifiedType: const FullType(bool),
    );
    yield r'created';
    yield serializers.serialize(
      object.created,
      specifiedType: const FullType(int),
    );
    yield r'existing';
    yield serializers.serialize(
      object.existing,
      specifiedType: const FullType(int),
    );
    yield r'dues';
    yield serializers.serialize(
      object.dues,
      specifiedType: const FullType(BuiltList, [FullType(GeneratedDue)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DueGeneration object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DueGenerationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'feePlanId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feePlanId = valueDes;
          break;
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.period = valueDes;
          break;
        case r'periodStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodStart = valueDes;
          break;
        case r'periodEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodEnd = valueDes;
          break;
        case r'preview':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.preview = valueDes;
          break;
        case r'created':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.created = valueDes;
          break;
        case r'existing':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.existing = valueDes;
          break;
        case r'dues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GeneratedDue)]),
          ) as BuiltList<GeneratedDue>;
          result.dues.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DueGeneration deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DueGenerationBuilder();
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
