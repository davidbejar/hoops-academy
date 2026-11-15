// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Expense extends Expense {
  @override
  final String id;
  @override
  final Date spentOn;
  @override
  final ExpenseCategory category;
  @override
  final int amountMinor;
  @override
  final String currency;
  @override
  final String description;
  @override
  final String? note;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Expense([void Function(ExpenseBuilder)? updates]) =>
      (ExpenseBuilder()..update(updates))._build();

  _$Expense._(
      {required this.id,
      required this.spentOn,
      required this.category,
      required this.amountMinor,
      required this.currency,
      required this.description,
      this.note,
      required this.createdAt,
      required this.updatedAt})
      : super._();
  @override
  Expense rebuild(void Function(ExpenseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpenseBuilder toBuilder() => ExpenseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Expense &&
        id == other.id &&
        spentOn == other.spentOn &&
        category == other.category &&
        amountMinor == other.amountMinor &&
        currency == other.currency &&
        description == other.description &&
        note == other.note &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, spentOn.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Expense')
          ..add('id', id)
          ..add('spentOn', spentOn)
          ..add('category', category)
          ..add('amountMinor', amountMinor)
          ..add('currency', currency)
          ..add('description', description)
          ..add('note', note)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ExpenseBuilder implements Builder<Expense, ExpenseBuilder> {
  _$Expense? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Date? _spentOn;
  Date? get spentOn => _$this._spentOn;
  set spentOn(Date? spentOn) => _$this._spentOn = spentOn;

  ExpenseCategory? _category;
  ExpenseCategory? get category => _$this._category;
  set category(ExpenseCategory? category) => _$this._category = category;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ExpenseBuilder() {
    Expense._defaults(this);
  }

  ExpenseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _spentOn = $v.spentOn;
      _category = $v.category;
      _amountMinor = $v.amountMinor;
      _currency = $v.currency;
      _description = $v.description;
      _note = $v.note;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Expense other) {
    _$v = other as _$Expense;
  }

  @override
  void update(void Function(ExpenseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Expense build() => _build();

  _$Expense _build() {
    final _$result = _$v ??
        _$Expense._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Expense', 'id'),
          spentOn: BuiltValueNullFieldError.checkNotNull(
              spentOn, r'Expense', 'spentOn'),
          category: BuiltValueNullFieldError.checkNotNull(
              category, r'Expense', 'category'),
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'Expense', 'amountMinor'),
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'Expense', 'currency'),
          description: BuiltValueNullFieldError.checkNotNull(
              description, r'Expense', 'description'),
          note: note,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'Expense', 'createdAt'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'Expense', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
