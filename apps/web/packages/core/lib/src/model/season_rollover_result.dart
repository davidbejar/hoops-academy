//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/orphan.dart';
import 'package:hoops_core_api/src/model/team_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'season_rollover_result.g.dart';

/// SeasonRolloverResult
///
/// Properties:
/// * [fromSeasonId] 
/// * [toSeasonId] 
/// * [clonedTeams] 
/// * [orphans] - Active players left without a valid open assignment in the target season.
/// * [openedCaseIds] 
@BuiltValue()
abstract class SeasonRolloverResult implements Built<SeasonRolloverResult, SeasonRolloverResultBuilder> {
  @BuiltValueField(wireName: r'fromSeasonId')
  String get fromSeasonId;

  @BuiltValueField(wireName: r'toSeasonId')
  String get toSeasonId;

  @BuiltValueField(wireName: r'clonedTeams')
  BuiltList<TeamRef> get clonedTeams;

  /// Active players left without a valid open assignment in the target season.
  @BuiltValueField(wireName: r'orphans')
  BuiltList<Orphan> get orphans;

  @BuiltValueField(wireName: r'openedCaseIds')
  BuiltList<String> get openedCaseIds;

  SeasonRolloverResult._();

  factory SeasonRolloverResult([void updates(SeasonRolloverResultBuilder b)]) = _$SeasonRolloverResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeasonRolloverResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeasonRolloverResult> get serializer => _$SeasonRolloverResultSerializer();
}

class _$SeasonRolloverResultSerializer implements PrimitiveSerializer<SeasonRolloverResult> {
  @override
  final Iterable<Type> types = const [SeasonRolloverResult, _$SeasonRolloverResult];

  @override
  final String wireName = r'SeasonRolloverResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeasonRolloverResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'fromSeasonId';
    yield serializers.serialize(
      object.fromSeasonId,
      specifiedType: const FullType(String),
    );
    yield r'toSeasonId';
    yield serializers.serialize(
      object.toSeasonId,
      specifiedType: const FullType(String),
    );
    yield r'clonedTeams';
    yield serializers.serialize(
      object.clonedTeams,
      specifiedType: const FullType(BuiltList, [FullType(TeamRef)]),
    );
    yield r'orphans';
    yield serializers.serialize(
      object.orphans,
      specifiedType: const FullType(BuiltList, [FullType(Orphan)]),
    );
    yield r'openedCaseIds';
    yield serializers.serialize(
      object.openedCaseIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SeasonRolloverResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SeasonRolloverResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fromSeasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromSeasonId = valueDes;
          break;
        case r'toSeasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.toSeasonId = valueDes;
          break;
        case r'clonedTeams':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TeamRef)]),
          ) as BuiltList<TeamRef>;
          result.clonedTeams.replace(valueDes);
          break;
        case r'orphans':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Orphan)]),
          ) as BuiltList<Orphan>;
          result.orphans.replace(valueDes);
          break;
        case r'openedCaseIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.openedCaseIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeasonRolloverResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeasonRolloverResultBuilder();
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


