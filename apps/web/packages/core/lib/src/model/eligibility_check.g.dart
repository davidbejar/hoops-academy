// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_check.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EligibilityCheck extends EligibilityCheck {
  @override
  final String playerId;
  @override
  final String teamId;
  @override
  final Date asOf;
  @override
  final EligibilityResult result;
  @override
  final int? playUpLevels;
  @override
  final BuiltList<EligibilityReason> reasons;
  @override
  final int? age;
  @override
  final AgeCategory? naturalCategory;

  factory _$EligibilityCheck(
          [void Function(EligibilityCheckBuilder)? updates]) =>
      (EligibilityCheckBuilder()..update(updates))._build();

  _$EligibilityCheck._(
      {required this.playerId,
      required this.teamId,
      required this.asOf,
      required this.result,
      this.playUpLevels,
      required this.reasons,
      this.age,
      this.naturalCategory})
      : super._();
  @override
  EligibilityCheck rebuild(void Function(EligibilityCheckBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EligibilityCheckBuilder toBuilder() =>
      EligibilityCheckBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EligibilityCheck &&
        playerId == other.playerId &&
        teamId == other.teamId &&
        asOf == other.asOf &&
        result == other.result &&
        playUpLevels == other.playUpLevels &&
        reasons == other.reasons &&
        age == other.age &&
        naturalCategory == other.naturalCategory;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, asOf.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, playUpLevels.hashCode);
    _$hash = $jc(_$hash, reasons.hashCode);
    _$hash = $jc(_$hash, age.hashCode);
    _$hash = $jc(_$hash, naturalCategory.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EligibilityCheck')
          ..add('playerId', playerId)
          ..add('teamId', teamId)
          ..add('asOf', asOf)
          ..add('result', result)
          ..add('playUpLevels', playUpLevels)
          ..add('reasons', reasons)
          ..add('age', age)
          ..add('naturalCategory', naturalCategory))
        .toString();
  }
}

class EligibilityCheckBuilder
    implements Builder<EligibilityCheck, EligibilityCheckBuilder> {
  _$EligibilityCheck? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  Date? _asOf;
  Date? get asOf => _$this._asOf;
  set asOf(Date? asOf) => _$this._asOf = asOf;

  EligibilityResult? _result;
  EligibilityResult? get result => _$this._result;
  set result(EligibilityResult? result) => _$this._result = result;

  int? _playUpLevels;
  int? get playUpLevels => _$this._playUpLevels;
  set playUpLevels(int? playUpLevels) => _$this._playUpLevels = playUpLevels;

  ListBuilder<EligibilityReason>? _reasons;
  ListBuilder<EligibilityReason> get reasons =>
      _$this._reasons ??= ListBuilder<EligibilityReason>();
  set reasons(ListBuilder<EligibilityReason>? reasons) =>
      _$this._reasons = reasons;

  int? _age;
  int? get age => _$this._age;
  set age(int? age) => _$this._age = age;

  AgeCategoryBuilder? _naturalCategory;
  AgeCategoryBuilder get naturalCategory =>
      _$this._naturalCategory ??= AgeCategoryBuilder();
  set naturalCategory(AgeCategoryBuilder? naturalCategory) =>
      _$this._naturalCategory = naturalCategory;

  EligibilityCheckBuilder() {
    EligibilityCheck._defaults(this);
  }

  EligibilityCheckBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _teamId = $v.teamId;
      _asOf = $v.asOf;
      _result = $v.result;
      _playUpLevels = $v.playUpLevels;
      _reasons = $v.reasons.toBuilder();
      _age = $v.age;
      _naturalCategory = $v.naturalCategory?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EligibilityCheck other) {
    _$v = other as _$EligibilityCheck;
  }

  @override
  void update(void Function(EligibilityCheckBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EligibilityCheck build() => _build();

  _$EligibilityCheck _build() {
    _$EligibilityCheck _$result;
    try {
      _$result = _$v ??
          _$EligibilityCheck._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'EligibilityCheck', 'playerId'),
            teamId: BuiltValueNullFieldError.checkNotNull(
                teamId, r'EligibilityCheck', 'teamId'),
            asOf: BuiltValueNullFieldError.checkNotNull(
                asOf, r'EligibilityCheck', 'asOf'),
            result: BuiltValueNullFieldError.checkNotNull(
                result, r'EligibilityCheck', 'result'),
            playUpLevels: playUpLevels,
            reasons: reasons.build(),
            age: age,
            naturalCategory: _naturalCategory?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'reasons';
        reasons.build();

        _$failedField = 'naturalCategory';
        _naturalCategory?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EligibilityCheck', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
