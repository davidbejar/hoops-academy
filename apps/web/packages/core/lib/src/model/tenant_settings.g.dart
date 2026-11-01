// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_settings.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantSettings extends TenantSettings {
  @override
  final AgeRule ageRule;
  @override
  final int? maxPlayUpLevels;
  @override
  final int? attendanceLateThresholdMinutes;

  factory _$TenantSettings([void Function(TenantSettingsBuilder)? updates]) =>
      (TenantSettingsBuilder()..update(updates))._build();

  _$TenantSettings._(
      {required this.ageRule,
      this.maxPlayUpLevels,
      this.attendanceLateThresholdMinutes})
      : super._();
  @override
  TenantSettings rebuild(void Function(TenantSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantSettingsBuilder toBuilder() => TenantSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantSettings &&
        ageRule == other.ageRule &&
        maxPlayUpLevels == other.maxPlayUpLevels &&
        attendanceLateThresholdMinutes == other.attendanceLateThresholdMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ageRule.hashCode);
    _$hash = $jc(_$hash, maxPlayUpLevels.hashCode);
    _$hash = $jc(_$hash, attendanceLateThresholdMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantSettings')
          ..add('ageRule', ageRule)
          ..add('maxPlayUpLevels', maxPlayUpLevels)
          ..add(
              'attendanceLateThresholdMinutes', attendanceLateThresholdMinutes))
        .toString();
  }
}

class TenantSettingsBuilder
    implements Builder<TenantSettings, TenantSettingsBuilder> {
  _$TenantSettings? _$v;

  AgeRule? _ageRule;
  AgeRule? get ageRule => _$this._ageRule;
  set ageRule(AgeRule? ageRule) => _$this._ageRule = ageRule;

  int? _maxPlayUpLevels;
  int? get maxPlayUpLevels => _$this._maxPlayUpLevels;
  set maxPlayUpLevels(int? maxPlayUpLevels) =>
      _$this._maxPlayUpLevels = maxPlayUpLevels;

  int? _attendanceLateThresholdMinutes;
  int? get attendanceLateThresholdMinutes =>
      _$this._attendanceLateThresholdMinutes;
  set attendanceLateThresholdMinutes(int? attendanceLateThresholdMinutes) =>
      _$this._attendanceLateThresholdMinutes = attendanceLateThresholdMinutes;

  TenantSettingsBuilder() {
    TenantSettings._defaults(this);
  }

  TenantSettingsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ageRule = $v.ageRule;
      _maxPlayUpLevels = $v.maxPlayUpLevels;
      _attendanceLateThresholdMinutes = $v.attendanceLateThresholdMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantSettings other) {
    _$v = other as _$TenantSettings;
  }

  @override
  void update(void Function(TenantSettingsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantSettings build() => _build();

  _$TenantSettings _build() {
    final _$result = _$v ??
        _$TenantSettings._(
          ageRule: BuiltValueNullFieldError.checkNotNull(
              ageRule, r'TenantSettings', 'ageRule'),
          maxPlayUpLevels: maxPlayUpLevels,
          attendanceLateThresholdMinutes: attendanceLateThresholdMinutes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
