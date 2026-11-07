//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/approval_request.dart';
import 'package:hoops_core_api/src/model/player.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_command_result.g.dart';

/// Outcome of an add/withdraw command; `approvalRequest.status` tells whether it took effect (APPROVED) or awaits a decision (PENDING).
///
/// Properties:
/// * [player]
/// * [approvalRequest]
/// * [temporaryPassword] - Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
@BuiltValue()
abstract class PlayerCommandResult
    implements Built<PlayerCommandResult, PlayerCommandResultBuilder> {
  @BuiltValueField(wireName: r'player')
  Player get player;

  @BuiltValueField(wireName: r'approvalRequest')
  ApprovalRequest get approvalRequest;

  /// Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
  @BuiltValueField(wireName: r'temporaryPassword')
  String? get temporaryPassword;

  PlayerCommandResult._();

  factory PlayerCommandResult([void updates(PlayerCommandResultBuilder b)]) =
      _$PlayerCommandResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerCommandResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerCommandResult> get serializer =>
      _$PlayerCommandResultSerializer();
}

class _$PlayerCommandResultSerializer
    implements PrimitiveSerializer<PlayerCommandResult> {
  @override
  final Iterable<Type> types = const [
    PlayerCommandResult,
    _$PlayerCommandResult
  ];

  @override
  final String wireName = r'PlayerCommandResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerCommandResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(Player),
    );
    yield r'approvalRequest';
    yield serializers.serialize(
      object.approvalRequest,
      specifiedType: const FullType(ApprovalRequest),
    );
    if (object.temporaryPassword != null) {
      yield r'temporaryPassword';
      yield serializers.serialize(
        object.temporaryPassword,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerCommandResult object, {
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
    required PlayerCommandResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Player),
          ) as Player;
          result.player.replace(valueDes);
          break;
        case r'approvalRequest':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ApprovalRequest),
          ) as ApprovalRequest;
          result.approvalRequest.replace(valueDes);
          break;
        case r'temporaryPassword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.temporaryPassword = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerCommandResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerCommandResultBuilder();
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
