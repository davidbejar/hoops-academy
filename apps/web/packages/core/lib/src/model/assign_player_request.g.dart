// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssignPlayerRequest extends AssignPlayerRequest {
  @override
  final String playerId;
  @override
  final String? jerseyNumber;
  @override
  final Date? joinedOn;

  factory _$AssignPlayerRequest(
          [void Function(AssignPlayerRequestBuilder)? updates]) =>
      (AssignPlayerRequestBuilder()..update(updates))._build();

  _$AssignPlayerRequest._(
      {required this.playerId, this.jerseyNumber, this.joinedOn})
      : super._();
  @override
  AssignPlayerRequest rebuild(
          void Function(AssignPlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssignPlayerRequestBuilder toBuilder() =>
      AssignPlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssignPlayerRequest &&
        playerId == other.playerId &&
        jerseyNumber == other.jerseyNumber &&
        joinedOn == other.joinedOn;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, joinedOn.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssignPlayerRequest')
          ..add('playerId', playerId)
          ..add('jerseyNumber', jerseyNumber)
          ..add('joinedOn', joinedOn))
        .toString();
  }
}

class AssignPlayerRequestBuilder
    implements Builder<AssignPlayerRequest, AssignPlayerRequestBuilder> {
  _$AssignPlayerRequest? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  Date? _joinedOn;
  Date? get joinedOn => _$this._joinedOn;
  set joinedOn(Date? joinedOn) => _$this._joinedOn = joinedOn;

  AssignPlayerRequestBuilder() {
    AssignPlayerRequest._defaults(this);
  }

  AssignPlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _jerseyNumber = $v.jerseyNumber;
      _joinedOn = $v.joinedOn;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssignPlayerRequest other) {
    _$v = other as _$AssignPlayerRequest;
  }

  @override
  void update(void Function(AssignPlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssignPlayerRequest build() => _build();

  _$AssignPlayerRequest _build() {
    final _$result = _$v ??
        _$AssignPlayerRequest._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'AssignPlayerRequest', 'playerId'),
          jerseyNumber: jerseyNumber,
          joinedOn: joinedOn,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
