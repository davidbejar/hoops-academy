// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_scope.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ExerciseScope _$GLOBAL = const ExerciseScope._('GLOBAL');
const ExerciseScope _$TENANT = const ExerciseScope._('TENANT');
const ExerciseScope _$unknownDefaultOpenApi =
    const ExerciseScope._('unknownDefaultOpenApi');

ExerciseScope _$valueOf(String name) {
  switch (name) {
    case 'GLOBAL':
      return _$GLOBAL;
    case 'TENANT':
      return _$TENANT;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<ExerciseScope> _$values =
    BuiltSet<ExerciseScope>(const <ExerciseScope>[
  _$GLOBAL,
  _$TENANT,
  _$unknownDefaultOpenApi,
]);

class _$ExerciseScopeMeta {
  const _$ExerciseScopeMeta();
  ExerciseScope get GLOBAL => _$GLOBAL;
  ExerciseScope get TENANT => _$TENANT;
  ExerciseScope get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  ExerciseScope valueOf(String name) => _$valueOf(name);
  BuiltSet<ExerciseScope> get values => _$values;
}

abstract class _$ExerciseScopeMixin {
  // ignore: non_constant_identifier_names
  _$ExerciseScopeMeta get ExerciseScope => const _$ExerciseScopeMeta();
}

Serializer<ExerciseScope> _$exerciseScopeSerializer =
    _$ExerciseScopeSerializer();

class _$ExerciseScopeSerializer implements PrimitiveSerializer<ExerciseScope> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'GLOBAL': 'GLOBAL',
    'TENANT': 'TENANT',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'GLOBAL': 'GLOBAL',
    'TENANT': 'TENANT',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ExerciseScope];
  @override
  final String wireName = 'ExerciseScope';

  @override
  Object serialize(Serializers serializers, ExerciseScope object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ExerciseScope deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ExerciseScope.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
