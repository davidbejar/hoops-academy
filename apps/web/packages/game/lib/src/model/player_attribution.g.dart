// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_attribution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class PlayerAttributionBuilder {
  void replace(PlayerAttribution other);
  void update(void Function(PlayerAttributionBuilder) updates);
  String? get playerId;
  set playerId(String? playerId);
}

class _$$PlayerAttribution extends $PlayerAttribution {
  @override
  final String playerId;

  factory _$$PlayerAttribution(
          [void Function($PlayerAttributionBuilder)? updates]) =>
      ($PlayerAttributionBuilder()..update(updates))._build();

  _$$PlayerAttribution._({required this.playerId}) : super._();
  @override
  $PlayerAttribution rebuild(
          void Function($PlayerAttributionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $PlayerAttributionBuilder toBuilder() =>
      $PlayerAttributionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $PlayerAttribution && playerId == other.playerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$PlayerAttribution')
          ..add('playerId', playerId))
        .toString();
  }
}

class $PlayerAttributionBuilder
    implements
        Builder<$PlayerAttribution, $PlayerAttributionBuilder>,
        PlayerAttributionBuilder {
  _$$PlayerAttribution? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  $PlayerAttributionBuilder() {
    $PlayerAttribution._defaults(this);
  }

  $PlayerAttributionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $PlayerAttribution other) {
    _$v = other as _$$PlayerAttribution;
  }

  @override
  void update(void Function($PlayerAttributionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $PlayerAttribution build() => _build();

  _$$PlayerAttribution _build() {
    final _$result = _$v ??
        _$$PlayerAttribution._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'$PlayerAttribution', 'playerId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
