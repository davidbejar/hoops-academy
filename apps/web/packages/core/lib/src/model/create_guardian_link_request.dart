//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_guardian_link_request.g.dart';

/// CreateGuardianLinkRequest
///
/// Properties:
/// * [guardianPersonId]
/// * [playerId]
@BuiltValue()
abstract class CreateGuardianLinkRequest
    implements
        Built<CreateGuardianLinkRequest, CreateGuardianLinkRequestBuilder> {
  @BuiltValueField(wireName: r'guardianPersonId')
  String get guardianPersonId;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  CreateGuardianLinkRequest._();

  factory CreateGuardianLinkRequest(
          [void updates(CreateGuardianLinkRequestBuilder b)]) =
      _$CreateGuardianLinkRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateGuardianLinkRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateGuardianLinkRequest> get serializer =>
      _$CreateGuardianLinkRequestSerializer();
}

class _$CreateGuardianLinkRequestSerializer
    implements PrimitiveSerializer<CreateGuardianLinkRequest> {
  @override
  final Iterable<Type> types = const [
    CreateGuardianLinkRequest,
    _$CreateGuardianLinkRequest
  ];

  @override
  final String wireName = r'CreateGuardianLinkRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateGuardianLinkRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'guardianPersonId';
    yield serializers.serialize(
      object.guardianPersonId,
      specifiedType: const FullType(String),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateGuardianLinkRequest object, {
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
    required CreateGuardianLinkRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'guardianPersonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.guardianPersonId = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateGuardianLinkRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateGuardianLinkRequestBuilder();
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
