//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_roster_entry.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_roster.g.dart';

/// MatchRoster
///
/// Properties:
/// * [matchId] 
/// * [entries] 
@BuiltValue()
abstract class MatchRoster implements Built<MatchRoster, MatchRosterBuilder> {
  @BuiltValueField(wireName: r'matchId')
  String get matchId;

  @BuiltValueField(wireName: r'entries')
  BuiltList<MatchRosterEntry> get entries;

  MatchRoster._();

  factory MatchRoster([void updates(MatchRosterBuilder b)]) = _$MatchRoster;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchRosterBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchRoster> get serializer => _$MatchRosterSerializer();
}

class _$MatchRosterSerializer implements PrimitiveSerializer<MatchRoster> {
  @override
  final Iterable<Type> types = const [MatchRoster, _$MatchRoster];

  @override
  final String wireName = r'MatchRoster';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchRoster object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'matchId';
    yield serializers.serialize(
      object.matchId,
      specifiedType: const FullType(String),
    );
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(MatchRosterEntry)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchRoster object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchRosterBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'matchId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.matchId = valueDes;
          break;
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MatchRosterEntry)]),
          ) as BuiltList<MatchRosterEntry>;
          result.entries.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchRoster deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchRosterBuilder();
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


