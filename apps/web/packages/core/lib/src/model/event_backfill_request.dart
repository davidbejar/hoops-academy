//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_backfill_request.g.dart';

/// EventBackfillRequest
///
/// Properties:
/// * [tenantId] - Only this academy (404 when unknown); every academy when absent.
/// * [force] - Also aggregates that have events already (a fresh snapshot of everything).
@BuiltValue()
abstract class EventBackfillRequest implements Built<EventBackfillRequest, EventBackfillRequestBuilder> {
  /// Only this academy (404 when unknown); every academy when absent.
  @BuiltValueField(wireName: r'tenantId')
  String? get tenantId;

  /// Also aggregates that have events already (a fresh snapshot of everything).
  @BuiltValueField(wireName: r'force')
  bool? get force;

  EventBackfillRequest._();

  factory EventBackfillRequest([void updates(EventBackfillRequestBuilder b)]) = _$EventBackfillRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventBackfillRequestBuilder b) => b
      ..force = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventBackfillRequest> get serializer => _$EventBackfillRequestSerializer();
}

class _$EventBackfillRequestSerializer implements PrimitiveSerializer<EventBackfillRequest> {
  @override
  final Iterable<Type> types = const [EventBackfillRequest, _$EventBackfillRequest];

  @override
  final String wireName = r'EventBackfillRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventBackfillRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.tenantId != null) {
      yield r'tenantId';
      yield serializers.serialize(
        object.tenantId,
        specifiedType: const FullType(String),
      );
    }
    if (object.force != null) {
      yield r'force';
      yield serializers.serialize(
        object.force,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EventBackfillRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventBackfillRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tenantId = valueDes;
          break;
        case r'force':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.force = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventBackfillRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventBackfillRequestBuilder();
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


