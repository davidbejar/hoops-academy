//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_team_player_request.g.dart';

/// UpdateTeamPlayerRequest
///
/// Properties:
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTeamPlayerRequest
    implements Built<UpdateTeamPlayerRequest, UpdateTeamPlayerRequestBuilder> {
  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTeamPlayerRequestClearEnum>? get clear;
  // enum clearEnum {  jerseyNumber,  };

  UpdateTeamPlayerRequest._();

  factory UpdateTeamPlayerRequest(
          [void updates(UpdateTeamPlayerRequestBuilder b)]) =
      _$UpdateTeamPlayerRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTeamPlayerRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTeamPlayerRequest> get serializer =>
      _$UpdateTeamPlayerRequestSerializer();
}

class _$UpdateTeamPlayerRequestSerializer
    implements PrimitiveSerializer<UpdateTeamPlayerRequest> {
  @override
  final Iterable<Type> types = const [
    UpdateTeamPlayerRequest,
    _$UpdateTeamPlayerRequest
  ];

  @override
  final String wireName = r'UpdateTeamPlayerRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTeamPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(
            BuiltSet, [FullType(UpdateTeamPlayerRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTeamPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(
                BuiltSet, [FullType(UpdateTeamPlayerRequestClearEnum)]),
          ) as BuiltSet<UpdateTeamPlayerRequestClearEnum>?;
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

class UpdateTeamPlayerRequestClearEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'jerseyNumber')
  static const UpdateTeamPlayerRequestClearEnum jerseyNumber =
      _$updateTeamPlayerRequestClearEnum_jerseyNumber;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTeamPlayerRequestClearEnum unknownDefaultOpenApi =
      _$updateTeamPlayerRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTeamPlayerRequestClearEnum> get serializer =>
      _$updateTeamPlayerRequestClearEnumSerializer;

  const UpdateTeamPlayerRequestClearEnum._(String name) : super(name);

  static BuiltSet<UpdateTeamPlayerRequestClearEnum> get values =>
      _$updateTeamPlayerRequestClearEnumValues;
  static UpdateTeamPlayerRequestClearEnum valueOf(String name) =>
      _$updateTeamPlayerRequestClearEnumValueOf(name);
}
