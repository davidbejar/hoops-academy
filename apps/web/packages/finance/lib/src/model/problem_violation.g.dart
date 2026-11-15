// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_violation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProblemViolation extends ProblemViolation {
  @override
  final String? field;
  @override
  final String? code;
  @override
  final String message;

  factory _$ProblemViolation(
          [void Function(ProblemViolationBuilder)? updates]) =>
      (ProblemViolationBuilder()..update(updates))._build();

  _$ProblemViolation._({this.field, this.code, required this.message})
      : super._();
  @override
  ProblemViolation rebuild(void Function(ProblemViolationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProblemViolationBuilder toBuilder() =>
      ProblemViolationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProblemViolation &&
        field == other.field &&
        code == other.code &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, field.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProblemViolation')
          ..add('field', field)
          ..add('code', code)
          ..add('message', message))
        .toString();
  }
}

class ProblemViolationBuilder
    implements Builder<ProblemViolation, ProblemViolationBuilder> {
  _$ProblemViolation? _$v;

  String? _field;
  String? get field => _$this._field;
  set field(String? field) => _$this._field = field;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  ProblemViolationBuilder() {
    ProblemViolation._defaults(this);
  }

  ProblemViolationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _field = $v.field;
      _code = $v.code;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProblemViolation other) {
    _$v = other as _$ProblemViolation;
  }

  @override
  void update(void Function(ProblemViolationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProblemViolation build() => _build();

  _$ProblemViolation _build() {
    final _$result = _$v ??
        _$ProblemViolation._(
          field: field,
          code: code,
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'ProblemViolation', 'message'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
