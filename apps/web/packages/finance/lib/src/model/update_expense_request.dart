//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/expense_category.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_expense_request.g.dart';

/// UpdateExpenseRequest
///
/// Properties:
/// * [spentOn]
/// * [category]
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [description]
/// * [note]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateExpenseRequest implements Built<UpdateExpenseRequest, UpdateExpenseRequestBuilder> {
  @BuiltValueField(wireName: r'spentOn')
  Date? get spentOn;

  @BuiltValueField(wireName: r'category')
  ExpenseCategory? get category;
  // enum categoryEnum {  COURT_RENTAL,  SALARIES,  KIT,  TOURNAMENT_FEES,  TRAVEL,  OTHER,  };

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int? get amountMinor;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'note')
  String? get note;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateExpenseRequestClearEnum>? get clear;
  // enum clearEnum {  note,  };

  UpdateExpenseRequest._();

  factory UpdateExpenseRequest([void updates(UpdateExpenseRequestBuilder b)]) = _$UpdateExpenseRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateExpenseRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateExpenseRequest> get serializer => _$UpdateExpenseRequestSerializer();
}

class _$UpdateExpenseRequestSerializer implements PrimitiveSerializer<UpdateExpenseRequest> {
  @override
  final Iterable<Type> types = const [UpdateExpenseRequest, _$UpdateExpenseRequest];

  @override
  final String wireName = r'UpdateExpenseRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateExpenseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.spentOn != null) {
      yield r'spentOn';
      yield serializers.serialize(
        object.spentOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType(ExpenseCategory),
      );
    }
    if (object.amountMinor != null) {
      yield r'amountMinor';
      yield serializers.serialize(
        object.amountMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateExpenseRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateExpenseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateExpenseRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'spentOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.spentOn = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ExpenseCategory),
          ) as ExpenseCategory?;
          if (valueDes == null) continue;
          result.category = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.amountMinor = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateExpenseRequestClearEnum)]),
          ) as BuiltSet<UpdateExpenseRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateExpenseRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateExpenseRequestBuilder();
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


class UpdateExpenseRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'note')
  static const UpdateExpenseRequestClearEnum note = _$updateExpenseRequestClearEnum_note;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateExpenseRequestClearEnum unknownDefaultOpenApi = _$updateExpenseRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateExpenseRequestClearEnum> get serializer => _$updateExpenseRequestClearEnumSerializer;

  const UpdateExpenseRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateExpenseRequestClearEnum> get values => _$updateExpenseRequestClearEnumValues;
  static UpdateExpenseRequestClearEnum valueOf(String name) => _$updateExpenseRequestClearEnumValueOf(name);
}
