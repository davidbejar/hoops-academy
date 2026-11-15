// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PaymentMethod _$CASH = const PaymentMethod._('CASH');
const PaymentMethod _$BANK_TRANSFER = const PaymentMethod._('BANK_TRANSFER');
const PaymentMethod _$CARD = const PaymentMethod._('CARD');
const PaymentMethod _$OTHER = const PaymentMethod._('OTHER');
const PaymentMethod _$unknownDefaultOpenApi =
    const PaymentMethod._('unknownDefaultOpenApi');

PaymentMethod _$valueOf(String name) {
  switch (name) {
    case 'CASH':
      return _$CASH;
    case 'BANK_TRANSFER':
      return _$BANK_TRANSFER;
    case 'CARD':
      return _$CARD;
    case 'OTHER':
      return _$OTHER;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<PaymentMethod> _$values =
    BuiltSet<PaymentMethod>(const <PaymentMethod>[
  _$CASH,
  _$BANK_TRANSFER,
  _$CARD,
  _$OTHER,
  _$unknownDefaultOpenApi,
]);

class _$PaymentMethodMeta {
  const _$PaymentMethodMeta();
  PaymentMethod get CASH => _$CASH;
  PaymentMethod get BANK_TRANSFER => _$BANK_TRANSFER;
  PaymentMethod get CARD => _$CARD;
  PaymentMethod get OTHER => _$OTHER;
  PaymentMethod get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  PaymentMethod valueOf(String name) => _$valueOf(name);
  BuiltSet<PaymentMethod> get values => _$values;
}

abstract class _$PaymentMethodMixin {
  // ignore: non_constant_identifier_names
  _$PaymentMethodMeta get PaymentMethod => const _$PaymentMethodMeta();
}

Serializer<PaymentMethod> _$paymentMethodSerializer =
    _$PaymentMethodSerializer();

class _$PaymentMethodSerializer implements PrimitiveSerializer<PaymentMethod> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CASH': 'CASH',
    'BANK_TRANSFER': 'BANK_TRANSFER',
    'CARD': 'CARD',
    'OTHER': 'OTHER',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CASH': 'CASH',
    'BANK_TRANSFER': 'BANK_TRANSFER',
    'CARD': 'CARD',
    'OTHER': 'OTHER',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[PaymentMethod];
  @override
  final String wireName = 'PaymentMethod';

  @override
  Object serialize(Serializers serializers, PaymentMethod object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PaymentMethod deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PaymentMethod.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
