//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'change_due_amount_request.g.dart';

/// ChangeDueAmountRequest
///
/// Properties:
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [reason] - Why (short). Never health or family details, never a named person's salary (P-12). Read by ADMIN only; never logged or put in audit metadata.
@BuiltValue()
abstract class ChangeDueAmountRequest implements Built<ChangeDueAmountRequest, ChangeDueAmountRequestBuilder> {
  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// Why (short). Never health or family details, never a named person's salary (P-12). Read by ADMIN only; never logged or put in audit metadata.
  @BuiltValueField(wireName: r'reason')
  String get reason;

  ChangeDueAmountRequest._();

  factory ChangeDueAmountRequest([void updates(ChangeDueAmountRequestBuilder b)]) = _$ChangeDueAmountRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChangeDueAmountRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ChangeDueAmountRequest> get serializer => _$ChangeDueAmountRequestSerializer();
}

class _$ChangeDueAmountRequestSerializer implements PrimitiveSerializer<ChangeDueAmountRequest> {
  @override
  final Iterable<Type> types = const [ChangeDueAmountRequest, _$ChangeDueAmountRequest];

  @override
  final String wireName = r'ChangeDueAmountRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ChangeDueAmountRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ChangeDueAmountRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChangeDueAmountRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
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
  ChangeDueAmountRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChangeDueAmountRequestBuilder();
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
