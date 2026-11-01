// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_ref.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamRef extends TeamRef {
  @override
  final String id;
  @override
  final String name;

  factory _$TeamRef([void Function(TeamRefBuilder)? updates]) =>
      (TeamRefBuilder()..update(updates))._build();

  _$TeamRef._({required this.id, required this.name}) : super._();
  @override
  TeamRef rebuild(void Function(TeamRefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamRefBuilder toBuilder() => TeamRefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamRef && id == other.id && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamRef')
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class TeamRefBuilder implements Builder<TeamRef, TeamRefBuilder> {
  _$TeamRef? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  TeamRefBuilder() {
    TeamRef._defaults(this);
  }

  TeamRefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamRef other) {
    _$v = other as _$TeamRef;
  }

  @override
  void update(void Function(TeamRefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamRef build() => _build();

  _$TeamRef _build() {
    final _$result = _$v ??
        _$TeamRef._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'TeamRef', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'TeamRef', 'name'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
