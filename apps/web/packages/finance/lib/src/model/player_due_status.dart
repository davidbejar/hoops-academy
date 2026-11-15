//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_due_status.g.dart';

/// PlayerDueStatus
///
/// Properties:
/// * [playerId]
/// * [playerName]
/// * [upToDate] - false when an OPEN due of a started period exists.
@BuiltValue()
abstract class PlayerDueStatus implements Built<PlayerDueStatus, PlayerDueStatusBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'playerName')
  String get playerName;

  /// false when an OPEN due of a started period exists.
  @BuiltValueField(wireName: r'upToDate')
  bool get upToDate;

  PlayerDueStatus._();

  factory PlayerDueStatus([void updates(PlayerDueStatusBuilder b)]) = _$PlayerDueStatus;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerDueStatusBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerDueStatus> get serializer => _$PlayerDueStatusSerializer();
}

class _$PlayerDueStatusSerializer implements PrimitiveSerializer<PlayerDueStatus> {
  @override
  final Iterable<Type> types = const [PlayerDueStatus, _$PlayerDueStatus];

  @override
  final String wireName = r'PlayerDueStatus';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerDueStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'playerName';
    yield serializers.serialize(
      object.playerName,
      specifiedType: const FullType(String),
    );
    yield r'upToDate';
    yield serializers.serialize(
      object.upToDate,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerDueStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerDueStatusBuilder result,
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
        case r'playerName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerName = valueDes;
          break;
        case r'upToDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.upToDate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerDueStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerDueStatusBuilder();
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
