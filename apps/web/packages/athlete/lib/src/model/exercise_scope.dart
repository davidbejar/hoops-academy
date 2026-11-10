//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'exercise_scope.g.dart';

class ExerciseScope extends EnumClass {

  @BuiltValueEnumConst(wireName: r'GLOBAL')
  static const ExerciseScope GLOBAL = _$GLOBAL;
  @BuiltValueEnumConst(wireName: r'TENANT')
  static const ExerciseScope TENANT = _$TENANT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ExerciseScope unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ExerciseScope> get serializer => _$exerciseScopeSerializer;

  const ExerciseScope._(String name): super(name);

  static BuiltSet<ExerciseScope> get values => _$values;
  static ExerciseScope valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ExerciseScopeMixin = Object with _$ExerciseScopeMixin;

