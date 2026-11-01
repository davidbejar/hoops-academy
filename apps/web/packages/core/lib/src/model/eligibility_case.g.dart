// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_case.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EligibilityCase extends EligibilityCase {
  @override
  final String id;
  @override
  final PlayerRef player;
  @override
  final TeamRef team;
  @override
  final EligibilityReason reason;
  @override
  final EligibilityCaseStatus status;
  @override
  final DateTime openedAt;
  @override
  final DateTime? resolvedAt;
  @override
  final PersonRef? resolvedBy;
  @override
  final EligibilityCaseResolution? resolution;
  @override
  final String? resolutionNote;

  factory _$EligibilityCase([void Function(EligibilityCaseBuilder)? updates]) =>
      (EligibilityCaseBuilder()..update(updates))._build();

  _$EligibilityCase._(
      {required this.id,
      required this.player,
      required this.team,
      required this.reason,
      required this.status,
      required this.openedAt,
      this.resolvedAt,
      this.resolvedBy,
      this.resolution,
      this.resolutionNote})
      : super._();
  @override
  EligibilityCase rebuild(void Function(EligibilityCaseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EligibilityCaseBuilder toBuilder() => EligibilityCaseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EligibilityCase &&
        id == other.id &&
        player == other.player &&
        team == other.team &&
        reason == other.reason &&
        status == other.status &&
        openedAt == other.openedAt &&
        resolvedAt == other.resolvedAt &&
        resolvedBy == other.resolvedBy &&
        resolution == other.resolution &&
        resolutionNote == other.resolutionNote;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, team.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, openedAt.hashCode);
    _$hash = $jc(_$hash, resolvedAt.hashCode);
    _$hash = $jc(_$hash, resolvedBy.hashCode);
    _$hash = $jc(_$hash, resolution.hashCode);
    _$hash = $jc(_$hash, resolutionNote.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EligibilityCase')
          ..add('id', id)
          ..add('player', player)
          ..add('team', team)
          ..add('reason', reason)
          ..add('status', status)
          ..add('openedAt', openedAt)
          ..add('resolvedAt', resolvedAt)
          ..add('resolvedBy', resolvedBy)
          ..add('resolution', resolution)
          ..add('resolutionNote', resolutionNote))
        .toString();
  }
}

class EligibilityCaseBuilder
    implements Builder<EligibilityCase, EligibilityCaseBuilder> {
  _$EligibilityCase? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  TeamRefBuilder? _team;
  TeamRefBuilder get team => _$this._team ??= TeamRefBuilder();
  set team(TeamRefBuilder? team) => _$this._team = team;

  EligibilityReason? _reason;
  EligibilityReason? get reason => _$this._reason;
  set reason(EligibilityReason? reason) => _$this._reason = reason;

  EligibilityCaseStatus? _status;
  EligibilityCaseStatus? get status => _$this._status;
  set status(EligibilityCaseStatus? status) => _$this._status = status;

  DateTime? _openedAt;
  DateTime? get openedAt => _$this._openedAt;
  set openedAt(DateTime? openedAt) => _$this._openedAt = openedAt;

  DateTime? _resolvedAt;
  DateTime? get resolvedAt => _$this._resolvedAt;
  set resolvedAt(DateTime? resolvedAt) => _$this._resolvedAt = resolvedAt;

  PersonRefBuilder? _resolvedBy;
  PersonRefBuilder get resolvedBy => _$this._resolvedBy ??= PersonRefBuilder();
  set resolvedBy(PersonRefBuilder? resolvedBy) =>
      _$this._resolvedBy = resolvedBy;

  EligibilityCaseResolution? _resolution;
  EligibilityCaseResolution? get resolution => _$this._resolution;
  set resolution(EligibilityCaseResolution? resolution) =>
      _$this._resolution = resolution;

  String? _resolutionNote;
  String? get resolutionNote => _$this._resolutionNote;
  set resolutionNote(String? resolutionNote) =>
      _$this._resolutionNote = resolutionNote;

  EligibilityCaseBuilder() {
    EligibilityCase._defaults(this);
  }

  EligibilityCaseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _player = $v.player.toBuilder();
      _team = $v.team.toBuilder();
      _reason = $v.reason;
      _status = $v.status;
      _openedAt = $v.openedAt;
      _resolvedAt = $v.resolvedAt;
      _resolvedBy = $v.resolvedBy?.toBuilder();
      _resolution = $v.resolution;
      _resolutionNote = $v.resolutionNote;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EligibilityCase other) {
    _$v = other as _$EligibilityCase;
  }

  @override
  void update(void Function(EligibilityCaseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EligibilityCase build() => _build();

  _$EligibilityCase _build() {
    _$EligibilityCase _$result;
    try {
      _$result = _$v ??
          _$EligibilityCase._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'EligibilityCase', 'id'),
            player: player.build(),
            team: team.build(),
            reason: BuiltValueNullFieldError.checkNotNull(
                reason, r'EligibilityCase', 'reason'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'EligibilityCase', 'status'),
            openedAt: BuiltValueNullFieldError.checkNotNull(
                openedAt, r'EligibilityCase', 'openedAt'),
            resolvedAt: resolvedAt,
            resolvedBy: _resolvedBy?.build(),
            resolution: resolution,
            resolutionNote: resolutionNote,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
        _$failedField = 'team';
        team.build();

        _$failedField = 'resolvedBy';
        _resolvedBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EligibilityCase', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
