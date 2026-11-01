// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authz_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthzSummary extends AuthzSummary {
  @override
  final BuiltList<String> staffTeamIds;
  @override
  final BuiltList<String> linkedPlayerIds;
  @override
  final String? ownPlayerId;
  @override
  final BuiltList<String> playerTeamIds;
  @override
  final String timezone;

  factory _$AuthzSummary([void Function(AuthzSummaryBuilder)? updates]) =>
      (AuthzSummaryBuilder()..update(updates))._build();

  _$AuthzSummary._(
      {required this.staffTeamIds,
      required this.linkedPlayerIds,
      this.ownPlayerId,
      required this.playerTeamIds,
      required this.timezone})
      : super._();
  @override
  AuthzSummary rebuild(void Function(AuthzSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuthzSummaryBuilder toBuilder() => AuthzSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthzSummary &&
        staffTeamIds == other.staffTeamIds &&
        linkedPlayerIds == other.linkedPlayerIds &&
        ownPlayerId == other.ownPlayerId &&
        playerTeamIds == other.playerTeamIds &&
        timezone == other.timezone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, staffTeamIds.hashCode);
    _$hash = $jc(_$hash, linkedPlayerIds.hashCode);
    _$hash = $jc(_$hash, ownPlayerId.hashCode);
    _$hash = $jc(_$hash, playerTeamIds.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthzSummary')
          ..add('staffTeamIds', staffTeamIds)
          ..add('linkedPlayerIds', linkedPlayerIds)
          ..add('ownPlayerId', ownPlayerId)
          ..add('playerTeamIds', playerTeamIds)
          ..add('timezone', timezone))
        .toString();
  }
}

class AuthzSummaryBuilder
    implements Builder<AuthzSummary, AuthzSummaryBuilder> {
  _$AuthzSummary? _$v;

  ListBuilder<String>? _staffTeamIds;
  ListBuilder<String> get staffTeamIds =>
      _$this._staffTeamIds ??= ListBuilder<String>();
  set staffTeamIds(ListBuilder<String>? staffTeamIds) =>
      _$this._staffTeamIds = staffTeamIds;

  ListBuilder<String>? _linkedPlayerIds;
  ListBuilder<String> get linkedPlayerIds =>
      _$this._linkedPlayerIds ??= ListBuilder<String>();
  set linkedPlayerIds(ListBuilder<String>? linkedPlayerIds) =>
      _$this._linkedPlayerIds = linkedPlayerIds;

  String? _ownPlayerId;
  String? get ownPlayerId => _$this._ownPlayerId;
  set ownPlayerId(String? ownPlayerId) => _$this._ownPlayerId = ownPlayerId;

  ListBuilder<String>? _playerTeamIds;
  ListBuilder<String> get playerTeamIds =>
      _$this._playerTeamIds ??= ListBuilder<String>();
  set playerTeamIds(ListBuilder<String>? playerTeamIds) =>
      _$this._playerTeamIds = playerTeamIds;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  AuthzSummaryBuilder() {
    AuthzSummary._defaults(this);
  }

  AuthzSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _staffTeamIds = $v.staffTeamIds.toBuilder();
      _linkedPlayerIds = $v.linkedPlayerIds.toBuilder();
      _ownPlayerId = $v.ownPlayerId;
      _playerTeamIds = $v.playerTeamIds.toBuilder();
      _timezone = $v.timezone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthzSummary other) {
    _$v = other as _$AuthzSummary;
  }

  @override
  void update(void Function(AuthzSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthzSummary build() => _build();

  _$AuthzSummary _build() {
    _$AuthzSummary _$result;
    try {
      _$result = _$v ??
          _$AuthzSummary._(
            staffTeamIds: staffTeamIds.build(),
            linkedPlayerIds: linkedPlayerIds.build(),
            ownPlayerId: ownPlayerId,
            playerTeamIds: playerTeamIds.build(),
            timezone: BuiltValueNullFieldError.checkNotNull(
                timezone, r'AuthzSummary', 'timezone'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'staffTeamIds';
        staffTeamIds.build();
        _$failedField = 'linkedPlayerIds';
        linkedPlayerIds.build();

        _$failedField = 'playerTeamIds';
        playerTeamIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AuthzSummary', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
