//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/accepted_admin.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'accept_academy_request.g.dart';

/// What the request does not carry; the academy name and the administrator's e-mail come from the request.
///
/// Properties:
/// * [slug]
/// * [timezone]
/// * [defaultLocale]
/// * [firstAdmin]
@BuiltValue()
abstract class AcceptAcademyRequest
    implements Built<AcceptAcademyRequest, AcceptAcademyRequestBuilder> {
  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'firstAdmin')
  AcceptedAdmin get firstAdmin;

  AcceptAcademyRequest._();

  factory AcceptAcademyRequest([void updates(AcceptAcademyRequestBuilder b)]) =
      _$AcceptAcademyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptAcademyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptAcademyRequest> get serializer =>
      _$AcceptAcademyRequestSerializer();
}

class _$AcceptAcademyRequestSerializer
    implements PrimitiveSerializer<AcceptAcademyRequest> {
  @override
  final Iterable<Type> types = const [
    AcceptAcademyRequest,
    _$AcceptAcademyRequest
  ];

  @override
  final String wireName = r'AcceptAcademyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptAcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'defaultLocale';
    yield serializers.serialize(
      object.defaultLocale,
      specifiedType: const FullType(Locale),
    );
    yield r'firstAdmin';
    yield serializers.serialize(
      object.firstAdmin,
      specifiedType: const FullType(AcceptedAdmin),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AcceptAcademyRequest object, {
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
    required AcceptAcademyRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'defaultLocale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Locale),
          ) as Locale;
          result.defaultLocale = valueDes;
          break;
        case r'firstAdmin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcceptedAdmin),
          ) as AcceptedAdmin;
          result.firstAdmin.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcceptAcademyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptAcademyRequestBuilder();
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
