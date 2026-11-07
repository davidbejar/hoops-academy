//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'temporary_password_status.g.dart';

/// State of the temporary password of the person's login (ADR-0028). ACTIVE = issued and not used yet (it still signs in until it expires); EXPIRED = not used in time: the login is disabled until a new temporary password is issued (re-issue while the invitation is PENDING); NONE = no login, or no temporary password outstanding (the person chose their own password, or the login was linked as it was).
class TemporaryPasswordStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ACTIVE')
  static const TemporaryPasswordStatus ACTIVE = _$ACTIVE;
  @BuiltValueEnumConst(wireName: r'EXPIRED')
  static const TemporaryPasswordStatus EXPIRED = _$EXPIRED;
  @BuiltValueEnumConst(wireName: r'NONE')
  static const TemporaryPasswordStatus NONE = _$NONE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TemporaryPasswordStatus unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<TemporaryPasswordStatus> get serializer =>
      _$temporaryPasswordStatusSerializer;

  const TemporaryPasswordStatus._(String name) : super(name);

  static BuiltSet<TemporaryPasswordStatus> get values => _$values;
  static TemporaryPasswordStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TemporaryPasswordStatusMixin = Object
    with _$TemporaryPasswordStatusMixin;
