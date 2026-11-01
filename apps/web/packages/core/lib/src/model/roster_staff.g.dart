// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roster_staff.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RosterStaff extends RosterStaff {
  @override
  final String personId;
  @override
  final StaffRole role;

  factory _$RosterStaff([void Function(RosterStaffBuilder)? updates]) =>
      (RosterStaffBuilder()..update(updates))._build();

  _$RosterStaff._({required this.personId, required this.role}) : super._();
  @override
  RosterStaff rebuild(void Function(RosterStaffBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RosterStaffBuilder toBuilder() => RosterStaffBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RosterStaff &&
        personId == other.personId &&
        role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RosterStaff')
          ..add('personId', personId)
          ..add('role', role))
        .toString();
  }
}

class RosterStaffBuilder implements Builder<RosterStaff, RosterStaffBuilder> {
  _$RosterStaff? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  StaffRole? _role;
  StaffRole? get role => _$this._role;
  set role(StaffRole? role) => _$this._role = role;

  RosterStaffBuilder() {
    RosterStaff._defaults(this);
  }

  RosterStaffBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RosterStaff other) {
    _$v = other as _$RosterStaff;
  }

  @override
  void update(void Function(RosterStaffBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RosterStaff build() => _build();

  _$RosterStaff _build() {
    final _$result = _$v ??
        _$RosterStaff._(
          personId: BuiltValueNullFieldError.checkNotNull(
              personId, r'RosterStaff', 'personId'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'RosterStaff', 'role'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
