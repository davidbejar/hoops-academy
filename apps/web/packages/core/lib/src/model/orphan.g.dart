// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orphan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Orphan extends Orphan {
  @override
  final PlayerRef player;
  @override
  final TeamRef? previousTeam;
  @override
  final BuiltList<EligibilityReason> reasons;

  factory _$Orphan([void Function(OrphanBuilder)? updates]) =>
      (OrphanBuilder()..update(updates))._build();

  _$Orphan._({required this.player, this.previousTeam, required this.reasons})
      : super._();
  @override
  Orphan rebuild(void Function(OrphanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrphanBuilder toBuilder() => OrphanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Orphan &&
        player == other.player &&
        previousTeam == other.previousTeam &&
        reasons == other.reasons;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, previousTeam.hashCode);
    _$hash = $jc(_$hash, reasons.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Orphan')
          ..add('player', player)
          ..add('previousTeam', previousTeam)
          ..add('reasons', reasons))
        .toString();
  }
}

class OrphanBuilder implements Builder<Orphan, OrphanBuilder> {
  _$Orphan? _$v;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  TeamRefBuilder? _previousTeam;
  TeamRefBuilder get previousTeam => _$this._previousTeam ??= TeamRefBuilder();
  set previousTeam(TeamRefBuilder? previousTeam) =>
      _$this._previousTeam = previousTeam;

  ListBuilder<EligibilityReason>? _reasons;
  ListBuilder<EligibilityReason> get reasons =>
      _$this._reasons ??= ListBuilder<EligibilityReason>();
  set reasons(ListBuilder<EligibilityReason>? reasons) =>
      _$this._reasons = reasons;

  OrphanBuilder() {
    Orphan._defaults(this);
  }

  OrphanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _player = $v.player.toBuilder();
      _previousTeam = $v.previousTeam?.toBuilder();
      _reasons = $v.reasons.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Orphan other) {
    _$v = other as _$Orphan;
  }

  @override
  void update(void Function(OrphanBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Orphan build() => _build();

  _$Orphan _build() {
    _$Orphan _$result;
    try {
      _$result = _$v ??
          _$Orphan._(
            player: player.build(),
            previousTeam: _previousTeam?.build(),
            reasons: reasons.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
        _$failedField = 'previousTeam';
        _previousTeam?.build();
        _$failedField = 'reasons';
        reasons.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Orphan', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
