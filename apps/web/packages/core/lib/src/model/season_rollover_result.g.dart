// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_rollover_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SeasonRolloverResult extends SeasonRolloverResult {
  @override
  final String fromSeasonId;
  @override
  final String toSeasonId;
  @override
  final BuiltList<TeamRef> clonedTeams;
  @override
  final BuiltList<Orphan> orphans;
  @override
  final BuiltList<String> openedCaseIds;

  factory _$SeasonRolloverResult(
          [void Function(SeasonRolloverResultBuilder)? updates]) =>
      (SeasonRolloverResultBuilder()..update(updates))._build();

  _$SeasonRolloverResult._(
      {required this.fromSeasonId,
      required this.toSeasonId,
      required this.clonedTeams,
      required this.orphans,
      required this.openedCaseIds})
      : super._();
  @override
  SeasonRolloverResult rebuild(
          void Function(SeasonRolloverResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeasonRolloverResultBuilder toBuilder() =>
      SeasonRolloverResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeasonRolloverResult &&
        fromSeasonId == other.fromSeasonId &&
        toSeasonId == other.toSeasonId &&
        clonedTeams == other.clonedTeams &&
        orphans == other.orphans &&
        openedCaseIds == other.openedCaseIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fromSeasonId.hashCode);
    _$hash = $jc(_$hash, toSeasonId.hashCode);
    _$hash = $jc(_$hash, clonedTeams.hashCode);
    _$hash = $jc(_$hash, orphans.hashCode);
    _$hash = $jc(_$hash, openedCaseIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeasonRolloverResult')
          ..add('fromSeasonId', fromSeasonId)
          ..add('toSeasonId', toSeasonId)
          ..add('clonedTeams', clonedTeams)
          ..add('orphans', orphans)
          ..add('openedCaseIds', openedCaseIds))
        .toString();
  }
}

class SeasonRolloverResultBuilder
    implements Builder<SeasonRolloverResult, SeasonRolloverResultBuilder> {
  _$SeasonRolloverResult? _$v;

  String? _fromSeasonId;
  String? get fromSeasonId => _$this._fromSeasonId;
  set fromSeasonId(String? fromSeasonId) => _$this._fromSeasonId = fromSeasonId;

  String? _toSeasonId;
  String? get toSeasonId => _$this._toSeasonId;
  set toSeasonId(String? toSeasonId) => _$this._toSeasonId = toSeasonId;

  ListBuilder<TeamRef>? _clonedTeams;
  ListBuilder<TeamRef> get clonedTeams =>
      _$this._clonedTeams ??= ListBuilder<TeamRef>();
  set clonedTeams(ListBuilder<TeamRef>? clonedTeams) =>
      _$this._clonedTeams = clonedTeams;

  ListBuilder<Orphan>? _orphans;
  ListBuilder<Orphan> get orphans => _$this._orphans ??= ListBuilder<Orphan>();
  set orphans(ListBuilder<Orphan>? orphans) => _$this._orphans = orphans;

  ListBuilder<String>? _openedCaseIds;
  ListBuilder<String> get openedCaseIds =>
      _$this._openedCaseIds ??= ListBuilder<String>();
  set openedCaseIds(ListBuilder<String>? openedCaseIds) =>
      _$this._openedCaseIds = openedCaseIds;

  SeasonRolloverResultBuilder() {
    SeasonRolloverResult._defaults(this);
  }

  SeasonRolloverResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fromSeasonId = $v.fromSeasonId;
      _toSeasonId = $v.toSeasonId;
      _clonedTeams = $v.clonedTeams.toBuilder();
      _orphans = $v.orphans.toBuilder();
      _openedCaseIds = $v.openedCaseIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeasonRolloverResult other) {
    _$v = other as _$SeasonRolloverResult;
  }

  @override
  void update(void Function(SeasonRolloverResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeasonRolloverResult build() => _build();

  _$SeasonRolloverResult _build() {
    _$SeasonRolloverResult _$result;
    try {
      _$result = _$v ??
          _$SeasonRolloverResult._(
            fromSeasonId: BuiltValueNullFieldError.checkNotNull(
                fromSeasonId, r'SeasonRolloverResult', 'fromSeasonId'),
            toSeasonId: BuiltValueNullFieldError.checkNotNull(
                toSeasonId, r'SeasonRolloverResult', 'toSeasonId'),
            clonedTeams: clonedTeams.build(),
            orphans: orphans.build(),
            openedCaseIds: openedCaseIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clonedTeams';
        clonedTeams.build();
        _$failedField = 'orphans';
        orphans.build();
        _$failedField = 'openedCaseIds';
        openedCaseIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SeasonRolloverResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
