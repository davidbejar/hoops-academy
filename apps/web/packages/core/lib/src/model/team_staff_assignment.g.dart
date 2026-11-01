// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_staff_assignment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamStaffAssignment extends TeamStaffAssignment {
  @override
  final StaffRole role;

  factory _$TeamStaffAssignment(
          [void Function(TeamStaffAssignmentBuilder)? updates]) =>
      (TeamStaffAssignmentBuilder()..update(updates))._build();

  _$TeamStaffAssignment._({required this.role}) : super._();
  @override
  TeamStaffAssignment rebuild(
          void Function(TeamStaffAssignmentBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamStaffAssignmentBuilder toBuilder() =>
      TeamStaffAssignmentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamStaffAssignment && role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamStaffAssignment')
          ..add('role', role))
        .toString();
  }
}

class TeamStaffAssignmentBuilder
    implements Builder<TeamStaffAssignment, TeamStaffAssignmentBuilder> {
  _$TeamStaffAssignment? _$v;

  StaffRole? _role;
  StaffRole? get role => _$this._role;
  set role(StaffRole? role) => _$this._role = role;

  TeamStaffAssignmentBuilder() {
    TeamStaffAssignment._defaults(this);
  }

  TeamStaffAssignmentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamStaffAssignment other) {
    _$v = other as _$TeamStaffAssignment;
  }

  @override
  void update(void Function(TeamStaffAssignmentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamStaffAssignment build() => _build();

  _$TeamStaffAssignment _build() {
    final _$result = _$v ??
        _$TeamStaffAssignment._(
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'TeamStaffAssignment', 'role'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
