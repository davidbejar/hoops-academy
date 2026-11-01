//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'norm_band.g.dart';

/// Expected performance band, worst to best.
class NormBand extends EnumClass {

  @BuiltValueEnumConst(wireName: r'POOR')
  static const NormBand POOR = _$POOR;
  @BuiltValueEnumConst(wireName: r'BELOW_AVERAGE')
  static const NormBand BELOW_AVERAGE = _$BELOW_AVERAGE;
  @BuiltValueEnumConst(wireName: r'AVERAGE')
  static const NormBand AVERAGE = _$AVERAGE;
  @BuiltValueEnumConst(wireName: r'ABOVE_AVERAGE')
  static const NormBand ABOVE_AVERAGE = _$ABOVE_AVERAGE;
  @BuiltValueEnumConst(wireName: r'EXCELLENT')
  static const NormBand EXCELLENT = _$EXCELLENT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const NormBand unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<NormBand> get serializer => _$normBandSerializer;

  const NormBand._(String name): super(name);

  static BuiltSet<NormBand> get values => _$values;
  static NormBand valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class NormBandMixin = Object with _$NormBandMixin;

