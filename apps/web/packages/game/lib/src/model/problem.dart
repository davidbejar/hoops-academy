//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/problem_violation.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'problem.g.dart';

/// RFC 9457 problem details (serialised by `com.hoopsacademy.common.problem.Problem`; absent members are omitted). Extension members: `traceId` (correlation with logs/traces), `code` (stable machine-readable reason clients may branch on) and `violations` (field-level violations for 400, rule reasons for 422). 
///
/// Properties:
/// * [type] - Problem type URI, `urn:hoops:problem:<slug>` (e.g. `urn:hoops:problem:domain-rule-violation`).
/// * [title] - Short, human-readable summary of the problem type.
/// * [status] 
/// * [detail] - Human-readable explanation specific to this occurrence.
/// * [instance] - URI reference identifying this occurrence (usually the request path).
/// * [traceId] - Trace id of the request (from the logging MDC / OpenTelemetry), for support.
/// * [code] - Machine-readable reason in SCREAMING_SNAKE_CASE, e.g. `PLAYER_INELIGIBLE`, `NOT_PENDING`.
/// * [violations] - Field-level violations (400) or rule reasons (422, e.g. eligibility reasons in `code`).
@BuiltValue()
abstract class Problem implements Built<Problem, ProblemBuilder> {
  /// Problem type URI, `urn:hoops:problem:<slug>` (e.g. `urn:hoops:problem:domain-rule-violation`).
  @BuiltValueField(wireName: r'type')
  String get type;

  /// Short, human-readable summary of the problem type.
  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'status')
  int get status;

  /// Human-readable explanation specific to this occurrence.
  @BuiltValueField(wireName: r'detail')
  String? get detail;

  /// URI reference identifying this occurrence (usually the request path).
  @BuiltValueField(wireName: r'instance')
  String? get instance;

  /// Trace id of the request (from the logging MDC / OpenTelemetry), for support.
  @BuiltValueField(wireName: r'traceId')
  String? get traceId;

  /// Machine-readable reason in SCREAMING_SNAKE_CASE, e.g. `PLAYER_INELIGIBLE`, `NOT_PENDING`.
  @BuiltValueField(wireName: r'code')
  String? get code;

  /// Field-level violations (400) or rule reasons (422, e.g. eligibility reasons in `code`).
  @BuiltValueField(wireName: r'violations')
  BuiltList<ProblemViolation>? get violations;

  Problem._();

  factory Problem([void updates(ProblemBuilder b)]) = _$Problem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProblemBuilder b) => b
      ..type = 'about:blank';

  @BuiltValueSerializer(custom: true)
  static Serializer<Problem> get serializer => _$ProblemSerializer();
}

class _$ProblemSerializer implements PrimitiveSerializer<Problem> {
  @override
  final Iterable<Type> types = const [Problem, _$Problem];

  @override
  final String wireName = r'Problem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Problem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(
        object.detail,
        specifiedType: const FullType(String),
      );
    }
    if (object.instance != null) {
      yield r'instance';
      yield serializers.serialize(
        object.instance,
        specifiedType: const FullType(String),
      );
    }
    if (object.traceId != null) {
      yield r'traceId';
      yield serializers.serialize(
        object.traceId,
        specifiedType: const FullType(String),
      );
    }
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType(String),
      );
    }
    if (object.violations != null) {
      yield r'violations';
      yield serializers.serialize(
        object.violations,
        specifiedType: const FullType(BuiltList, [FullType(ProblemViolation)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Problem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProblemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.status = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detail = valueDes;
          break;
        case r'instance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.instance = valueDes;
          break;
        case r'traceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.traceId = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'violations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(ProblemViolation)]),
          ) as BuiltList<ProblemViolation>?;
          if (valueDes == null) continue;
          result.violations.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Problem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProblemBuilder();
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


