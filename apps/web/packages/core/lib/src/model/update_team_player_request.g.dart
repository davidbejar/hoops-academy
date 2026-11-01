// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_team_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTeamPlayerRequest extends UpdateTeamPlayerRequest {
  @override
  final String? jerseyNumber;

  factory _$UpdateTeamPlayerRequest(
          [void Function(UpdateTeamPlayerRequestBuilder)? updates]) =>
      (UpdateTeamPlayerRequestBuilder()..update(updates))._build();

  _$UpdateTeamPlayerRequest._({this.jerseyNumber}) : super._();
  @override
  UpdateTeamPlayerRequest rebuild(
          void Function(UpdateTeamPlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTeamPlayerRequestBuilder toBuilder() =>
      UpdateTeamPlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTeamPlayerRequest &&
        jerseyNumber == other.jerseyNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTeamPlayerRequest')
          ..add('jerseyNumber', jerseyNumber))
        .toString();
  }
}

class UpdateTeamPlayerRequestBuilder
    implements
        Builder<UpdateTeamPlayerRequest, UpdateTeamPlayerRequestBuilder> {
  _$UpdateTeamPlayerRequest? _$v;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  UpdateTeamPlayerRequestBuilder() {
    UpdateTeamPlayerRequest._defaults(this);
  }

  UpdateTeamPlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jerseyNumber = $v.jerseyNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTeamPlayerRequest other) {
    _$v = other as _$UpdateTeamPlayerRequest;
  }

  @override
  void update(void Function(UpdateTeamPlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTeamPlayerRequest build() => _build();

  _$UpdateTeamPlayerRequest _build() {
    final _$result = _$v ??
        _$UpdateTeamPlayerRequest._(
          jerseyNumber: jerseyNumber,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
