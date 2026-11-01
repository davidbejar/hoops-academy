//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/plan_progress_counts.dart';
import 'package:hoops_athlete_api/src/model/player_progress.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_progress.g.dart';

/// PlanProgress
///
/// Properties:
/// * [assignmentId] 
/// * [total] - Targeted players visible to the caller.
/// * [notRecorded] 
/// * [counts] 
/// * [players] 
@BuiltValue()
abstract class PlanProgress implements Built<PlanProgress, PlanProgressBuilder> {
  @BuiltValueField(wireName: r'assignmentId')
  String get assignmentId;

  /// Targeted players visible to the caller.
  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'notRecorded')
  int get notRecorded;

  @BuiltValueField(wireName: r'counts')
  PlanProgressCounts get counts;

  @BuiltValueField(wireName: r'players')
  BuiltList<PlayerProgress> get players;

  PlanProgress._();

  factory PlanProgress([void updates(PlanProgressBuilder b)]) = _$PlanProgress;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanProgressBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanProgress> get serializer => _$PlanProgressSerializer();
}

class _$PlanProgressSerializer implements PrimitiveSerializer<PlanProgress> {
  @override
  final Iterable<Type> types = const [PlanProgress, _$PlanProgress];

  @override
  final String wireName = r'PlanProgress';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'assignmentId';
    yield serializers.serialize(
      object.assignmentId,
      specifiedType: const FullType(String),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    yield r'notRecorded';
    yield serializers.serialize(
      object.notRecorded,
      specifiedType: const FullType(int),
    );
    yield r'counts';
    yield serializers.serialize(
      object.counts,
      specifiedType: const FullType(PlanProgressCounts),
    );
    yield r'players';
    yield serializers.serialize(
      object.players,
      specifiedType: const FullType(BuiltList, [FullType(PlayerProgress)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanProgressBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'assignmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assignmentId = valueDes;
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'notRecorded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.notRecorded = valueDes;
          break;
        case r'counts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlanProgressCounts),
          ) as PlanProgressCounts;
          result.counts.replace(valueDes);
          break;
        case r'players':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerProgress)]),
          ) as BuiltList<PlayerProgress>;
          result.players.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanProgress deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanProgressBuilder();
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


