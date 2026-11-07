//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/usage_report.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_usage_snapshot.g.dart';

/// TenantUsageSnapshot
///
/// Properties:
/// * [date] - UTC day of `collectedAt`.
/// * [collectedAt]
/// * [services]
/// * [unavailableServices] - Non-empty for a partial snapshot.
@BuiltValue()
abstract class TenantUsageSnapshot
    implements Built<TenantUsageSnapshot, TenantUsageSnapshotBuilder> {
  /// UTC day of `collectedAt`.
  @BuiltValueField(wireName: r'date')
  Date get date;

  @BuiltValueField(wireName: r'collectedAt')
  DateTime get collectedAt;

  @BuiltValueField(wireName: r'services')
  BuiltList<UsageReport> get services;

  /// Non-empty for a partial snapshot.
  @BuiltValueField(wireName: r'unavailableServices')
  BuiltList<TenantUsageSnapshotUnavailableServicesEnum> get unavailableServices;
  // enum unavailableServicesEnum {  core,  game,  athlete,  };

  TenantUsageSnapshot._();

  factory TenantUsageSnapshot([void updates(TenantUsageSnapshotBuilder b)]) =
      _$TenantUsageSnapshot;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantUsageSnapshotBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantUsageSnapshot> get serializer =>
      _$TenantUsageSnapshotSerializer();
}

class _$TenantUsageSnapshotSerializer
    implements PrimitiveSerializer<TenantUsageSnapshot> {
  @override
  final Iterable<Type> types = const [
    TenantUsageSnapshot,
    _$TenantUsageSnapshot
  ];

  @override
  final String wireName = r'TenantUsageSnapshot';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantUsageSnapshot object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'date';
    yield serializers.serialize(
      object.date,
      specifiedType: const FullType(Date),
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
      specifiedType: const FullType(
          BuiltList, [FullType(TenantUsageSnapshotUnavailableServicesEnum)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantUsageSnapshot object, {
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
    required TenantUsageSnapshotBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.date = valueDes;
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
            specifiedType: const FullType(BuiltList,
                [FullType(TenantUsageSnapshotUnavailableServicesEnum)]),
          ) as BuiltList<TenantUsageSnapshotUnavailableServicesEnum>;
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
  TenantUsageSnapshot deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantUsageSnapshotBuilder();
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

class TenantUsageSnapshotUnavailableServicesEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'core')
  static const TenantUsageSnapshotUnavailableServicesEnum core =
      _$tenantUsageSnapshotUnavailableServicesEnum_core;
  @BuiltValueEnumConst(wireName: r'game')
  static const TenantUsageSnapshotUnavailableServicesEnum game =
      _$tenantUsageSnapshotUnavailableServicesEnum_game;
  @BuiltValueEnumConst(wireName: r'athlete')
  static const TenantUsageSnapshotUnavailableServicesEnum athlete =
      _$tenantUsageSnapshotUnavailableServicesEnum_athlete;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TenantUsageSnapshotUnavailableServicesEnum
      unknownDefaultOpenApi =
      _$tenantUsageSnapshotUnavailableServicesEnum_unknownDefaultOpenApi;

  static Serializer<TenantUsageSnapshotUnavailableServicesEnum>
      get serializer => _$tenantUsageSnapshotUnavailableServicesEnumSerializer;

  const TenantUsageSnapshotUnavailableServicesEnum._(String name) : super(name);

  static BuiltSet<TenantUsageSnapshotUnavailableServicesEnum> get values =>
      _$tenantUsageSnapshotUnavailableServicesEnumValues;
  static TenantUsageSnapshotUnavailableServicesEnum valueOf(String name) =>
      _$tenantUsageSnapshotUnavailableServicesEnumValueOf(name);
}
