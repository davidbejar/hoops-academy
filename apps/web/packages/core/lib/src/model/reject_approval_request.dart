//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reject_approval_request.g.dart';

/// RejectApprovalRequest
///
/// Properties:
/// * [note] - Reason of the rejection (must contain non-whitespace text).
@BuiltValue()
abstract class RejectApprovalRequest implements Built<RejectApprovalRequest, RejectApprovalRequestBuilder> {
  /// Reason of the rejection (must contain non-whitespace text).
  @BuiltValueField(wireName: r'note')
  String get note;

  RejectApprovalRequest._();

  factory RejectApprovalRequest([void updates(RejectApprovalRequestBuilder b)]) = _$RejectApprovalRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RejectApprovalRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RejectApprovalRequest> get serializer => _$RejectApprovalRequestSerializer();
}

class _$RejectApprovalRequestSerializer implements PrimitiveSerializer<RejectApprovalRequest> {
  @override
  final Iterable<Type> types = const [RejectApprovalRequest, _$RejectApprovalRequest];

  @override
  final String wireName = r'RejectApprovalRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RejectApprovalRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'note';
    yield serializers.serialize(
      object.note,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RejectApprovalRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RejectApprovalRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RejectApprovalRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RejectApprovalRequestBuilder();
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


