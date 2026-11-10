//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/usage_report.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_usage.g.dart';

/// TenantUsage
///
/// Properties:
/// * [tenantId] 
/// * [collectedAt] 
/// * [services] 
/// * [unavailableServices] - Services that did not answer within the timeout.
@BuiltValue()
abstract class TenantUsage implements Built<TenantUsage, TenantUsageBuilder> {
  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'collectedAt')
  DateTime get collectedAt;

  @BuiltValueField(wireName: r'services')
  BuiltList<UsageReport> get services;

  /// Services that did not answer within the timeout.
  @BuiltValueField(wireName: r'unavailableServices')
  BuiltList<TenantUsageUnavailableServicesEnum> get unavailableServices;
  // enum unavailableServicesEnum {  core,  game,  athlete,  };

  TenantUsage._();

  factory TenantUsage([void updates(TenantUsageBuilder b)]) = _$TenantUsage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantUsageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantUsage> get serializer => _$TenantUsageSerializer();
}

class _$TenantUsageSerializer implements PrimitiveSerializer<TenantUsage> {
  @override
  final Iterable<Type> types = const [TenantUsage, _$TenantUsage];

  @override
  final String wireName = r'TenantUsage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantUsage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
      specifiedType: const FullType(String),
    );
    yield r'collectedAt';
    yield serializers.serialize(
      object.collectedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'services';
    yield serializers.serialize(
      object.services,
      specifiedType: const FullType(BuiltList, [FullType(UsageReport)]),
    );
    yield r'unavailableServices';
    yield serializers.serialize(
      object.unavailableServices,
      specifiedType: const FullType(BuiltList, [FullType(TenantUsageUnavailableServicesEnum)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantUsage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantUsageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantId = valueDes;
          break;
        case r'collectedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.collectedAt = valueDes;
          break;
        case r'services':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(UsageReport)]),
          ) as BuiltList<UsageReport>;
          result.services.replace(valueDes);
          break;
        case r'unavailableServices':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TenantUsageUnavailableServicesEnum)]),
          ) as BuiltList<TenantUsageUnavailableServicesEnum>;
          result.unavailableServices.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantUsage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantUsageBuilder();
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


class TenantUsageUnavailableServicesEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'core')
  static const TenantUsageUnavailableServicesEnum core = _$tenantUsageUnavailableServicesEnum_core;
  @BuiltValueEnumConst(wireName: r'game')
  static const TenantUsageUnavailableServicesEnum game = _$tenantUsageUnavailableServicesEnum_game;
  @BuiltValueEnumConst(wireName: r'athlete')
  static const TenantUsageUnavailableServicesEnum athlete = _$tenantUsageUnavailableServicesEnum_athlete;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TenantUsageUnavailableServicesEnum unknownDefaultOpenApi = _$tenantUsageUnavailableServicesEnum_unknownDefaultOpenApi;

  static Serializer<TenantUsageUnavailableServicesEnum> get serializer => _$tenantUsageUnavailableServicesEnumSerializer;

  const TenantUsageUnavailableServicesEnum._(String name): super(name);

  static BuiltSet<TenantUsageUnavailableServicesEnum> get values => _$tenantUsageUnavailableServicesEnumValues;
  static TenantUsageUnavailableServicesEnum valueOf(String name) => _$tenantUsageUnavailableServicesEnumValueOf(name);
}

