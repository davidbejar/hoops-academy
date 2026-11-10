//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/age_rule.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_settings.g.dart';

/// TenantSettings
///
/// Properties:
/// * [ageRule] 
/// * [maxPlayUpLevels] - Maximum category levels a player may play up; null = unlimited.
/// * [attendanceLateThresholdMinutes] - Minutes after which a LATE arrival is highlighted.
@BuiltValue()
abstract class TenantSettings implements Built<TenantSettings, TenantSettingsBuilder> {
  @BuiltValueField(wireName: r'ageRule')
  AgeRule get ageRule;
  // enum ageRuleEnum {  BIRTH_YEAR,  BIRTHDAY,  };

  /// Maximum category levels a player may play up; null = unlimited.
  @BuiltValueField(wireName: r'maxPlayUpLevels')
  int? get maxPlayUpLevels;

  /// Minutes after which a LATE arrival is highlighted.
  @BuiltValueField(wireName: r'attendanceLateThresholdMinutes')
  int? get attendanceLateThresholdMinutes;

  TenantSettings._();

  factory TenantSettings([void updates(TenantSettingsBuilder b)]) = _$TenantSettings;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantSettingsBuilder b) => b
      ..attendanceLateThresholdMinutes = 10;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantSettings> get serializer => _$TenantSettingsSerializer();
}

class _$TenantSettingsSerializer implements PrimitiveSerializer<TenantSettings> {
  @override
  final Iterable<Type> types = const [TenantSettings, _$TenantSettings];

  @override
  final String wireName = r'TenantSettings';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantSettings object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ageRule';
    yield serializers.serialize(
      object.ageRule,
      specifiedType: const FullType(AgeRule),
    );
    yield r'maxPlayUpLevels';
    yield object.maxPlayUpLevels == null ? null : serializers.serialize(
      object.maxPlayUpLevels,
      specifiedType: const FullType.nullable(int),
    );
    if (object.attendanceLateThresholdMinutes != null) {
      yield r'attendanceLateThresholdMinutes';
      yield serializers.serialize(
        object.attendanceLateThresholdMinutes,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantSettings object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantSettingsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ageRule':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AgeRule),
          ) as AgeRule;
          result.ageRule = valueDes;
          break;
        case r'maxPlayUpLevels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.maxPlayUpLevels = valueDes;
          break;
        case r'attendanceLateThresholdMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.attendanceLateThresholdMinutes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantSettings deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantSettingsBuilder();
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


