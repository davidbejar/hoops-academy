//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'band_status.g.dart';

/// How `expectedBand` was resolved: MATCHED — a norm covers (gender, age, value); NO_NORM — no effective norm covers it (`expectedBand` null); MISSING_PLAYER_DATA — core has no birth date or gender for the player (`expectedBand` null, `ageAtMeasurement` null when the birth date is missing). 
class BandStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MATCHED')
  static const BandStatus MATCHED = _$MATCHED;
  @BuiltValueEnumConst(wireName: r'NO_NORM')
  static const BandStatus NO_NORM = _$NO_NORM;
  @BuiltValueEnumConst(wireName: r'MISSING_PLAYER_DATA')
  static const BandStatus MISSING_PLAYER_DATA = _$MISSING_PLAYER_DATA;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const BandStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<BandStatus> get serializer => _$bandStatusSerializer;

  const BandStatus._(String name): super(name);

  static BuiltSet<BandStatus> get values => _$values;
  static BandStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class BandStatusMixin = Object with _$BandStatusMixin;

