//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/payment_method.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pay_due_request.g.dart';

/// PayDueRequest
///
/// Properties:
/// * [paidOn]
/// * [method]
/// * [note] - Short; never health or family details (P-12).
@BuiltValue()
abstract class PayDueRequest implements Built<PayDueRequest, PayDueRequestBuilder> {
  @BuiltValueField(wireName: r'paidOn')
  Date get paidOn;

  @BuiltValueField(wireName: r'method')
  PaymentMethod get method;
  // enum methodEnum {  CASH,  BANK_TRANSFER,  CARD,  OTHER,  };

  /// Short; never health or family details (P-12).
  @BuiltValueField(wireName: r'note')
  String? get note;

  PayDueRequest._();

  factory PayDueRequest([void updates(PayDueRequestBuilder b)]) = _$PayDueRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PayDueRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PayDueRequest> get serializer => _$PayDueRequestSerializer();
}

class _$PayDueRequestSerializer implements PrimitiveSerializer<PayDueRequest> {
  @override
  final Iterable<Type> types = const [PayDueRequest, _$PayDueRequest];

  @override
  final String wireName = r'PayDueRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PayDueRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'paidOn';
    yield serializers.serialize(
      object.paidOn,
      specifiedType: const FullType(Date),
    );
    yield r'method';
    yield serializers.serialize(
      object.method,
      specifiedType: const FullType(PaymentMethod),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PayDueRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PayDueRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'paidOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.paidOn = valueDes;
          break;
        case r'method':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaymentMethod),
          ) as PaymentMethod;
          result.method = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  PayDueRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PayDueRequestBuilder();
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
