// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_progress_counts.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanProgressCounts extends PlanProgressCounts {
  @override
  final int DONE;
  @override
  final int PARTIAL;
  @override
  final int NOT_DONE;

  factory _$PlanProgressCounts(
          [void Function(PlanProgressCountsBuilder)? updates]) =>
      (PlanProgressCountsBuilder()..update(updates))._build();

  _$PlanProgressCounts._(
      {required this.DONE, required this.PARTIAL, required this.NOT_DONE})
      : super._();
  @override
  PlanProgressCounts rebuild(
          void Function(PlanProgressCountsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanProgressCountsBuilder toBuilder() =>
      PlanProgressCountsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanProgressCounts &&
        DONE == other.DONE &&
        PARTIAL == other.PARTIAL &&
        NOT_DONE == other.NOT_DONE;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, DONE.hashCode);
    _$hash = $jc(_$hash, PARTIAL.hashCode);
    _$hash = $jc(_$hash, NOT_DONE.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanProgressCounts')
          ..add('DONE', DONE)
          ..add('PARTIAL', PARTIAL)
          ..add('NOT_DONE', NOT_DONE))
        .toString();
  }
}

class PlanProgressCountsBuilder
    implements Builder<PlanProgressCounts, PlanProgressCountsBuilder> {
  _$PlanProgressCounts? _$v;

  int? _DONE;
  int? get DONE => _$this._DONE;
  set DONE(int? DONE) => _$this._DONE = DONE;

  int? _PARTIAL;
  int? get PARTIAL => _$this._PARTIAL;
  set PARTIAL(int? PARTIAL) => _$this._PARTIAL = PARTIAL;

  int? _NOT_DONE;
  int? get NOT_DONE => _$this._NOT_DONE;
  set NOT_DONE(int? NOT_DONE) => _$this._NOT_DONE = NOT_DONE;

  PlanProgressCountsBuilder() {
    PlanProgressCounts._defaults(this);
  }

  PlanProgressCountsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _DONE = $v.DONE;
      _PARTIAL = $v.PARTIAL;
      _NOT_DONE = $v.NOT_DONE;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanProgressCounts other) {
    _$v = other as _$PlanProgressCounts;
  }

  @override
  void update(void Function(PlanProgressCountsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanProgressCounts build() => _build();

  _$PlanProgressCounts _build() {
    final _$result = _$v ??
        _$PlanProgressCounts._(
          DONE: BuiltValueNullFieldError.checkNotNull(
              DONE, r'PlanProgressCounts', 'DONE'),
          PARTIAL: BuiltValueNullFieldError.checkNotNull(
              PARTIAL, r'PlanProgressCounts', 'PARTIAL'),
          NOT_DONE: BuiltValueNullFieldError.checkNotNull(
              NOT_DONE, r'PlanProgressCounts', 'NOT_DONE'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
