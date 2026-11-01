//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_roster_entry_input.g.dart';

/// MatchRosterEntryInput
///
/// Properties:
/// * [playerId] 
/// * [jerseyNumber] - Overrides the team jersey for this match.
/// * [isStarter] 
@BuiltValue()
abstract class MatchRosterEntryInput implements Built<MatchRosterEntryInput, MatchRosterEntryInputBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  /// Overrides the team jersey for this match.
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'isStarter')
  bool get isStarter;

  MatchRosterEntryInput._();

  factory MatchRosterEntryInput([void updates(MatchRosterEntryInputBuilder b)]) = _$MatchRosterEntryInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchRosterEntryInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchRosterEntryInput> get serializer => _$MatchRosterEntryInputSerializer();
}

class _$MatchRosterEntryInputSerializer implements PrimitiveSerializer<MatchRosterEntryInput> {
  @override
  final Iterable<Type> types = const [MatchRosterEntryInput, _$MatchRosterEntryInput];

  @override
  final String wireName = r'MatchRosterEntryInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchRosterEntryInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType(String),
      );
    }
    yield r'isStarter';
    yield serializers.serialize(
      object.isStarter,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchRosterEntryInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchRosterEntryInputBuilder result,
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
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        case r'isStarter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isStarter = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchRosterEntryInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchRosterEntryInputBuilder();
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


