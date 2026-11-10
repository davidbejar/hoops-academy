//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'jersey_source.g.dart';

/// Which rule numbered a new assignment (ADR-0048): REQUESTED = the number given in the request; PREFERRED = the player's preferred number; PREVIOUS = the number of the player's most recent assignment that had one; NONE = no number (none given, and neither the preferred nor the previous number was free, or the player has neither). 
class JerseySource extends EnumClass {

  @BuiltValueEnumConst(wireName: r'REQUESTED')
  static const JerseySource REQUESTED = _$REQUESTED;
  @BuiltValueEnumConst(wireName: r'PREFERRED')
  static const JerseySource PREFERRED = _$PREFERRED;
  @BuiltValueEnumConst(wireName: r'PREVIOUS')
  static const JerseySource PREVIOUS = _$PREVIOUS;
  @BuiltValueEnumConst(wireName: r'NONE')
  static const JerseySource NONE = _$NONE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const JerseySource unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<JerseySource> get serializer => _$jerseySourceSerializer;

  const JerseySource._(String name): super(name);

  static BuiltSet<JerseySource> get values => _$values;
  static JerseySource valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class JerseySourceMixin = Object with _$JerseySourceMixin;

