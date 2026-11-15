//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_finance_settings_request.g.dart';

/// UpdateFinanceSettingsRequest
///
/// Properties:
/// * [currency] - Alphabetic ISO 4217 code of the academy's currency.
@BuiltValue()
abstract class UpdateFinanceSettingsRequest implements Built<UpdateFinanceSettingsRequest, UpdateFinanceSettingsRequestBuilder> {
  /// Alphabetic ISO 4217 code of the academy's currency.
  @BuiltValueField(wireName: r'currency')
  String get currency;

  UpdateFinanceSettingsRequest._();

  factory UpdateFinanceSettingsRequest([void updates(UpdateFinanceSettingsRequestBuilder b)]) = _$UpdateFinanceSettingsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateFinanceSettingsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateFinanceSettingsRequest> get serializer => _$UpdateFinanceSettingsRequestSerializer();
}

class _$UpdateFinanceSettingsRequestSerializer implements PrimitiveSerializer<UpdateFinanceSettingsRequest> {
  @override
  final Iterable<Type> types = const [UpdateFinanceSettingsRequest, _$UpdateFinanceSettingsRequest];

  @override
  final String wireName = r'UpdateFinanceSettingsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateFinanceSettingsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateFinanceSettingsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateFinanceSettingsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateFinanceSettingsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateFinanceSettingsRequestBuilder();
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
