//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assign_player_request.g.dart';

/// AssignPlayerRequest
///
/// Properties:
/// * [playerId] 
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [joinedOn] - Defaults to today (tenant time zone).
@BuiltValue()
abstract class AssignPlayerRequest implements Built<AssignPlayerRequest, AssignPlayerRequestBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  /// Defaults to today (tenant time zone).
  @BuiltValueField(wireName: r'joinedOn')
  Date? get joinedOn;

  AssignPlayerRequest._();

  factory AssignPlayerRequest([void updates(AssignPlayerRequestBuilder b)]) = _$AssignPlayerRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssignPlayerRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AssignPlayerRequest> get serializer => _$AssignPlayerRequestSerializer();
}

class _$AssignPlayerRequestSerializer implements PrimitiveSerializer<AssignPlayerRequest> {
  @override
  final Iterable<Type> types = const [AssignPlayerRequest, _$AssignPlayerRequest];

  @override
  final String wireName = r'AssignPlayerRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AssignPlayerRequest object, {
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
    if (object.joinedOn != null) {
      yield r'joinedOn';
      yield serializers.serialize(
        object.joinedOn,
        specifiedType: const FullType(Date),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AssignPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AssignPlayerRequestBuilder result,
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
        case r'joinedOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.joinedOn = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AssignPlayerRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssignPlayerRequestBuilder();
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


