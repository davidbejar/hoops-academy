//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'season_rollover_request.g.dart';

/// SeasonRolloverRequest
///
/// Properties:
/// * [fromSeasonId] - Season whose teams are cloned into the target season.
/// * [cloneStaff]
/// * [clonePlayers] - Carry open player assignments over (then eligibility-checked).
@BuiltValue()
abstract class SeasonRolloverRequest
    implements Built<SeasonRolloverRequest, SeasonRolloverRequestBuilder> {
  /// Season whose teams are cloned into the target season.
  @BuiltValueField(wireName: r'fromSeasonId')
  String get fromSeasonId;

  @BuiltValueField(wireName: r'cloneStaff')
  bool? get cloneStaff;

  /// Carry open player assignments over (then eligibility-checked).
  @BuiltValueField(wireName: r'clonePlayers')
  bool? get clonePlayers;

  SeasonRolloverRequest._();

  factory SeasonRolloverRequest(
      [void updates(SeasonRolloverRequestBuilder b)]) = _$SeasonRolloverRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeasonRolloverRequestBuilder b) => b
    ..cloneStaff = true
    ..clonePlayers = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeasonRolloverRequest> get serializer =>
      _$SeasonRolloverRequestSerializer();
}

class _$SeasonRolloverRequestSerializer
    implements PrimitiveSerializer<SeasonRolloverRequest> {
  @override
  final Iterable<Type> types = const [
    SeasonRolloverRequest,
    _$SeasonRolloverRequest
  ];

  @override
  final String wireName = r'SeasonRolloverRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeasonRolloverRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'fromSeasonId';
    yield serializers.serialize(
      object.fromSeasonId,
      specifiedType: const FullType(String),
    );
    if (object.cloneStaff != null) {
      yield r'cloneStaff';
      yield serializers.serialize(
        object.cloneStaff,
        specifiedType: const FullType(bool),
      );
    }
    if (object.clonePlayers != null) {
      yield r'clonePlayers';
      yield serializers.serialize(
        object.clonePlayers,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SeasonRolloverRequest object, {
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
    required SeasonRolloverRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fromSeasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromSeasonId = valueDes;
          break;
        case r'cloneStaff':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.cloneStaff = valueDes;
          break;
        case r'clonePlayers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.clonePlayers = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeasonRolloverRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeasonRolloverRequestBuilder();
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
