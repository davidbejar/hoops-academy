//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_availability.g.dart';

/// PlayerAvailability
///
/// Properties:
/// * [playerId] 
/// * [available] 
/// * [expectedReturnOn] - Latest expected return of the blocking injuries; absent/null when available or unknown.
/// * [injuries] - Ids of the injuries that block availability.
@BuiltValue()
abstract class PlayerAvailability implements Built<PlayerAvailability, PlayerAvailabilityBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'available')
  bool get available;

  /// Latest expected return of the blocking injuries; absent/null when available or unknown.
  @BuiltValueField(wireName: r'expectedReturnOn')
  Date? get expectedReturnOn;

  /// Ids of the injuries that block availability.
  @BuiltValueField(wireName: r'injuries')
  BuiltList<String> get injuries;

  PlayerAvailability._();

  factory PlayerAvailability([void updates(PlayerAvailabilityBuilder b)]) = _$PlayerAvailability;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerAvailabilityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerAvailability> get serializer => _$PlayerAvailabilitySerializer();
}

class _$PlayerAvailabilitySerializer implements PrimitiveSerializer<PlayerAvailability> {
  @override
  final Iterable<Type> types = const [PlayerAvailability, _$PlayerAvailability];

  @override
  final String wireName = r'PlayerAvailability';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerAvailability object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'available';
    yield serializers.serialize(
      object.available,
      specifiedType: const FullType(bool),
    );
    if (object.expectedReturnOn != null) {
      yield r'expectedReturnOn';
      yield serializers.serialize(
        object.expectedReturnOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    yield r'injuries';
    yield serializers.serialize(
      object.injuries,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerAvailability object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerAvailabilityBuilder result,
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
        case r'available':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.available = valueDes;
          break;
        case r'expectedReturnOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.expectedReturnOn = valueDes;
          break;
        case r'injuries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.injuries.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerAvailability deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerAvailabilityBuilder();
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


