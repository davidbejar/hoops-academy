//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/completion_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_progress.g.dart';

/// PlayerProgress
///
/// Properties:
/// * [playerId] 
/// * [status] - Null when nothing was recorded for the player yet.
/// * [completionId] 
@BuiltValue()
abstract class PlayerProgress implements Built<PlayerProgress, PlayerProgressBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  /// Null when nothing was recorded for the player yet.
  @BuiltValueField(wireName: r'status')
  CompletionStatus? get status;
  // enum statusEnum {  DONE,  PARTIAL,  NOT_DONE,  };

  @BuiltValueField(wireName: r'completionId')
  String? get completionId;

  PlayerProgress._();

  factory PlayerProgress([void updates(PlayerProgressBuilder b)]) = _$PlayerProgress;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerProgressBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerProgress> get serializer => _$PlayerProgressSerializer();
}

class _$PlayerProgressSerializer implements PrimitiveSerializer<PlayerProgress> {
  @override
  final Iterable<Type> types = const [PlayerProgress, _$PlayerProgress];

  @override
  final String wireName = r'PlayerProgress';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(CompletionStatus),
      );
    }
    if (object.completionId != null) {
      yield r'completionId';
      yield serializers.serialize(
        object.completionId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerProgressBuilder result,
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CompletionStatus),
          ) as CompletionStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'completionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.completionId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerProgress deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerProgressBuilder();
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


