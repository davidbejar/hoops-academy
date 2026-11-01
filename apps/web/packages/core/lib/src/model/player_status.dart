//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_status.g.dart';

/// PENDING_APPROVAL — requested by a coach, awaiting an admin decision; ACTIVE — has a valid assignment in a current season; ORPHAN — active but without a valid assignment; WITHDRAWN — left the academy (withdrawal approved, or a pending ADD_PLAYER request cancelled by its requester); REJECTED — an ADD_PLAYER request for this player was rejected (never admitted). WITHDRAWN and REJECTED are final. 
class PlayerStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING_APPROVAL')
  static const PlayerStatus PENDING_APPROVAL = _$PENDING_APPROVAL;
  @BuiltValueEnumConst(wireName: r'ACTIVE')
  static const PlayerStatus ACTIVE = _$ACTIVE;
  @BuiltValueEnumConst(wireName: r'ORPHAN')
  static const PlayerStatus ORPHAN = _$ORPHAN;
  @BuiltValueEnumConst(wireName: r'WITHDRAWN')
  static const PlayerStatus WITHDRAWN = _$WITHDRAWN;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const PlayerStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const PlayerStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<PlayerStatus> get serializer => _$playerStatusSerializer;

  const PlayerStatus._(String name): super(name);

  static BuiltSet<PlayerStatus> get values => _$values;
  static PlayerStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PlayerStatusMixin = Object with _$PlayerStatusMixin;

