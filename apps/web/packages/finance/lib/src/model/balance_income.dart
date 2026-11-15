//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'balance_income.g.dart';

/// BalanceIncome
///
/// Properties:
/// * [paidMinor]
/// * [openMinor]
/// * [waivedMinor]
@BuiltValue()
abstract class BalanceIncome implements Built<BalanceIncome, BalanceIncomeBuilder> {
  @BuiltValueField(wireName: r'paidMinor')
  int get paidMinor;

  @BuiltValueField(wireName: r'openMinor')
  int get openMinor;

  @BuiltValueField(wireName: r'waivedMinor')
  int get waivedMinor;

  BalanceIncome._();

  factory BalanceIncome([void updates(BalanceIncomeBuilder b)]) = _$BalanceIncome;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BalanceIncomeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BalanceIncome> get serializer => _$BalanceIncomeSerializer();
}

class _$BalanceIncomeSerializer implements PrimitiveSerializer<BalanceIncome> {
  @override
  final Iterable<Type> types = const [BalanceIncome, _$BalanceIncome];

  @override
  final String wireName = r'BalanceIncome';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BalanceIncome object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'paidMinor';
    yield serializers.serialize(
      object.paidMinor,
      specifiedType: const FullType(int),
    );
    yield r'openMinor';
    yield serializers.serialize(
      object.openMinor,
      specifiedType: const FullType(int),
    );
    yield r'waivedMinor';
    yield serializers.serialize(
      object.waivedMinor,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BalanceIncome object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BalanceIncomeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'paidMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.paidMinor = valueDes;
          break;
        case r'openMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.openMinor = valueDes;
          break;
        case r'waivedMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.waivedMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BalanceIncome deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BalanceIncomeBuilder();
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
