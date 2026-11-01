//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_team_player_request.g.dart';

/// UpdateTeamPlayerRequest
///
/// Properties:
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
@BuiltValue()
abstract class UpdateTeamPlayerRequest implements Built<UpdateTeamPlayerRequest, UpdateTeamPlayerRequestBuilder> {
  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  UpdateTeamPlayerRequest._();

  factory UpdateTeamPlayerRequest([void updates(UpdateTeamPlayerRequestBuilder b)]) = _$UpdateTeamPlayerRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTeamPlayerRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTeamPlayerRequest> get serializer => _$UpdateTeamPlayerRequestSerializer();
}

class _$UpdateTeamPlayerRequestSerializer implements PrimitiveSerializer<UpdateTeamPlayerRequest> {
  @override
  final Iterable<Type> types = const [UpdateTeamPlayerRequest, _$UpdateTeamPlayerRequest];

  @override
  final String wireName = r'UpdateTeamPlayerRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTeamPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'jerseyNumber';
    yield object.jerseyNumber == null ? null : serializers.serialize(
      object.jerseyNumber,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTeamPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTeamPlayerRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTeamPlayerRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTeamPlayerRequestBuilder();
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


