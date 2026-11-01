// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TrainingSessionStatus _$PLANNED =
    const TrainingSessionStatus._('PLANNED');
const TrainingSessionStatus _$DONE = const TrainingSessionStatus._('DONE');
const TrainingSessionStatus _$CANCELLED =
    const TrainingSessionStatus._('CANCELLED');
const TrainingSessionStatus _$unknownDefaultOpenApi =
    const TrainingSessionStatus._('unknownDefaultOpenApi');

TrainingSessionStatus _$valueOf(String name) {
  switch (name) {
    case 'PLANNED':
      return _$PLANNED;
    case 'DONE':
      return _$DONE;
    case 'CANCELLED':
      return _$CANCELLED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<TrainingSessionStatus> _$values =
    BuiltSet<TrainingSessionStatus>(const <TrainingSessionStatus>[
  _$PLANNED,
  _$DONE,
  _$CANCELLED,
  _$unknownDefaultOpenApi,
]);

class _$TrainingSessionStatusMeta {
  const _$TrainingSessionStatusMeta();
  TrainingSessionStatus get PLANNED => _$PLANNED;
  TrainingSessionStatus get DONE => _$DONE;
  TrainingSessionStatus get CANCELLED => _$CANCELLED;
  TrainingSessionStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  TrainingSessionStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<TrainingSessionStatus> get values => _$values;
}

abstract class _$TrainingSessionStatusMixin {
  // ignore: non_constant_identifier_names
  _$TrainingSessionStatusMeta get TrainingSessionStatus =>
      const _$TrainingSessionStatusMeta();
}

Serializer<TrainingSessionStatus> _$trainingSessionStatusSerializer =
    _$TrainingSessionStatusSerializer();

class _$TrainingSessionStatusSerializer
    implements PrimitiveSerializer<TrainingSessionStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PLANNED': 'PLANNED',
    'DONE': 'DONE',
    'CANCELLED': 'CANCELLED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PLANNED': 'PLANNED',
    'DONE': 'DONE',
    'CANCELLED': 'CANCELLED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TrainingSessionStatus];
  @override
  final String wireName = 'TrainingSessionStatus';

  @override
  Object serialize(Serializers serializers, TrainingSessionStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TrainingSessionStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TrainingSessionStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
