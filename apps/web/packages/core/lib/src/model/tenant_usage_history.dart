//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/tenant_usage_snapshot.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_usage_history.g.dart';

/// TenantUsageHistory
///
/// Properties:
/// * [tenantId]
/// * [from]
/// * [to]
/// * [snapshots] - At most one per UTC day, ascending; days without a snapshot are absent.
@BuiltValue()
abstract class TenantUsageHistory
    implements Built<TenantUsageHistory, TenantUsageHistoryBuilder> {
  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'from')
  Date get from;

  @BuiltValueField(wireName: r'to')
  Date get to;

  /// At most one per UTC day, ascending; days without a snapshot are absent.
  @BuiltValueField(wireName: r'snapshots')
  BuiltList<TenantUsageSnapshot> get snapshots;

  TenantUsageHistory._();

  factory TenantUsageHistory([void updates(TenantUsageHistoryBuilder b)]) =
      _$TenantUsageHistory;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantUsageHistoryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantUsageHistory> get serializer =>
      _$TenantUsageHistorySerializer();
}

class _$TenantUsageHistorySerializer
    implements PrimitiveSerializer<TenantUsageHistory> {
  @override
  final Iterable<Type> types = const [TenantUsageHistory, _$TenantUsageHistory];

  @override
  final String wireName = r'TenantUsageHistory';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantUsageHistory object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
      specifiedType: const FullType(String),
    );
    yield r'from';
    yield serializers.serialize(
      object.from,
      specifiedType: const FullType(Date),
    );
    yield r'to';
    yield serializers.serialize(
      object.to,
      specifiedType: const FullType(Date),
    );
    yield r'snapshots';
    yield serializers.serialize(
      object.snapshots,
      specifiedType: const FullType(BuiltList, [FullType(TenantUsageSnapshot)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantUsageHistory object, {
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
    required TenantUsageHistoryBuilder result,
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
        case r'from':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.from = valueDes;
          break;
        case r'to':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.to = valueDes;
          break;
        case r'snapshots':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(TenantUsageSnapshot)]),
          ) as BuiltList<TenantUsageSnapshot>;
          result.snapshots.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantUsageHistory deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantUsageHistoryBuilder();
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
