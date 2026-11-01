// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_progress.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanProgress extends PlanProgress {
  @override
  final String assignmentId;
  @override
  final int total;
  @override
  final int notRecorded;
  @override
  final PlanProgressCounts counts;
  @override
  final BuiltList<PlayerProgress> players;

  factory _$PlanProgress([void Function(PlanProgressBuilder)? updates]) =>
      (PlanProgressBuilder()..update(updates))._build();

  _$PlanProgress._(
      {required this.assignmentId,
      required this.total,
      required this.notRecorded,
      required this.counts,
      required this.players})
      : super._();
  @override
  PlanProgress rebuild(void Function(PlanProgressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanProgressBuilder toBuilder() => PlanProgressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanProgress &&
        assignmentId == other.assignmentId &&
        total == other.total &&
        notRecorded == other.notRecorded &&
        counts == other.counts &&
        players == other.players;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assignmentId.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, notRecorded.hashCode);
    _$hash = $jc(_$hash, counts.hashCode);
    _$hash = $jc(_$hash, players.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanProgress')
          ..add('assignmentId', assignmentId)
          ..add('total', total)
          ..add('notRecorded', notRecorded)
          ..add('counts', counts)
          ..add('players', players))
        .toString();
  }
}

class PlanProgressBuilder
    implements Builder<PlanProgress, PlanProgressBuilder> {
  _$PlanProgress? _$v;

  String? _assignmentId;
  String? get assignmentId => _$this._assignmentId;
  set assignmentId(String? assignmentId) => _$this._assignmentId = assignmentId;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _notRecorded;
  int? get notRecorded => _$this._notRecorded;
  set notRecorded(int? notRecorded) => _$this._notRecorded = notRecorded;

  PlanProgressCountsBuilder? _counts;
  PlanProgressCountsBuilder get counts =>
      _$this._counts ??= PlanProgressCountsBuilder();
  set counts(PlanProgressCountsBuilder? counts) => _$this._counts = counts;

  ListBuilder<PlayerProgress>? _players;
  ListBuilder<PlayerProgress> get players =>
      _$this._players ??= ListBuilder<PlayerProgress>();
  set players(ListBuilder<PlayerProgress>? players) =>
      _$this._players = players;

  PlanProgressBuilder() {
    PlanProgress._defaults(this);
  }

  PlanProgressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assignmentId = $v.assignmentId;
      _total = $v.total;
      _notRecorded = $v.notRecorded;
      _counts = $v.counts.toBuilder();
      _players = $v.players.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanProgress other) {
    _$v = other as _$PlanProgress;
  }

  @override
  void update(void Function(PlanProgressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanProgress build() => _build();

  _$PlanProgress _build() {
    _$PlanProgress _$result;
    try {
      _$result = _$v ??
          _$PlanProgress._(
            assignmentId: BuiltValueNullFieldError.checkNotNull(
                assignmentId, r'PlanProgress', 'assignmentId'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'PlanProgress', 'total'),
            notRecorded: BuiltValueNullFieldError.checkNotNull(
                notRecorded, r'PlanProgress', 'notRecorded'),
            counts: counts.build(),
            players: players.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'counts';
        counts.build();
        _$failedField = 'players';
        players.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlanProgress', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
