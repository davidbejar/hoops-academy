// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_batch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchEventBatch extends MatchEventBatch {
  @override
  final BuiltList<MatchEvent> events;

  factory _$MatchEventBatch([void Function(MatchEventBatchBuilder)? updates]) =>
      (MatchEventBatchBuilder()..update(updates))._build();

  _$MatchEventBatch._({required this.events}) : super._();
  @override
  MatchEventBatch rebuild(void Function(MatchEventBatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchEventBatchBuilder toBuilder() => MatchEventBatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchEventBatch && events == other.events;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, events.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchEventBatch')
          ..add('events', events))
        .toString();
  }
}

class MatchEventBatchBuilder
    implements Builder<MatchEventBatch, MatchEventBatchBuilder> {
  _$MatchEventBatch? _$v;

  ListBuilder<MatchEvent>? _events;
  ListBuilder<MatchEvent> get events =>
      _$this._events ??= ListBuilder<MatchEvent>();
  set events(ListBuilder<MatchEvent>? events) => _$this._events = events;

  MatchEventBatchBuilder() {
    MatchEventBatch._defaults(this);
  }

  MatchEventBatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _events = $v.events.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchEventBatch other) {
    _$v = other as _$MatchEventBatch;
  }

  @override
  void update(void Function(MatchEventBatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchEventBatch build() => _build();

  _$MatchEventBatch _build() {
    _$MatchEventBatch _$result;
    try {
      _$result = _$v ??
          _$MatchEventBatch._(
            events: events.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'events';
        events.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MatchEventBatch', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
