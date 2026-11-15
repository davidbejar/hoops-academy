// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_expense_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateExpenseRequest extends CreateExpenseRequest {
  @override
  final Date spentOn;
  @override
  final ExpenseCategory category;
  @override
  final int amountMinor;
  @override
  final String description;
  @override
  final String? note;

  factory _$CreateExpenseRequest(
          [void Function(CreateExpenseRequestBuilder)? updates]) =>
      (CreateExpenseRequestBuilder()..update(updates))._build();

  _$CreateExpenseRequest._(
      {required this.spentOn,
      required this.category,
      required this.amountMinor,
      required this.description,
      this.note})
      : super._();
  @override
  CreateExpenseRequest rebuild(
          void Function(CreateExpenseRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateExpenseRequestBuilder toBuilder() =>
      CreateExpenseRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateExpenseRequest &&
        spentOn == other.spentOn &&
        category == other.category &&
        amountMinor == other.amountMinor &&
        description == other.description &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, spentOn.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateExpenseRequest')
          ..add('spentOn', spentOn)
          ..add('category', category)
          ..add('amountMinor', amountMinor)
          ..add('description', description)
          ..add('note', note))
        .toString();
  }
}

class CreateExpenseRequestBuilder
    implements Builder<CreateExpenseRequest, CreateExpenseRequestBuilder> {
  _$CreateExpenseRequest? _$v;

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

  CreateExpenseRequestBuilder() {
    CreateExpenseRequest._defaults(this);
  }

  CreateExpenseRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _spentOn = $v.spentOn;
      _category = $v.category;
      _amountMinor = $v.amountMinor;
      _description = $v.description;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateExpenseRequest other) {
    _$v = other as _$CreateExpenseRequest;
  }

  @override
  void update(void Function(CreateExpenseRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateExpenseRequest build() => _build();

  _$CreateExpenseRequest _build() {
    final _$result = _$v ??
        _$CreateExpenseRequest._(
          spentOn: BuiltValueNullFieldError.checkNotNull(
              spentOn, r'CreateExpenseRequest', 'spentOn'),
          category: BuiltValueNullFieldError.checkNotNull(
              category, r'CreateExpenseRequest', 'category'),
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'CreateExpenseRequest', 'amountMinor'),
          description: BuiltValueNullFieldError.checkNotNull(
              description, r'CreateExpenseRequest', 'description'),
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
