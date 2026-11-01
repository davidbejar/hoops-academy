// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completion_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CompletionStatus _$DONE = const CompletionStatus._('DONE');
const CompletionStatus _$PARTIAL = const CompletionStatus._('PARTIAL');
const CompletionStatus _$NOT_DONE = const CompletionStatus._('NOT_DONE');
const CompletionStatus _$unknownDefaultOpenApi =
    const CompletionStatus._('unknownDefaultOpenApi');

CompletionStatus _$valueOf(String name) {
  switch (name) {
    case 'DONE':
      return _$DONE;
    case 'PARTIAL':
      return _$PARTIAL;
    case 'NOT_DONE':
      return _$NOT_DONE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<CompletionStatus> _$values =
    BuiltSet<CompletionStatus>(const <CompletionStatus>[
  _$DONE,
  _$PARTIAL,
  _$NOT_DONE,
  _$unknownDefaultOpenApi,
]);

class _$CompletionStatusMeta {
  const _$CompletionStatusMeta();
  CompletionStatus get DONE => _$DONE;
  CompletionStatus get PARTIAL => _$PARTIAL;
  CompletionStatus get NOT_DONE => _$NOT_DONE;
  CompletionStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  CompletionStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<CompletionStatus> get values => _$values;
}

abstract class _$CompletionStatusMixin {
  // ignore: non_constant_identifier_names
  _$CompletionStatusMeta get CompletionStatus => const _$CompletionStatusMeta();
}

Serializer<CompletionStatus> _$completionStatusSerializer =
    _$CompletionStatusSerializer();

class _$CompletionStatusSerializer
    implements PrimitiveSerializer<CompletionStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DONE': 'DONE',
    'PARTIAL': 'PARTIAL',
    'NOT_DONE': 'NOT_DONE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DONE': 'DONE',
    'PARTIAL': 'PARTIAL',
    'NOT_DONE': 'NOT_DONE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[CompletionStatus];
  @override
  final String wireName = 'CompletionStatus';

  @override
  Object serialize(Serializers serializers, CompletionStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CompletionStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CompletionStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
