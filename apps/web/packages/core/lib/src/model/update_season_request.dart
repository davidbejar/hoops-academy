//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_season_request.g.dart';

/// UpdateSeasonRequest
///
/// Properties:
/// * [name] 
/// * [startsOn] 
/// * [endsOn] 
/// * [referenceYear] 
@BuiltValue()
abstract class UpdateSeasonRequest implements Built<UpdateSeasonRequest, UpdateSeasonRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'startsOn')
  Date? get startsOn;

  @BuiltValueField(wireName: r'endsOn')
  Date? get endsOn;

  @BuiltValueField(wireName: r'referenceYear')
  int? get referenceYear;

  UpdateSeasonRequest._();

  factory UpdateSeasonRequest([void updates(UpdateSeasonRequestBuilder b)]) = _$UpdateSeasonRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateSeasonRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateSeasonRequest> get serializer => _$UpdateSeasonRequestSerializer();
}

class _$UpdateSeasonRequestSerializer implements PrimitiveSerializer<UpdateSeasonRequest> {
  @override
  final Iterable<Type> types = const [UpdateSeasonRequest, _$UpdateSeasonRequest];

  @override
  final String wireName = r'UpdateSeasonRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateSeasonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.startsOn != null) {
      yield r'startsOn';
      yield serializers.serialize(
        object.startsOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.endsOn != null) {
      yield r'endsOn';
      yield serializers.serialize(
        object.endsOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.referenceYear != null) {
      yield r'referenceYear';
      yield serializers.serialize(
        object.referenceYear,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateSeasonRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateSeasonRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'startsOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.startsOn = valueDes;
          break;
        case r'endsOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.endsOn = valueDes;
          break;
        case r'referenceYear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
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
  UpdateSeasonRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateSeasonRequestBuilder();
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


