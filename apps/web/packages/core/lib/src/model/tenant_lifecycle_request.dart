//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_lifecycle_request.g.dart';

/// TenantLifecycleRequest
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class TenantLifecycleRequest implements Built<TenantLifecycleRequest, TenantLifecycleRequestBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  TenantLifecycleRequest._();

  factory TenantLifecycleRequest([void updates(TenantLifecycleRequestBuilder b)]) = _$TenantLifecycleRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantLifecycleRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantLifecycleRequest> get serializer => _$TenantLifecycleRequestSerializer();
}

class _$TenantLifecycleRequestSerializer implements PrimitiveSerializer<TenantLifecycleRequest> {
  @override
  final Iterable<Type> types = const [TenantLifecycleRequest, _$TenantLifecycleRequest];

  @override
  final String wireName = r'TenantLifecycleRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantLifecycleRequest object, {
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
    TenantLifecycleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantLifecycleRequestBuilder result,
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
  TenantLifecycleRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantLifecycleRequestBuilder();
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


