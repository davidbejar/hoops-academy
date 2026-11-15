//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/payment.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_finance_api/src/model/due_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'due_detail.g.dart';

/// DueDetail
///
/// Properties:
/// * [id]
/// * [feePlanId]
/// * [feePlanName]
/// * [playerId]
/// * [playerName]
/// * [teamId] - The team through which the player owed it.
/// * [period] - A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
/// * [periodStart]
/// * [periodEnd]
/// * [amountMinor] - What is owed (the plan's amount when generated, unless ADMIN changed it).
/// * [planAmountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [currency] - Alphabetic ISO 4217 code of the academy's currency.
/// * [status]
/// * [reason] - Of the last waiver or amount change.
/// * [payment] - The valid (not voided) payment of a PAID due.
/// * [createdAt]
/// * [updatedAt]
/// * [payments] - Every payment recorded for the due, voided ones included, oldest first.
@BuiltValue()
abstract class DueDetail implements Built<DueDetail, DueDetailBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'feePlanId')
  String get feePlanId;

  @BuiltValueField(wireName: r'feePlanName')
  String get feePlanName;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'playerName')
  String get playerName;

  /// The team through which the player owed it.
  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  /// A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
  @BuiltValueField(wireName: r'period')
  String get period;

  @BuiltValueField(wireName: r'periodStart')
  Date get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  Date get periodEnd;

  /// What is owed (the plan's amount when generated, unless ADMIN changed it).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'planAmountMinor')
  int get planAmountMinor;

  /// Alphabetic ISO 4217 code of the academy's currency.
  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'status')
  DueStatus get status;
  // enum statusEnum {  OPEN,  PAID,  WAIVED,  };

  /// Of the last waiver or amount change.
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  /// The valid (not voided) payment of a PAID due.
  @BuiltValueField(wireName: r'payment')
  Payment? get payment;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  /// Every payment recorded for the due, voided ones included, oldest first.
  @BuiltValueField(wireName: r'payments')
  BuiltList<Payment> get payments;

  DueDetail._();

  factory DueDetail([void updates(DueDetailBuilder b)]) = _$DueDetail;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DueDetailBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DueDetail> get serializer => _$DueDetailSerializer();
}

class _$DueDetailSerializer implements PrimitiveSerializer<DueDetail> {
  @override
  final Iterable<Type> types = const [DueDetail, _$DueDetail];

  @override
  final String wireName = r'DueDetail';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DueDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'feePlanId';
    yield serializers.serialize(
      object.feePlanId,
      specifiedType: const FullType(String),
    );
    yield r'feePlanName';
    yield serializers.serialize(
      object.feePlanName,
      specifiedType: const FullType(String),
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
    yield r'planAmountMinor';
    yield serializers.serialize(
      object.planAmountMinor,
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
    yield r'reason';
    yield object.reason == null ? null : serializers.serialize(
      object.reason,
      specifiedType: const FullType.nullable(String),
    );
    yield r'payment';
    yield object.payment == null ? null : serializers.serialize(
      object.payment,
      specifiedType: const FullType.nullable(Payment),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'payments';
    yield serializers.serialize(
      object.payments,
      specifiedType: const FullType(BuiltList, [FullType(Payment)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DueDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DueDetailBuilder result,
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
        case r'feePlanId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feePlanId = valueDes;
          break;
        case r'feePlanName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feePlanName = valueDes;
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
        case r'planAmountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.planAmountMinor = valueDes;
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
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'payment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Payment),
          ) as Payment?;
          if (valueDes == null) continue;
          result.payment.replace(valueDes);
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'payments':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Payment)]),
          ) as BuiltList<Payment>;
          result.payments.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DueDetail deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DueDetailBuilder();
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
