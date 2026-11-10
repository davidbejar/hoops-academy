//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/academy_request_role.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'submit_academy_request.g.dart';

/// The landing page's invitation form (ADR-0044). Text without control characters.
///
/// Properties:
/// * [name] - The requester's name (optional).
/// * [email] 
/// * [role] 
/// * [academyName] 
/// * [locale] - The page's language; the decision e-mail is written in it (default en).
/// * [website] - Honeypot; must be absent or empty. A request with a value is answered 202 and dropped.
@BuiltValue()
abstract class SubmitAcademyRequest implements Built<SubmitAcademyRequest, SubmitAcademyRequestBuilder> {
  /// The requester's name (optional).
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'role')
  AcademyRequestRole get role;
  // enum roleEnum {  ADMIN,  COACH,  PARENT,  };

  @BuiltValueField(wireName: r'academyName')
  String get academyName;

  /// The page's language; the decision e-mail is written in it (default en).
  @BuiltValueField(wireName: r'locale')
  Locale? get locale;
  // enum localeEnum {  es,  en,  id,  };

  /// Honeypot; must be absent or empty. A request with a value is answered 202 and dropped.
  @BuiltValueField(wireName: r'website')
  String? get website;

  SubmitAcademyRequest._();

  factory SubmitAcademyRequest([void updates(SubmitAcademyRequestBuilder b)]) = _$SubmitAcademyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubmitAcademyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SubmitAcademyRequest> get serializer => _$SubmitAcademyRequestSerializer();
}

class _$SubmitAcademyRequestSerializer implements PrimitiveSerializer<SubmitAcademyRequest> {
  @override
  final Iterable<Type> types = const [SubmitAcademyRequest, _$SubmitAcademyRequest];

  @override
  final String wireName = r'SubmitAcademyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubmitAcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(AcademyRequestRole),
    );
    yield r'academyName';
    yield serializers.serialize(
      object.academyName,
      specifiedType: const FullType(String),
    );
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(Locale),
      );
    }
    if (object.website != null) {
      yield r'website';
      yield serializers.serialize(
        object.website,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SubmitAcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SubmitAcademyRequestBuilder result,
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
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcademyRequestRole),
          ) as AcademyRequestRole;
          result.role = valueDes;
          break;
        case r'academyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.academyName = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Locale),
          ) as Locale?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        case r'website':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.website = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubmitAcademyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubmitAcademyRequestBuilder();
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


