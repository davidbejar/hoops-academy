//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_me_request.g.dart';

/// At least one member. A name change needs `tenantId` (the academy of the person renamed); core 3.4.0 made `locale` optional.
///
/// Properties:
/// * [locale]
/// * [givenName]
/// * [familyName]
/// * [tenantId] - The academy whose person (the caller's own) gets the new name; required with a name only.
@BuiltValue()
abstract class UpdateMeRequest
    implements Built<UpdateMeRequest, UpdateMeRequestBuilder> {
  @BuiltValueField(wireName: r'locale')
  Locale? get locale;
  // enum localeEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'givenName')
  String? get givenName;

  @BuiltValueField(wireName: r'familyName')
  String? get familyName;

  /// The academy whose person (the caller's own) gets the new name; required with a name only.
  @BuiltValueField(wireName: r'tenantId')
  String? get tenantId;

  UpdateMeRequest._();

  factory UpdateMeRequest([void updates(UpdateMeRequestBuilder b)]) =
      _$UpdateMeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateMeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateMeRequest> get serializer =>
      _$UpdateMeRequestSerializer();
}

class _$UpdateMeRequestSerializer
    implements PrimitiveSerializer<UpdateMeRequest> {
  @override
  final Iterable<Type> types = const [UpdateMeRequest, _$UpdateMeRequest];

  @override
  final String wireName = r'UpdateMeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateMeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(Locale),
      );
    }
    if (object.givenName != null) {
      yield r'givenName';
      yield serializers.serialize(
        object.givenName,
        specifiedType: const FullType(String),
      );
    }
    if (object.familyName != null) {
      yield r'familyName';
      yield serializers.serialize(
        object.familyName,
        specifiedType: const FullType(String),
      );
    }
    if (object.tenantId != null) {
      yield r'tenantId';
      yield serializers.serialize(
        object.tenantId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateMeRequest object, {
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
    required UpdateMeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Locale),
          ) as Locale?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.familyName = valueDes;
          break;
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tenantId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateMeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateMeRequestBuilder();
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
