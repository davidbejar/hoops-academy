//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_rejection_reason.g.dart';

/// SCHEMA_INVALID — event does not match its type's schema; NOT_AUTHORIZED — caller may not enter this event (e.g. PARENT for a non-linked player, VOID of someone else's event); MATCH_CANCELLED — match is CANCELLED; CLIENT_SEQ_CONFLICT — (deviceId, clientSeq) already used by a different event id. 
class MatchEventRejectionReason extends EnumClass {

  @BuiltValueEnumConst(wireName: r'SCHEMA_INVALID')
  static const MatchEventRejectionReason SCHEMA_INVALID = _$SCHEMA_INVALID;
  @BuiltValueEnumConst(wireName: r'NOT_AUTHORIZED')
  static const MatchEventRejectionReason NOT_AUTHORIZED = _$NOT_AUTHORIZED;
  @BuiltValueEnumConst(wireName: r'MATCH_CANCELLED')
  static const MatchEventRejectionReason MATCH_CANCELLED = _$MATCH_CANCELLED;
  @BuiltValueEnumConst(wireName: r'CLIENT_SEQ_CONFLICT')
  static const MatchEventRejectionReason CLIENT_SEQ_CONFLICT = _$CLIENT_SEQ_CONFLICT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MatchEventRejectionReason unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<MatchEventRejectionReason> get serializer => _$matchEventRejectionReasonSerializer;

  const MatchEventRejectionReason._(String name): super(name);

  static BuiltSet<MatchEventRejectionReason> get values => _$values;
  static MatchEventRejectionReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class MatchEventRejectionReasonMixin = Object with _$MatchEventRejectionReasonMixin;

