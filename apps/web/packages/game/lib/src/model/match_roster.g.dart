// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_roster.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchRoster extends MatchRoster {
  @override
  final String matchId;
  @override
  final BuiltList<MatchRosterEntry> entries;

  factory _$MatchRoster([void Function(MatchRosterBuilder)? updates]) =>
      (MatchRosterBuilder()..update(updates))._build();

  _$MatchRoster._({required this.matchId, required this.entries}) : super._();
  @override
  MatchRoster rebuild(void Function(MatchRosterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchRosterBuilder toBuilder() => MatchRosterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchRoster &&
        matchId == other.matchId &&
        entries == other.entries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, matchId.hashCode);
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchRoster')
          ..add('matchId', matchId)
          ..add('entries', entries))
        .toString();
  }
}

class MatchRosterBuilder implements Builder<MatchRoster, MatchRosterBuilder> {
  _$MatchRoster? _$v;

  String? _matchId;
  String? get matchId => _$this._matchId;
  set matchId(String? matchId) => _$this._matchId = matchId;

  ListBuilder<MatchRosterEntry>? _entries;
  ListBuilder<MatchRosterEntry> get entries =>
      _$this._entries ??= ListBuilder<MatchRosterEntry>();
  set entries(ListBuilder<MatchRosterEntry>? entries) =>
      _$this._entries = entries;

  MatchRosterBuilder() {
    MatchRoster._defaults(this);
  }

  MatchRosterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _matchId = $v.matchId;
      _entries = $v.entries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchRoster other) {
    _$v = other as _$MatchRoster;
  }

  @override
  void update(void Function(MatchRosterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchRoster build() => _build();

  _$MatchRoster _build() {
    _$MatchRoster _$result;
    try {
      _$result = _$v ??
          _$MatchRoster._(
            matchId: BuiltValueNullFieldError.checkNotNull(
                matchId, r'MatchRoster', 'matchId'),
            entries: entries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MatchRoster', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
