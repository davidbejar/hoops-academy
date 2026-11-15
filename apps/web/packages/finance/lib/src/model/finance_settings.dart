//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finance_settings.g.dart';

/// FinanceSettings
///
/// Properties:
/// * [currency] - null until ADMIN chooses it.
/// * [minorDigits] - Decimals of the currency's minor unit (EUR 2, JPY 0, BHD 3); null without a currency.
/// * [currencyLocked] - true once the first due exists; the currency cannot change any more.
@BuiltValue()
abstract class FinanceSettings implements Built<FinanceSettings, FinanceSettingsBuilder> {
  /// null until ADMIN chooses it.
  @BuiltValueField(wireName: r'currency')
  String? get currency;

  /// Decimals of the currency's minor unit (EUR 2, JPY 0, BHD 3); null without a currency.
  @BuiltValueField(wireName: r'minorDigits')
  int? get minorDigits;

  /// true once the first due exists; the currency cannot change any more.
  @BuiltValueField(wireName: r'currencyLocked')
  bool get currencyLocked;

  FinanceSettings._();

  factory FinanceSettings([void updates(FinanceSettingsBuilder b)]) = _$FinanceSettings;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FinanceSettingsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FinanceSettings> get serializer => _$FinanceSettingsSerializer();
}

class _$FinanceSettingsSerializer implements PrimitiveSerializer<FinanceSettings> {
  @override
  final Iterable<Type> types = const [FinanceSettings, _$FinanceSettings];

  @override
  final String wireName = r'FinanceSettings';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FinanceSettings object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'currency';
    yield object.currency == null ? null : serializers.serialize(
      object.currency,
      specifiedType: const FullType.nullable(String),
    );
    yield r'minorDigits';
    yield object.minorDigits == null ? null : serializers.serialize(
      object.minorDigits,
      specifiedType: const FullType.nullable(int),
    );
    yield r'currencyLocked';
    yield serializers.serialize(
      object.currencyLocked,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FinanceSettings object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FinanceSettingsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.currency = valueDes;
          break;
        case r'minorDigits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.minorDigits = valueDes;
          break;
        case r'currencyLocked':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.currencyLocked = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FinanceSettings deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FinanceSettingsBuilder();
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
