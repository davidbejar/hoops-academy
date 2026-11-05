// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_target.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditTarget extends AuditTarget {
  @override
  final AuditTargetType type;
  @override
  final String id;
  @override
  final String? displayName;

  factory _$AuditTarget([void Function(AuditTargetBuilder)? updates]) =>
      (AuditTargetBuilder()..update(updates))._build();

  _$AuditTarget._({required this.type, required this.id, this.displayName})
      : super._();
  @override
  AuditTarget rebuild(void Function(AuditTargetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditTargetBuilder toBuilder() => AuditTargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditTarget &&
        type == other.type &&
        id == other.id &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditTarget')
          ..add('type', type)
          ..add('id', id)
          ..add('displayName', displayName))
        .toString();
  }
}

class AuditTargetBuilder implements Builder<AuditTarget, AuditTargetBuilder> {
  _$AuditTarget? _$v;

  AuditTargetType? _type;
  AuditTargetType? get type => _$this._type;
  set type(AuditTargetType? type) => _$this._type = type;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  AuditTargetBuilder() {
    AuditTarget._defaults(this);
  }

  AuditTargetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _id = $v.id;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditTarget other) {
    _$v = other as _$AuditTarget;
  }

  @override
  void update(void Function(AuditTargetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditTarget build() => _build();

  _$AuditTarget _build() {
    final _$result = _$v ??
        _$AuditTarget._(
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'AuditTarget', 'type'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'AuditTarget', 'id'),
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
