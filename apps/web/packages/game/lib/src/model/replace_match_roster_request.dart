//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_roster_entry_input.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'replace_match_roster_request.g.dart';

/// ReplaceMatchRosterRequest
///
/// Properties:
/// * [entries] 
@BuiltValue()
abstract class ReplaceMatchRosterRequest implements Built<ReplaceMatchRosterRequest, ReplaceMatchRosterRequestBuilder> {
  @BuiltValueField(wireName: r'entries')
  BuiltList<MatchRosterEntryInput> get entries;

  ReplaceMatchRosterRequest._();

  factory ReplaceMatchRosterRequest([void updates(ReplaceMatchRosterRequestBuilder b)]) = _$ReplaceMatchRosterRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReplaceMatchRosterRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReplaceMatchRosterRequest> get serializer => _$ReplaceMatchRosterRequestSerializer();
}

class _$ReplaceMatchRosterRequestSerializer implements PrimitiveSerializer<ReplaceMatchRosterRequest> {
  @override
  final Iterable<Type> types = const [ReplaceMatchRosterRequest, _$ReplaceMatchRosterRequest];

  @override
  final String wireName = r'ReplaceMatchRosterRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReplaceMatchRosterRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(MatchRosterEntryInput)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReplaceMatchRosterRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReplaceMatchRosterRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MatchRosterEntryInput)]),
          ) as BuiltList<MatchRosterEntryInput>;
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
  ReplaceMatchRosterRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReplaceMatchRosterRequestBuilder();
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


