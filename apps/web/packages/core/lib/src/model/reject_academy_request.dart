//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reject_academy_request.g.dart';

/// RejectAcademyRequest
///
/// Properties:
/// * [reason] - Sent to the requester in the e-mail; write it for them.
@BuiltValue()
abstract class RejectAcademyRequest
    implements Built<RejectAcademyRequest, RejectAcademyRequestBuilder> {
  /// Sent to the requester in the e-mail; write it for them.
  @BuiltValueField(wireName: r'reason')
  String get reason;

  RejectAcademyRequest._();

  factory RejectAcademyRequest([void updates(RejectAcademyRequestBuilder b)]) =
      _$RejectAcademyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RejectAcademyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RejectAcademyRequest> get serializer =>
      _$RejectAcademyRequestSerializer();
}

class _$RejectAcademyRequestSerializer
    implements PrimitiveSerializer<RejectAcademyRequest> {
  @override
  final Iterable<Type> types = const [
    RejectAcademyRequest,
    _$RejectAcademyRequest
  ];

  @override
  final String wireName = r'RejectAcademyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RejectAcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RejectAcademyRequest object, {
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
    required RejectAcademyRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RejectAcademyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RejectAcademyRequestBuilder();
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
