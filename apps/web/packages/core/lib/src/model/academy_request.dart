//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/academy_request_status.dart';
import 'package:hoops_core_api/src/model/academy_request_role.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request.g.dart';

/// A request for a new academy as the super admin sees it (ADR-0044).
///
/// Properties:
/// * [id] 
/// * [status] 
/// * [name] 
/// * [email] 
/// * [role] 
/// * [academyName] 
/// * [locale] 
/// * [requestedAt] 
/// * [decidedAt] 
/// * [decidedBy] - The super admin's login (token subject) that accepted or rejected the request.
/// * [reason] - The rejection reason, as e-mailed to the requester.
/// * [tenantId] - The academy created on acceptance.
/// * [notifiedAt] - When the decision e-mail was handed to the mail server; null while pending or when it failed.
@BuiltValue()
abstract class AcademyRequest implements Built<AcademyRequest, AcademyRequestBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  AcademyRequestStatus get status;
  // enum statusEnum {  PENDING,  ACCEPTED,  REJECTED,  };

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'role')
  AcademyRequestRole get role;
  // enum roleEnum {  ADMIN,  COACH,  PARENT,  };

  @BuiltValueField(wireName: r'academyName')
  String get academyName;

  @BuiltValueField(wireName: r'locale')
  Locale get locale;
  // enum localeEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'requestedAt')
  DateTime get requestedAt;

  @BuiltValueField(wireName: r'decidedAt')
  DateTime? get decidedAt;

  /// The super admin's login (token subject) that accepted or rejected the request.
  @BuiltValueField(wireName: r'decidedBy')
  String? get decidedBy;

  /// The rejection reason, as e-mailed to the requester.
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  /// The academy created on acceptance.
  @BuiltValueField(wireName: r'tenantId')
  String? get tenantId;

  /// When the decision e-mail was handed to the mail server; null while pending or when it failed.
  @BuiltValueField(wireName: r'notifiedAt')
  DateTime? get notifiedAt;

  AcademyRequest._();

  factory AcademyRequest([void updates(AcademyRequestBuilder b)]) = _$AcademyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcademyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcademyRequest> get serializer => _$AcademyRequestSerializer();
}

class _$AcademyRequestSerializer implements PrimitiveSerializer<AcademyRequest> {
  @override
  final Iterable<Type> types = const [AcademyRequest, _$AcademyRequest];

  @override
  final String wireName = r'AcademyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(AcademyRequestStatus),
    );
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType.nullable(String),
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
    yield r'locale';
    yield serializers.serialize(
      object.locale,
      specifiedType: const FullType(Locale),
    );
    yield r'requestedAt';
    yield serializers.serialize(
      object.requestedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.decidedAt != null) {
      yield r'decidedAt';
      yield serializers.serialize(
        object.decidedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.decidedBy != null) {
      yield r'decidedBy';
      yield serializers.serialize(
        object.decidedBy,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.tenantId != null) {
      yield r'tenantId';
      yield serializers.serialize(
        object.tenantId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.notifiedAt != null) {
      yield r'notifiedAt';
      yield serializers.serialize(
        object.notifiedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AcademyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AcademyRequestBuilder result,
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcademyRequestStatus),
          ) as AcademyRequestStatus;
          result.status = valueDes;
          break;
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
            specifiedType: const FullType(Locale),
          ) as Locale;
          result.locale = valueDes;
          break;
        case r'requestedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.requestedAt = valueDes;
          break;
        case r'decidedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.decidedAt = valueDes;
          break;
        case r'decidedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.decidedBy = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tenantId = valueDes;
          break;
        case r'notifiedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.notifiedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcademyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcademyRequestBuilder();
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


