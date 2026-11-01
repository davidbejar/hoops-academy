//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_age_category_request.g.dart';

/// UpdateAgeCategoryRequest
///
/// Properties:
/// * [code] 
/// * [name] 
/// * [maxAge] 
/// * [rank] 
@BuiltValue()
abstract class UpdateAgeCategoryRequest implements Built<UpdateAgeCategoryRequest, UpdateAgeCategoryRequestBuilder> {
  @BuiltValueField(wireName: r'code')
  String? get code;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'maxAge')
  int? get maxAge;

  @BuiltValueField(wireName: r'rank')
  int? get rank;

  UpdateAgeCategoryRequest._();

  factory UpdateAgeCategoryRequest([void updates(UpdateAgeCategoryRequestBuilder b)]) = _$UpdateAgeCategoryRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateAgeCategoryRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateAgeCategoryRequest> get serializer => _$UpdateAgeCategoryRequestSerializer();
}

class _$UpdateAgeCategoryRequestSerializer implements PrimitiveSerializer<UpdateAgeCategoryRequest> {
  @override
  final Iterable<Type> types = const [UpdateAgeCategoryRequest, _$UpdateAgeCategoryRequest];

  @override
  final String wireName = r'UpdateAgeCategoryRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateAgeCategoryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType(String),
      );
    }
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.maxAge != null) {
      yield r'maxAge';
      yield serializers.serialize(
        object.maxAge,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.rank != null) {
      yield r'rank';
      yield serializers.serialize(
        object.rank,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateAgeCategoryRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateAgeCategoryRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'maxAge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.maxAge = valueDes;
          break;
        case r'rank':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.rank = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateAgeCategoryRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateAgeCategoryRequestBuilder();
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


