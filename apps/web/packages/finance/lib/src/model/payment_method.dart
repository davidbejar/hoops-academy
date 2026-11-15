//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_method.g.dart';

class PaymentMethod extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CASH')
  static const PaymentMethod CASH = _$CASH;
  @BuiltValueEnumConst(wireName: r'BANK_TRANSFER')
  static const PaymentMethod BANK_TRANSFER = _$BANK_TRANSFER;
  @BuiltValueEnumConst(wireName: r'CARD')
  static const PaymentMethod CARD = _$CARD;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const PaymentMethod OTHER = _$OTHER;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PaymentMethod unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<PaymentMethod> get serializer => _$paymentMethodSerializer;

  const PaymentMethod._(String name): super(name);

  static BuiltSet<PaymentMethod> get values => _$values;
  static PaymentMethod valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PaymentMethodMixin = Object with _$PaymentMethodMixin;
