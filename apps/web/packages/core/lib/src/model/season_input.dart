//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'season_input.g.dart';

/// SeasonInput
///
/// Properties:
/// * [name]
/// * [startsOn]
/// * [endsOn]
/// * [referenceYear] - Year used by the BIRTH_YEAR age rule (age = referenceYear − birth year).
@BuiltValue()
abstract class SeasonInput implements Built<SeasonInput, SeasonInputBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'startsOn')
  Date get startsOn;

  @BuiltValueField(wireName: r'endsOn')
  Date get endsOn;

  /// Year used by the BIRTH_YEAR age rule (age = referenceYear − birth year).
  @BuiltValueField(wireName: r'referenceYear')
  int get referenceYear;

  SeasonInput._();

  factory SeasonInput([void updates(SeasonInputBuilder b)]) = _$SeasonInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeasonInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeasonInput> get serializer => _$SeasonInputSerializer();
}

class _$SeasonInputSerializer implements PrimitiveSerializer<SeasonInput> {
  @override
  final Iterable<Type> types = const [SeasonInput, _$SeasonInput];

  @override
  final String wireName = r'SeasonInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeasonInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'startsOn';
    yield serializers.serialize(
      object.startsOn,
      specifiedType: const FullType(Date),
    );
    yield r'endsOn';
    yield serializers.serialize(
      object.endsOn,
      specifiedType: const FullType(Date),
    );
    yield r'referenceYear';
    yield serializers.serialize(
      object.referenceYear,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SeasonInput object, {
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
    required SeasonInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'startsOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.startsOn = valueDes;
          break;
        case r'endsOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.endsOn = valueDes;
          break;
        case r'referenceYear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.referenceYear = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeasonInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeasonInputBuilder();
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
