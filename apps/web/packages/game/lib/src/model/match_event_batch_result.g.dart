// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_batch_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchEventBatchResult extends MatchEventBatchResult {
  @override
  final BuiltList<MatchEventResult> results;
  @override
  final int lastServerSeq;

  factory _$MatchEventBatchResult(
          [void Function(MatchEventBatchResultBuilder)? updates]) =>
      (MatchEventBatchResultBuilder()..update(updates))._build();

  _$MatchEventBatchResult._(
      {required this.results, required this.lastServerSeq})
      : super._();
  @override
  MatchEventBatchResult rebuild(
          void Function(MatchEventBatchResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchEventBatchResultBuilder toBuilder() =>
      MatchEventBatchResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchEventBatchResult &&
        results == other.results &&
        lastServerSeq == other.lastServerSeq;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jc(_$hash, lastServerSeq.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchEventBatchResult')
          ..add('results', results)
          ..add('lastServerSeq', lastServerSeq))
        .toString();
  }
}

class MatchEventBatchResultBuilder
    implements Builder<MatchEventBatchResult, MatchEventBatchResultBuilder> {
  _$MatchEventBatchResult? _$v;

  ListBuilder<MatchEventResult>? _results;
  ListBuilder<MatchEventResult> get results =>
      _$this._results ??= ListBuilder<MatchEventResult>();
  set results(ListBuilder<MatchEventResult>? results) =>
      _$this._results = results;

  int? _lastServerSeq;
  int? get lastServerSeq => _$this._lastServerSeq;
  set lastServerSeq(int? lastServerSeq) =>
      _$this._lastServerSeq = lastServerSeq;

  MatchEventBatchResultBuilder() {
    MatchEventBatchResult._defaults(this);
  }

  MatchEventBatchResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _results = $v.results.toBuilder();
      _lastServerSeq = $v.lastServerSeq;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchEventBatchResult other) {
    _$v = other as _$MatchEventBatchResult;
  }

  @override
  void update(void Function(MatchEventBatchResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchEventBatchResult build() => _build();

  _$MatchEventBatchResult _build() {
    _$MatchEventBatchResult _$result;
    try {
      _$result = _$v ??
          _$MatchEventBatchResult._(
            results: results.build(),
            lastServerSeq: BuiltValueNullFieldError.checkNotNull(
                lastServerSeq, r'MatchEventBatchResult', 'lastServerSeq'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MatchEventBatchResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
