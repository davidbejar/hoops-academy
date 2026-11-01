// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_staff_member.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamStaffMember extends TeamStaffMember {
  @override
  final PersonRef person;
  @override
  final StaffRole role;
  @override
  final Date since;

  factory _$TeamStaffMember([void Function(TeamStaffMemberBuilder)? updates]) =>
      (TeamStaffMemberBuilder()..update(updates))._build();

  _$TeamStaffMember._(
      {required this.person, required this.role, required this.since})
      : super._();
  @override
  TeamStaffMember rebuild(void Function(TeamStaffMemberBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamStaffMemberBuilder toBuilder() => TeamStaffMemberBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamStaffMember &&
        person == other.person &&
        role == other.role &&
        since == other.since;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, person.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, since.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamStaffMember')
          ..add('person', person)
          ..add('role', role)
          ..add('since', since))
        .toString();
  }
}

class TeamStaffMemberBuilder
    implements Builder<TeamStaffMember, TeamStaffMemberBuilder> {
  _$TeamStaffMember? _$v;

  PersonRefBuilder? _person;
  PersonRefBuilder get person => _$this._person ??= PersonRefBuilder();
  set person(PersonRefBuilder? person) => _$this._person = person;

  StaffRole? _role;
  StaffRole? get role => _$this._role;
  set role(StaffRole? role) => _$this._role = role;

  Date? _since;
  Date? get since => _$this._since;
  set since(Date? since) => _$this._since = since;

  TeamStaffMemberBuilder() {
    TeamStaffMember._defaults(this);
  }

  TeamStaffMemberBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _person = $v.person.toBuilder();
      _role = $v.role;
      _since = $v.since;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamStaffMember other) {
    _$v = other as _$TeamStaffMember;
  }

  @override
  void update(void Function(TeamStaffMemberBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamStaffMember build() => _build();

  _$TeamStaffMember _build() {
    _$TeamStaffMember _$result;
    try {
      _$result = _$v ??
          _$TeamStaffMember._(
            person: person.build(),
            role: BuiltValueNullFieldError.checkNotNull(
                role, r'TeamStaffMember', 'role'),
            since: BuiltValueNullFieldError.checkNotNull(
                since, r'TeamStaffMember', 'since'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'person';
        person.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TeamStaffMember', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
