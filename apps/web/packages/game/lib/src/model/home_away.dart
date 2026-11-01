//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'home_away.g.dart';

class HomeAway extends EnumClass {

  @BuiltValueEnumConst(wireName: r'HOME')
  static const HomeAway HOME = _$HOME;
  @BuiltValueEnumConst(wireName: r'AWAY')
  static const HomeAway AWAY = _$AWAY;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const HomeAway unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<HomeAway> get serializer => _$homeAwaySerializer;

  const HomeAway._(String name): super(name);

  static BuiltSet<HomeAway> get values => _$values;
  static HomeAway valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class HomeAwayMixin = Object with _$HomeAwayMixin;

