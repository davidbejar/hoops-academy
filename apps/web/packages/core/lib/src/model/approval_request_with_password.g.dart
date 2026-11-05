// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_request_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ApprovalRequestWithPassword extends ApprovalRequestWithPassword {
  @override
  final String id;
  @override
  final ApprovalAction action;
  @override
  final ApprovalStatus status;
  @override
  final PlayerRef player;
  @override
  final ApprovalPayload payload;
  @override
  final PersonRef requestedBy;
  @override
  final DateTime requestedAt;
  @override
  final PersonRef? decidedBy;
  @override
  final DateTime? decidedAt;
  @override
  final String? decisionNote;
  @override
  final String? temporaryPassword;

  factory _$ApprovalRequestWithPassword(
          [void Function(ApprovalRequestWithPasswordBuilder)? updates]) =>
      (ApprovalRequestWithPasswordBuilder()..update(updates))._build();

  _$ApprovalRequestWithPassword._(
      {required this.id,
      required this.action,
      required this.status,
      required this.player,
      required this.payload,
      required this.requestedBy,
      required this.requestedAt,
      this.decidedBy,
      this.decidedAt,
      this.decisionNote,
      this.temporaryPassword})
      : super._();
  @override
  ApprovalRequestWithPassword rebuild(
          void Function(ApprovalRequestWithPasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApprovalRequestWithPasswordBuilder toBuilder() =>
      ApprovalRequestWithPasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApprovalRequestWithPassword &&
        id == other.id &&
        action == other.action &&
        status == other.status &&
        player == other.player &&
        payload == other.payload &&
        requestedBy == other.requestedBy &&
        requestedAt == other.requestedAt &&
        decidedBy == other.decidedBy &&
        decidedAt == other.decidedAt &&
        decisionNote == other.decisionNote &&
        temporaryPassword == other.temporaryPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, requestedBy.hashCode);
    _$hash = $jc(_$hash, requestedAt.hashCode);
    _$hash = $jc(_$hash, decidedBy.hashCode);
    _$hash = $jc(_$hash, decidedAt.hashCode);
    _$hash = $jc(_$hash, decisionNote.hashCode);
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ApprovalRequestWithPassword')
          ..add('id', id)
          ..add('action', action)
          ..add('status', status)
          ..add('player', player)
          ..add('payload', payload)
          ..add('requestedBy', requestedBy)
          ..add('requestedAt', requestedAt)
          ..add('decidedBy', decidedBy)
          ..add('decidedAt', decidedAt)
          ..add('decisionNote', decisionNote)
          ..add('temporaryPassword', temporaryPassword))
        .toString();
  }
}

class ApprovalRequestWithPasswordBuilder
    implements
        Builder<ApprovalRequestWithPassword,
            ApprovalRequestWithPasswordBuilder> {
  _$ApprovalRequestWithPassword? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ApprovalAction? _action;
  ApprovalAction? get action => _$this._action;
  set action(ApprovalAction? action) => _$this._action = action;

  ApprovalStatus? _status;
  ApprovalStatus? get status => _$this._status;
  set status(ApprovalStatus? status) => _$this._status = status;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  ApprovalPayloadBuilder? _payload;
  ApprovalPayloadBuilder get payload =>
      _$this._payload ??= ApprovalPayloadBuilder();
  set payload(ApprovalPayloadBuilder? payload) => _$this._payload = payload;

  PersonRefBuilder? _requestedBy;
  PersonRefBuilder get requestedBy =>
      _$this._requestedBy ??= PersonRefBuilder();
  set requestedBy(PersonRefBuilder? requestedBy) =>
      _$this._requestedBy = requestedBy;

  DateTime? _requestedAt;
  DateTime? get requestedAt => _$this._requestedAt;
  set requestedAt(DateTime? requestedAt) => _$this._requestedAt = requestedAt;

  PersonRefBuilder? _decidedBy;
  PersonRefBuilder get decidedBy => _$this._decidedBy ??= PersonRefBuilder();
  set decidedBy(PersonRefBuilder? decidedBy) => _$this._decidedBy = decidedBy;

  DateTime? _decidedAt;
  DateTime? get decidedAt => _$this._decidedAt;
  set decidedAt(DateTime? decidedAt) => _$this._decidedAt = decidedAt;

  String? _decisionNote;
  String? get decisionNote => _$this._decisionNote;
  set decisionNote(String? decisionNote) => _$this._decisionNote = decisionNote;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  ApprovalRequestWithPasswordBuilder() {
    ApprovalRequestWithPassword._defaults(this);
  }

  ApprovalRequestWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _action = $v.action;
      _status = $v.status;
      _player = $v.player.toBuilder();
      _payload = $v.payload.toBuilder();
      _requestedBy = $v.requestedBy.toBuilder();
      _requestedAt = $v.requestedAt;
      _decidedBy = $v.decidedBy?.toBuilder();
      _decidedAt = $v.decidedAt;
      _decisionNote = $v.decisionNote;
      _temporaryPassword = $v.temporaryPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApprovalRequestWithPassword other) {
    _$v = other as _$ApprovalRequestWithPassword;
  }

  @override
  void update(void Function(ApprovalRequestWithPasswordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ApprovalRequestWithPassword build() => _build();

  _$ApprovalRequestWithPassword _build() {
    _$ApprovalRequestWithPassword _$result;
    try {
      _$result = _$v ??
          _$ApprovalRequestWithPassword._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ApprovalRequestWithPassword', 'id'),
            action: BuiltValueNullFieldError.checkNotNull(
                action, r'ApprovalRequestWithPassword', 'action'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'ApprovalRequestWithPassword', 'status'),
            player: player.build(),
            payload: payload.build(),
            requestedBy: requestedBy.build(),
            requestedAt: BuiltValueNullFieldError.checkNotNull(
                requestedAt, r'ApprovalRequestWithPassword', 'requestedAt'),
            decidedBy: _decidedBy?.build(),
            decidedAt: decidedAt,
            decisionNote: decisionNote,
            temporaryPassword: temporaryPassword,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
        _$failedField = 'payload';
        payload.build();
        _$failedField = 'requestedBy';
        requestedBy.build();

        _$failedField = 'decidedBy';
        _decidedBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ApprovalRequestWithPassword', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
