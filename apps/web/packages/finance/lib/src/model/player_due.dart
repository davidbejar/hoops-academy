//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/payment_method.dart';
import 'package:hoops_finance_api/src/model/due_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_due.g.dart';

/// A due as the family sees it (no reasons, notes or voided payments).
///
/// Properties:
/// * [id]
/// * [feePlanName]
/// * [period] - A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
/// * [periodStart]
/// * [periodEnd]
/// * [amountMinor]
/// * [currency] - Alphabetic ISO 4217 code of the academy's currency.
/// * [status]
/// * [paidOn]
/// * [paymentMethod]
@BuiltValue()
abstract class PlayerDue implements Built<PlayerDue, PlayerDueBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'feePlanName')
  String get feePlanName;

  /// A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
  @BuiltValueField(wireName: r'period')
  String get period;

  @BuiltValueField(wireName: r'periodStart')
  Date get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  Date get periodEnd;

  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// Alphabetic ISO 4217 code of the academy's currency.
  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'status')
  DueStatus get status;
  // enum statusEnum {  OPEN,  PAID,  WAIVED,  };

  @BuiltValueField(wireName: r'paidOn')
  Date? get paidOn;

  @BuiltValueField(wireName: r'paymentMethod')
  PaymentMethod? get paymentMethod;
  // enum paymentMethodEnum {  CASH,  BANK_TRANSFER,  CARD,  OTHER,  };

  PlayerDue._();

  factory PlayerDue([void updates(PlayerDueBuilder b)]) = _$PlayerDue;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerDueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerDue> get serializer => _$PlayerDueSerializer();
}

class _$PlayerDueSerializer implements PrimitiveSerializer<PlayerDue> {
  @override
  final Iterable<Type> types = const [PlayerDue, _$PlayerDue];

  @override
  final String wireName = r'PlayerDue';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerDue object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'feePlanName';
    yield serializers.serialize(
      object.feePlanName,
      specifiedType: const FullType(String),
    );
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(String),
    );
    yield r'periodStart';
    yield serializers.serialize(
      object.periodStart,
      specifiedType: const FullType(Date),
    );
    yield r'periodEnd';
    yield serializers.serialize(
      object.periodEnd,
      specifiedType: const FullType(Date),
    );
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DueStatus),
    );
    yield r'paidOn';
    yield object.paidOn == null ? null : serializers.serialize(
      object.paidOn,
      specifiedType: const FullType.nullable(Date),
    );
    yield r'paymentMethod';
    yield object.paymentMethod == null ? null : serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType.nullable(PaymentMethod),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerDue object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerDueBuilder result,
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
        case r'feePlanName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feePlanName = valueDes;
          break;
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.period = valueDes;
          break;
        case r'periodStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodStart = valueDes;
          break;
        case r'periodEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodEnd = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DueStatus),
          ) as DueStatus;
          result.status = valueDes;
          break;
        case r'paidOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.paidOn = valueDes;
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PaymentMethod),
          ) as PaymentMethod?;
          if (valueDes == null) continue;
          result.paymentMethod = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerDue deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerDueBuilder();
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
