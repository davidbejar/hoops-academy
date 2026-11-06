//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/home_away.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_match_request.g.dart';

/// UpdateMatchRequest
///
/// Properties:
/// * [opponentName] 
/// * [homeAway] 
/// * [scheduledAt] 
/// * [venue] 
/// * [periodCount] 
/// * [periodMinutes] 
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateMatchRequest implements Built<UpdateMatchRequest, UpdateMatchRequestBuilder> {
  @BuiltValueField(wireName: r'opponentName')
  String? get opponentName;

  @BuiltValueField(wireName: r'homeAway')
  HomeAway? get homeAway;
  // enum homeAwayEnum {  HOME,  AWAY,  };

  @BuiltValueField(wireName: r'scheduledAt')
  DateTime? get scheduledAt;

  @BuiltValueField(wireName: r'venue')
  String? get venue;

  @BuiltValueField(wireName: r'periodCount')
  int? get periodCount;

  @BuiltValueField(wireName: r'periodMinutes')
  int? get periodMinutes;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateMatchRequestClearEnum>? get clear;
  // enum clearEnum {  venue,  };

  UpdateMatchRequest._();

  factory UpdateMatchRequest([void updates(UpdateMatchRequestBuilder b)]) = _$UpdateMatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateMatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateMatchRequest> get serializer => _$UpdateMatchRequestSerializer();
}

class _$UpdateMatchRequestSerializer implements PrimitiveSerializer<UpdateMatchRequest> {
  @override
  final Iterable<Type> types = const [UpdateMatchRequest, _$UpdateMatchRequest];

  @override
  final String wireName = r'UpdateMatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateMatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.opponentName != null) {
      yield r'opponentName';
      yield serializers.serialize(
        object.opponentName,
        specifiedType: const FullType(String),
      );
    }
    if (object.homeAway != null) {
      yield r'homeAway';
      yield serializers.serialize(
        object.homeAway,
        specifiedType: const FullType(HomeAway),
      );
    }
    if (object.scheduledAt != null) {
      yield r'scheduledAt';
      yield serializers.serialize(
        object.scheduledAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.venue != null) {
      yield r'venue';
      yield serializers.serialize(
        object.venue,
        specifiedType: const FullType.nullable(String),
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
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateMatchRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateMatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateMatchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'opponentName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.opponentName = valueDes;
          break;
        case r'homeAway':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(HomeAway),
          ) as HomeAway?;
          if (valueDes == null) continue;
          result.homeAway = valueDes;
          break;
        case r'scheduledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateMatchRequestClearEnum)]),
          ) as BuiltSet<UpdateMatchRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateMatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateMatchRequestBuilder();
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


class UpdateMatchRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'venue')
  static const UpdateMatchRequestClearEnum venue = _$updateMatchRequestClearEnum_venue;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateMatchRequestClearEnum unknownDefaultOpenApi = _$updateMatchRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateMatchRequestClearEnum> get serializer => _$updateMatchRequestClearEnumSerializer;

  const UpdateMatchRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateMatchRequestClearEnum> get values => _$updateMatchRequestClearEnumValues;
  static UpdateMatchRequestClearEnum valueOf(String name) => _$updateMatchRequestClearEnumValueOf(name);
}

