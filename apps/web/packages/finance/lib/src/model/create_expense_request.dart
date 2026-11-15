//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/expense_category.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_expense_request.g.dart';

/// CreateExpenseRequest
///
/// Properties:
/// * [spentOn]
/// * [category]
/// * [amountMinor] - An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
/// * [description] - What it was for (e.g. \"Court, March\"); no names with salaries (P-12).
/// * [note]
@BuiltValue()
abstract class CreateExpenseRequest implements Built<CreateExpenseRequest, CreateExpenseRequestBuilder> {
  @BuiltValueField(wireName: r'spentOn')
  Date get spentOn;

  @BuiltValueField(wireName: r'category')
  ExpenseCategory get category;
  // enum categoryEnum {  COURT_RENTAL,  SALARIES,  KIT,  TOURNAMENT_FEES,  TRAVEL,  OTHER,  };

  /// An amount in the minor unit of the academy's currency (EUR cents, IDR sen, JPY yen).
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// What it was for (e.g. \"Court, March\"); no names with salaries (P-12).
  @BuiltValueField(wireName: r'description')
  String get description;

  @BuiltValueField(wireName: r'note')
  String? get note;

  CreateExpenseRequest._();

  factory CreateExpenseRequest([void updates(CreateExpenseRequestBuilder b)]) = _$CreateExpenseRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateExpenseRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateExpenseRequest> get serializer => _$CreateExpenseRequestSerializer();
}

class _$CreateExpenseRequestSerializer implements PrimitiveSerializer<CreateExpenseRequest> {
  @override
  final Iterable<Type> types = const [CreateExpenseRequest, _$CreateExpenseRequest];

  @override
  final String wireName = r'CreateExpenseRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateExpenseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'spentOn';
    yield serializers.serialize(
      object.spentOn,
      specifiedType: const FullType(Date),
    );
    yield r'category';
    yield serializers.serialize(
      object.category,
      specifiedType: const FullType(ExpenseCategory),
    );
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'description';
    yield serializers.serialize(
      object.description,
      specifiedType: const FullType(String),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateExpenseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateExpenseRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'spentOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.spentOn = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ExpenseCategory),
          ) as ExpenseCategory;
          result.category = valueDes;
          break;
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateExpenseRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateExpenseRequestBuilder();
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
