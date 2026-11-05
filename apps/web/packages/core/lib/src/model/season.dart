//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'season.g.dart';

/// Season
///
/// Properties:
/// * [name]
/// * [startsOn]
/// * [endsOn]
/// * [referenceYear] - Year used by the BIRTH_YEAR age rule (age = referenceYear − birth year).
/// * [id]
/// * [current] - Today (tenant time zone) lies within the season.
@BuiltValue()
abstract class Season implements Built<Season, SeasonBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'startsOn')
  Date get startsOn;

  @BuiltValueField(wireName: r'endsOn')
  Date get endsOn;

  /// Year used by the BIRTH_YEAR age rule (age = referenceYear − birth year).
  @BuiltValueField(wireName: r'referenceYear')
  int get referenceYear;

  @BuiltValueField(wireName: r'id')
  String get id;

  /// Today (tenant time zone) lies within the season.
  @BuiltValueField(wireName: r'current')
  bool get current;

  Season._();

  factory Season([void updates(SeasonBuilder b)]) = _$Season;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeasonBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Season> get serializer => _$SeasonSerializer();
}

class _$SeasonSerializer implements PrimitiveSerializer<Season> {
  @override
  final Iterable<Type> types = const [Season, _$Season];

  @override
  final String wireName = r'Season';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Season object, {
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
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'current';
    yield serializers.serialize(
      object.current,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Season object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SeasonBuilder result,
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'current':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.current = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Season deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeasonBuilder();
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
