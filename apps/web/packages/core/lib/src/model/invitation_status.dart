//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'invitation_status.g.dart';

/// NONE = person without login; PENDING = login created by this academy, the person has not signed in here yet (a temporary password can be issued); ACCEPTED = signed in, or an existing login was linked.
class InvitationStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'NONE')
  static const InvitationStatus NONE = _$NONE;
  @BuiltValueEnumConst(wireName: r'PENDING')
  static const InvitationStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const InvitationStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const InvitationStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<InvitationStatus> get serializer =>
      _$invitationStatusSerializer;

  const InvitationStatus._(String name) : super(name);

  static BuiltSet<InvitationStatus> get values => _$values;
  static InvitationStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class InvitationStatusMixin = Object with _$InvitationStatusMixin;
