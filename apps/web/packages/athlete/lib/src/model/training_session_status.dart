//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_session_status.g.dart';

class TrainingSessionStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PLANNED')
  static const TrainingSessionStatus PLANNED = _$PLANNED;
  @BuiltValueEnumConst(wireName: r'DONE')
  static const TrainingSessionStatus DONE = _$DONE;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const TrainingSessionStatus CANCELLED = _$CANCELLED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TrainingSessionStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<TrainingSessionStatus> get serializer => _$trainingSessionStatusSerializer;

  const TrainingSessionStatus._(String name): super(name);

  static BuiltSet<TrainingSessionStatus> get values => _$values;
  static TrainingSessionStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TrainingSessionStatusMixin = Object with _$TrainingSessionStatusMixin;

