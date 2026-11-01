// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_feed.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchEventFeed extends MatchEventFeed {
  @override
  final BuiltList<StoredMatchEvent> events;
  @override
  final int lastServerSeq;
  @override
  final bool hasMore;

  factory _$MatchEventFeed([void Function(MatchEventFeedBuilder)? updates]) =>
      (MatchEventFeedBuilder()..update(updates))._build();

  _$MatchEventFeed._(
      {required this.events,
      required this.lastServerSeq,
      required this.hasMore})
      : super._();
  @override
  MatchEventFeed rebuild(void Function(MatchEventFeedBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchEventFeedBuilder toBuilder() => MatchEventFeedBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchEventFeed &&
        events == other.events &&
        lastServerSeq == other.lastServerSeq &&
        hasMore == other.hasMore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, events.hashCode);
    _$hash = $jc(_$hash, lastServerSeq.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchEventFeed')
          ..add('events', events)
          ..add('lastServerSeq', lastServerSeq)
          ..add('hasMore', hasMore))
        .toString();
  }
}

class MatchEventFeedBuilder
    implements Builder<MatchEventFeed, MatchEventFeedBuilder> {
  _$MatchEventFeed? _$v;

  ListBuilder<StoredMatchEvent>? _events;
  ListBuilder<StoredMatchEvent> get events =>
      _$this._events ??= ListBuilder<StoredMatchEvent>();
  set events(ListBuilder<StoredMatchEvent>? events) => _$this._events = events;

  int? _lastServerSeq;
  int? get lastServerSeq => _$this._lastServerSeq;
  set lastServerSeq(int? lastServerSeq) =>
      _$this._lastServerSeq = lastServerSeq;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  MatchEventFeedBuilder() {
    MatchEventFeed._defaults(this);
  }

  MatchEventFeedBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _events = $v.events.toBuilder();
      _lastServerSeq = $v.lastServerSeq;
      _hasMore = $v.hasMore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchEventFeed other) {
    _$v = other as _$MatchEventFeed;
  }

  @override
  void update(void Function(MatchEventFeedBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchEventFeed build() => _build();

  _$MatchEventFeed _build() {
    _$MatchEventFeed _$result;
    try {
      _$result = _$v ??
          _$MatchEventFeed._(
            events: events.build(),
            lastServerSeq: BuiltValueNullFieldError.checkNotNull(
                lastServerSeq, r'MatchEventFeed', 'lastServerSeq'),
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'MatchEventFeed', 'hasMore'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'events';
        events.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MatchEventFeed', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
