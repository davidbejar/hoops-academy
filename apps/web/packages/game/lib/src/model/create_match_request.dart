//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/home_away.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_match_request.g.dart';

/// CreateMatchRequest
///
/// Properties:
/// * [teamId] 
/// * [opponentName] 
/// * [homeAway] 
/// * [scheduledAt] 
/// * [venue] 
/// * [periodCount] 
/// * [periodMinutes] 
@BuiltValue()
abstract class CreateMatchRequest implements Built<CreateMatchRequest, CreateMatchRequestBuilder> {
  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'opponentName')
  String get opponentName;

  @BuiltValueField(wireName: r'homeAway')
  HomeAway get homeAway;
  // enum homeAwayEnum {  HOME,  AWAY,  };

  @BuiltValueField(wireName: r'scheduledAt')
  DateTime get scheduledAt;

  @BuiltValueField(wireName: r'venue')
  String? get venue;

  @BuiltValueField(wireName: r'periodCount')
  int? get periodCount;

  @BuiltValueField(wireName: r'periodMinutes')
  int? get periodMinutes;

  CreateMatchRequest._();

  factory CreateMatchRequest([void updates(CreateMatchRequestBuilder b)]) = _$CreateMatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateMatchRequestBuilder b) => b
      ..periodCount = 4
      ..periodMinutes = 10;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateMatchRequest> get serializer => _$CreateMatchRequestSerializer();
}

class _$CreateMatchRequestSerializer implements PrimitiveSerializer<CreateMatchRequest> {
  @override
  final Iterable<Type> types = const [CreateMatchRequest, _$CreateMatchRequest];

  @override
  final String wireName = r'CreateMatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateMatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'opponentName';
    yield serializers.serialize(
      object.opponentName,
      specifiedType: const FullType(String),
    );
    yield r'homeAway';
    yield serializers.serialize(
      object.homeAway,
      specifiedType: const FullType(HomeAway),
    );
    yield r'scheduledAt';
    yield serializers.serialize(
      object.scheduledAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.venue != null) {
      yield r'venue';
      yield serializers.serialize(
        object.venue,
        specifiedType: const FullType(String),
      );
    }
    if (object.periodCount != null) {
      yield r'periodCount';
      yield serializers.serialize(
        object.periodCount,
        specifiedType: const FullType(int),
      );
    }
    if (object.periodMinutes != null) {
      yield r'periodMinutes';
      yield serializers.serialize(
        object.periodMinutes,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateMatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateMatchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'opponentName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.opponentName = valueDes;
          break;
        case r'homeAway':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HomeAway),
          ) as HomeAway;
          result.homeAway = valueDes;
          break;
        case r'scheduledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scheduledAt = valueDes;
          break;
        case r'venue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.venue = valueDes;
          break;
        case r'periodCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.periodCount = valueDes;
          break;
        case r'periodMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.periodMinutes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateMatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateMatchRequestBuilder();
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


