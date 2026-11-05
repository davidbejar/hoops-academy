//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/approval_status.dart';
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/approval_action.dart';
import 'package:hoops_core_api/src/model/approval_payload.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_request.g.dart';

/// ApprovalRequest
///
/// Properties:
/// * [id]
/// * [action]
/// * [status]
/// * [player]
/// * [payload]
/// * [requestedBy]
/// * [requestedAt]
/// * [decidedBy]
/// * [decidedAt]
/// * [decisionNote]
@BuiltValue()
abstract class ApprovalRequest implements Built<ApprovalRequest, ApprovalRequestBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'action')
  ApprovalAction get action;
  // enum actionEnum {  ADD_PLAYER,  WITHDRAW_PLAYER,  };

  @BuiltValueField(wireName: r'status')
  ApprovalStatus get status;
  // enum statusEnum {  PENDING,  APPROVED,  REJECTED,  CANCELLED,  };

  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'payload')
  ApprovalPayload get payload;

  @BuiltValueField(wireName: r'requestedBy')
  PersonRef get requestedBy;

  @BuiltValueField(wireName: r'requestedAt')
  DateTime get requestedAt;

  @BuiltValueField(wireName: r'decidedBy')
  PersonRef? get decidedBy;

  @BuiltValueField(wireName: r'decidedAt')
  DateTime? get decidedAt;

  @BuiltValueField(wireName: r'decisionNote')
  String? get decisionNote;

  ApprovalRequest._();

  factory ApprovalRequest([void updates(ApprovalRequestBuilder b)]) = _$ApprovalRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ApprovalRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ApprovalRequest> get serializer => _$ApprovalRequestSerializer();
}

class _$ApprovalRequestSerializer implements PrimitiveSerializer<ApprovalRequest> {
  @override
  final Iterable<Type> types = const [ApprovalRequest, _$ApprovalRequest];

  @override
  final String wireName = r'ApprovalRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ApprovalRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(ApprovalAction),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ApprovalStatus),
    );
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(ApprovalPayload),
    );
    yield r'requestedBy';
    yield serializers.serialize(
      object.requestedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'requestedAt';
    yield serializers.serialize(
      object.requestedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.decidedBy != null) {
      yield r'decidedBy';
      yield serializers.serialize(
        object.decidedBy,
        specifiedType: const FullType.nullable(PersonRef),
      );
    }
    if (object.decidedAt != null) {
      yield r'decidedAt';
      yield serializers.serialize(
        object.decidedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.decisionNote != null) {
      yield r'decisionNote';
      yield serializers.serialize(
        object.decisionNote,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ApprovalRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ApprovalRequestBuilder result,
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
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ApprovalAction),
          ) as ApprovalAction;
          result.action = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ApprovalStatus),
          ) as ApprovalStatus;
          result.status = valueDes;
          break;
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerRef),
          ) as PlayerRef;
          result.player.replace(valueDes);
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ApprovalPayload),
          ) as ApprovalPayload;
          result.payload.replace(valueDes);
          break;
        case r'requestedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.requestedBy.replace(valueDes);
          break;
        case r'requestedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.requestedAt = valueDes;
          break;
        case r'decidedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PersonRef),
          ) as PersonRef?;
          if (valueDes == null) continue;
          result.decidedBy.replace(valueDes);
          break;
        case r'decidedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.decidedAt = valueDes;
          break;
        case r'decisionNote':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.decisionNote = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ApprovalRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ApprovalRequestBuilder();
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
