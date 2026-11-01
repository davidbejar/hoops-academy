// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchEvent extends MatchEvent {
  @override
  final OneOf oneOf;

  factory _$MatchEvent([void Function(MatchEventBuilder)? updates]) =>
      (MatchEventBuilder()..update(updates))._build();

  _$MatchEvent._({required this.oneOf}) : super._();
  @override
  MatchEvent rebuild(void Function(MatchEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchEventBuilder toBuilder() => MatchEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchEvent && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchEvent')..add('oneOf', oneOf))
        .toString();
  }
}

class MatchEventBuilder implements Builder<MatchEvent, MatchEventBuilder> {
  _$MatchEvent? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  MatchEventBuilder() {
    MatchEvent._defaults(this);
  }

  MatchEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchEvent other) {
    _$v = other as _$MatchEvent;
  }

  @override
  void update(void Function(MatchEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchEvent build() => _build();

  _$MatchEvent _build() {
    final _$result = _$v ??
        _$MatchEvent._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
              oneOf, r'MatchEvent', 'oneOf'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
