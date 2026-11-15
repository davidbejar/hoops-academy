// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DueStatus _$OPEN = const DueStatus._('OPEN');
const DueStatus _$PAID = const DueStatus._('PAID');
const DueStatus _$WAIVED = const DueStatus._('WAIVED');
const DueStatus _$unknownDefaultOpenApi =
    const DueStatus._('unknownDefaultOpenApi');

DueStatus _$valueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$OPEN;
    case 'PAID':
      return _$PAID;
    case 'WAIVED':
      return _$WAIVED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<DueStatus> _$values = BuiltSet<DueStatus>(const <DueStatus>[
  _$OPEN,
  _$PAID,
  _$WAIVED,
  _$unknownDefaultOpenApi,
]);

class _$DueStatusMeta {
  const _$DueStatusMeta();
  DueStatus get OPEN => _$OPEN;
  DueStatus get PAID => _$PAID;
  DueStatus get WAIVED => _$WAIVED;
  DueStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  DueStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DueStatus> get values => _$values;
}

abstract class _$DueStatusMixin {
  // ignore: non_constant_identifier_names
  _$DueStatusMeta get DueStatus => const _$DueStatusMeta();
}

Serializer<DueStatus> _$dueStatusSerializer = _$DueStatusSerializer();

class _$DueStatusSerializer implements PrimitiveSerializer<DueStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'PAID': 'PAID',
    'WAIVED': 'WAIVED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'PAID': 'PAID',
    'WAIVED': 'WAIVED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[DueStatus];
  @override
  final String wireName = 'DueStatus';

  @override
  Object serialize(Serializers serializers, DueStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DueStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DueStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
