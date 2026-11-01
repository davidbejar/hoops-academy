// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replace_match_roster_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReplaceMatchRosterRequest extends ReplaceMatchRosterRequest {
  @override
  final BuiltList<MatchRosterEntryInput> entries;

  factory _$ReplaceMatchRosterRequest(
          [void Function(ReplaceMatchRosterRequestBuilder)? updates]) =>
      (ReplaceMatchRosterRequestBuilder()..update(updates))._build();

  _$ReplaceMatchRosterRequest._({required this.entries}) : super._();
  @override
  ReplaceMatchRosterRequest rebuild(
          void Function(ReplaceMatchRosterRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReplaceMatchRosterRequestBuilder toBuilder() =>
      ReplaceMatchRosterRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReplaceMatchRosterRequest && entries == other.entries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReplaceMatchRosterRequest')
          ..add('entries', entries))
        .toString();
  }
}

class ReplaceMatchRosterRequestBuilder
    implements
        Builder<ReplaceMatchRosterRequest, ReplaceMatchRosterRequestBuilder> {
  _$ReplaceMatchRosterRequest? _$v;

  ListBuilder<MatchRosterEntryInput>? _entries;
  ListBuilder<MatchRosterEntryInput> get entries =>
      _$this._entries ??= ListBuilder<MatchRosterEntryInput>();
  set entries(ListBuilder<MatchRosterEntryInput>? entries) =>
      _$this._entries = entries;

  ReplaceMatchRosterRequestBuilder() {
    ReplaceMatchRosterRequest._defaults(this);
  }

  ReplaceMatchRosterRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entries = $v.entries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReplaceMatchRosterRequest other) {
    _$v = other as _$ReplaceMatchRosterRequest;
  }

  @override
  void update(void Function(ReplaceMatchRosterRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReplaceMatchRosterRequest build() => _build();

  _$ReplaceMatchRosterRequest _build() {
    _$ReplaceMatchRosterRequest _$result;
    try {
      _$result = _$v ??
          _$ReplaceMatchRosterRequest._(
            entries: entries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReplaceMatchRosterRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
