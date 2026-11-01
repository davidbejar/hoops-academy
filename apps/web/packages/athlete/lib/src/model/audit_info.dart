//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_info.g.dart';

/// AuditInfo
///
/// Properties:
/// * [recordedBy] 
/// * [recordedAt] 
@BuiltValue(instantiable: false)
abstract class AuditInfo  {
  @BuiltValueField(wireName: r'recordedBy')
  PersonRef get recordedBy;

  @BuiltValueField(wireName: r'recordedAt')
  DateTime get recordedAt;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuditInfo> get serializer => _$AuditInfoSerializer();
}

class _$AuditInfoSerializer implements PrimitiveSerializer<AuditInfo> {
  @override
  final Iterable<Type> types = const [AuditInfo];

  @override
  final String wireName = r'AuditInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuditInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'recordedBy';
    yield serializers.serialize(
      object.recordedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'recordedAt';
    yield serializers.serialize(
      object.recordedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AuditInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  AuditInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($AuditInfo)) as $AuditInfo;
  }
}


/// a concrete implementation of [AuditInfo], since [AuditInfo] is not instantiable
@BuiltValue(instantiable: true)
abstract class $AuditInfo implements AuditInfo, Built<$AuditInfo, $AuditInfoBuilder> {
  $AuditInfo._();

  factory $AuditInfo([void Function($AuditInfoBuilder)? updates]) = _$$AuditInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($AuditInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$AuditInfo> get serializer => _$$AuditInfoSerializer();
}

class _$$AuditInfoSerializer implements PrimitiveSerializer<$AuditInfo> {
  @override
  final Iterable<Type> types = const [$AuditInfo, _$$AuditInfo];

  @override
  final String wireName = r'$AuditInfo';

  @override
  Object serialize(
    Serializers serializers,
    $AuditInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(AuditInfo))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuditInfoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.recordedBy.replace(valueDes);
          break;
        case r'recordedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $AuditInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $AuditInfoBuilder();
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

