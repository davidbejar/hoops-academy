//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'generated_due.g.dart';

/// GeneratedDue
///
/// Properties:
/// * [dueId] - null in a preview.
/// * [playerId]
/// * [playerName]
/// * [teamId]
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
@BuiltValue()
abstract class GeneratedDue implements Built<GeneratedDue, GeneratedDueBuilder> {
  /// null in a preview.
  @BuiltValueField(wireName: r'dueId')
  String? get dueId;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'playerName')
  String get playerName;

  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  GeneratedDue._();

  factory GeneratedDue([void updates(GeneratedDueBuilder b)]) = _$GeneratedDue;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GeneratedDueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GeneratedDue> get serializer => _$GeneratedDueSerializer();
}

class _$GeneratedDueSerializer implements PrimitiveSerializer<GeneratedDue> {
  @override
  final Iterable<Type> types = const [GeneratedDue, _$GeneratedDue];

  @override
  final String wireName = r'GeneratedDue';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GeneratedDue object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'dueId';
    yield object.dueId == null ? null : serializers.serialize(
      object.dueId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'playerName';
    yield serializers.serialize(
      object.playerName,
      specifiedType: const FullType(String),
    );
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GeneratedDue object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GeneratedDueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'dueId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.dueId = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'playerName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerName = valueDes;
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GeneratedDue deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GeneratedDueBuilder();
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
