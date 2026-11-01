//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/eligibility_case_resolution.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resolve_eligibility_case_request.g.dart';

/// ResolveEligibilityCaseRequest
///
/// Properties:
/// * [resolution] 
/// * [targetTeamId] - Required when resolution = REASSIGNED.
/// * [note] 
@BuiltValue()
abstract class ResolveEligibilityCaseRequest implements Built<ResolveEligibilityCaseRequest, ResolveEligibilityCaseRequestBuilder> {
  @BuiltValueField(wireName: r'resolution')
  EligibilityCaseResolution get resolution;
  // enum resolutionEnum {  REASSIGNED,  REMOVED_FROM_TEAM,  DISMISSED,  };

  /// Required when resolution = REASSIGNED.
  @BuiltValueField(wireName: r'targetTeamId')
  String? get targetTeamId;

  @BuiltValueField(wireName: r'note')
  String? get note;

  ResolveEligibilityCaseRequest._();

  factory ResolveEligibilityCaseRequest([void updates(ResolveEligibilityCaseRequestBuilder b)]) = _$ResolveEligibilityCaseRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResolveEligibilityCaseRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResolveEligibilityCaseRequest> get serializer => _$ResolveEligibilityCaseRequestSerializer();
}

class _$ResolveEligibilityCaseRequestSerializer implements PrimitiveSerializer<ResolveEligibilityCaseRequest> {
  @override
  final Iterable<Type> types = const [ResolveEligibilityCaseRequest, _$ResolveEligibilityCaseRequest];

  @override
  final String wireName = r'ResolveEligibilityCaseRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResolveEligibilityCaseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'resolution';
    yield serializers.serialize(
      object.resolution,
      specifiedType: const FullType(EligibilityCaseResolution),
    );
    if (object.targetTeamId != null) {
      yield r'targetTeamId';
      yield serializers.serialize(
        object.targetTeamId,
        specifiedType: const FullType(String),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ResolveEligibilityCaseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResolveEligibilityCaseRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'resolution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EligibilityCaseResolution),
          ) as EligibilityCaseResolution;
          result.resolution = valueDes;
          break;
        case r'targetTeamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.targetTeamId = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResolveEligibilityCaseRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResolveEligibilityCaseRequestBuilder();
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


