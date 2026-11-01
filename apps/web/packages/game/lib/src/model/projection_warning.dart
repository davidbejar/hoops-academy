//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'projection_warning.g.dart';

/// Domain inconsistency found while projecting (events are never rejected for these).
///
/// Properties:
/// * [code] - Open set (new codes may appear; clients must tolerate unknown values), e.g. SUB_IN_PLAYER_ON_COURT, SUB_OUT_PLAYER_NOT_ON_COURT, PLAYER_NOT_IN_ROSTER, VOID_TARGET_NOT_FOUND, EVENT_OUTSIDE_PERIOD. 
/// * [eventId] 
/// * [playerId] 
/// * [message] 
@BuiltValue()
abstract class ProjectionWarning implements Built<ProjectionWarning, ProjectionWarningBuilder> {
  /// Open set (new codes may appear; clients must tolerate unknown values), e.g. SUB_IN_PLAYER_ON_COURT, SUB_OUT_PLAYER_NOT_ON_COURT, PLAYER_NOT_IN_ROSTER, VOID_TARGET_NOT_FOUND, EVENT_OUTSIDE_PERIOD. 
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'playerId')
  String? get playerId;

  @BuiltValueField(wireName: r'message')
  String get message;

  ProjectionWarning._();

  factory ProjectionWarning([void updates(ProjectionWarningBuilder b)]) = _$ProjectionWarning;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProjectionWarningBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProjectionWarning> get serializer => _$ProjectionWarningSerializer();
}

class _$ProjectionWarningSerializer implements PrimitiveSerializer<ProjectionWarning> {
  @override
  final Iterable<Type> types = const [ProjectionWarning, _$ProjectionWarning];

  @override
  final String wireName = r'ProjectionWarning';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProjectionWarning object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'eventId';
    yield serializers.serialize(
      object.eventId,
      specifiedType: const FullType(String),
    );
    if (object.playerId != null) {
      yield r'playerId';
      yield serializers.serialize(
        object.playerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProjectionWarning object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProjectionWarningBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'eventId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.eventId = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.playerId = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProjectionWarning deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProjectionWarningBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


