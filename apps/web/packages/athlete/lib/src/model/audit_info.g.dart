// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_info.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class AuditInfoBuilder {
  void replace(AuditInfo other);
  void update(void Function(AuditInfoBuilder) updates);
  PersonRefBuilder get recordedBy;
  set recordedBy(PersonRefBuilder? recordedBy);

  DateTime? get recordedAt;
  set recordedAt(DateTime? recordedAt);
}

class _$$AuditInfo extends $AuditInfo {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$$AuditInfo([void Function($AuditInfoBuilder)? updates]) =>
      ($AuditInfoBuilder()..update(updates))._build();

  _$$AuditInfo._({required this.recordedBy, required this.recordedAt})
      : super._();
  @override
  $AuditInfo rebuild(void Function($AuditInfoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $AuditInfoBuilder toBuilder() => $AuditInfoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $AuditInfo &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$AuditInfo')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class $AuditInfoBuilder
    implements Builder<$AuditInfo, $AuditInfoBuilder>, AuditInfoBuilder {
  _$$AuditInfo? _$v;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  $AuditInfoBuilder() {
    $AuditInfo._defaults(this);
  }

  $AuditInfoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $AuditInfo other) {
    _$v = other as _$$AuditInfo;
  }

  @override
  void update(void Function($AuditInfoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $AuditInfo build() => _build();

  _$$AuditInfo _build() {
    _$$AuditInfo _$result;
    try {
      _$result = _$v ??
          _$$AuditInfo._(
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'$AuditInfo', 'recordedAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'$AuditInfo', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
