//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_summary.g.dart';

/// TenantSummary
///
/// Properties:
/// * [id] 
/// * [slug] 
/// * [name] 
/// * [status] 
/// * [hasLogo] 
@BuiltValue()
abstract class TenantSummary implements Built<TenantSummary, TenantSummaryBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'status')
  TenantStatus get status;
  // enum statusEnum {  ACTIVE,  SUSPENDED,  WITHDRAWN,  };

  @BuiltValueField(wireName: r'hasLogo')
  bool get hasLogo;

  TenantSummary._();

  factory TenantSummary([void updates(TenantSummaryBuilder b)]) = _$TenantSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantSummary> get serializer => _$TenantSummarySerializer();
}

class _$TenantSummarySerializer implements PrimitiveSerializer<TenantSummary> {
  @override
  final Iterable<Type> types = const [TenantSummary, _$TenantSummary];

  @override
  final String wireName = r'TenantSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TenantStatus),
    );
    yield r'hasLogo';
    yield serializers.serialize(
      object.hasLogo,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantSummaryBuilder result,
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
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantStatus),
          ) as TenantStatus;
          result.status = valueDes;
          break;
        case r'hasLogo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasLogo = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantSummaryBuilder();
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


