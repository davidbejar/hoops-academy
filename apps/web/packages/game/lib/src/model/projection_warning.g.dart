// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projection_warning.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProjectionWarning extends ProjectionWarning {
  @override
  final String code;
  @override
  final String eventId;
  @override
  final String? playerId;
  @override
  final String message;

  factory _$ProjectionWarning(
          [void Function(ProjectionWarningBuilder)? updates]) =>
      (ProjectionWarningBuilder()..update(updates))._build();

  _$ProjectionWarning._(
      {required this.code,
      required this.eventId,
      this.playerId,
      required this.message})
      : super._();
  @override
  ProjectionWarning rebuild(void Function(ProjectionWarningBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProjectionWarningBuilder toBuilder() =>
      ProjectionWarningBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProjectionWarning &&
        code == other.code &&
        eventId == other.eventId &&
        playerId == other.playerId &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, eventId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProjectionWarning')
          ..add('code', code)
          ..add('eventId', eventId)
          ..add('playerId', playerId)
          ..add('message', message))
        .toString();
  }
}

class ProjectionWarningBuilder
    implements Builder<ProjectionWarning, ProjectionWarningBuilder> {
  _$ProjectionWarning? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  ProjectionWarningBuilder() {
    ProjectionWarning._defaults(this);
  }

  ProjectionWarningBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _eventId = $v.eventId;
      _playerId = $v.playerId;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProjectionWarning other) {
    _$v = other as _$ProjectionWarning;
  }

  @override
  void update(void Function(ProjectionWarningBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProjectionWarning build() => _build();

  _$ProjectionWarning _build() {
    final _$result = _$v ??
        _$ProjectionWarning._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'ProjectionWarning', 'code'),
          eventId: BuiltValueNullFieldError.checkNotNull(
              eventId, r'ProjectionWarning', 'eventId'),
          playerId: playerId,
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'ProjectionWarning', 'message'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
