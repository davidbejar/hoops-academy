//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_backfill.g.dart';

/// EventBackfill
///
/// Properties:
/// * [force]
/// * [tenants] - Academies examined.
/// * [failed] - Academies whose backfill failed (logged; the others went on). Run again to retry them.
/// * [appended] - Events appended to the outbox (all topics).
/// * [appendedByTopic] - Events appended per topic (`core.<aggregate>`); topics without any are left out.
@BuiltValue()
abstract class EventBackfill
    implements Built<EventBackfill, EventBackfillBuilder> {
  @BuiltValueField(wireName: r'force')
  bool get force;

  /// Academies examined.
  @BuiltValueField(wireName: r'tenants')
  int get tenants;

  /// Academies whose backfill failed (logged; the others went on). Run again to retry them.
  @BuiltValueField(wireName: r'failed')
  int get failed;

  /// Events appended to the outbox (all topics).
  @BuiltValueField(wireName: r'appended')
  int get appended;

  /// Events appended per topic (`core.<aggregate>`); topics without any are left out.
  @BuiltValueField(wireName: r'appendedByTopic')
  BuiltMap<String, int> get appendedByTopic;

  EventBackfill._();

  factory EventBackfill([void updates(EventBackfillBuilder b)]) =
      _$EventBackfill;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventBackfillBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventBackfill> get serializer =>
      _$EventBackfillSerializer();
}

class _$EventBackfillSerializer implements PrimitiveSerializer<EventBackfill> {
  @override
  final Iterable<Type> types = const [EventBackfill, _$EventBackfill];

  @override
  final String wireName = r'EventBackfill';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventBackfill object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'force';
    yield serializers.serialize(
      object.force,
      specifiedType: const FullType(bool),
    );
    yield r'tenants';
    yield serializers.serialize(
      object.tenants,
      specifiedType: const FullType(int),
    );
    yield r'failed';
    yield serializers.serialize(
      object.failed,
      specifiedType: const FullType(int),
    );
    yield r'appended';
    yield serializers.serialize(
      object.appended,
      specifiedType: const FullType(int),
    );
    yield r'appendedByTopic';
    yield serializers.serialize(
      object.appendedByTopic,
      specifiedType:
          const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EventBackfill object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventBackfillBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'force':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.force = valueDes;
          break;
        case r'tenants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.tenants = valueDes;
          break;
        case r'failed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.failed = valueDes;
          break;
        case r'appended':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.appended = valueDes;
          break;
        case r'appendedByTopic':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.appendedByTopic.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventBackfill deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventBackfillBuilder();
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
