//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'usage_report.g.dart';

/// Usage counters of one service for one tenant (platform statistics and future billing). Counters by service: core — `members`, `players`, `activePlayers`, `teams`, `seasons`; game — `matches`, `liveMatches`, `matchEvents`, `matchEventsLast30Days`; athlete — `trainingSessions`, `attendanceRecords`, `trainingPlans`, `physicalTestResults`, `injuries`, `bodyMeasurements`. Counters are additive: new keys may appear at any time. 
///
/// Properties:
/// * [tenantId] 
/// * [service] 
/// * [collectedAt] 
/// * [lastActivityAt] 
/// * [counters] 
@BuiltValue()
abstract class UsageReport implements Built<UsageReport, UsageReportBuilder> {
  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'service')
  UsageReportServiceEnum get service;
  // enum serviceEnum {  core,  game,  athlete,  };

  @BuiltValueField(wireName: r'collectedAt')
  DateTime get collectedAt;

  @BuiltValueField(wireName: r'lastActivityAt')
  DateTime? get lastActivityAt;

  @BuiltValueField(wireName: r'counters')
  BuiltMap<String, int> get counters;

  UsageReport._();

  factory UsageReport([void updates(UsageReportBuilder b)]) = _$UsageReport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UsageReportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UsageReport> get serializer => _$UsageReportSerializer();
}

class _$UsageReportSerializer implements PrimitiveSerializer<UsageReport> {
  @override
  final Iterable<Type> types = const [UsageReport, _$UsageReport];

  @override
  final String wireName = r'UsageReport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UsageReport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
      specifiedType: const FullType(String),
    );
    yield r'service';
    yield serializers.serialize(
      object.service,
      specifiedType: const FullType(UsageReportServiceEnum),
    );
    yield r'collectedAt';
    yield serializers.serialize(
      object.collectedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.lastActivityAt != null) {
      yield r'lastActivityAt';
      yield serializers.serialize(
        object.lastActivityAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'counters';
    yield serializers.serialize(
      object.counters,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UsageReport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UsageReportBuilder result,
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
        case r'service':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UsageReportServiceEnum),
          ) as UsageReportServiceEnum;
          result.service = valueDes;
          break;
        case r'collectedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.collectedAt = valueDes;
          break;
        case r'lastActivityAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastActivityAt = valueDes;
          break;
        case r'counters':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.counters.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UsageReport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UsageReportBuilder();
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


class UsageReportServiceEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'core')
  static const UsageReportServiceEnum core = _$usageReportServiceEnum_core;
  @BuiltValueEnumConst(wireName: r'game')
  static const UsageReportServiceEnum game = _$usageReportServiceEnum_game;
  @BuiltValueEnumConst(wireName: r'athlete')
  static const UsageReportServiceEnum athlete = _$usageReportServiceEnum_athlete;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UsageReportServiceEnum unknownDefaultOpenApi = _$usageReportServiceEnum_unknownDefaultOpenApi;

  static Serializer<UsageReportServiceEnum> get serializer => _$usageReportServiceEnumSerializer;

  const UsageReportServiceEnum._(String name): super(name);

  static BuiltSet<UsageReportServiceEnum> get values => _$usageReportServiceEnumValues;
  static UsageReportServiceEnum valueOf(String name) => _$usageReportServiceEnumValueOf(name);
}

