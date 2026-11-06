//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_item_match.g.dart';

/// An item found by the plan search, enough to show \"found in <plan>\" and to quick-add it.
///
/// Properties:
/// * [id] 
/// * [planId] 
/// * [title] - In the negotiated language for a template's item; as stored otherwise.
@BuiltValue()
abstract class PlanItemMatch implements Built<PlanItemMatch, PlanItemMatchBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'planId')
  String get planId;

  /// In the negotiated language for a template's item; as stored otherwise.
  @BuiltValueField(wireName: r'title')
  String get title;

  PlanItemMatch._();

  factory PlanItemMatch([void updates(PlanItemMatchBuilder b)]) = _$PlanItemMatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanItemMatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanItemMatch> get serializer => _$PlanItemMatchSerializer();
}

class _$PlanItemMatchSerializer implements PrimitiveSerializer<PlanItemMatch> {
  @override
  final Iterable<Type> types = const [PlanItemMatch, _$PlanItemMatch];

  @override
  final String wireName = r'PlanItemMatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanItemMatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'planId';
    yield serializers.serialize(
      object.planId,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanItemMatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanItemMatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'planId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.planId = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanItemMatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanItemMatchBuilder();
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


