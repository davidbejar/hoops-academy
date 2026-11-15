// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_expense_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateExpenseRequestClearEnum _$updateExpenseRequestClearEnum_note =
    const UpdateExpenseRequestClearEnum._('note');
const UpdateExpenseRequestClearEnum
    _$updateExpenseRequestClearEnum_unknownDefaultOpenApi =
    const UpdateExpenseRequestClearEnum._('unknownDefaultOpenApi');

UpdateExpenseRequestClearEnum _$updateExpenseRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'note':
      return _$updateExpenseRequestClearEnum_note;
    case 'unknownDefaultOpenApi':
      return _$updateExpenseRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateExpenseRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateExpenseRequestClearEnum>
    _$updateExpenseRequestClearEnumValues = BuiltSet<
        UpdateExpenseRequestClearEnum>(const <UpdateExpenseRequestClearEnum>[
  _$updateExpenseRequestClearEnum_note,
  _$updateExpenseRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateExpenseRequestClearEnum>
    _$updateExpenseRequestClearEnumSerializer =
    _$UpdateExpenseRequestClearEnumSerializer();

class _$UpdateExpenseRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateExpenseRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'note': 'note',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'note': 'note',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateExpenseRequestClearEnum];
  @override
  final String wireName = 'UpdateExpenseRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateExpenseRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateExpenseRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateExpenseRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateExpenseRequest extends UpdateExpenseRequest {
  @override
  final Date? spentOn;
  @override
  final ExpenseCategory? category;
  @override
  final int? amountMinor;
  @override
  final String? description;
  @override
  final String? note;
  @override
  final BuiltSet<UpdateExpenseRequestClearEnum>? clear;

  factory _$UpdateExpenseRequest(
          [void Function(UpdateExpenseRequestBuilder)? updates]) =>
      (UpdateExpenseRequestBuilder()..update(updates))._build();

  _$UpdateExpenseRequest._(
      {this.spentOn,
      this.category,
      this.amountMinor,
      this.description,
      this.note,
      this.clear})
      : super._();
  @override
  UpdateExpenseRequest rebuild(
          void Function(UpdateExpenseRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateExpenseRequestBuilder toBuilder() =>
      UpdateExpenseRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateExpenseRequest &&
        spentOn == other.spentOn &&
        category == other.category &&
        amountMinor == other.amountMinor &&
        description == other.description &&
        note == other.note &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, spentOn.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateExpenseRequest')
          ..add('spentOn', spentOn)
          ..add('category', category)
          ..add('amountMinor', amountMinor)
          ..add('description', description)
          ..add('note', note)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateExpenseRequestBuilder
    implements Builder<UpdateExpenseRequest, UpdateExpenseRequestBuilder> {
  _$UpdateExpenseRequest? _$v;

  Date? _spentOn;
  Date? get spentOn => _$this._spentOn;
  set spentOn(Date? spentOn) => _$this._spentOn = spentOn;

  ExpenseCategory? _category;
  ExpenseCategory? get category => _$this._category;
  set category(ExpenseCategory? category) => _$this._category = category;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  SetBuilder<UpdateExpenseRequestClearEnum>? _clear;
  SetBuilder<UpdateExpenseRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateExpenseRequestClearEnum>();
  set clear(SetBuilder<UpdateExpenseRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateExpenseRequestBuilder() {
    UpdateExpenseRequest._defaults(this);
  }

  UpdateExpenseRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _spentOn = $v.spentOn;
      _category = $v.category;
      _amountMinor = $v.amountMinor;
      _description = $v.description;
      _note = $v.note;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateExpenseRequest other) {
    _$v = other as _$UpdateExpenseRequest;
  }

  @override
  void update(void Function(UpdateExpenseRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateExpenseRequest build() => _build();

  _$UpdateExpenseRequest _build() {
    _$UpdateExpenseRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateExpenseRequest._(
            spentOn: spentOn,
            category: category,
            amountMinor: amountMinor,
            description: description,
            note: note,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateExpenseRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
