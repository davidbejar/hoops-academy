// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_ref.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PersonRef extends PersonRef {
  @override
  final String personId;
  @override
  final String displayName;

  factory _$PersonRef([void Function(PersonRefBuilder)? updates]) =>
      (PersonRefBuilder()..update(updates))._build();

  _$PersonRef._({required this.personId, required this.displayName})
      : super._();
  @override
  PersonRef rebuild(void Function(PersonRefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PersonRefBuilder toBuilder() => PersonRefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PersonRef &&
        personId == other.personId &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PersonRef')
          ..add('personId', personId)
          ..add('displayName', displayName))
        .toString();
  }
}

class PersonRefBuilder implements Builder<PersonRef, PersonRefBuilder> {
  _$PersonRef? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  PersonRefBuilder() {
    PersonRef._defaults(this);
  }

  PersonRefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PersonRef other) {
    _$v = other as _$PersonRef;
  }

  @override
  void update(void Function(PersonRefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PersonRef build() => _build();

  _$PersonRef _build() {
    final _$result = _$v ??
        _$PersonRef._(
          personId: BuiltValueNullFieldError.checkNotNull(
              personId, r'PersonRef', 'personId'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'PersonRef', 'displayName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
