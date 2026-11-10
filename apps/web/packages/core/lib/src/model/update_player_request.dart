//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_player_request.g.dart';

/// UpdatePlayerRequest
///
/// Properties:
/// * [preferredJerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdatePlayerRequest implements Built<UpdatePlayerRequest, UpdatePlayerRequestBuilder> {
  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'preferredJerseyNumber')
  String? get preferredJerseyNumber;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdatePlayerRequestClearEnum>? get clear;
  // enum clearEnum {  preferredJerseyNumber,  };

  UpdatePlayerRequest._();

  factory UpdatePlayerRequest([void updates(UpdatePlayerRequestBuilder b)]) = _$UpdatePlayerRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePlayerRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePlayerRequest> get serializer => _$UpdatePlayerRequestSerializer();
}

class _$UpdatePlayerRequestSerializer implements PrimitiveSerializer<UpdatePlayerRequest> {
  @override
  final Iterable<Type> types = const [UpdatePlayerRequest, _$UpdatePlayerRequest];

  @override
  final String wireName = r'UpdatePlayerRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.preferredJerseyNumber != null) {
      yield r'preferredJerseyNumber';
      yield serializers.serialize(
        object.preferredJerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdatePlayerRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePlayerRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'preferredJerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.preferredJerseyNumber = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdatePlayerRequestClearEnum)]),
          ) as BuiltSet<UpdatePlayerRequestClearEnum>?;
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
  UpdatePlayerRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePlayerRequestBuilder();
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


class UpdatePlayerRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'preferredJerseyNumber')
  static const UpdatePlayerRequestClearEnum preferredJerseyNumber = _$updatePlayerRequestClearEnum_preferredJerseyNumber;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdatePlayerRequestClearEnum unknownDefaultOpenApi = _$updatePlayerRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdatePlayerRequestClearEnum> get serializer => _$updatePlayerRequestClearEnumSerializer;

  const UpdatePlayerRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdatePlayerRequestClearEnum> get values => _$updatePlayerRequestClearEnumValues;
  static UpdatePlayerRequestClearEnum valueOf(String name) => _$updatePlayerRequestClearEnumValueOf(name);
}

